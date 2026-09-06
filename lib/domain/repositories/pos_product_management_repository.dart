import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import 'dart:math';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/error/error_handler.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../data/graphql/pos_queries.dart';
import '../models/pos_product.dart';

class PosProductManagementRepository {
  final GraphQLClientProvider _clientProvider;

  PosProductManagementRepository(this._clientProvider);

  Map<String, String> _buildLocalIdentifierPreview() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final suffix = random.nextInt(0x10000).toRadixString(16).padLeft(4, '0');
    final body = StringBuffer('20');
    for (var index = 0; index < 10; index++) {
      body.write(random.nextInt(10));
    }
    final bodyValue = body.toString();
    var checksumSum = 0;
    for (var index = 0; index < bodyValue.length; index++) {
      checksumSum += int.parse(bodyValue[index]) * (index.isEven ? 1 : 3);
    }
    final checkDigit = (10 - (checksumSum % 10)) % 10;
    return {
      'kode_inventaris': '',
      'sku': 'SKU-${timestamp.toUpperCase()}-${suffix.toUpperCase()}',
      'barcode': '$bodyValue$checkDigit',
    };
  }

  Future<Either<Failure, Map<String, String>>>
  generateProductIdentifiers() async {
    try {
      final result = await _clientProvider.client.mutate(
        MutationOptions(
          document: gql(PosQueries.generateInventoryProductIdentifiers),
          variables: const {'kategori': 'barang_dagangan'},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      final row = result.data?['GenerateInventoryProductIdentifiers'];
      if (row is Map) {
        return Right({
          'kode_inventaris': row['kode_inventaris']?.toString() ?? '',
          'sku': row['sku']?.toString() ?? '',
          'barcode': row['barcode']?.toString() ?? '',
        });
      }
      if (result.hasException) {
        final failure = AppErrorHandler.handle(result.exception!);
        if (failure is AuthFailure) return Left(failure);
        // Preview harus tetap responsif ketika aplikasi terhubung ke versi API
        // yang belum memuat mutation generator. Keunikan final tetap divalidasi
        // oleh Add/UpdateInventarisUmum di server saat produk disimpan.
        return Right(_buildLocalIdentifierPreview());
      }
      return Right(_buildLocalIdentifierPreview());
    } catch (error) {
      final failure = AppErrorHandler.handle(error);
      if (failure is AuthFailure) return Left(failure);
      return Right(_buildLocalIdentifierPreview());
    }
  }

  Future<Either<Failure, String>> uploadProductImage({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      final extension = filename.split('.').last.toLowerCase();
      final subtype = switch (extension) {
        'jpg' || 'jpeg' => 'jpeg',
        'png' => 'png',
        'webp' => 'webp',
        _ => '',
      };
      if (subtype.isEmpty) {
        return const Left(
          ServerFailure('Format foto harus JPG, PNG, atau WebP'),
        );
      }
      final file = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType('image', subtype),
      );
      final result = await _clientProvider.client.mutate(
        MutationOptions(
          document: gql(PosQueries.uploadInventoryProductImage),
          variables: {'file': file},
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final url = result.data?['UploadInventoryProductImage']?.toString() ?? '';
      return url.isEmpty
          ? const Left(ServerFailure('Server tidak mengembalikan URL foto'))
          : Right(url);
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<PosProduct>>> getPackageCandidates({
    String search = '',
  }) async {
    try {
      final result = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosQueries.getAllInventarisUmum),
          variables: {
            'filter': {
              'kategori': 'barang_dagangan',
              'status': 'active',
              if (search.trim().isNotEmpty) 'search': search.trim(),
            },
            'pagination': const {'page': 0, 'limit': 200},
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final rows =
          result.data?['GetAllInventarisUmum']?['items'] as List? ?? const [];
      return Right(
        rows
            .whereType<Map>()
            .map(
              (row) => PosProduct.fromJson({
                ...Map<String, dynamic>.from(row),
                'id': row['_id']?.toString() ?? '',
                'code': row['kode_inventaris']?.toString() ?? '',
                'name': row['nama_inventaris']?.toString() ?? '',
                'category': row['merchandise_category_name']?.toString() ?? '',
                'price': row['harga_jual'] ?? 0,
                'stock': row['stok'] ?? 0,
              }),
            )
            .where((item) => item.productType == 'product' && item.tracksStock)
            .toList(),
      );
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> getCategories({
    String search = '',
  }) async {
    try {
      final result = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosQueries.getMerchandiseCategories),
          variables: {
            'filter': {
              'status': 'active',
              if (search.trim().isNotEmpty) 'search': search.trim(),
            },
            'pagination': const {'page': 0, 'limit': 100},
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final rows =
          result.data?['GetMerchandiseCategories']?['items'] as List? ??
          const [];
      return Right(
        rows
            .whereType<Map>()
            .map((row) => Map<String, dynamic>.from(row))
            .toList(),
      );
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> createCategory(
    String name,
  ) async {
    try {
      final result = await _clientProvider.client.mutate(
        MutationOptions(
          document: gql(PosQueries.addMerchandiseCategory),
          variables: {
            'input': {'nama': name.trim(), 'status': 'active'},
          },
        ),
      );
      final row = result.data?['AddMerchandiseCategory'];
      // GraphQL dapat membawa data mutation yang valid bersama warning/link
      // exception non-fatal. Payload sukses harus menjadi sumber kebenaran agar
      // kategori yang sudah tersimpan tidak dilaporkan sebagai gagal jaringan.
      if (row is Map) {
        return Right(Map<String, dynamic>.from(row));
      }
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return const Left(ServerFailure('Gagal membuat kategori'));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

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
      Map<String, dynamic>? toko = activeShift?['toko'] == null
          ? null
          : Map<String, dynamic>.from(activeShift['toko'] as Map);

      // Katalog adalah data master: pembuatannya tidak boleh bergantung pada
      // shift transaksi. Jika belum ada shift, gunakan toko aktif pertama yang
      // sudah terhubung ke lokasi penjualan.
      if (toko == null) {
        final storeResult = await _clientProvider.client.query(
          QueryOptions(
            document: gql(PosQueries.getAllPOSToko),
            variables: const {
              'pagination': {'page': 0, 'limit': 100},
            },
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        );
        if (storeResult.hasException) {
          return Left(AppErrorHandler.handle(storeResult.exception!));
        }
        final stores =
            storeResult.data?['GetAllPOSToko']?['items'] as List? ?? const [];
        final configuredStores = stores.whereType<Map>().where(
          (store) =>
              store['status']?.toString().toLowerCase() == 'active' &&
              store['lokasi_cabang_id']?.toString().isNotEmpty == true,
        );
        if (configuredStores.isNotEmpty) {
          toko = Map<String, dynamic>.from(configuredStores.first);
        }
      }

      final branchId = toko?['lokasi_cabang_id']?.toString();
      if (branchId == null || branchId.isEmpty) {
        return const Left(
          ServerFailure(
            'Hubungkan toko aktif ke lokasi penjualan sebelum menambahkan produk.',
          ),
        );
      }
      productInput['lokasi_cabang_id'] = branchId;
      productInput['lokasi_cabang_nama'] =
          toko?['lokasi_cabang_nama']?.toString() ?? '';
      productInput['pos_product_type'] ??= 'product';
      productInput['sellable_in_pos'] ??= true;
      productInput['tracks_stock'] ??= ![
        'service',
        'deposit',
        'package',
      ].contains(productInput['pos_product_type']);
      final MutationOptions options = MutationOptions(
        document: gql(PosQueries.createInventarisUmum),
        variables: {'input': productInput},
      );

      final QueryResult result = await _clientProvider.client.mutate(options);

      final data = result.data?['AddInventarisUmum'];
      if (data == null) {
        if (result.hasException) {
          return Left(AppErrorHandler.handle(result.exception!));
        }
        return const Left(ServerFailure('Gagal membuat produk'));
      }

      return Right(
        PosProduct(
          id: data['_id']?.toString() ?? '',
          code: data['kode_inventaris']?.toString() ?? '',
          name: data['nama_inventaris']?.toString() ?? '',
          category:
              data['merchandise_category_name']?.toString() ??
              'Belum dikategorikan',
          categoryId: data['merchandise_category_id']?.toString() ?? '',
          productType: data['pos_product_type']?.toString() ?? 'product',
          tracksStock: data['tracks_stock'] == true,
          description: data['deskripsi']?.toString() ?? '',
          brand: data['brand']?.toString() ?? '',
          purchasePrice:
              double.tryParse(data['harga_beli']?.toString() ?? '0') ?? 0,
          purchasePriceSource:
              data['harga_beli_source']?.toString() ?? 'manual',
          packageComponents:
              (data['pos_package_components'] as List? ?? const [])
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList(),
          price: double.tryParse(data['harga_jual']?.toString() ?? '0') ?? 0.0,
          stock: double.tryParse(data['stok']?.toString() ?? '0') ?? 0,
          sku: data['sku']?.toString() ?? '',
          barcode: data['barcode']?.toString() ?? '',
          imageUrl: data['foto']?.toString() ?? '',
          baseUnit: data['base_unit']?.toString() ?? 'unit',
          unitConversions: (data['unit_conversions'] as List? ?? const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
          minimumStock:
              double.tryParse(data['stok_minimum']?.toString() ?? '0') ?? 0,
          maximumStock:
              double.tryParse(data['stok_maksimum']?.toString() ?? '0') ?? 0,
          reorderPoint:
              double.tryParse(data['titik_reorder']?.toString() ?? '0') ?? 0,
          procurementLeadTime:
              int.tryParse(data['lead_time_pengadaan']?.toString() ?? '0') ?? 0,
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

      final data = result.data?['UpdateInventarisUmum'];
      if (data == null) {
        if (result.hasException) {
          return Left(AppErrorHandler.handle(result.exception!));
        }
        return const Left(ServerFailure('Gagal mengupdate produk'));
      }

      return Right(
        PosProduct(
          id: data['_id']?.toString() ?? '',
          code: data['kode_inventaris']?.toString() ?? '',
          name: data['nama_inventaris']?.toString() ?? '',
          category:
              data['merchandise_category_name']?.toString() ??
              'Belum dikategorikan',
          categoryId: data['merchandise_category_id']?.toString() ?? '',
          productType: data['pos_product_type']?.toString() ?? 'product',
          tracksStock: data['tracks_stock'] == true,
          description: data['deskripsi']?.toString() ?? '',
          brand: data['brand']?.toString() ?? '',
          purchasePrice:
              double.tryParse(data['harga_beli']?.toString() ?? '0') ?? 0,
          purchasePriceSource:
              data['harga_beli_source']?.toString() ?? 'manual',
          packageComponents:
              (data['pos_package_components'] as List? ?? const [])
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList(),
          price: double.tryParse(data['harga_jual']?.toString() ?? '0') ?? 0.0,
          stock: double.tryParse(data['stok']?.toString() ?? '0') ?? 0,
          sku: data['sku']?.toString() ?? '',
          barcode: data['barcode']?.toString() ?? '',
          imageUrl: data['foto']?.toString() ?? '',
          baseUnit: data['base_unit']?.toString() ?? 'unit',
          unitConversions: (data['unit_conversions'] as List? ?? const [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(),
          minimumStock:
              double.tryParse(data['stok_minimum']?.toString() ?? '0') ?? 0,
          maximumStock:
              double.tryParse(data['stok_maksimum']?.toString() ?? '0') ?? 0,
          reorderPoint:
              double.tryParse(data['titik_reorder']?.toString() ?? '0') ?? 0,
          procurementLeadTime:
              int.tryParse(data['lead_time_pengadaan']?.toString() ?? '0') ?? 0,
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
