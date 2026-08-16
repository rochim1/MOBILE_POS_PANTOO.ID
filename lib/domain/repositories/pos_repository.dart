import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../core/error/failures.dart';
import '../../core/error/error_handler.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../core/database/database_platform_initializer.dart';
import '../../core/utils/logger.dart';
import '../../data/graphql/pos_queries.dart';
import '../../data/graphql/pos_return_queries.dart';
import '../../data/datasources/local/pos_local_database.dart';
import '../models/pos_product.dart';
import '../models/pos_customer.dart';
import '../models/pos_store.dart';
import '../models/pos_order.dart';
import '../models/pos_transaction_result.dart';
import '../models/hold_order.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PosRepository {
  final GraphQLClientProvider _clientProvider;
  final SharedPreferences _prefs;
  String _operatorSessionToken = '';

  PosRepository(this._clientProvider, this._prefs);

  void setOperatorSessionToken(String token) {
    _operatorSessionToken = token.trim();
  }

  Future<Set<String>> getFavoriteProductIds() async {
    final local = (_prefs.getStringList('pos_favorite_product_ids') ?? const [])
        .toSet();
    try {
      final result = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosQueries.getMyPOSFavoriteProductIds),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) return local;
      final ids =
          (result.data?['GetMyPOSFavoriteProductIds'] as List? ?? const [])
              .map((id) => id.toString())
              .toSet();
      await _prefs.setStringList('pos_favorite_product_ids', ids.toList());
      return ids;
    } catch (_) {
      return local;
    }
  }

  Future<void> saveFavoriteProductIds(Set<String> ids) async {
    await _prefs.setStringList('pos_favorite_product_ids', ids.toList());
    try {
      final result = await _clientProvider.client.mutate(
        MutationOptions(
          document: gql(PosQueries.saveMyPOSFavoriteProductIds),
          variables: {'productIds': ids.toList()},
        ),
      );
      if (result.hasException) throw result.exception!;
    } catch (error) {
      appLogger.e(
        'Favorit tersimpan lokal tetapi belum tersinkron',
        error: error,
      );
    }
  }

  Future<Map<String, dynamic>> getRuntimeConfig() async {
    const fallbackPermissions = <String, dynamic>{
      'view_dashboard': false,
      'use_cashier': false,
      'view_products': false,
      'view_promos': false,
      'view_customers': false,
      'view_stores': false,
      'view_shifts': false,
      'view_transactions': false,
      'view_reports': false,
      'view_returns': false,
      'view_settings': false,
      'view_receipt': false,
      'view_stock': false,
      'view_tables': false,
      'manage_products': false,
      'adjust_stock': false,
      'manage_tables': false,
      'manage_settings': false,
    };
    final fallback = <String, dynamic>{
      'business_profile': 'retail',
      'inventory_profile': 'simple',
      'default_order_type': 'take_away',
      'default_sales_channel': 'retail',
      'default_customer_segment': 'regular',
      'default_price_level': 'retail',
      'tax_percent': 0.0,
      'features': <String, dynamic>{'track_stock': true},
      'configuration_health': <String, dynamic>{
        'valid': false,
        'issues': <String>[
          'Konfigurasi POS tidak dapat dimuat. Periksa koneksi lalu coba lagi.',
        ],
      },
      'permissions': fallbackPermissions,
    };
    final cachedJson = _prefs.getString('pos_runtime_config');
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final cached = Map<String, dynamic>.from(jsonDecode(cachedJson) as Map);
        cached['permissions'] = <String, dynamic>{
          ...fallbackPermissions,
          ...Map<String, dynamic>.from(
            cached['permissions'] as Map? ?? const {},
          ),
        };
        return cached;
      } catch (_) {
        await _prefs.remove('pos_runtime_config');
      }
    }
    try {
      final result = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosQueries.getPOSRuntimeConfig),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException || result.data?['GetPOSRuntimeConfig'] == null) {
        appLogger.e(
          'Runtime permission POS gagal dimuat; memakai navigasi operasional',
          error: result.exception,
        );
        return fallback;
      }
      final config = Map<String, dynamic>.from(
        result.data!['GetPOSRuntimeConfig'],
      );
      final serverPermissions = Map<String, dynamic>.from(
        config['permissions'] as Map? ?? const {},
      );
      config['permissions'] = <String, dynamic>{
        ...fallbackPermissions,
        ...serverPermissions,
      };
      return config;
    } catch (error, stackTrace) {
      appLogger.e(
        'Runtime permission POS tidak tersedia; memakai navigasi operasional',
        error: error,
        stackTrace: stackTrace,
      );
      return fallback;
    }
  }

  Future<Map<String, dynamic>> getDashboardData({int days = 7}) async {
    final result = await _clientProvider.client.query(
      QueryOptions(
        document: gql(PosQueries.getPOSDashboardData),
        variables: {'days': days},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final data = result.data?['GetPOSDashboardData'];
    if (data is! Map) {
      throw const ServerFailure('Data dashboard POS tidak tersedia');
    }
    return Map<String, dynamic>.from(data);
  }

  String get _heldOrderUserKey =>
      '${_prefs.getString('instansi_id') ?? ''}:${_prefs.getString('username')?.trim().toLowerCase() ?? ''}';

  Future<List<HoldOrder>> getHeldOrders({
    required String storeId,
    required String shiftId,
  }) async {
    try {
      final db = await PosLocalDatabase.instance.database;
      final rows = await db.query(
        'held_orders',
        where: 'user_key = ? AND store_id = ? AND shift_id = ?',
        whereArgs: [_heldOrderUserKey, storeId, shiftId],
        orderBy: 'created_at DESC',
      );
      return rows
          .map(
            (row) => HoldOrder.fromJson(
              Map<String, dynamic>.from(
                jsonDecode(row['payload']?.toString() ?? '{}') as Map,
              ),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveHeldOrder({
    required HoldOrder order,
    required String shiftId,
  }) async {
    final db = await PosLocalDatabase.instance.database;
    await db.insert('held_orders', {
      'id': order.id,
      'payload': jsonEncode(order.toJson()),
      'user_key': _heldOrderUserKey,
      'store_id': order.store.id,
      'shift_id': shiftId,
      'created_at': order.time.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteHeldOrder(String id) async {
    final db = await PosLocalDatabase.instance.database;
    await db.delete('held_orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<Either<Failure, Map<String, dynamic>>> getMyPOSLockStatus() async {
    try {
      final result = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosQueries.getMyPOSLockStatus),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final data = result.data?['GetMyPOSLockStatus'];
      if (data == null) {
        return const Left(ServerFailure('Status kunci POS tidak tersedia'));
      }
      return Right(Map<String, dynamic>.from(data));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> verifyMyPOSPin(
    String pin,
  ) async {
    try {
      if (!await _clientProvider.hasAccessToken()) {
        return const Left(
          ServerFailure('Sesi login tidak ditemukan. Silakan login kembali.'),
        );
      }
      final result = await _clientProvider.client.mutate(
        MutationOptions(
          document: gql(PosQueries.verifyMyPOSPin),
          variables: {'pin': pin},
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final data = result.data?['VerifyMyPOSPin'];
      if (data == null) {
        return const Left(ServerFailure('Verifikasi PIN tidak tersedia'));
      }
      return Right(Map<String, dynamic>.from(data));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> getPOSPinUsers({
    String search = '',
  }) async {
    try {
      final result = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosQueries.getPOSPinUsers),
          variables: {
            'search': search.trim().isEmpty ? null : search.trim(),
            'pagination': {'page': 0, 'limit': 100},
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final rows =
          result.data?['GetPOSPinUsers']?['items'] as List? ?? const [];
      return Right(
        rows.map((row) => Map<String, dynamic>.from(row as Map)).toList(),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> verifyPOSUserPin(
    String userId,
    String pin,
  ) async {
    try {
      final result = await _clientProvider.client.mutate(
        MutationOptions(
          document: gql(PosQueries.verifyPOSUserPin),
          variables: {'userId': userId, 'pin': pin},
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final data = result.data?['VerifyPOSUserPin'];
      if (data is! Map) {
        return const Left(ServerFailure('Verifikasi operator tidak tersedia'));
      }
      return Right(Map<String, dynamic>.from(data));
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<List<PosProduct>> getProducts({String? branchId}) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(
          branchId != null && branchId.isNotEmpty
              ? PosQueries.getInventarisAvailableInLocation
              : PosQueries.getAllInventarisUmum,
        ),
        variables: branchId != null && branchId.isNotEmpty
            ? {'cabang_id': branchId}
            : const {
                'filter': {'kategori': 'barang_dagangan'},
                'pagination': {'page': 0, 'limit': 1000},
              },
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await _clientProvider.client.query(options);

      if (result.hasException || result.data == null) {
        return _getLocalProducts();
      }

      final items = branchId != null && branchId.isNotEmpty
          ? (result.data?['GetInventarisAvailableInLocation']
                    as List<dynamic>? ??
                [])
          : (result.data?['GetAllInventarisUmum']?['items'] as List<dynamic>? ??
                []);
      final products = items
          .map(
            (e) => PosProduct(
              id: e['inventaris_id']?.toString() ?? e['_id']?.toString() ?? '',
              code:
                  e['kode_inventaris']?.toString() ??
                  e['_id']?.toString() ??
                  '',
              name: e['nama_inventaris']?.toString() ?? 'Unknown',
              category: (e['brand']?.toString().trim().isNotEmpty == true)
                  ? e['brand'].toString()
                  : (e['kategori']?.toString() ?? 'Umum'),
              productType: e['pos_product_type']?.toString() ?? 'product',
              promoEligible: e['promo_eligible'] == true,
              // Paket divalidasi terhadap stok komponennya oleh server; qty
              // katalog bukan stok paket yang dapat dibandingkan langsung.
              tracksStock:
                  e['tracks_stock'] != false &&
                  e['pos_product_type']?.toString() != 'package',
              price: double.tryParse(e['harga_jual']?.toString() ?? '0') ?? 0.0,
              stock:
                  double.tryParse((e['qty'] ?? e['stok'] ?? 0).toString()) ?? 0,
              sku: e['sku']?.toString() ?? '',
              barcode: e['barcode']?.toString() ?? '',
              imageUrl: e['foto']?.toString() ?? '',
              baseUnit:
                  e['base_unit']?.toString() ?? e['unit']?.toString() ?? 'unit',
              unitConversions: e['unit_conversions'] is List
                  ? (e['unit_conversions'] as List)
                        .map((row) => Map<String, dynamic>.from(row as Map))
                        .toList()
                  : const [],
            ),
          )
          .toList();

      _saveProductsToLocal(products);
      return products;
    } catch (e) {
      return _getLocalProducts();
    }
  }

  Future<List<PosProduct>> _getLocalProducts() async {
    try {
      final db = await PosLocalDatabase.instance.database;
      final result = await db.query('products');
      return result
          .map(
            (e) => PosProduct(
              id: e['id'] as String,
              code: e['code'] as String,
              name: e['name'] as String,
              category: e['category'] as String,
              productType: e['product_type']?.toString() ?? 'product',
              promoEligible: (e['promo_eligible'] as int? ?? 0) == 1,
              tracksStock: (e['tracks_stock'] as int? ?? 1) == 1,
              price: e['price'] as double,
              stock: (e['stock'] as num).toDouble(),
              sku: e['sku']?.toString() ?? '',
              barcode: e['barcode']?.toString() ?? '',
              imageUrl: e['image_url']?.toString() ?? '',
              baseUnit: e['base_unit']?.toString() ?? 'unit',
              unitConversions: _decodeUnitConversions(
                e['unit_conversions']?.toString(),
              ),
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveProductsToLocal(List<PosProduct> products) async {
    try {
      final db = await PosLocalDatabase.instance.database;
      final batch = db.batch();
      batch.delete('products'); // Clear old data
      for (var product in products) {
        batch.insert('products', {
          'id': product.id,
          'code': product.code,
          'name': product.name,
          'category': product.category,
          'product_type': product.productType,
          'promo_eligible': product.promoEligible ? 1 : 0,
          'tracks_stock': product.tracksStock ? 1 : 0,
          'price': product.price,
          'stock': product.stock,
          'sku': product.sku,
          'barcode': product.barcode,
          'image_url': product.imageUrl,
          'base_unit': product.saleUnit,
          'unit_conversions': jsonEncode(product.unitConversions),
        });
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  Future<List<PosCustomer>> getCustomers() async {
    final result = await getCustomersPage(page: 1, limit: 100);
    return result.items;
  }

  Future<PosCustomerPageResult> getCustomersPage({
    int page = 1,
    int limit = 20,
    String search = '',
  }) async {
    final safePage = page < 1 ? 1 : page;
    final safeLimit = limit.clamp(1, 100).toInt();
    try {
      final QueryOptions options = QueryOptions(
        document: gql(PosQueries.getAllPOSPelanggan),
        variables: {
          'filter': {
            'type': 'CUSTOMER',
            if (search.trim().isNotEmpty) 'keyword': search.trim(),
          },
          'pagination': {'page': safePage, 'limit': safeLimit},
        },
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await _clientProvider.client.query(options);

      if (result.hasException || result.data == null) {
        final local = await _getLocalCustomers();
        final filtered = search.trim().isEmpty
            ? local
            : local.where((customer) {
                final query = search.trim().toLowerCase();
                return customer.name.toLowerCase().contains(query) ||
                    customer.phone.toLowerCase().contains(query);
              }).toList();
        final start = ((safePage - 1) * safeLimit)
            .clamp(0, filtered.length)
            .toInt();
        final end = (start + safeLimit).clamp(start, filtered.length).toInt();
        return PosCustomerPageResult(
          items: filtered.sublist(start, end),
          totalCount: filtered.length,
          page: safePage,
          limit: safeLimit,
        );
      }

      final items =
          result.data?['getAllCrmContacts']?['data'] as List<dynamic>? ?? [];
      final customers = items
          .map(
            (e) => PosCustomer(
              id: e['_id']?.toString() ?? '',
              name: e['name']?.toString() ?? 'Unknown',
              phone: e['phone']?.toString() ?? '',
              email: e['email']?.toString() ?? '',
              priceLevel: e['price_level']?.toString() ?? 'retail',
            ),
          )
          .toList();

      if (search.trim().isEmpty) {
        _saveCustomersToLocal(customers, replace: safePage == 1);
      }
      final info = result.data?['getAllCrmContacts']?['info_page'] as List?;
      final totalCount = info?.isNotEmpty == true
          ? (info!.first['count'] as num?)?.toInt() ?? customers.length
          : customers.length;
      return PosCustomerPageResult(
        items: customers,
        totalCount: totalCount,
        page: safePage,
        limit: safeLimit,
      );
    } catch (e) {
      final local = await _getLocalCustomers();
      return PosCustomerPageResult(
        items: local.take(safeLimit).toList(),
        totalCount: local.length,
        page: safePage,
        limit: safeLimit,
      );
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> createCustomer(
    Map<String, dynamic> input,
  ) async {
    try {
      final result = await _clientProvider.client.mutate(
        MutationOptions(
          document: gql(PosQueries.createPOSPelanggan),
          variables: {'input': input},
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final data = result.data?['createCrmContact'];
      return data == null
          ? const Left(ServerFailure('Gagal menambahkan pelanggan'))
          : Right(Map<String, dynamic>.from(data));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> updateCustomer(
    String id,
    Map<String, dynamic> input,
  ) async {
    try {
      final result = await _clientProvider.client.mutate(
        MutationOptions(
          document: gql(PosQueries.updatePOSPelanggan),
          variables: {'_id': id, 'input': input},
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final data = result.data?['updateCrmContact'];
      return data == null
          ? const Left(ServerFailure('Gagal memperbarui pelanggan'))
          : Right(Map<String, dynamic>.from(data));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, bool>> deleteCustomer(String id) async {
    try {
      final result = await _clientProvider.client.mutate(
        MutationOptions(
          document: gql(PosQueries.deletePOSPelanggan),
          variables: {'_id': id},
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return result.data?['deleteCrmContact'] != null
          ? const Right(true)
          : const Left(ServerFailure('Gagal menghapus pelanggan'));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<List<PosCustomer>> _getLocalCustomers() async {
    try {
      final db = await PosLocalDatabase.instance.database;
      final result = await db.query('customers');
      return result
          .map(
            (e) => PosCustomer(
              id: e['id'] as String,
              name: e['name'] as String,
              phone: e['phone'] as String,
              email: e['email']?.toString() ?? '',
              priceLevel: 'retail',
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveCustomersToLocal(
    List<PosCustomer> customers, {
    bool replace = true,
  }) async {
    try {
      final db = await PosLocalDatabase.instance.database;
      final batch = db.batch();
      if (replace) batch.delete('customers');
      for (var customer in customers) {
        batch.insert('customers', {
          'id': customer.id,
          'name': customer.name,
          'phone': customer.phone,
          'email': customer.email,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  Future<List<PosStore>> getStores() async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(PosQueries.getAllPOSToko),
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await _clientProvider.client.query(options);

      if (result.hasException || result.data == null) {
        return _getLocalStores();
      }

      final items =
          result.data?['GetAllPOSToko']?['items'] as List<dynamic>? ?? [];
      final stores = items
          .map(
            (e) => PosStore(
              id: e['_id'] ?? '',
              name: e['nama_toko'] ?? 'Unknown',
              code: e['kode_toko'] ?? '',
              status: e['status'] ?? 'Active',
              address: e['alamat'] ?? '-',
              phone: e['telepon'] ?? '-',
              branchName: e['lokasi_cabang_nama'] ?? '-',
              branchId: e['lokasi_cabang_id']?.toString() ?? '',
            ),
          )
          .toList();

      _saveStoresToLocal(stores);
      return stores;
    } catch (e) {
      return _getLocalStores();
    }
  }

  Future<Either<Failure, bool>> createStore(Map<String, dynamic> input) async {
    try {
      final result = await _clientProvider.client.mutate(
        MutationOptions(
          document: gql(PosQueries.addPOSToko),
          variables: {'input': input},
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return result.data?['AddPOSToko'] != null
          ? const Right(true)
          : const Left(ServerFailure('Gagal menambahkan outlet'));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, bool>> updateStore(
    String id,
    Map<String, dynamic> input,
  ) async {
    try {
      final result = await _clientProvider.client.mutate(
        MutationOptions(
          document: gql(PosQueries.updatePOSToko),
          variables: {'_id': id, 'input': input},
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return result.data?['UpdatePOSToko'] != null
          ? const Right(true)
          : const Left(ServerFailure('Gagal memperbarui outlet'));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, bool>> deleteStore(String id) async {
    try {
      final result = await _clientProvider.client.mutate(
        MutationOptions(
          document: gql(PosQueries.deletePOSToko),
          variables: {'_id': id},
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return result.data?['DeletePOSToko'] != null
          ? const Right(true)
          : const Left(ServerFailure('Gagal menghapus outlet'));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<List<PosStore>> _getLocalStores() async {
    try {
      final db = await PosLocalDatabase.instance.database;
      final result = await db.query('stores');
      return result
          .map(
            (e) => PosStore(
              id: e['id'] as String,
              name: e['name'] as String,
              code: e['id'] as String,
              status: e['status'] as String,
              address: e['address'] as String,
              phone: e['phone'] as String,
              branchName: e['branchName'] as String,
              branchId: e['branchId'] as String? ?? '',
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveStoresToLocal(List<PosStore> stores) async {
    try {
      final db = await PosLocalDatabase.instance.database;
      final batch = db.batch();
      batch.delete('stores');
      for (var store in stores) {
        batch.insert('stores', {
          'id': store.id,
          'name': store.name,
          'status': store.status,
          'address': store.address,
          'phone': store.phone,
          'branchName': store.branchName,
          'branchId': store.branchId,
        });
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  Future<({List<PosOrder> items, bool hasMore})> getOrdersPage({
    int page = 0,
    int limit = 50,
  }) async {
    try {
      final transactionResult = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosQueries.getPOSPenjualan),
          variables: {
            'sorting': {'createdAt': 'desc'},
            'pagination': {'page': page, 'limit': limit},
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (transactionResult.hasException) throw transactionResult.exception!;
      final transactionPayload = transactionResult.data?['GetPOSPenjualan'];
      final transactions =
          transactionPayload?['items'] as List<dynamic>? ?? const [];
      final transactionCount =
          (transactionPayload?['info_page'] as List?)?.firstOrNull?['count']
              as int? ??
          transactions.length;

      final invoiceResult = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosQueries.getPendingPOSOrders),
          variables: {
            'filter': {'status_pembayaran': 'belum_bayar'},
            'sorting': {'createdAt': 'desc'},
            'pagination': {'page': page, 'limit': limit},
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (invoiceResult.hasException) throw invoiceResult.exception!;
      final invoicePayload = invoiceResult.data?['GetAllPOSOrder'];
      final invoices = invoicePayload?['items'] as List<dynamic>? ?? const [];
      final invoiceCount =
          (invoicePayload?['info_page'] as List?)?.firstOrNull?['count']
              as int? ??
          invoices.length;
      final orders = [
        ...invoices.map(
          (item) => PosOrder.fromPendingOrderJson(
            Map<String, dynamic>.from(item as Map),
          ),
        ),
        ...transactions.map(
          (item) => PosOrder.fromJson(Map<String, dynamic>.from(item as Map)),
        ),
      ];
      orders.sort((a, b) => b.dateTime.compareTo(a.dateTime));
      return (
        items: orders,
        hasMore:
            (page + 1) * limit < transactionCount ||
            (page + 1) * limit < invoiceCount,
      );
    } catch (e) {
      appLogger.e('Gagal memuat riwayat transaksi', error: e);
      rethrow;
    }
  }

  Future<List<PosOrder>> getOrders() async => (await getOrdersPage()).items;

  Future<Map<String, dynamic>?> getActiveShift(String tokoId) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(PosQueries.getMyActiveKasirShift),
        variables: {'toko_id': tokoId},
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await _clientProvider.client.query(options);

      if (result.hasException) throw result.exception!;
      if (result.data == null) return null;
      return result.data?['GetMyActiveKasirShift'];
    } catch (e) {
      appLogger.e('Gagal memuat shift kasir aktif', error: e);
      rethrow;
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> payPendingOrder({
    required String orderId,
    required String method,
    double? cashReceived,
    List<Map<String, dynamic>> splitPayments = const [],
  }) async {
    try {
      final result = await _clientProvider.client.mutate(
        MutationOptions(
          document: gql(PosQueries.payPOSOrder),
          variables: {
            'id': orderId,
            'method': method,
            'cashReceived': cashReceived,
            'splitPayments': splitPayments,
          },
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final data = result.data?['PayPOSOrder'];
      if (data is! Map) {
        return const Left(ServerFailure('Pembayaran invoice gagal diproses'));
      }
      return Right(Map<String, dynamic>.from(data));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<bool> openShift(
    String tokoId,
    double amount, [
    String notes = '',
  ]) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PosQueries.openPOSKasirShift),
        variables: {
          'input': {
            'toko_id': tokoId,
            'opening_cash': amount,
            'open_notes': notes,
          },
        },
      );

      final QueryResult result = await _clientProvider.client.mutate(options);
      return !result.hasException && result.data != null;
    } catch (e) {
      return false;
    }
  }

  Future<Either<Failure, bool>> closeShift(
    String shiftId,
    double closingCashActual,
    String closeNotes,
  ) async {
    try {
      final db = await PosLocalDatabase.instance.database;
      final pending =
          Sqflite.firstIntValue(
            await db.rawQuery(
              "SELECT COUNT(*) FROM offline_transactions WHERE shift_id = ? AND status IN ('pending','syncing','failed_permanent')",
              [shiftId],
            ),
          ) ??
          0;
      if (pending > 0) {
        return const Left(
          ServerFailure(
            'Shift belum dapat ditutup karena masih ada transaksi offline',
          ),
        );
      }
      final MutationOptions options = MutationOptions(
        document: gql(PosQueries.closePOSKasirShift),
        variables: {
          'input': {
            'shift_id': shiftId,
            'closing_cash_actual': closingCashActual,
            'close_notes': closeNotes,
          },
        },
      );
      final QueryResult result = await _clientProvider.client.mutate(options);
      if (result.data != null && result.data!['ClosePOSKasirShift'] != null) {
        return const Right(true);
      }
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return const Left(ServerFailure('Gagal menutup shift'));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, bool>> addPettyCash(
    String shiftId,
    String tipe,
    double jumlah,
    String keterangan,
  ) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PosQueries.addPOSKasirPettyCash),
        variables: {
          'input': {
            'shift_id': shiftId,
            'tipe': tipe,
            'jumlah': jumlah,
            'keterangan': keterangan,
          },
        },
      );
      final QueryResult result = await _clientProvider.client.mutate(options);
      if (result.data != null && result.data!['AddPOSKasirPettyCash'] != null) {
        return const Right(true);
      }
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return const Left(ServerFailure('Gagal menyimpan petty cash'));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> getShiftHistory({
    int page = 0,
    int limit = 100,
  }) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(PosQueries.getPOSKasirShifts),
        variables: {
          'pagination': {'page': page, 'limit': limit},
        },
        fetchPolicy: FetchPolicy.networkOnly,
      );
      final QueryResult result = await _clientProvider.client.query(options);
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final items = result.data?['GetPOSKasirShifts']?['items'] as List?;
      if (items == null) return const Right([]);
      return Right(List<Map<String, dynamic>>.from(items));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, PosTransactionResult>> submitTransaction({
    required Map<PosProduct, int> cart,
    required double total,
    required String paymentMethod,
    required String tokoId,
    required String shiftId,
    required double cashReceived,
    List<Map<String, dynamic>> payments = const [],
    String? pelangganId,
    String? pelangganName,
    String? pelangganPhone,
    String? pelangganEmail,
    String? promoCode,
    String? discountPolicy,
    double? diskon,
    double? pajak,
    String? catatan,
    String orderType = 'take_away',
    String salesChannel = 'retail',
    String customerSegment = 'regular',
    String priceLevel = 'retail',
    String expiredSaleReason = '',
    String expiredSaleAuthorizerUsername = '',
    String expiredSaleAuthorizerPin = '',
    String operatorSessionToken = '',
  }) async {
    final items = cart.entries
        .map(
          (e) => {
            'inventaris_id': e.key.id,
            'unit': e.key.saleUnit,
            'qty': e.value.toDouble(),
          },
        )
        .toList();

    final payload = {
      'client_transaction_id': const Uuid().v4(),
      'tanggal': DateTime.now().toIso8601String(),
      'toko_id': tokoId,
      'pelanggan': pelangganName?.trim() ?? '',
      'pelanggan_id': pelangganId,
      'channel_penjualan': salesChannel,
      'customer_segment': customerSegment,
      'price_level': priceLevel,
      'promo_code': promoCode ?? '',
      'discount_policy': discountPolicy ?? 'stack',
      'tipe_pesanan': orderType,
      'metode_pembayaran': paymentMethod,
      'uang_diterima': paymentMethod == 'tunai' ? cashReceived : null,
      'payments': paymentMethod == 'split' ? payments : const [],
      'diskon': diskon ?? 0,
      'pajak': pajak ?? 0,
      'catatan': catatan ?? 'POS Mobile ($paymentMethod)',
      if (expiredSaleReason.trim().isNotEmpty)
        'expired_sale_reason': expiredSaleReason.trim(),
      if (expiredSaleAuthorizerUsername.trim().isNotEmpty)
        'expired_sale_authorizer_username': expiredSaleAuthorizerUsername
            .trim(),
      if (expiredSaleAuthorizerPin.trim().isNotEmpty)
        'expired_sale_authorizer_pin': expiredSaleAuthorizerPin.trim(),
      if ((operatorSessionToken.trim().isNotEmpty
              ? operatorSessionToken.trim()
              : _operatorSessionToken)
          .isNotEmpty)
        'operator_session_token': operatorSessionToken.trim().isNotEmpty
            ? operatorSessionToken.trim()
            : _operatorSessionToken,
      'items': items,
    };

    try {
      final MutationOptions options = MutationOptions(
        document: gql(PosQueries.processPOSPenjualan),
        variables: {'input': payload},
      );

      final QueryResult result = await _clientProvider.client.mutate(options);

      if (result.data != null && result.data!['ProcessPOSPenjualan'] != null) {
        return Right(
          PosTransactionResult.fromJson(
            Map<String, dynamic>.from(result.data!['ProcessPOSPenjualan']),
            customerName: pelangganName ?? '',
            customerPhone: pelangganPhone ?? '',
            customerEmail: pelangganEmail ?? '',
          ),
        );
      }

      if (result.hasException && _isRetryableNetworkFailure(result.exception)) {
        if (!supportsOfflineDatabase) {
          return Left(AppErrorHandler.handle(result.exception!));
        }
        await _saveTransactionToOfflineQueue(
          payload,
          tokoId: tokoId,
          shiftId: shiftId,
        );
        return Right(
          PosTransactionResult(
            id: payload['client_transaction_id'].toString(),
            invoice: 'OFF-${DateTime.now().millisecondsSinceEpoch}',
            subtotal: total,
            discount: diskon ?? 0,
            promoDiscount: 0,
            tax: pajak ?? 0,
            total: total,
            cashReceived: cashReceived,
            change: cashReceived > total ? cashReceived - total : 0,
            paymentMethod: paymentMethod,
            pendingSync: true,
            customerName: pelangganName ?? '',
            customerPhone: pelangganPhone ?? '',
            customerEmail: pelangganEmail ?? '',
          ),
        );
      }
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      return const Left(ServerFailure('Format respon tidak valid dari server'));
    } on LinkException {
      if (!supportsOfflineDatabase) {
        return const Left(
          NetworkFailure(
            'Koneksi server terputus. Transaksi web belum disimpan; silakan coba kembali.',
          ),
        );
      }
      await _saveTransactionToOfflineQueue(
        payload,
        tokoId: tokoId,
        shiftId: shiftId,
      );
      return Right(
        PosTransactionResult(
          id: payload['client_transaction_id'].toString(),
          invoice: 'OFF-${DateTime.now().millisecondsSinceEpoch}',
          subtotal: total,
          discount: diskon ?? 0,
          promoDiscount: 0,
          tax: pajak ?? 0,
          total: total,
          cashReceived: cashReceived,
          change: cashReceived > total ? cashReceived - total : 0,
          paymentMethod: paymentMethod,
          pendingSync: true,
          customerName: pelangganName ?? '',
          customerPhone: pelangganPhone ?? '',
          customerEmail: pelangganEmail ?? '',
        ),
      );
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> createUnpaidInvoice({
    required Map<PosProduct, int> cart,
    required String tokoId,
    required String shiftId,
    required String orderType,
    String? customerId,
    String? customerName,
    String? note,
    double discountPercent = 0,
    double taxPercent = 0,
    String salesChannel = 'retail',
    String customerSegment = 'regular',
    String priceLevel = 'retail',
    Map<String, double> itemPrices = const {},
  }) async {
    try {
      final result = await _clientProvider.client.mutate(
        MutationOptions(
          document: gql(PosQueries.createPOSInvoice),
          variables: {
            'input': {
              'client_request_id': const Uuid().v4(),
              'toko_id': tokoId,
              'shift_id': shiftId,
              'pelanggan_id': customerId,
              'pelanggan_nama': customerName ?? '',
              'channel': orderType == 'dine_in' ? 'Dine-In' : 'Take Away',
              'sales_channel': salesChannel,
              'customer_segment': customerSegment,
              'price_level': priceLevel,
              'tipe_pesanan': orderType,
              'catatan': note ?? '',
              'diskon_persen': discountPercent,
              'pajak_persen': taxPercent,
              'source': 'kasir',
              'items': cart.entries
                  .map(
                    (entry) => {
                      'produk_id': entry.key.id,
                      'nama': entry.key.name,
                      'kode': entry.key.code,
                      'qty': entry.value.toDouble(),
                      'unit': entry.key.saleUnit,
                      'harga_satuan':
                          itemPrices[entry.key.id] ?? entry.key.price,
                    },
                  )
                  .toList(),
            },
          },
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final data = result.data?['CreatePOSOrder'];
      if (data is! Map) {
        return const Left(ServerFailure('Invoice gagal dibuat'));
      }
      return Right(Map<String, dynamic>.from(data));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> previewPricing({
    required Map<PosProduct, int> cart,
    required String tokoId,
    required String promoCode,
    required String discountPolicy,
    required double manualDiscount,
    required String salesChannel,
    required String customerSegment,
    required String priceLevel,
    String? customerId,
  }) async {
    try {
      final result = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosQueries.previewPOSPricing),
          fetchPolicy: FetchPolicy.networkOnly,
          variables: {
            'input': {
              'toko_id': tokoId,
              'channel_penjualan': salesChannel,
              'customer_segment': customerSegment,
              'price_level': priceLevel,
              if (customerId != null && customerId.isNotEmpty)
                'pelanggan': customerId,
              'promo_code': promoCode,
              'discount_policy': discountPolicy,
              'diskon': manualDiscount,
              'tanggal': DateTime.now().toIso8601String(),
              'items': cart.entries
                  .map(
                    (entry) => {
                      'inventaris_id': entry.key.id,
                      'unit': entry.key.saleUnit,
                      'qty': entry.value.toDouble(),
                    },
                  )
                  .toList(),
            },
          },
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final data = result.data?['PreviewPOSPricing'];
      if (data == null) {
        return const Left(ServerFailure('Preview harga tidak tersedia'));
      }
      return Right(Map<String, dynamic>.from(data));
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  bool _isRetryableNetworkFailure(OperationException? exception) {
    return exception?.linkException != null &&
        exception?.graphqlErrors.isEmpty == true;
  }

  static List<Map<String, dynamic>> _decodeUnitConversions(String? value) {
    if (value == null || value.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _saveTransactionToOfflineQueue(
    Map<String, dynamic> payload, {
    required String tokoId,
    required String shiftId,
  }) async {
    final clientTransactionId = payload['client_transaction_id']?.toString();
    if (clientTransactionId == null || clientTransactionId.isEmpty) {
      throw StateError('Client transaction ID wajib tersedia');
    }
    final db = await PosLocalDatabase.instance.database;
    await db.transaction((txn) async {
      final rowId = await txn.insert('offline_transactions', {
        'payload': jsonEncode(payload),
        'status': 'pending',
        'timestamp': DateTime.now().toIso8601String(),
        'instansi_id': _prefs.getString('instansi_id') ?? '',
        'toko_id': tokoId,
        'shift_id': shiftId,
        'client_transaction_id': clientTransactionId,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      // Baris sudah ada berarti payload ini pernah disimpan. Jangan kurangi
      // cache stok untuk kedua kalinya.
      if (rowId == 0) return;
      for (final rawItem in payload['items'] as List<dynamic>? ?? const []) {
        final item = Map<String, dynamic>.from(rawItem as Map);
        final productId = item['inventaris_id']?.toString();
        final qty = (item['qty'] as num?)?.toDouble() ?? 0;
        if (productId == null || qty <= 0) continue;
        await txn.rawUpdate(
          'UPDATE products SET stock = MAX(0, stock - ?) WHERE id = ?',
          [qty, productId],
        );
      }
    });
  }

  // --- Retur Penjualan ---
  Future<Either<Failure, List<Map<String, dynamic>>>> getAllSalesReturns({
    String? search,
    String? status,
  }) async {
    try {
      final filter = <String, dynamic>{};
      if (search != null && search.isNotEmpty) filter['search'] = search;
      if (status != null && status.isNotEmpty) filter['status'] = status;

      final QueryOptions options = QueryOptions(
        document: gql(PosReturnQueries.getAllSalesReturns),
        variables: {
          'filter': filter,
          'pagination': {'page': 1, 'limit': 100},
        },
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await _clientProvider.client.query(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final items = result.data?['GetAllSalesReturns']?['items'] as List?;
      if (items == null) return const Right([]);

      return Right(List<Map<String, dynamic>>.from(items));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> findInvoice(
    String invoice,
  ) async {
    try {
      final QueryOptions options = QueryOptions(
        document: gql(PosQueries.getPOSPenjualan),
        variables: {
          'filter': {'search': invoice},
          'pagination': {'page': 0, 'limit': 5},
        },
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final QueryResult result = await _clientProvider.client.query(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final items = result.data?['GetPOSPenjualan']?['items'] as List?;
      if (items == null || items.isEmpty) {
        return const Left(ServerFailure('Invoice tidak ditemukan'));
      }

      final match = items.firstWhere(
        (i) => i['invoice'].toString().toLowerCase() == invoice.toLowerCase(),
        orElse: () => null,
      );

      if (match == null) {
        return const Left(ServerFailure('Invoice tidak cocok'));
      }

      return Right(Map<String, dynamic>.from(match));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, bool>> createSalesReturn(
    Map<String, dynamic> payload,
  ) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PosReturnQueries.createSalesReturn),
        variables: {'input': payload},
      );
      final QueryResult result = await _clientProvider.client.mutate(options);

      if (result.data != null && result.data!['CreateSalesReturn'] != null) {
        return const Right(true);
      }
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return const Left(ServerFailure('Gagal membuat draf retur'));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, bool>> approveSalesReturn(String id) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PosReturnQueries.approveSalesReturn),
        variables: {'_id': id, 'catatan': 'Approved via Mobile POS'},
      );
      final QueryResult result = await _clientProvider.client.mutate(options);

      if (result.data != null && result.data!['ApproveSalesReturn'] != null) {
        return const Right(true);
      }
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return const Left(ServerFailure('Gagal menyetujui retur'));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, bool>> processSalesReturn(String id) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PosReturnQueries.processSalesReturn),
        variables: {'_id': id},
      );
      final QueryResult result = await _clientProvider.client.mutate(options);

      if (result.data != null && result.data!['ProcessSalesReturn'] != null) {
        return const Right(true);
      }
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return const Left(ServerFailure('Gagal memproses retur'));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, bool>> deleteSalesReturn(String id) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PosReturnQueries.deleteSalesReturn),
        variables: {'_id': id},
      );
      final QueryResult result = await _clientProvider.client.mutate(options);

      if (result.data != null && result.data!['DeleteSalesReturn'] != null) {
        return const Right(true);
      }
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return const Left(ServerFailure('Gagal menghapus retur'));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }
}
