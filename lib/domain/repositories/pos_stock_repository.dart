import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/error/error_handler.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../data/graphql/pos_stock_queries.dart';
import '../models/pos_stock.dart';

class PosStockRepository {
  final GraphQLClientProvider _clientProvider;

  PosStockRepository(this._clientProvider);

  Future<Either<Failure, List<PosStock>>> getStocks({
    String? search,
    String? stockFilter,
  }) async {
    try {
      final locationResult = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosStockQueries.getActiveStockLocation),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (locationResult.hasException) {
        return Left(AppErrorHandler.handle(locationResult.exception!));
      }
      final branchId = locationResult
          .data?['GetMyActiveKasirShift']?['toko']?['lokasi_cabang_id']
          ?.toString();
      if (branchId == null || branchId.isEmpty) {
        return const Left(
          ServerFailure(
            'Buka shift pada toko yang memiliki lokasi stok terlebih dahulu.',
          ),
        );
      }

      final QueryOptions options = QueryOptions(
        document: gql(PosStockQueries.getStockByStore),
        variables: {'cabangId': branchId},
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await _clientProvider.client.query(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final items =
          result.data?['GetInventarisAvailableInLocation'] as List<dynamic>? ??
          [];
      var stocks = items.map((raw) {
        final item = Map<String, dynamic>.from(raw as Map);
        item['stok'] = item['qty'];
        item['status'] = 'active';
        return PosStock.fromJson(item);
      }).toList();
      final keyword = search?.trim().toLowerCase() ?? '';
      if (keyword.isNotEmpty) {
        stocks = stocks
            .where(
              (item) =>
                  item.namaInventaris.toLowerCase().contains(keyword) ||
                  item.kodeInventaris.toLowerCase().contains(keyword) ||
                  item.sku.toLowerCase().contains(keyword),
            )
            .toList();
      }
      if (stockFilter == 'out') {
        stocks = stocks.where((item) => item.stok <= 0).toList();
      } else if (stockFilter == 'low') {
        stocks = stocks
            .where((item) => item.stok > 0 && item.stok <= item.stokMinimum)
            .toList();
      }
      return Right(stocks);
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, double>> adjustStock({
    required String id,
    required double newStock,
    required String reason,
    String? note,
    required String stockBalanceId,
  }) async {
    try {
      final locationResult = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosStockQueries.getActiveStockLocation),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (locationResult.hasException) {
        return Left(AppErrorHandler.handle(locationResult.exception!));
      }
      final branchId = locationResult
          .data?['GetMyActiveKasirShift']?['toko']?['lokasi_cabang_id']
          ?.toString();
      if (branchId == null || branchId.isEmpty) {
        return const Left(
          ServerFailure(
            'Lokasi stok toko belum tersedia. Buka shift pada toko yang memiliki lokasi cabang.',
          ),
        );
      }
      final result = await _clientProvider.client.mutate(
        MutationOptions(
          document: gql(PosStockQueries.adjustStock),
          variables: {
            'id': id,
            'input': {
              'jenis': 'penyesuaian',
              'jumlah': newStock,
              'sumber': 'manual_adjustment',
              'alasan': reason,
              'stock_balance_id': stockBalanceId,
              'lokasi_cabang_id': branchId,
              if (note != null && note.trim().isNotEmpty)
                'keterangan': note.trim(),
            },
          },
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final data = result.data?['UpdateStokInventarisUmum'];
      if (data == null) {
        return const Left(ServerFailure('Stok gagal diperbarui'));
      }
      // Kartu POS menampilkan saldo cabang/lokasi, sedangkan `stok` pada
      // response mutation adalah agregat global seluruh lokasi.
      return Right(newStock);
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, PosStockStatistics>> getStatistics() async {
    try {
      final locationResult = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosStockQueries.getActiveStockLocation),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (locationResult.hasException) {
        return Left(AppErrorHandler.handle(locationResult.exception!));
      }
      final branchId = locationResult
          .data?['GetMyActiveKasirShift']?['toko']?['lokasi_cabang_id']
          ?.toString();
      if (branchId == null || branchId.isEmpty) {
        return const Left(ServerFailure('Lokasi stok toko belum tersedia'));
      }
      final result = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosStockQueries.getStockByStore),
          variables: {'cabangId': branchId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final rows =
          result.data?['GetInventarisAvailableInLocation'] as List<dynamic>? ??
          [];
      final stocks = rows.map((raw) {
        final item = Map<String, dynamic>.from(raw as Map);
        item['stok'] = item['qty'];
        return PosStock.fromJson(item);
      }).toList();
      return Right(
        PosStockStatistics(
          totalInventaris: stocks.length,
          totalNilaiInventaris: stocks.fold(
            0,
            (sum, item) => sum + (item.stok * item.hargaPokok),
          ),
          lowStockCount: stocks
              .where((item) => item.stok > 0 && item.stok <= item.stokMinimum)
              .length,
          outOfStockCount: stocks.where((item) => item.stok <= 0).length,
        ),
      );
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, PosStockMovementPage>> getMovements({
    String? search,
    String? type,
    int page = 0,
    int limit = 30,
  }) async {
    try {
      final result = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosStockQueries.getStockMovements),
          variables: {
            if (search != null && search.trim().isNotEmpty)
              'search': search.trim(),
            if (type != null && type.isNotEmpty) 'jenis': type,
            'pagination': {'page': page, 'limit': limit},
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final rows =
          result.data?['GetMyPOSStockMovements']?['items'] as List<dynamic>? ??
          [];
      final pageInfo =
          result.data?['GetMyPOSStockMovements']?['info_page']
              as List<dynamic>? ??
          [];
      final totalCount = pageInfo.isEmpty
          ? rows.length
          : int.tryParse((pageInfo.first as Map)['count']?.toString() ?? '0') ??
                0;
      return Right(
        PosStockMovementPage(
          items: rows
              .map(
                (row) => PosStockMovement.fromJson(
                  Map<String, dynamic>.from(row as Map),
                ),
              )
              .toList(),
          totalCount: totalCount,
        ),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }
}
