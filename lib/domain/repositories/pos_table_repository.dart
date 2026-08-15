import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/error/error_handler.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/data/graphql/pos_table_queries.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_table.dart';

class PosTableRepository {
  final GraphQLClientProvider _clientProvider;

  PosTableRepository(this._clientProvider);

  Future<Either<Failure, List<PosTableModel>>> getTables({
    required String storeId,
    String? search,
  }) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(PosTableQueries.getAll),
        // Backend pagination is zero-based. Page 1 would skip the first 100
        // tables and made a successful create appear missing from the list.
        variables: {
          'tokoId': storeId,
          'search': search ?? '',
          'limit': 100,
          'page': 0,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await _clientProvider.client.query(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final items =
          (result.data?['GetAllPOSTable']?['items'] as List<dynamic>?) ?? [];
      final tables = items
          .map((e) => PosTableModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right(tables);
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, PosTableModel>> createTable({
    required String storeId,
    required String name,
    int capacity = 4,
  }) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PosTableQueries.create),
        variables: {'tokoId': storeId, 'name': name, 'capacity': capacity},
      );

      final QueryResult result = await _clientProvider.client.mutate(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final data = result.data?['CreatePOSTable'];
      if (data == null) {
        return const Left(ServerFailure('Gagal membuat meja baru'));
      }

      return Right(PosTableModel.fromJson(data as Map<String, dynamic>));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, PosTableModel>> updateTable({
    required String storeId,
    required String id,
    String? name,
    int? capacity,
    String? status,
  }) async {
    try {
      final variables = <String, dynamic>{'_id': id, 'tokoId': storeId};
      if (name != null) variables['name'] = name;
      if (capacity != null) variables['capacity'] = capacity;
      if (status != null) variables['status'] = status;

      final MutationOptions options = MutationOptions(
        document: gql(PosTableQueries.update),
        variables: variables,
      );

      final QueryResult result = await _clientProvider.client.mutate(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final data = result.data?['UpdatePOSTable'];
      if (data == null) {
        return const Left(ServerFailure('Gagal mengupdate meja'));
      }

      return Right(PosTableModel.fromJson(data as Map<String, dynamic>));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, String>> deleteTable({
    required String id,
    required String storeId,
  }) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PosTableQueries.delete),
        variables: {'_id': id, 'tokoId': storeId},
      );

      final QueryResult result = await _clientProvider.client.mutate(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final message =
          result.data?['DeletePOSTable']?.toString() ?? 'Meja berhasil dihapus';
      return Right(message);
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }
}
