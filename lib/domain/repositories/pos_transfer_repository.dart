import 'package:graphql_flutter/graphql_flutter.dart';
import '../../core/error/error_handler.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../data/graphql/pos_transfer_queries.dart';
import '../../core/network/pos_transfer_intent_store.dart';

class PosTransferRepository {
  final GraphQLClientProvider provider;
  PosTransferRepository(this.provider);
  static final _inFlight = <String, (String, Future<Map<String, dynamic>>)>{};
  PosTransferIntentStore get _store => PosTransferIntentStore(
    provider.sharedPreferences,
    provider.subscriptionScope,
  );
  Map<String, dynamic>? pendingIntent({String? documentId}) =>
      _store.load(documentId);

  Future<Map<String, dynamic>> recoverPending({String? documentId}) {
    final row = pendingIntent(documentId: documentId);
    if (row == null) {
      throw StateError('Tidak ada transfer yang perlu diperiksa.');
    }
    return execute(
      row['document'] as String,
      Map<String, dynamic>.from(row['variables'] as Map),
      row['root'] as String,
    );
  }

  Future<Map<String, dynamic>> execute(
    String document,
    Map<String, dynamic> variables,
    String root,
  ) {
    final scope = provider.subscriptionScope;
    final store = _store;
    final id = variables['id']?.toString();
    final key = store.key(id);
    final signature = PosTransferIntentStore.signature(root, variables);
    final running = _inFlight[key];
    if (running != null) {
      if (signature != running.$1) {
        return Future.error(StateError('Transfer sebelumnya masih diproses.'));
      }
      return running.$2;
    }
    final future = _execute(store, scope, id, document, variables, root);
    _inFlight[key] = (signature, future);
    // Remove only our own entry, including after a failed durable write.
    return future.whenComplete(() {
      if (identical(_inFlight[key]?.$2, future)) _inFlight.remove(key);
    });
  }

  Future<Map<String, dynamic>> _execute(
    PosTransferIntentStore store,
    String scope,
    String? id,
    String document,
    Map<String, dynamic> variables,
    String root,
  ) async {
    final replay = store.load(id) != null;
    final row = await store.prepare(document, variables, root);
    if (provider.subscriptionScope != scope) {
      throw StateError('Operator berubah. Buka ulang transfer.');
    }
    try {
      final result = await provider.client.mutate(
        MutationOptions(
          document: gql(row['document'] as String),
          variables: Map<String, dynamic>.from(row['variables'] as Map),
          fetchPolicy: FetchPolicy.noCache,
          errorPolicy: ErrorPolicy.all,
        ),
      );
      if (result.hasException) {
        final error = result.exception!;
        const definitive = {
          'BAD_REQUEST',
          'BAD_USER_INPUT',
          'GRAPHQL_VALIDATION_FAILED',
          'FORBIDDEN',
          'UNAUTHORIZED',
          'UNAUTHENTICATED',
          'NOT_FOUND',
        };
        if (!replay &&
            result.data?[root] is! Map &&
            error.linkException == null &&
            error.graphqlErrors.isNotEmpty &&
            error.graphqlErrors.every(
              (e) => definitive.contains(e.extensions?['code']),
            )) {
          await store.acknowledge(id, row['request_id'] as String);
        }
        throw Exception(AppErrorHandler.handle(error).message);
      }
      final data = result.data?[root];
      if (data is! Map || data['_id'] is! String || (data['_id'] as String).isEmpty ||
          (id != null && data['_id'] != id)) {
        throw StateError(
          'Hasil transfer belum terkonfirmasi. Periksa permintaan yang sama.',
        );
      }
      await store.acknowledge(id, row['request_id'] as String);
      if (provider.subscriptionScope != scope) {
        throw StateError('Operator berubah. Muat ulang daftar transfer.');
      }
      return Map<String, dynamic>.from(data);
    } catch (_) {
      // Unknown outcomes retain the exact original document, payload and ID.
      rethrow;
    }
  }

