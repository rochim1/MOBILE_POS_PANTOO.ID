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

  // Receipt settings are used immediately after payment. Keep the latest
  // successful response in memory so opening the print dialog never needs to
  // wait for another round trip. A single in-flight request also prevents
  // cashier and success page from fetching the same template concurrently.
  PosReceiptPrintData? _cachedPrintData;
  Future<Either<Failure, PosReceiptPrintData>>? _inFlightPrintData;

  PosReceiptRepository(this._clientProvider);

  Future<Either<Failure, PosReceiptTemplate>> getReceiptTemplate() async {
    final result = await getReceiptPrintData();
    return result.map((data) => data.template);
  }

  Future<Either<Failure, PosReceiptPrintData>> getReceiptPrintData() async {
    final cached = _cachedPrintData;
    if (cached != null) return Right(cached);

    final inFlight = _inFlightPrintData;
    if (inFlight != null) return inFlight;

    final request = _fetchReceiptPrintData();
    _inFlightPrintData = request;
    final result = await request;
    if (identical(_inFlightPrintData, request)) {
      _inFlightPrintData = null;
    }
    return result;
  }

  /// Starts loading the receipt settings while the cashier is being used.
  /// It is intentionally safe to call more than once; concurrent calls share
  /// the same request and a cached response is returned immediately.
  Future<Either<Failure, PosReceiptPrintData>> preloadReceiptPrintData() {
    return getReceiptPrintData();
  }

  Future<Either<Failure, PosReceiptPrintData>> _fetchReceiptPrintData() async {
    try {
      final options = QueryOptions(
        document: gql(PosReceiptQueries.getReceipt),
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final result = await _clientProvider.client.query(options);

      if (result.hasException) {
        final cached = _cachedPrintData;
        if (cached != null) return Right(cached);
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final receiptData = result.data?['GetPOSReceiptData'];
      final templateData = receiptData?['template'];
      if (templateData == null) {
        final cached = _cachedPrintData;
        if (cached != null) return Right(cached);
        return const Left(ServerFailure('Data tidak ditemukan'));
      }
      final rawCompany = Map<String, dynamic>.from(
        receiptData?['instansi'] as Map? ?? const {},
      );
      final company = rawCompany.map(
        (key, value) => MapEntry(key, value?.toString() ?? ''),
      );
      company['logo'] = _clientProvider.resolveMediaUrl(rawCompany['logo']);
      final data = PosReceiptPrintData(
        template: PosReceiptTemplate.fromJson(templateData),
        company: company,
      );
      _cachedPrintData = data;
      return Right(data);
    } catch (e) {
      // A previously loaded template is still safer than falling back to a
      // blank receipt when the network briefly disappears.
      final cached = _cachedPrintData;
      if (cached != null) return Right(cached);
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

      final template = PosReceiptTemplate.fromJson(data);
      final cached = _cachedPrintData;
      if (cached != null) {
        _cachedPrintData = PosReceiptPrintData(
          template: template,
          company: cached.company,
        );
      }
      return Right(template);
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }
}
