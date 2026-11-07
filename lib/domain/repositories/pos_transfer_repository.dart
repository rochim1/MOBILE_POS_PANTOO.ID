import 'package:graphql_flutter/graphql_flutter.dart';
import '../../core/error/error_handler.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../data/graphql/pos_transfer_queries.dart';

class PosTransferRepository {
  final GraphQLClientProvider provider;
  PosTransferRepository(this.provider);
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
    return mutate(
      'mutation MobileTransferAction(${params.join(',')}) {$root(${args.join(',')}) {${PosTransferQueries.fields}}}',
      variables,
      root,
    );
  }
}
