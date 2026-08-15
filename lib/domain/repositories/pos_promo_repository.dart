import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/error/error_handler.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../data/graphql/pos_promo_queries.dart';
import '../models/pos_promo.dart';

class PosPromoRepository {
  final GraphQLClientProvider _clientProvider;

  PosPromoRepository(this._clientProvider);

  Future<Either<Failure, List<PosPromo>>> getPromos({
    String? search,
    bool? isActive,
  }) async {
    try {
      final filter = <String, dynamic>{};
      if (search != null && search.isNotEmpty) filter['search'] = search;
      if (isActive != null) filter['is_active'] = isActive;

      final QueryOptions options = QueryOptions(
        document: gql(PosPromoQueries.getAll),
        variables: {
          'filter': filter,
          'pagination': {'page': 1, 'limit': 100},
        },
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await _clientProvider.client.query(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final items =
          result.data?['getAllDiscounts']?['discounts'] as List<dynamic>? ?? [];
      return Right(items.map((e) => PosPromo.fromJson(e)).toList());
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, PosPromo>> createPromo(
    Map<String, dynamic> input,
  ) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PosPromoQueries.create),
        variables: {'input': input},
      );

      final QueryResult result = await _clientProvider.client.mutate(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final response = result.data?['createDiscount'];
      if (response?['success'] == true && response?['discount'] != null) {
        return Right(PosPromo.fromJson(response['discount']));
      }
      if (response?['message'] != null) {
        return Left(ServerFailure(response['message'].toString()));
      }
      return const Left(ServerFailure('Gagal membuat promo'));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, PosPromo>> updatePromo(
    String id,
    Map<String, dynamic> input,
  ) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PosPromoQueries.update),
        variables: {'id': id, 'input': input},
      );

      final QueryResult result = await _clientProvider.client.mutate(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final response = result.data?['updateDiscount'];
      if (response?['success'] == true && response?['discount'] != null) {
        return Right(PosPromo.fromJson(response['discount']));
      }
      if (response?['message'] != null) {
        return Left(ServerFailure(response['message'].toString()));
      }
      return const Left(ServerFailure('Gagal mengupdate promo'));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, bool>> deletePromo(String id) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PosPromoQueries.delete),
        variables: {'id': id},
      );

      final QueryResult result = await _clientProvider.client.mutate(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final response = result.data?['deleteDiscount'];
      if (response?['success'] == true) return const Right(true);
      if (response?['message'] != null) {
        return Left(ServerFailure(response['message'].toString()));
      }
      return const Left(ServerFailure('Gagal menghapus promo'));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, PosPromo>> togglePromoStatus(String id) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PosPromoQueries.toggleStatus),
        variables: {'id': id},
      );

      final QueryResult result = await _clientProvider.client.mutate(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final response = result.data?['toggleDiscountStatus'];
      if (response?['success'] == true && response?['discount'] != null) {
        return Right(PosPromo.fromJson(response['discount']));
      }
      if (response?['message'] != null) {
        return Left(ServerFailure(response['message'].toString()));
      }
      return const Left(ServerFailure('Gagal mengubah status promo'));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }
}
