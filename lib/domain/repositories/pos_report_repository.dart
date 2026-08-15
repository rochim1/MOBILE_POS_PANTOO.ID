import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../core/error/error_handler.dart';
import '../../core/error/failures.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../data/graphql/pos_report_queries.dart';
import '../models/pos_report.dart';

class PosReportRepository {
  final GraphQLClientProvider _clientProvider;

  PosReportRepository(this._clientProvider);

  Future<Either<Failure, PosReportData>> getReportData({int days = 7}) async {
    try {
      final options = QueryOptions(
        document: gql(PosReportQueries.getDashboardData),
        variables: {'days': days},
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final result = await _clientProvider.client.query(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final data = result.data?['GetPOSDashboardData'];
      if (data == null) {
        return const Left(ServerFailure('Data tidak ditemukan'));
      }

      return Right(PosReportData.fromJson(data));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }
}
