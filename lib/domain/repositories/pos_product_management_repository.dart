import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/error/error_handler.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../data/graphql/pos_queries.dart';
import '../models/pos_product.dart';

class PosProductManagementRepository {
  final GraphQLClientProvider _clientProvider;

  PosProductManagementRepository(this._clientProvider);

  Future<Either<Failure, PosProduct>> createProduct(
    Map<String, dynamic> input,
  ) async {
    try {
      final productInput = Map<String, dynamic>.from(input);
      final shiftResult = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosQueries.getMyActiveKasirShift),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (shiftResult.hasException) {
        return Left(AppErrorHandler.handle(shiftResult.exception!));
      }
      final activeShift = shiftResult.data?['GetMyActiveKasirShift'];
      final toko = activeShift?['toko'];
      final branchId = toko?['lokasi_cabang_id']?.toString();
      if (activeShift == null) {
        return const Left(
          ServerFailure('Buka shift kasir sebelum menambahkan produk'),
        );
      }
      if (branchId == null || branchId.isEmpty) {
        return const Left(
          ServerFailure(
            'Outlet aktif belum terhubung ke warehouse. Atur lokasi outlet terlebih dahulu.',
          ),
        );
      }
      productInput['lokasi_cabang_id'] = branchId;
      productInput['lokasi_cabang_nama'] =
          toko?['lokasi_cabang_nama']?.toString() ?? '';
      productInput['sellable_in_pos'] = true;
      productInput['pos_product_type'] ??= 'product';
      productInput['tracks_stock'] ??= true;
      final MutationOptions options = MutationOptions(
        document: gql(PosQueries.createInventarisUmum),
        variables: {'input': productInput},
      );

      final QueryResult result = await _clientProvider.client.mutate(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final data = result.data?['AddInventarisUmum'];
      if (data == null) {
        return const Left(ServerFailure('Gagal membuat produk'));
      }

      return Right(
        PosProduct(
          id: data['_id']?.toString() ?? '',
          code: data['kode_inventaris']?.toString() ?? '',
          name: data['nama_inventaris']?.toString() ?? '',
          category: data['kategori']?.toString() ?? '',
          price: double.tryParse(data['harga_jual']?.toString() ?? '0') ?? 0.0,
          stock: double.tryParse(data['stok']?.toString() ?? '0') ?? 0,
        ),
      );
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, PosProduct>> updateProduct(
    String id,
    Map<String, dynamic> input,
  ) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PosQueries.updateInventarisUmum),
        variables: {'_id': id, 'input': input},
      );

      final QueryResult result = await _clientProvider.client.mutate(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final data = result.data?['UpdateInventarisUmum'];
      if (data == null) {
        return const Left(ServerFailure('Gagal mengupdate produk'));
      }

      return Right(
        PosProduct(
          id: data['_id']?.toString() ?? '',
          code: data['kode_inventaris']?.toString() ?? '',
          name: data['nama_inventaris']?.toString() ?? '',
          category: data['kategori']?.toString() ?? '',
          price: double.tryParse(data['harga_jual']?.toString() ?? '0') ?? 0.0,
          stock: double.tryParse(data['stok']?.toString() ?? '0') ?? 0,
        ),
      );
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, bool>> deleteProduct(String id) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PosQueries.deleteInventarisUmum),
        variables: {'_id': id, 'deleteReason': 'Dihapus melalui Mobile POS'},
      );

      final QueryResult result = await _clientProvider.client.mutate(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      return const Right(true);
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }
}
