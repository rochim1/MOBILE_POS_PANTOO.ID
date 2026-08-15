import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../core/error/error_handler.dart';
import '../../core/error/failures.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../data/graphql/pos_receipt_queries.dart';
import '../models/pos_receipt_template.dart';

class PosReceiptRepository {
  final GraphQLClientProvider _clientProvider;

  PosReceiptRepository(this._clientProvider);

  Future<Either<Failure, PosReceiptTemplate>> getReceiptTemplate() async {
    try {
      final options = QueryOptions(
        document: gql(PosReceiptQueries.getReceipt),
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final result = await _clientProvider.client.query(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final data = result.data?['GetPOSReceiptData']?['template'];
      if (data == null) {
        return const Left(ServerFailure('Data tidak ditemukan'));
      }

      return Right(PosReceiptTemplate.fromJson(data));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, PosReceiptTemplate>> updateReceiptTemplate(
    Map<String, dynamic> input,
  ) async {
    try {
      final options = MutationOptions(
        document: gql(PosReceiptQueries.updateReceipt),
        variables: {'input': input},
      );

      final result = await _clientProvider.client.mutate(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final data =
          result.data?['UpdatePOSReceiptTemplate']?['pos_receipt_template'];
      if (data == null) {
        return const Left(ServerFailure('Gagal menyimpan data'));
      }

      return Right(PosReceiptTemplate.fromJson(data));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }
}