  Future<Map<String, dynamic>> query(
    String document, [
    Map<String, dynamic> variables = const {},
  ]) async {
    final result = await provider.client.query(
      QueryOptions(
        document: gql(document),
        variables: variables,
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) {
      throw Exception(AppErrorHandler.handle(result.exception!).message);
    }
    if (result.data == null) {
      throw Exception(
        'Respons transfer kosong. Muat ulang sebelum melanjutkan.',
      );
    }
    return result.data!;
  }

  Future<Map<String, dynamic>> mutate(
    String document,
    Map<String, dynamic> variables,
    String root,
  ) async {
    final result = await provider.client.mutate(
      MutationOptions(document: gql(document), variables: variables),
    );
    if (result.hasException) {
      throw Exception(AppErrorHandler.handle(result.exception!).message);
    }
    final data = result.data?[root];
    if (data is! Map) {
      throw Exception(
        'Hasil belum terkonfirmasi. Periksa ulang status transfer sebelum mengulang.',
      );
    }
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> detail(String id) async {
    final data = (await query(PosTransferQueries.detail, {
      'id': id,
    }))['GetOneInventoryTransfer'];
    if (data is! Map) {
      throw Exception('Transfer tidak ditemukan atau tidak dapat diakses.');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<List<Map<String, dynamic>>> warehouses() async {
    final rows = <Map<String, dynamic>>[];
    for (var page = 0; ; page++) {
      final result =
          (await query(PosTransferQueries.warehouses, {
                'page': page,
              }))['getAllCabangs']
              as Map;
      final next = (result['cabang'] as List)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
      rows.addAll(next);
      if (next.length < 200) return rows;
    }
  }

  Future<Map<String, dynamic>> action(
    String action,
    Map<String, dynamic> doc, {
    String? reason,
    String? postingDate,
    String? requestId,
  }) {
    final roots = {
      'submit': 'SubmitInventoryTransfer',
      'approve': 'ApproveInventoryTransfer',
      'reject': 'RejectInventoryTransfer',
      'post': 'PostInventoryTransfer',
      'cancel': 'CancelInventoryTransfer',
      'retry_journal': 'RetryInventoryTransferJournal',
      'retry_cancel_journal': 'RetryInventoryTransferCancelJournal',
      'delete': 'DeleteInventoryTransfer',
    };
    final root = roots[action];
    if (root == null) throw ArgumentError('Aksi transfer tidak dikenal');
    final params = <String>['\$id:ID!'], args = <String>['id:\$id'];
    final variables = <String, dynamic>{'id': doc['_id']};
    if (['submit', 'approve', 'reject', 'post', 'cancel'].contains(action)) {
      params.add('\$request_id:String');
      args.add('request_id:\$request_id');
      variables['request_id'] = requestId;
    }
    if (action == 'reject' || action == 'cancel') {
      final field = action == 'reject' ? 'alasan_penolakan' : 'alasan';
      params.add('\$reason:String${action == 'reject' ? '!' : ''}');
      args.add('$field:\$reason');
      variables['reason'] = reason;
    }
    if (action == 'retry_journal') {
      params.addAll(['\$posting_date:String', '\$reason:String']);
      args.addAll(['posting_date:\$posting_date', 'reason:\$reason']);
      variables.addAll({'posting_date': postingDate, 'reason': reason});
    }
    if (pendingIntent(documentId: doc['_id'].toString()) != null) {
      return Future.error(
        StateError(
          'Periksa transfer sebelumnya sebelum menjalankan aksi lain.',
        ),
      );
    }
    final perform =
        ['submit', 'approve', 'reject', 'post', 'cancel'].contains(action)
        ? execute
        : mutate;
    return perform(
      'mutation MobileTransferAction(${params.join(',')}) {$root(${args.join(',')}) {${PosTransferQueries.fields}}}',
      variables,
      root,
    );
  }
}
