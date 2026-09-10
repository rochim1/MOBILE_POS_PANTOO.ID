import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../core/error/error_handler.dart';
import '../../core/error/failures.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../data/graphql/pos_table_order_queries.dart';
import '../models/pos_order_detail.dart';

class PosOrderRepository {
  final GraphQLClientProvider _clientProvider;

  PosOrderRepository(this._clientProvider);

  Future<Either<Failure, List<PosOrderDetail>>> getActiveOrders({
    required String storeId,
    String search = '',
    String status = '',
  }) async {
    try {
      final filter = <String, dynamic>{
        'toko_id': storeId,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'status': status.isEmpty ? '__active__' : status,
      };
      final result = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosTableOrderQueries.getActiveOrders),
          variables: {
            'filter': filter,
            'pagination': {'page': 0, 'limit': 100},
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final rows =
          result.data?['GetAllPOSOrder']?['items'] as List? ?? const [];
      return Right(
        rows
            .whereType<Map>()
            .map(
              (row) => PosOrderDetail.fromJson(Map<String, dynamic>.from(row)),
            )
            .toList(),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, List<PosOrderDetail>>> getOrdersByTable(
    String tableId,
  ) async {
    try {
      final options = QueryOptions(
        document: gql(PosTableOrderQueries.getOrdersByTable),
        variables: {'tableId': tableId},
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final result = await _clientProvider.client.query(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final data = result.data?['GetPOSOrderByTable'];
      if (data == null) {
        return const Right([]);
      }
      return Right([PosOrderDetail.fromJson(Map<String, dynamic>.from(data))]);
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, bool>> updateOrderItemStatus(
    String orderId,
    String _,
    String status,
  ) async {
    try {
      final options = MutationOptions(
        document: gql(PosTableOrderQueries.updateOrderItemStatus),
        variables: {
          'orderId': orderId,
          'status':
              const {
                'pending': 'Baru',
                'preparing': 'Diproses',
                'served': 'Siap',
                'completed': 'Selesai',
              }[status] ??
              status,
        },
      );

      final result = await _clientProvider.client.mutate(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      return const Right(true);
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }
}
