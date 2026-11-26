import 'dart:async';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../data/graphql/pos_inventory_flow_queries.dart';
import '../models/pos_inventory_flow_settings.dart';

enum InventoryFlowFailureKind {
  forbidden,
  conflict,
  uncertain,
  validation,
  connection,
  session,
}

class PosInventoryFlowFailure implements Exception {
  final InventoryFlowFailureKind kind;
  final String? detail;
  const PosInventoryFlowFailure(this.kind, [this.detail]);
  bool get requiresReload => ![
    InventoryFlowFailureKind.validation,
    InventoryFlowFailureKind.connection,
  ].contains(kind);
}

class PosInventoryFlowRepository {
  final GraphQLClientProvider _provider;
  final Duration timeout;
  PosInventoryFlowRepository(
    this._provider, {
    this.timeout = const Duration(seconds: 15),
  });

  void _assertScope(String scope) {
    if (scope != _provider.subscriptionScope) {
      throw const PosInventoryFlowFailure(InventoryFlowFailureKind.session);
    }
  }

  Map<String, dynamic> _data(
    QueryResult result,
    String root, {
    bool saving = false,
  }) {
    if (result.hasException) {
      final errors = result.exception!.graphqlErrors;
      final codes = errors.map((e) => e.extensions?['code']).toSet();
      if (result.data?[root] == null &&
          result.exception!.linkException == null &&
          errors.any(
            (e) => e.extensions?['reason'] == 'TRANSIT_SETUP_PERMISSION',
          )) {
        throw const PosInventoryFlowFailure(
          InventoryFlowFailureKind.validation,
          'transitSetupPermission',
        );
      }
      if (codes.any(
        (code) =>
            ['FORBIDDEN', 'UNAUTHORIZED', 'UNAUTHENTICATED'].contains(code),
      )) {
        throw const PosInventoryFlowFailure(InventoryFlowFailureKind.forbidden);
      }
      if (codes.contains('CONFLICT')) {
        throw const PosInventoryFlowFailure(InventoryFlowFailureKind.conflict);
      }
      if (saving &&
          result.data?[root] == null &&
          result.exception!.linkException == null &&
          codes.contains('BAD_REQUEST')) {
        throw PosInventoryFlowFailure(
          InventoryFlowFailureKind.validation,
          errors.first.message,
        );
      }
      throw PosInventoryFlowFailure(
        saving
            ? InventoryFlowFailureKind.uncertain
            : InventoryFlowFailureKind.connection,
      );
    }
    final data = result.data?[root];
    if (data is! Map) {
      throw PosInventoryFlowFailure(
        saving
            ? InventoryFlowFailureKind.uncertain
            : InventoryFlowFailureKind.connection,
      );
    }
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> _read(
    String document,
    String root, {
    Map<String, dynamic> variables = const {},
  }) async {
    final result = await _provider.client
        .query(
          QueryOptions(
            document: gql(document),
            variables: variables,
            fetchPolicy: FetchPolicy.networkOnly,
            operationName: switch (root) {
              'GetMyPermissions' => 'InventoryFlowPermissions',
              'getAllCabangs' => 'InventoryFlowLocations',
              _ => 'InventoryFlowSettings',
            },
            errorPolicy: ErrorPolicy.all,
            queryRequestTimeout: timeout,
          ),
        )
        .timeout(timeout);
    return _data(result, root);
  }

  Future<PosInventoryFlowSnapshot> load() async {
    final scope = _provider.subscriptionScope;
    try {
      final permissions = await _read(
        PosInventoryFlowQueries.permissions,
        'GetMyPermissions',
      );
      _assertScope(scope);
      final actions = <String>{
        for (final entry
            in permissions['merged_permissions'] as List? ?? const [])
          if (entry is Map && entry['module'] == 'inventory_settings')
            ...((entry['actions'] as List? ?? const []).map(
              (e) => e.toString(),
            )),
      };
      final full = permissions['is_full_access'] == true;
      final canCreateLocations =
          full ||
          (permissions['merged_permissions'] as List? ?? const []).any(
            (entry) =>
                entry is Map &&
                ['warehouse', 'cabang'].contains(entry['module']) &&
                (entry['actions'] as List? ?? const []).contains('create'),
          );
      if (!full && !actions.contains('view')) {
        throw const PosInventoryFlowFailure(InventoryFlowFailureKind.forbidden);
      }
      final settings = await _read(
        PosInventoryFlowQueries.settings,
        'GetInventorySettings',
      );
      final locations = <PosInventoryFlowLocation>[];
      final seen = <String>{};
      for (var page = 0; ; page++) {
        _assertScope(scope);
        final result = await _read(
          PosInventoryFlowQueries.locations,
          'getAllCabangs',
          variables: {'page': page},
        );
        final rows = result['cabang'];
        final pageInfo = result['info_page'];
        final info = pageInfo is List
            ? (pageInfo.isEmpty ? const {'count': 0} : pageInfo.first)
            : pageInfo;
        final count = info is Map ? info['count'] : null;
        if (rows is! List || count is! num || page > 500) {
          throw const FormatException('locations');
        }
        for (final row in rows) {
          if (row is! Map || row['_id'] == null) {
            throw const FormatException('location');
          }
          final location = PosInventoryFlowLocation.fromJson(
            Map<String, dynamic>.from(row),
          );
          if (!seen.add(location.id)) {
            throw const FormatException('duplicateLocation');
          }
          locations.add(location);
        }
        if (locations.length >= count) break;
        if (rows.isEmpty) throw const FormatException('missingLocations');
      }
      _assertScope(scope);
      return PosInventoryFlowSnapshot.fromJson(
        settings,
        scope: scope,
        canUpdate: full || actions.contains('update'),
        canCreateLocations: canCreateLocations,
        locations: locations,
      );
    } on PosInventoryFlowFailure {
      rethrow;
    } catch (_) {
      throw const PosInventoryFlowFailure(InventoryFlowFailureKind.connection);
    }
  }

  Future<PosInventoryFlowSnapshot> save(
    PosInventoryFlowSnapshot baseline,
    PosInventoryFlowPolicy policy, {
    bool prepareTransit = false,
  }) async {
    _assertScope(baseline.scope);
    if (!baseline.canUpdate) {
      throw const PosInventoryFlowFailure(InventoryFlowFailureKind.forbidden);
    }
    final patch = policy.patchFrom(baseline.policy);
    if (patch.isEmpty && !prepareTransit) return baseline;
    if (prepareTransit && policy.values['inventory_profile'] == 'simple') {
      throw const PosInventoryFlowFailure(
        InventoryFlowFailureKind.validation,
        'transitChooseMovement',
      );
    }
    final invalid = policy.validationError(
      trackStock: baseline.trackStock,
      locations: baseline.locations,
      prepareTransit: prepareTransit,
    );
    if (invalid != null) {
      throw PosInventoryFlowFailure(
        InventoryFlowFailureKind.validation,
        invalid,
      );
    }
    try {
      final result = await _provider.client
          .mutate(
            MutationOptions(
              document: gql(PosInventoryFlowQueries.save),
              operationName: 'InventoryFlowSave',
              variables: {
                'input': {
                  'expected_revision': baseline.revision,
                  if (patch.isNotEmpty) 'inventory_operation_defaults': patch,
                  if (prepareTransit) 'auto_prepare_transfer_transit': true,
                },
              },
              fetchPolicy: FetchPolicy.networkOnly,
              errorPolicy: ErrorPolicy.all,
            ),
          )
          .timeout(timeout);
      _assertScope(baseline.scope);
      final data = _data(result, 'UpdateInventorySettings', saving: true);
      if (prepareTransit) {
        // The write is acknowledged, but the new location must also be loaded.
        // Any failed read requires reconciliation, not another preparation.
        try {
          return await load();
        } catch (_) {
          throw const PosInventoryFlowFailure(
            InventoryFlowFailureKind.uncertain,
          );
        }
      }
      return PosInventoryFlowSnapshot.fromJson(
        data,
        scope: baseline.scope,
        canUpdate: baseline.canUpdate,
        canCreateLocations: baseline.canCreateLocations,
        locations: baseline.locations,
      );
    } on PosInventoryFlowFailure {
      rethrow;
    } catch (_) {
      throw const PosInventoryFlowFailure(InventoryFlowFailureKind.uncertain);
    }
  }
}
