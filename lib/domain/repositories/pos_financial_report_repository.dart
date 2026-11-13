import 'dart:async';
import '../models/pos_business_report.dart';
import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../core/error/error_handler.dart';
import '../../core/error/failures.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../data/graphql/pos_financial_report_queries.dart';
import '../models/pos_financial_report.dart';

class FinancialReportChangedFailure extends Failure {
  const FinancialReportChangedFailure() : super('Report data changed');
}

class FinancialReportExportLimitFailure extends Failure {
  const FinancialReportExportLimitFailure() : super('Report export limit');
}

class FinancialReportAccessFailure extends Failure {
  const FinancialReportAccessFailure()
    : super('Financial report access denied');
}

abstract class PosFinancialReportRepository {
  Future<Either<Failure, FinancialReportOptions>> getOptions();
  Future<Either<Failure, PosProfitLossReport>> getProfitLoss(
    FinancialReportRange range, {
    bool forExport = false,
    String? fingerprint,
  });
  Future<Either<Failure, PosBusinessReport>> getBusinessReport(
    PosBusinessReportFilter filter, {
    int page = 1,
    bool forExport = false,
    String? fingerprint,
  }) async => const Left(ServerFailure());
  Future<Either<Failure, FinancialLedgerPage>> getAccountEntries({
    required String code,
    required FinancialReportRange range,
    required String instansiId,
    int page = 1,
  });
}

class GraphQLPosFinancialReportRepository
    implements PosFinancialReportRepository {
  GraphQLPosFinancialReportRepository(GraphQLClientProvider provider)
    : _client = (() => provider.client),
      requestTimeout = const Duration(seconds: 30);
  GraphQLPosFinancialReportRepository.withClient(
    this._client, {
    this.requestTimeout = const Duration(seconds: 30),
  });
  final GraphQLClient Function() _client;
  final Duration requestTimeout;

  Future<Either<Failure, Map<String, dynamic>>> _read(
    String query,
    String field,
    Map<String, dynamic> variables,
  ) async {
    try {
      final client = _client();
      final options = QueryOptions(
        document: gql(query),
        variables: variables,
        fetchPolicy: FetchPolicy.noCache,
      );
      final result = await (() async {
        var response = await client.query(options);
        // Read-only report queries may retry one dropped transport connection.
        // Never retry a permission/business error or a previous user's client.
        if (response.exception?.linkException != null &&
            response.exception!.graphqlErrors.isEmpty &&
            identical(client, _client())) {
          response = await client.query(options);
        }
        return response;
      })().timeout(requestTimeout);
      if (!identical(client, _client())) return const Left(AuthFailure());
      if (result.hasException) {
        if (result.exception!.graphqlErrors.any(
          (error) => error.extensions?['code'] == 'REPORT_CHANGED',
        )) {
          return const Left(FinancialReportChangedFailure());
        }
        if (result.exception!.graphqlErrors.any(
          (error) => error.extensions?['code'] == 'REPORT_EXPORT_LIMIT',
        )) {
          return const Left(FinancialReportExportLimitFailure());
        }
        if (result.exception!.graphqlErrors.any(
          (error) => error.extensions?['code'] == 'FORBIDDEN',
        )) {
          return const Left(FinancialReportAccessFailure());
        }
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final raw = result.data?[field];
      if (raw is! Map) {
        return const Left(ServerFailure('Data laporan belum tersedia.'));
      }
      return Right(Map<String, dynamic>.from(raw));
    } on TimeoutException {
      return const Left(NetworkFailure());
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  @override
  Future<Either<Failure, FinancialReportOptions>> getOptions() async {
    final result = await _read(
      PosFinancialReportQueries.options,
      'GetPOSFinancialReportOptions',
      const {},
    );
    return result.fold((failure) => Left(failure), (json) {
      try {
        return Right(FinancialReportOptions.fromJson(json));
      } on FormatException {
        return const Left(ServerFailure('Format laporan tidak valid.'));
      }
    });
  }

  @override
  Future<Either<Failure, PosProfitLossReport>> getProfitLoss(
    FinancialReportRange range, {
    bool forExport = false,
    String? fingerprint,
  }) async {
    final result =
        await _read(PosFinancialReportQueries.profitLoss, 'GetPOSProfitLoss', {
          'start': range.start,
          'end': range.end,
          'scope': 'instansi',
          'export': forExport,
          'fingerprint': fingerprint,
        });
    return result.fold((failure) => Left(failure), (json) {
      try {
        return Right(PosProfitLossReport.fromJson(json));
      } on FormatException {
        return const Left(ServerFailure('Format laporan tidak valid.'));
      }
    });
  }

  @override
  Future<Either<Failure, PosBusinessReport>> getBusinessReport(
    PosBusinessReportFilter filter, {
    int page = 1,
    bool forExport = false,
    String? fingerprint,
  }) async {
    final result = await _read(
      PosFinancialReportQueries.business,
      'GetPOSBusinessReport',
      {
        'kind': filter.kind.code,
        'start': filter.range.start,
        'end': filter.range.end,
        'page': page,
        'search': filter.search,
        'source': filter.sourceScope,
        'export': forExport,
        'fingerprint': fingerprint,
      },
    );
    return result.fold((failure) => Left(failure), (json) {
      try {
        return Right(PosBusinessReport.fromJson(json));
      } on FormatException {
        return const Left(ServerFailure('Format laporan tidak valid.'));
      }
    });
  }

  @override
  Future<Either<Failure, FinancialLedgerPage>> getAccountEntries({
    required String code,
    required FinancialReportRange range,
    required String instansiId,
    int page = 1,
  }) async {
    final result = await _read(
      PosFinancialReportQueries.ledger,
      'GetGeneralLedger',
      {'code': code, 'start': range.start, 'end': range.end, 'page': page},
    );
    return result.fold((failure) => Left(failure), (json) {
      try {
        final result = FinancialLedgerPage.fromJson(json);
        if (result.instansiId != instansiId) return const Left(AuthFailure());
        return Right(result);
      } on FormatException {
        return const Left(ServerFailure('Format laporan tidak valid.'));
      }
    });
  }
}
