import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/error/error_handler.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../data/graphql/pos_queries.dart';
import '../models/pos_product.dart';

class PosProductManagementRepository {
  final GraphQLClientProvider _clientProvider;

  PosProductManagementRepository(this._clientProvider);

  String _absoluteMediaUrl(dynamic rawValue) {
    return _clientProvider.resolveMediaUrl(rawValue);
  }

  Future<Either<Failure, Map<String, dynamic>>> _executeMutation(
    String document,
    Map<String, dynamic> variables,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(_clientProvider.endpointUrl),
        headers: {
          ...await _clientProvider.authenticatedRequestHeaders(),
          'content-type': 'application/json',
        },
        body: jsonEncode({'query': document, 'variables': variables}),
      );
      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        return Left(
          ServerFailure(
            'Server mengembalikan respons non-JSON '
            '(HTTP ${response.statusCode}).',
          ),
        );
      }
      if (decoded is! Map) {
        return const Left(ServerFailure('Format respons GraphQL tidak valid'));
      }
      final payload = Map<String, dynamic>.from(decoded);
      final errors = payload['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        final message = first is Map
            ? first['message']?.toString()
            : first.toString();
        final extensions = first is Map ? first['extensions'] : null;
        final code = extensions is Map ? extensions['code']?.toString() : null;
        if (code == 'UNAUTHORIZED' || code == 'UNAUTHENTICATED') {
          return Left(
            AuthFailure(
              message ?? 'Sesi telah berakhir. Silakan login kembali.',
            ),
          );
        }
        return Left(ServerFailure(message ?? 'Mutation GraphQL gagal'));
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Left(
          ServerFailure('Request gagal (HTTP ${response.statusCode})'),
        );
      }
      final data = payload['data'];
      if (data is! Map) {
        return const Left(ServerFailure('Server tidak mengembalikan data'));
      }
      return Right(Map<String, dynamic>.from(data));
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  static const fallbackUnitOptions = <String>[
    'unit',
    'pcs',
    'kg',
    'gram',
    'liter',
    'ml',
    'box',
    'rim',
    'set',
    'pack',
    'roll',
    'meter',
    'lembar',
    'buah',
    'pasang',
    'lusin',
  ];

  Future<List<String>> getUnitOptions() async {
    try {
      final result = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosQueries.getInventoryUnitOptions),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      final rows = result.data?['GetInventoryUnitOptions'];
      if (rows is List) {
        final values = rows
            .map((item) => item.toString().trim().toLowerCase())
            .where((item) => item.isNotEmpty)
            .toSet()
            .toList();
        if (values.isNotEmpty) return values;
      }
    } catch (_) {
      // Server lama: gunakan snapshot kanonik agar form tetap dapat dipakai.
    }
    return fallbackUnitOptions;
  }

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
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_clientProvider.endpointUrl),
      );
      request.headers.addAll(
        await _clientProvider.authenticatedRequestHeaders(),
      );
      request.fields['operations'] = jsonEncode({
        'query': PosQueries.uploadInventoryProductImage,
        'variables': {'file': null},
      });
      request.fields['map'] = jsonEncode({
        '0': ['variables.file'],
      });
      request.files.add(
        http.MultipartFile.fromBytes(
          '0',
          bytes,
          filename: filename,
          contentType: MediaType('image', subtype),
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      Map<String, dynamic>? payload;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) payload = Map<String, dynamic>.from(decoded);
      } catch (_) {
        return Left(
          ServerFailure(
            'Upload gambar gagal: respons server bukan JSON '
            '(HTTP ${response.statusCode}).',
          ),
        );
      }
      final errors = payload?['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        final message = first is Map
            ? first['message']?.toString()
            : first.toString();
        return Left(ServerFailure(message ?? 'Upload gambar gagal'));
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Left(
          ServerFailure('Upload gambar gagal (HTTP ${response.statusCode})'),
        );
      }
      final data = payload?['data'];
      final url = data is Map
          ? data['UploadInventoryProductImage']?.toString() ?? ''
          : '';
      return url.isEmpty
          ? const Left(ServerFailure('Server tidak mengembalikan URL foto'))
          : Right(_absoluteMediaUrl(url));
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
                'foto': _absoluteMediaUrl(row['foto']),
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
      // Produk adalah data master dengan saldo awal nol. Lokasi tidak boleh
      // diambil dari shift/toko karena saldo per lokasi baru terbentuk lewat
      // penerimaan, saldo awal, transfer, atau opname.
      productInput['pos_product_type'] ??= 'product';
      productInput['sellable_in_pos'] ??= true;
      productInput['tracks_stock'] ??= ![
        'service',
        'deposit',
        'package',
      ].contains(productInput['pos_product_type']);
      final mutation = await _executeMutation(PosQueries.createInventarisUmum, {
        'input': productInput,
      });
      Failure? mutationFailure;
      Map<String, dynamic>? mutationData;
      mutation.fold(
        (failure) => mutationFailure = failure,
        (value) => mutationData = value,
      );
      if (mutationFailure != null) return Left(mutationFailure!);
      if (mutationData == null) {
        return const Left(ServerFailure('Gagal membuat produk'));
      }
      final data = mutationData!['AddInventarisUmum'];
      if (data is! Map) {
        return const Left(
          ServerFailure('Produk tidak dikembalikan oleh server'),
        );
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
          imageUrl: _absoluteMediaUrl(data['foto']),
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
      final mutation = await _executeMutation(PosQueries.updateInventarisUmum, {
        '_id': id,
        'input': input,
      });
      Failure? mutationFailure;
      Map<String, dynamic>? mutationData;
      mutation.fold(
        (failure) => mutationFailure = failure,
        (value) => mutationData = value,
      );
      if (mutationFailure != null) return Left(mutationFailure!);
      if (mutationData == null) {
        return const Left(ServerFailure('Gagal mengupdate produk'));
      }
      final data = mutationData!['UpdateInventarisUmum'];
      if (data is! Map) {
        return const Left(
          ServerFailure('Produk tidak dikembalikan oleh server'),
        );
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
          imageUrl: _absoluteMediaUrl(data['foto']),
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
      final mutation = await _executeMutation(PosQueries.deleteInventarisUmum, {
        '_id': id,
        'deleteReason': 'Dihapus melalui Mobile POS',
      });
      return mutation.fold(
        Left.new,
        (data) => Right(data['DeleteInventarisUmum'] is Map),
      );
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }
}
