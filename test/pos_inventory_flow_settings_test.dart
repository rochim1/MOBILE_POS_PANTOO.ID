import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_inventory_flow_settings.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_flow_repository.dart';
import 'pos_transfer_recovery_test.dart' show TransferProvider;

const rawPolicy = <String, dynamic>{
  'inventory_profile': 'custom',
  'use_store_warehouse': true,
  'use_display_stock': true,
  'transfer_cross_branch_rule': 'direct',
  'allow_over_receipt': true,
  'over_receipt_tolerance_percent': 7,
  'default_receiving_location_id': 'warehouse',
};
Map<String, dynamic> settings([String revision = 'v1']) => {
  'revision': revision,
  'inventory_operation_defaults': rawPolicy,
  'pos_defaults': {
    'enabled_features': {'track_stock': true},
  },
};
Response response(Map<String, dynamic> data) =>
    Response(response: const {}, data: data);
const locations = [
  PosInventoryFlowLocation(id: 'warehouse', name: 'Warehouse', type: 'store'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'operation patch preserves every untouched field and never sends POS defaults',
    () {
      final old = PosInventoryFlowPolicy(rawPolicy);
      final draft = old.withValue('transfer_same_branch_rule', 'transit');
      expect(draft.patchFrom(old), {'transfer_same_branch_rule': 'transit'});
      expect(draft.values['allow_over_receipt'], true);
      expect(old.patchFrom(old), isEmpty);
      expect(
        draft.withValue('default_receiving_location_id', '').patchFrom(old),
        {
          'transfer_same_branch_rule': 'transit',
          'default_receiving_location_id': null,
        },
      );
      expect(() => old.withValue('pos_defaults', {}), throwsArgumentError);
      expect(
        () => old.values['inventory_profile'] = 'simple',
        throwsUnsupportedError,
      );
    },
  );
  test(
    'presets match web but preserve tolerance, locations and route rules',
    () {
      final old = PosInventoryFlowPolicy(rawPolicy);
      final advanced = old.withProfile('advanced');
      for (final key in PosInventoryFlowPolicy.flowFlags) {
        expect(advanced.values[key], true, reason: key);
      }
      expect(advanced.values['allow_direct_purchase_to_store'], false);
      expect(advanced.values['over_receipt_tolerance_percent'], 7);
      expect(advanced.values['transfer_cross_branch_rule'], 'direct');
      expect(advanced.withProfile('custom').values['use_display_stock'], true);
      expect(old.withProfile('simple').values['use_store_warehouse'], false);
    },
  );
  test(
    'dependency, tracking, tolerance and transit validation are explicit',
    () {
      final simple = PosInventoryFlowPolicy(const {}).withProfile('simple');
      expect(
        simple.validationError(trackStock: false, locations: const []),
        isNull,
      );
      expect(
        simple
            .withValue('use_display_stock', true)
            .validationError(trackStock: true, locations: const []),
        'displayRequiresStore',
      );
      expect(
        simple
            .withValue('use_transfer_approval', true)
            .validationError(trackStock: true, locations: const []),
        'approvalRequiresRequest',
      );
      expect(
        simple
            .withValue('use_transfer_request', true)
            .validationError(trackStock: true, locations: const []),
        'requestRequiresWarehouse',
      );
      expect(
        simple
            .withProfile('advanced')
            .validationError(trackStock: false, locations: const []),
        'trackingRequired',
      );
      expect(
        simple
            .withValue('over_receipt_tolerance_percent', 101)
            .validationError(trackStock: true, locations: const []),
        'invalidTolerance',
      );
      expect(
        simple
            .withValue('transfer_same_branch_rule', 'transit')
            .validationError(trackStock: true, locations: const []),
        'transitRequired',
      );
    },
  );
  test(
    'permissions are authoritative and never fall back to POS manage_settings',
    () async {
      var calls = 0;
      final provider = TransferProvider(await SharedPreferences.getInstance(), (
        request,
      ) async* {
        calls++;
        yield response({
          'GetMyPermissions': {
            'is_full_access': false,
            'merged_permissions': [
              {
                'module': 'pos',
                'actions': ['manage_settings'],
              },
            ],
          },
        });
      });
      await expectLater(
        PosInventoryFlowRepository(provider).load(),
        throwsA(
          isA<PosInventoryFlowFailure>().having(
            (e) => e.kind,
            'kind',
            InventoryFlowFailureKind.forbidden,
          ),
        ),
      );
      expect(calls, 1);
    },
  );
  test(
    'load and save reuse the web revision API with a minimal patch',
    () async {
      final writes = <Map<String, dynamic>>[];
      final provider = TransferProvider(await SharedPreferences.getInstance(), (
        request,
      ) async* {
        final op = request.operation.operationName!;
        if (op == 'InventoryFlowPermissions') {
          yield response({
            'GetMyPermissions': {
              'is_full_access': true,
              'merged_permissions': [],
            },
          });
        } else if (op == 'InventoryFlowLocations') {
          yield response({
            'getAllCabangs': {
              'info_page': [
                {'count': 1},
              ],
              'cabang': [
                {
                  '_id': 'warehouse',
                  'nama_cabang': 'Warehouse',
                  'warehouse_type': 'store',
                  'is_warehouse': true,
                  'is_receiving_location': true,
                  'status': 'active',
                },
              ],
            },
          });
        } else if (op == 'InventoryFlowSave') {
          writes.add(request.variables);
          yield response({
            'UpdateInventorySettings': {
              ...settings('v2'),
              'inventory_operation_defaults': {
                ...rawPolicy,
                'transfer_same_branch_rule': 'direct',
              },
            },
          });
        } else {
          yield response({'GetInventorySettings': settings()});
        }
      });
      final repo = PosInventoryFlowRepository(provider);
      final snapshot = await repo.load();
      expect(snapshot.canUpdate, true);
      expect(snapshot.locations.single.name, 'Warehouse');
      final saved = await repo.save(
        snapshot,
        snapshot.policy.withValue('transfer_same_branch_rule', 'direct'),
      );
      expect(saved.revision, 'v2');
      expect(writes.single, {
        'input': {
          'expected_revision': 'v1',
          'inventory_operation_defaults': {
            'transfer_same_branch_rule': 'direct',
          },
        },
      });
      await repo.save(saved, saved.policy);
      expect(writes, hasLength(1));
    },
  );
  for (final code in ['CONFLICT', 'FORBIDDEN']) {
    test(
      '$code is not retried or presented as success, even with partial data',
      () async {
        var writes = 0;
        final p = TransferProvider(await SharedPreferences.getInstance(), (
          r,
        ) async* {
          writes++;
          yield Response(
            response: const {},
            data: {'UpdateInventorySettings': settings('v2')},
            errors: [
              GraphQLError(message: 'Blocked', extensions: {'code': code}),
            ],
          );
        });
        final repo = PosInventoryFlowRepository(p);
        final snapshot = PosInventoryFlowSnapshot.fromJson(
          settings(),
          scope: p.scope,
          canUpdate: true,
          locations: locations,
        );
        await expectLater(
          repo.save(
            snapshot,
            snapshot.policy.withValue('transfer_same_branch_rule', 'direct'),
          ),
          throwsA(
            isA<PosInventoryFlowFailure>().having(
              (e) => e.requiresReload,
              'requires reload',
              true,
            ),
          ),
        );
        expect(writes, 1);
      },
    );
  }
  test(
    'lost response requires reload and changing account prevents a write',
    () async {
      var writes = 0;
      final p = TransferProvider(
        await SharedPreferences.getInstance(),
        (r) => Stream<Response>.error(TimeoutException('lost')),
      );
      final repo = PosInventoryFlowRepository(p);
      final snapshot = PosInventoryFlowSnapshot.fromJson(
        settings(),
        scope: p.scope,
        canUpdate: true,
        locations: locations,
      );
      await expectLater(
        repo.save(
          snapshot,
          snapshot.policy.withValue('transfer_same_branch_rule', 'direct'),
        ),
        throwsA(
          isA<PosInventoryFlowFailure>().having(
            (e) => e.requiresReload,
            'reload',
            true,
          ),
        ),
      );
      final other = TransferProvider(await SharedPreferences.getInstance(), (
        r,
      ) async* {
        writes++;
        yield response({});
      });
      other.scope = 'different-account';
      await expectLater(
        PosInventoryFlowRepository(other).save(
          snapshot,
          snapshot.policy.withValue('transfer_same_branch_rule', 'direct'),
        ),
        throwsA(isA<PosInventoryFlowFailure>()),
      );
      expect(writes, 0);
    },
  );
  test('validation covers valid locations and all unsafe combinations', () {
    final simple = PosInventoryFlowPolicy(const {}).withProfile('simple');
    String? error(
      PosInventoryFlowPolicy p, {
      List<PosInventoryFlowLocation> rows = const [],
    }) => p.validationError(trackStock: true, locations: rows);
    expect(
      error(simple.withValue('use_in_transit', true)),
      'transitRequiresRequest',
    );
    expect(
      error(simple.withValue('transfer_same_branch_rule', 'unknown')),
      'invalidRule',
    );
    expect(
      error(simple.withValue('over_receipt_tolerance_percent', null)),
      'invalidTolerance',
    );
    expect(
      error(simple.withValue('default_receiving_location_id', 'missing')),
      'receivingInvalid',
    );
    expect(
      error(
        simple,
        rows: const [
          PosInventoryFlowLocation(id: 'a', name: 'A', type: 'store'),
          PosInventoryFlowLocation(id: 'b', name: 'B', type: 'store'),
        ],
      ),
      'receivingRequired',
    );
    final central = simple
        .withProfile('centralized')
        .withValue('default_transfer_transit_location_id', 'transit');
    expect(
      error(
        central,
        rows: const [
          PosInventoryFlowLocation(
            id: 'transit',
            name: 'Transit',
            type: 'in_transit',
          ),
        ],
      ),
      'centralRequired',
    );
    expect(
      error(
        central,
        rows: const [
          PosInventoryFlowLocation(
            id: 'transit',
            name: 'Transit',
            type: 'in_transit',
          ),
          PosInventoryFlowLocation(
            id: 'central',
            name: 'Central',
            type: 'central',
          ),
        ],
      ),
      isNull,
    );
    for (final type in ['display', 'in_transit', 'quarantine']) {
      expect(
        PosInventoryFlowLocation(
          id: 'x',
          name: 'X',
          type: type,
        ).canReceive(allowStore: true),
        false,
      );
    }
    expect(
      const PosInventoryFlowLocation(
        id: 'x',
        name: 'X',
        type: 'store',
      ).canReceive(allowStore: false),
      false,
    );
    expect(
      const PosInventoryFlowLocation(
        id: 'x',
        name: 'X',
        type: 'central',
        active: false,
      ).canReceive(allowStore: true),
      false,
    );
    expect(
      () => PosInventoryFlowPolicy({'inventory_profile': 'future'}),
      throwsFormatException,
    );
    expect(
      () => PosInventoryFlowSnapshot.fromJson(
        {'revision': 'r'},
        scope: 's',
        canUpdate: true,
        locations: const [],
      ),
      throwsFormatException,
    );
    expect(
      () => PosInventoryFlowSnapshot.fromJson(
        {'inventory_operation_defaults': {}},
        scope: 's',
        canUpdate: true,
        locations: const [],
      ),
      throwsFormatException,
    );
  });
  test(
    'view-only permission reads settings but never transmits a mutation',
    () async {
      var mutations = 0;
      final p = TransferProvider(await SharedPreferences.getInstance(), (
        r,
      ) async* {
        switch (r.operation.operationName) {
          case 'InventoryFlowPermissions':
            yield response({
              'GetMyPermissions': {
                'merged_permissions': [
                  {
                    'module': 'inventory_settings',
                    'actions': ['view'],
                  },
                ],
              },
            });
          case 'InventoryFlowSettings':
            yield response({'GetInventorySettings': settings()});
          case 'InventoryFlowLocations':
            yield response({
              'getAllCabangs': {'info_page': [], 'cabang': []},
            });
          default:
            mutations++;
            yield response({});
        }
      });
      final repo = PosInventoryFlowRepository(p),
          snapshot = await PosInventoryFlowRepository(p).load();
      expect(snapshot.canUpdate, false);
      await expectLater(
        repo.save(snapshot, snapshot.policy.withProfile('simple')),
        throwsA(isA<PosInventoryFlowFailure>()),
      );
      expect(mutations, 0);
    },
  );
  test('all warehouse pages load, including the second page', () async {
    final pages = <int>[];
    final p = TransferProvider(await SharedPreferences.getInstance(), (
      r,
    ) async* {
      if (r.operation.operationName == 'InventoryFlowPermissions') {
        yield response({
          'GetMyPermissions': {'is_full_access': true},
        });
      } else if (r.operation.operationName == 'InventoryFlowSettings') {
        yield response({'GetInventorySettings': settings()});
      } else {
        final page = r.variables['page'] as int;
        pages.add(page);
        yield response({
          'getAllCabangs': {
            'info_page': [
              {'count': 201},
            ],
            'cabang': [
              for (var n = page * 200; n < (page == 0 ? 200 : 201); n++)
                {
                  '_id': 'loc$n',
                  'nama_cabang': '$n',
                  'status': 'active',
                  'is_warehouse': true,
                },
            ],
          },
        });
      }
    });
    final snapshot = await PosInventoryFlowRepository(p).load();
    expect(pages, [0, 1]);
    expect(snapshot.locations.length, 201);
  });
  for (final malformed in [
    'missingData',
    'missingRevision',
    'missingPolicy',
    'duplicateLocation',
    'missingPage',
    'invalidLocation',
  ]) {
    test(
      'incomplete load $malformed never produces savable defaults',
      () async {
        final p = TransferProvider(await SharedPreferences.getInstance(), (
          r,
        ) async* {
          if (r.operation.operationName == 'InventoryFlowPermissions') {
            yield response({
              'GetMyPermissions': {'is_full_access': true},
            });
          } else if (r.operation.operationName == 'InventoryFlowSettings') {
            yield response({
              'GetInventorySettings': switch (malformed) {
                'missingData' => null,
                'missingRevision' => {
                  'inventory_operation_defaults': rawPolicy,
                },
                'missingPolicy' => {'revision': 'v1'},
                _ => settings(),
              },
            });
          } else {
            final row = {'_id': 'one', 'nama_cabang': 'One'};
            yield response({
              'getAllCabangs': {
                'info_page': [
                  {'count': 2},
                ],
                'cabang': switch (malformed) {
                  'duplicateLocation' => [row, row],
                  'invalidLocation' => [{}],
                  _ => [],
                },
              },
            });
          }
        });
        await expectLater(
          PosInventoryFlowRepository(p).load(),
          throwsA(isA<PosInventoryFlowFailure>()),
        );
      },
    );
  }
  test(
    'a late load for another account cannot create a settings snapshot',
    () async {
      late TransferProvider p;
      p = TransferProvider(await SharedPreferences.getInstance(), (r) async* {
        p.scope = 'another-tenant';
        yield response({
          'GetMyPermissions': {'is_full_access': true},
        });
      });
      await expectLater(
        PosInventoryFlowRepository(p).load(),
        throwsA(
          isA<PosInventoryFlowFailure>().having(
            (e) => e.kind,
            'session',
            InventoryFlowFailureKind.session,
          ),
        ),
      );
    },
  );
  test(
    'server validation stays editable but unknown/partial/missing save requires reload',
    () async {
      for (final mode in [
        'badRequest',
        'unknown',
        'empty',
        'revision',
        'partial',
      ]) {
        final p = TransferProvider(await SharedPreferences.getInstance(), (
          r,
        ) async* {
          yield Response(
            response: const {},
            data: {
              'UpdateInventorySettings': mode == 'partial'
                  ? settings('v2')
                  : mode == 'revision'
                  ? {'inventory_operation_defaults': rawPolicy}
                  : null,
            },
            errors: mode == 'empty' || mode == 'revision'
                ? null
                : [
                    GraphQLError(
                      message: 'Check warehouse',
                      extensions: {
                        'code': mode == 'unknown'
                            ? 'INTERNAL_SERVER_ERROR'
                            : 'BAD_REQUEST',
                      },
                    ),
                  ],
          );
        });
        final snapshot = PosInventoryFlowSnapshot.fromJson(
          settings(),
          scope: p.scope,
          canUpdate: true,
          locations: locations,
        );
        await expectLater(
          PosInventoryFlowRepository(p).save(
            snapshot,
            snapshot.policy.withValue('transfer_same_branch_rule', 'direct'),
          ),
          throwsA(
            isA<PosInventoryFlowFailure>().having(
              (e) => e.requiresReload,
              'reload $mode',
              mode != 'badRequest',
            ),
          ),
        );
      }
    },
  );
  test(
    'invalid local options never reach the server and late saves reject a changed session',
    () async {
      var writes = 0;
      late TransferProvider p;
      p = TransferProvider(await SharedPreferences.getInstance(), (r) async* {
        writes++;
        p.scope = 'new-session';
        yield response({'UpdateInventorySettings': settings('v2')});
      });
      final repo = PosInventoryFlowRepository(p);
      final snapshot = PosInventoryFlowSnapshot.fromJson(
        settings(),
        scope: p.scope,
        canUpdate: true,
        locations: locations,
      );
      await expectLater(
        repo.save(
          snapshot,
          snapshot.policy.withValue('over_receipt_tolerance_percent', -1),
        ),
        throwsA(
          isA<PosInventoryFlowFailure>().having(
            (e) => e.kind,
            'validation',
            InventoryFlowFailureKind.validation,
          ),
        ),
      );
      expect(writes, 0);
      await expectLater(
        repo.save(
          snapshot,
          snapshot.policy.withValue('transfer_same_branch_rule', 'direct'),
        ),
        throwsA(
          isA<PosInventoryFlowFailure>().having(
            (e) => e.kind,
            'session',
            InventoryFlowFailureKind.session,
          ),
        ),
      );
      expect(writes, 1);
    },
  );
}
