import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../core/error/error_handler.dart';
import '../../core/error/failures.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../data/graphql/pos_receipt_queries.dart';
import '../models/pos_receipt_template.dart';

class PosReceiptPrintData {
  final PosReceiptTemplate template;
  final Map<String, String> company;

  const PosReceiptPrintData({required this.template, required this.company});
}

class PosReceiptRepository {
  final GraphQLClientProvider _clientProvider;

  PosReceiptRepository(this._clientProvider);

  Future<Either<Failure, PosReceiptTemplate>> getReceiptTemplate() async {
    final result = await getReceiptPrintData();
    return result.map((data) => data.template);
  }

  Future<Either<Failure, PosReceiptPrintData>> getReceiptPrintData() async {
    try {
      final options = QueryOptions(
        document: gql(PosReceiptQueries.getReceipt),
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final result = await _clientProvider.client.query(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final receiptData = result.data?['GetPOSReceiptData'];
      final templateData = receiptData?['template'];
      if (templateData == null) {
        return const Left(ServerFailure('Data tidak ditemukan'));
      }
      final rawCompany = Map<String, dynamic>.from(
        receiptData?['instansi'] as Map? ?? const {},
      );
      return Right(
        PosReceiptPrintData(
          template: PosReceiptTemplate.fromJson(templateData),
          company: rawCompany.map(
            (key, value) => MapEntry(key, value?.toString() ?? ''),
          ),
        ),
      );
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
