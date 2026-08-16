import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../core/error/error_handler.dart';
import '../../core/error/failures.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../data/graphql/purchase_return_queries.dart';

class PurchaseReturnPageResult {
  final List<Map<String, dynamic>> items;
  final int totalCount;
  const PurchaseReturnPageResult(this.items, this.totalCount);
}

class PurchaseReturnRepository {
  final GraphQLClientProvider _provider;
  PurchaseReturnRepository(this._provider);

  Future<Either<Failure, PurchaseReturnPageResult>> getAll({
    String search = '',
    String status = '',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PurchaseReturnQueries.list),
          variables: {
            'filter': {
              if (search.trim().isNotEmpty) 'search': search.trim(),
              if (status.isNotEmpty) 'approval_status': status,
            },
            // PaginationInput backend menggunakan indeks berbasis 0, sedangkan
            // UI menampilkan nomor halaman berbasis 1.
            'pagination': {'page': page > 0 ? page - 1 : 0, 'limit': limit},
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final data = result.data?['GetAllPurchaseReturns'] as Map?;
      return Right(
        PurchaseReturnPageResult(
          (data?['items'] as List? ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList(),
          (data?['totalCount'] as num?)?.toInt() ?? 0,
        ),
      );
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getOne(String id) => _queryOne(
    PurchaseReturnQueries.detail,
    {'_id': id},
    'GetOnePurchaseReturn',
  );

  Future<Either<Failure, List<Map<String, dynamic>>>> searchPurchases(
    String search,
  ) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PurchaseReturnQueries.searchPurchases),
          variables: {'search': search.trim(), 'limit': 30},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return Right(
        (result.data?['SearchPurchaseOrdersForReturn'] as List? ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> getAvailability(
    String purchaseId,
  ) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PurchaseReturnQueries.availability),
          variables: {'purchase_id': purchaseId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return Right(
        (result.data?['GetPurchaseReturnSourceAvailability'] as List? ??
                const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> createReturn(
    Map<String, dynamic> input,
  ) => _mutateOne(PurchaseReturnQueries.create, {
    'input': input,
  }, 'CreatePurchaseReturn');
  Future<Either<Failure, Map<String, dynamic>>> submit(String id) => _mutateOne(
    PurchaseReturnQueries.submit,
    {'_id': id},
    'SubmitPurchaseReturnForApproval',
  );
  Future<Either<Failure, Map<String, dynamic>>> approve(
    String id, {
    String notes = '',
  }) => _mutateOne(PurchaseReturnQueries.approve, {
    '_id': id,
    'notes': notes,
  }, 'ApprovePurchaseReturn');
  Future<Either<Failure, Map<String, dynamic>>> reject(
    String id,
    String reason,
  ) => _mutateOne(PurchaseReturnQueries.reject, {
    '_id': id,
    'reason': reason,
  }, 'RejectPurchaseReturn');
  Future<Either<Failure, Map<String, dynamic>>> process(String id) =>
      _mutateOne(PurchaseReturnQueries.process, {
        '_id': id,
      }, 'ProcessPurchaseReturn');
  Future<Either<Failure, Map<String, dynamic>>> retryJournal(String id) =>
      _mutateOne(PurchaseReturnQueries.retryJournal, {
        '_id': id,
      }, 'RetryPurchaseReturnJournal');

  Future<Either<Failure, Map<String, dynamic>>> _queryOne(
    String document,
    Map<String, dynamic> variables,
    String key,
  ) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(document),
          variables: variables,
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final data = result.data?[key];
      if (data is! Map) {
        return const Left(ServerFailure('Data tidak ditemukan'));
      }
      return Right(Map<String, dynamic>.from(data));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> _mutateOne(
    String document,
    Map<String, dynamic> variables,
    String key,
  ) async {
    try {
      final result = await _provider.client.mutate(
        MutationOptions(document: gql(document), variables: variables),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final data = result.data?[key];
      if (data is! Map) {
        return const Left(ServerFailure('Operasi gagal diproses'));
      }
      return Right(Map<String, dynamic>.from(data));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }
}
