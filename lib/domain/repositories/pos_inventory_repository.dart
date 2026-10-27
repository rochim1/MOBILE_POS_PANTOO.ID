import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/error/error_handler.dart';
import '../../core/error/failures.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../data/graphql/pos_inventory_queries.dart';

enum PosInventoryDocumentType { purchase, opname, transfer, scrap }

class PosInventoryDocumentPage {
  final List<Map<String, dynamic>> items;
  final int totalCount;
  const PosInventoryDocumentPage(this.items, this.totalCount);
}

class PosInventoryLookups {
  final List<Map<String, dynamic>> suppliers;
  final List<Map<String, dynamic>> warehouses;
  final String activeWarehouseId;
  final List<Map<String, dynamic>> inventoryItems;
  final List<Map<String, dynamic>> scrapReasons;
  final List<Map<String, dynamic>> scrapIncidentTypes;
  final List<Map<String, dynamic>> scrapOccurrenceLocations;
  final List<Map<String, dynamic>> purchaseReturnReasons;
  final List<Map<String, dynamic>> purchaseReturnMethods;
  const PosInventoryLookups({
    required this.suppliers,
    required this.warehouses,
    required this.activeWarehouseId,
    required this.inventoryItems,
    required this.scrapReasons,
    required this.scrapIncidentTypes,
    required this.scrapOccurrenceLocations,
    required this.purchaseReturnReasons,
    required this.purchaseReturnMethods,
  });
}

class PosInventoryRepository {
  final GraphQLClientProvider _provider;
  PosInventoryRepository(this._provider);
  Future<Either<Failure, PosInventoryDocumentPage>>
  getEligibleAdvancePurchases({String search = '', int page = 1}) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.eligibleAdvancePurchases),
          variables: {
            'search': search,
            'pagination': {'page': page, 'limit': 20},
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final data = result.data?['GetEligibleAdvancePurchasePage'];
      return Right(
        PosInventoryDocumentPage(
          (data?['items'] as List? ?? [])
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList(),
          (data?['totalCount'] as num?)?.toInt() ?? 0,
        ),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getPurchaseAdvanceWorkspace({
    String search = '',
    int page = 1,
  }) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.purchaseAdvanceWorkspace),
          variables: {
            'search': search,
            'pagination': {'page': page, 'limit': 20},
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return Right(Map<String, dynamic>.from(result.data ?? const {}));
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> requestPurchaseAdvance(
    Map<String, dynamic> input,
  ) async {
    try {
      final result = await _provider.client.mutate(
        MutationOptions(
          document: gql(PosInventoryQueries.requestPurchaseAdvance),
          variables: {'input': input},
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final raw = result.data?['RequestPurchaseAdvance'];
      return raw is Map
          ? Right(Map<String, dynamic>.from(raw))
          : const Left(ServerFailure('Permintaan DP gagal disimpan'));
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, String>> uploadVendorInvoiceEvidence(
    Uint8List bytes,
    String filename, {
    String folderName = 'vendor-invoice-submissions',
    String prefix = 'invoice',
    String label = 'Foto invoice',
  }) async {
    try {
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
        return Left(ServerFailure('$label wajib diisi dan maksimal 10 MB'));
      }
      final extension = filename.split('.').last.toLowerCase();
      final subtype = switch (extension) {
        'jpg' || 'jpeg' => 'jpeg',
        'png' => 'png',
        'webp' => 'webp',
        _ => '',
      };
      if (subtype.isEmpty) {
        return const Left(
          ServerFailure('Format foto invoice harus JPG, PNG, atau WebP'),
        );
      }
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_provider.endpointUrl),
      );
      request.headers.addAll(await _provider.authenticatedRequestHeaders());
      request.fields['operations'] = jsonEncode({
        'query': PosInventoryQueries.uploadVendorInvoiceEvidence,
        'variables': {'file': null, 'folderName': folderName, 'prefix': prefix},
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
      final response = await http.Response.fromStream(await request.send());
      final payload = jsonDecode(response.body);
      if (payload is! Map) {
        return const Left(ServerFailure('Respons upload bukti tidak valid'));
      }
      final errors = payload['errors'];
      if (errors is List && errors.isNotEmpty) {
        return Left(
          ServerFailure(
            (errors.first as Map?)?['message']?.toString() ??
                'Upload bukti gagal',
          ),
        );
      }
      final rawUrl =
          (payload['data'] as Map?)?['UploadQuestionImage']?['media_url']
              ?.toString() ??
          '';
      if (rawUrl.isEmpty) {
        return const Left(
          ServerFailure('Server tidak mengembalikan URL bukti'),
        );
      }
      return Right(rawUrl);
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, String>> uploadDirectPurchaseReceipt(
    Uint8List bytes,
    String filename,
  ) => uploadVendorInvoiceEvidence(
    bytes,
    filename,
    folderName: 'direct-purchase-receipts',
    prefix: 'receipt',
    label: 'Bukti nota',
  );

  Future<Either<Failure, String>> uploadPurchaseAdvanceProforma(
    Uint8List bytes,
    String filename,
  ) async {
    try {
      if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
        return const Left(ServerFailure('Lampiran proforma maksimal 10 MB'));
      }
      final extension = filename.split('.').last.toLowerCase();
      final subtype = switch (extension) {
        'jpg' || 'jpeg' => 'jpeg',
        'png' => 'png',
        'webp' => 'webp',
        _ => '',
      };
      if (subtype.isEmpty) {
        return const Left(
          ServerFailure('Format proforma harus JPG, PNG, atau WebP'),
        );
      }
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_provider.endpointUrl),
      );
      request.headers.addAll(await _provider.authenticatedRequestHeaders());
      request.fields['operations'] = jsonEncode({
        'query': PosInventoryQueries.uploadVendorInvoiceEvidence,
        'variables': {
          'file': null,
          'folderName': 'purchase-advance-proforma',
          'prefix': 'proforma',
        },
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
      final response = await http.Response.fromStream(await request.send());
      final payload = jsonDecode(response.body);
      if (payload is! Map) {
        return const Left(ServerFailure('Respons upload proforma tidak valid'));
      }
      final errors = payload['errors'];
      if (errors is List && errors.isNotEmpty) {
        return Left(
          ServerFailure(
            (errors.first as Map?)?['message']?.toString() ??
                'Upload proforma gagal',
          ),
        );
      }
      final url =
          (payload['data'] as Map?)?['UploadQuestionImage']?['media_url']
              ?.toString() ??
          '';
      return url.isEmpty
          ? const Left(ServerFailure('Server tidak mengembalikan URL proforma'))
          : Right(url);
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> submitVendorInvoiceEvidence(
    Map<String, dynamic> input,
  ) async {
    try {
      final result = await _provider.client.mutate(
        MutationOptions(
          document: gql(PosInventoryQueries.submitVendorInvoiceEvidence),
          variables: {'input': input},
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final raw = result.data?['SubmitVendorInvoiceEvidence'];
      return raw is Map
          ? Right(Map<String, dynamic>.from(raw))
          : const Left(ServerFailure('Submission invoice gagal disimpan'));
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getPayableForPaymentProof(
    String payableId,
  ) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.payableForPaymentProof),
          variables: {'id': payableId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(_verifiedPrintFailure(result.exception!));
      }
      final raw = result.data?['GetOneInventoryPayable'];
      if (raw is! Map) {
        return const Left(ServerFailure('Pembayaran tidak ditemukan'));
      }
      return Right(Map<String, dynamic>.from(raw));
    } catch (error) {
      return Left(_verifiedPrintFailure(error));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getPurchaseForPrint(
    String id,
  ) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.purchaseDetail),
          variables: {'id': id},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(_verifiedPrintFailure(result.exception!));
      }
      final raw = result.data?['GetOneInventoryPurchase'];
      if (raw is! Map) {
        return const Left(ServerFailure('PO tidak ditemukan'));
      }
      return Right(Map<String, dynamic>.from(raw));
    } catch (error) {
      return Left(_verifiedPrintFailure(error));
    }
  }

  Failure _verifiedPrintFailure(Object error) {
    final failure = AppErrorHandler.handle(error);
    if (failure is NetworkFailure) {
      return const NetworkFailure(
        'Dokumen resmi perlu koneksi untuk memverifikasi status terbaru. '
        'Sambungkan internet lalu coba lagi; data lama tidak dicetak otomatis.',
      );
    }
    return failure;
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> getWarehouses({
    String search = '',
  }) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.warehouses),
          variables: {'search': search.trim().isEmpty ? null : search.trim()},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final root = result.data?['getAllCabangs'] as Map?;
      return Right(
        (root?['cabang'] as List? ?? const [])
            .map((value) => Map<String, dynamic>.from(value as Map))
            .toList(),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, bool>> saveWarehouse(
    Map<String, dynamic> input, {
    String? id,
  }) async {
    try {
      final updating = id != null && id.isNotEmpty;
      final result = await _provider.client.mutate(
        MutationOptions(
          document: gql(
            updating
                ? PosInventoryQueries.updateWarehouse
                : PosInventoryQueries.createWarehouse,
          ),
          variables: {if (updating) 'id': id, 'input': input},
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final key = updating ? 'updateCabang' : 'createCabang';
      return result.data?[key] != null
          ? const Right(true)
          : const Left(ServerFailure('Warehouse gagal disimpan'));
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, bool>> deleteWarehouse(String id) async {
    try {
      final result = await _provider.client.mutate(
        MutationOptions(
          document: gql(PosInventoryQueries.deleteWarehouse),
          variables: {'id': id},
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return result.data?['deleteCabang'] != null
          ? const Right(true)
          : const Left(ServerFailure('Warehouse gagal dihapus'));
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, PosInventoryDocumentPage>> getDocuments({
    required PosInventoryDocumentType type,
    String search = '',
    String status = '',
    List<String> statuses = const [],
    String inventoryId = '',
    bool receivableOnly = false,
    bool openQuantityOnly = false,
    String workflowView = '',
    String locationId = '',
    String dateFrom = '',
    String dateTo = '',
    String reason = '',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final filter = <String, dynamic>{
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (status.isNotEmpty) 'status': status,
        if (type == PosInventoryDocumentType.purchase &&
            status.isEmpty &&
            statuses.isNotEmpty)
          'statuses': statuses,
        if (type == PosInventoryDocumentType.purchase && inventoryId.isNotEmpty)
          'inventaris_id': inventoryId,
        if (type == PosInventoryDocumentType.purchase && receivableOnly)
          'receivable_only': true,
        if (type == PosInventoryDocumentType.purchase && openQuantityOnly)
          'open_quantity_only': true,
        if (type == PosInventoryDocumentType.purchase &&
            workflowView.isNotEmpty)
          'workflow_view': workflowView,
        if (type == PosInventoryDocumentType.opname && locationId.isNotEmpty)
          'lokasi_cabang_id': locationId,
        if (type == PosInventoryDocumentType.opname && dateFrom.isNotEmpty)
          'tanggal_dari': dateFrom,
        if (type == PosInventoryDocumentType.opname && dateTo.isNotEmpty)
          'tanggal_sampai': dateTo,
        if (type == PosInventoryDocumentType.scrap && reason.isNotEmpty)
          'alasan': reason,
        if (type == PosInventoryDocumentType.scrap && dateFrom.isNotEmpty)
          'date_from': dateFrom,
        if (type == PosInventoryDocumentType.scrap && dateTo.isNotEmpty)
          'date_to': dateTo,
      };
      final document = switch (type) {
        PosInventoryDocumentType.purchase => PosInventoryQueries.purchases,
        PosInventoryDocumentType.opname => PosInventoryQueries.opnames,
        PosInventoryDocumentType.transfer => PosInventoryQueries.transfers,
        PosInventoryDocumentType.scrap => PosInventoryQueries.scraps,
      };
      final variables = <String, dynamic>{'filter': filter};
      if (type == PosInventoryDocumentType.purchase) {
        variables['pagination'] = {
          'page': page > 0 ? page - 1 : 0,
          'limit': limit,
        };
      } else if (type == PosInventoryDocumentType.scrap) {
        variables['pagination'] = {'page': page, 'limit': limit};
      } else {
        variables.addAll({'page': page, 'limit': limit});
      }
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(document),
          variables: variables,
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final rootKey = switch (type) {
        PosInventoryDocumentType.purchase => 'GetAllInventoryPurchases',
        PosInventoryDocumentType.opname => 'GetAllInventoryOpnames',
        PosInventoryDocumentType.transfer => 'GetAllInventoryTransfers',
        PosInventoryDocumentType.scrap => 'GetAllInventoryScraps',
      };
      final root = result.data?[rootKey] as Map?;
      final rawItems =
          type == PosInventoryDocumentType.purchase ||
              type == PosInventoryDocumentType.scrap
          ? (root?['items'] as List?)
          : (root?['data'] as List?);
      final total =
          type == PosInventoryDocumentType.purchase ||
              type == PosInventoryDocumentType.scrap
          ? (root?['totalCount'])
          : (root?['total']);
      return Right(
        PosInventoryDocumentPage(
          (rawItems ?? const [])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList(),
          (total as num?)?.toInt() ?? 0,
        ),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> receiveTransfer(
    String id,
    List<Map<String, dynamic>> items,
    String requestId,
  ) async {
    try {
      final result = await _provider.client.mutate(
        MutationOptions(
          document: gql(PosInventoryQueries.receiveTransfer),
          variables: {'id': id, 'items': items, 'request_id': requestId},
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final data = result.data?['ReceiveInventoryTransfer'];
      if (data is! Map) {
        return const Left(ServerFailure('Mutasi stok gagal diterima'));
      }
      return Right(Map<String, dynamic>.from(data));
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, PosInventoryLookups>> getLookups({
    bool purchaseOnly = false,
  }) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(
            purchaseOnly
                ? PosInventoryQueries.purchaseLookups
                : PosInventoryQueries.lookups,
          ),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final branchRoot = result.data?['getAllCabangs'] as Map?;
      final shift = result.data?['GetMyActiveKasirShift'] as Map?;
      final inventoryRoot = purchaseOnly
          ? null
          : result.data?['GetAllInventarisUmum'] as Map?;
      final settings = result.data?['GetInventorySettings'] as Map?;
      final operationDefaults =
          settings?['inventory_operation_defaults'] as Map?;
      final toko = shift?['toko'] as Map?;
      final transactionOptions =
          result.data?['GetInventoryTransactionOptions'] as Map?;
      final inventoryItems = purchaseOnly
          ? (result.data?['GetPOSPurchaseInventory'] as List? ?? const [])
          : (inventoryRoot?['items'] as List? ?? const []);
      List<Map<String, dynamic>> options(String key) =>
          (transactionOptions?[key] as List? ?? const [])
              .map((value) => Map<String, dynamic>.from(value as Map))
              .toList();
      return Right(
        PosInventoryLookups(
          suppliers: const [],
          warehouses: (branchRoot?['cabang'] as List? ?? const [])
              .map((value) => Map<String, dynamic>.from(value as Map))
              .toList(),
          activeWarehouseId:
              operationDefaults?['default_receiving_location_id']?.toString() ??
              toko?['lokasi_cabang_id']?.toString() ??
              '',
          inventoryItems: inventoryItems
              .map((value) => Map<String, dynamic>.from(value as Map))
              .toList(),
          scrapReasons: options('scrap_reasons'),
          scrapIncidentTypes: options('scrap_incident_types'),
          scrapOccurrenceLocations: options('scrap_occurrence_locations'),
          purchaseReturnReasons: options('purchase_return_reasons'),
          purchaseReturnMethods: options('purchase_return_methods'),
        ),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> searchPurchaseSuppliers(
    String search,
  ) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.purchaseSuppliers),
          variables: {'search': search.trim(), 'limit': 20},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final rows = result.data?['GetPOSPurchaseSuppliers'] as List? ?? const [];
      return Right(
        rows.map((row) => Map<String, dynamic>.from(row as Map)).toList(),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> createPurchaseSupplierQuick({
    required String name,
    String phone = '',
  }) async {
    try {
      final result = await _provider.client.mutate(
        MutationOptions(
          document: gql(PosInventoryQueries.createPurchaseSupplierQuick),
          variables: {
            'input': {'nama_supplier': name.trim(), 'telepon': phone.trim()},
          },
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final supplier = result.data?['AddPOSPurchaseSupplierQuick'];
      if (supplier is! Map) {
        return const Left(ServerFailure('Supplier belum tersimpan'));
      }
      return Right(Map<String, dynamic>.from(supplier));
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> searchPurchaseInventory(
    String search,
  ) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.purchaseInventorySearch),
          variables: {'search': search.trim()},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final rows = result.data?['GetPOSPurchaseInventory'] as List? ?? const [];
      return Right(
        rows.map((row) => Map<String, dynamic>.from(row as Map)).toList(),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, Map<String, dynamic>?>> getPurchaseInventoryById(
    String inventoryId,
  ) async {
    if (inventoryId.trim().isEmpty) return const Right(null);
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.purchaseInventoryById),
          variables: {'inventoryId': inventoryId.trim()},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final rows = result.data?['GetPOSPurchaseInventory'] as List? ?? const [];
      return Right(
        rows.isEmpty ? null : Map<String, dynamic>.from(rows.first as Map),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>>
  findPurchaseInventoryByCode(String code) async {
    if (code.trim().isEmpty) return const Right([]);
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.purchaseInventoryByCode),
          variables: {'code': code.trim()},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final rows = result.data?['GetPOSPurchaseInventory'] as List? ?? const [];
      return Right(
        rows.map((row) => Map<String, dynamic>.from(row as Map)).toList(),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> getLocationItems(
    String warehouseId,
  ) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.locationItems),
          variables: {'cabangId': warehouseId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return Right(
        (result.data?['GetInventarisAvailableInLocation'] as List? ?? const [])
            .map((value) => Map<String, dynamic>.from(value as Map))
            .toList(),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> getLocationBalances({
    required String inventoryId,
    String warehouseId = '',
  }) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.locationBalances),
          variables: {
            'inventoryId': inventoryId,
            'warehouseId': warehouseId.isEmpty ? null : warehouseId,
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final root = result.data?['GetInventoryLocationBalances'] as Map?;
      return Right(
        (root?['items'] as List? ?? const [])
            .map((item) => Map<String, dynamic>.from(item as Map))
            .where((item) => ((item['qty'] as num?)?.toDouble() ?? 0) > 0)
            .toList(),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, dynamic>> saveDocument({
    required PosInventoryDocumentType type,
    required Map<String, dynamic> input,
    String? id,
  }) {
    final updating = id != null && id.isNotEmpty;
    final document = switch (type) {
      PosInventoryDocumentType.purchase =>
        updating
            ? PosInventoryQueries.updatePurchase
            : PosInventoryQueries.createPurchase,
      PosInventoryDocumentType.opname =>
        updating
            ? PosInventoryQueries.updateOpname
            : PosInventoryQueries.createOpname,
      PosInventoryDocumentType.transfer =>
        updating
            ? PosInventoryQueries.updateTransfer
            : PosInventoryQueries.createTransfer,
      PosInventoryDocumentType.scrap =>
        updating
            ? PosInventoryQueries.updateScrap
            : PosInventoryQueries.createScrap,
    };
    final key = switch (type) {
      PosInventoryDocumentType.purchase =>
        updating ? 'UpdateInventoryPurchase' : 'AddInventoryPurchase',
      PosInventoryDocumentType.opname =>
        updating ? 'UpdateInventoryOpname' : 'CreateInventoryOpname',
      PosInventoryDocumentType.transfer =>
        updating ? 'UpdateInventoryTransfer' : 'CreateInventoryTransfer',
      PosInventoryDocumentType.scrap =>
        updating ? 'UpdateInventoryScrap' : 'CreateInventoryScrap',
    };
    return _mutate(document, {if (updating) 'id': id, 'input': input}, key);
  }

  Future<Either<Failure, dynamic>> runAction({
    required PosInventoryDocumentType type,
    required String action,
    required String id,
    String reason = '',
  }) {
    final entry = _actionEntry(type, action);
    return _mutate(entry.$1, {
      'id': id,
      if (entry.$3) 'reason': reason,
    }, entry.$2);
  }

  Future<Either<Failure, dynamic>> receivePurchase(
    Map<String, dynamic> input,
  ) => _mutate(PosInventoryQueries.receivePurchase, {
    'input': input,
  }, 'AddInventoryReceiving');

  Future<Either<Failure, dynamic>> markPurchaseSent(
    Map<String, dynamic> input,
  ) => _mutate(PosInventoryQueries.markPurchaseSent, {
    'input': input,
  }, 'MarkInventoryPurchaseSentToSupplier');

  Future<Either<Failure, dynamic>> acknowledgePurchase(
    Map<String, dynamic> input,
  ) => _mutate(
    PosInventoryQueries.acknowledgePurchase,
    {'input': input},
    'RecordSupplierPurchaseAcknowledgement',
  );

  Future<Either<Failure, dynamic>> closePurchaseWithVariance(
    Map<String, dynamic> input,
  ) => _mutate(
    PosInventoryQueries.closePurchaseWithVariance,
    {'input': input},
    'CloseInventoryPurchaseWithVariance',
  );

  Future<Either<Failure, Map<String, dynamic>>>
  getDirectPurchaseWorkspace() async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.directPurchases),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return Right(Map<String, dynamic>.from(result.data ?? const {}));
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, dynamic>> createDirectPurchase(
    Map<String, dynamic> input,
  ) => _mutate(PosInventoryQueries.createDirectPurchase, {
    'input': input,
  }, 'CreateDirectPurchase');

  Future<Either<Failure, Map<String, dynamic>?>> getPayableForPurchase(
    String purchaseId,
  ) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.payableForPurchase),
          variables: {
            'filter': {'purchase_id': purchaseId},
            'pagination': {'page': 0, 'limit': 100},
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final rows =
          result.data?['GetAllInventoryPayables']?['items'] as List? ??
          const [];
      for (final row in rows) {
        final item = Map<String, dynamic>.from(row as Map);
        if (item['purchase_id']?.toString() == purchaseId) return Right(item);
      }
      return const Right(null);
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>> getVendorBillsForPurchase(
    String purchaseId,
  ) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.vendorBillsForPurchase),
          variables: {'purchaseId': purchaseId, 'page': 1, 'limit': 100},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final rows =
          result.data?['GetVendorBills']?['items'] as List? ?? const [];
      return Right(
        rows.map((row) => Map<String, dynamic>.from(row as Map)).toList(),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, List<Map<String, dynamic>>>>
  getActiveBankAccounts() async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.activeBankAccounts),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final rows =
          result.data?['GetAllBankAccounts']?['items'] as List? ?? const [];
      return Right(
        rows.map((row) => Map<String, dynamic>.from(row as Map)).toList(),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> payInventoryPayable(
    Map<String, dynamic> input,
  ) async {
    try {
      final result = await _provider.client.mutate(
        MutationOptions(
          document: gql(PosInventoryQueries.payInventoryPayable),
          variables: {'input': input},
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final data = result.data?['PayInventoryPayable'];
      if (data is! Map) {
        return const Left(ServerFailure('Pembayaran hutang gagal disimpan'));
      }
      return Right(Map<String, dynamic>.from(data));
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> cancelInventoryPayablePayment(
    Map<String, dynamic> input,
  ) async {
    try {
      final result = await _provider.client.mutate(
        MutationOptions(
          document: gql(PosInventoryQueries.cancelInventoryPayablePayment),
          variables: {'input': input},
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final data = result.data?['CancelInventoryPayablePayment'];
      if (data is! Map) {
        return const Left(ServerFailure('Pembatalan pembayaran gagal'));
      }
      return Right(Map<String, dynamic>.from(data));
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, dynamic>> retryReceivingJournal(String id) => _mutate(
    PosInventoryQueries.retryReceivingJournal,
    {'id': id},
    'RetryInventoryReceivingJournal',
  );

  Future<Either<Failure, dynamic>> retryReceivingCancelJournal(String id) =>
      _mutate(
        PosInventoryQueries.retryReceivingCancelJournal,
        {'id': id},
        'RetryInventoryReceivingCancelJournal',
      );

  Future<Either<Failure, dynamic>> retryScrapJournal(String id) => _mutate(
    PosInventoryQueries.retryScrapJournal,
    {'id': id},
    'RetryInventoryScrapJournal',
  );

  Future<Either<Failure, List<Map<String, dynamic>>>> getPurchaseReceivings(
    String purchaseId,
  ) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.purchaseReceivings),
          variables: {
            'purchaseId': purchaseId,
            'pagination': {'page': 0, 'limit': 100},
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final root = result.data?['GetAllInventoryReceivings'] as Map?;
      return Right(
        (root?['items'] as List? ?? const [])
            .map((value) => Map<String, dynamic>.from(value as Map))
            .toList(),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, PosInventoryDocumentPage>>
  getGlobalPurchaseReceivings({
    String search = '',
    String status = '',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.globalPurchaseReceivings),
          variables: {
            'filter': {
              if (search.trim().isNotEmpty) 'search': search.trim(),
              if (status.isNotEmpty) 'status': status,
            },
            'pagination': {'page': page > 0 ? page - 1 : 0, 'limit': limit},
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final root = result.data?['GetAllInventoryReceivingsGlobal'] as Map?;
      return Right(
        PosInventoryDocumentPage(
          (root?['items'] as List? ?? const [])
              .map((value) => Map<String, dynamic>.from(value as Map))
              .toList(),
          (root?['totalCount'] as num?)?.toInt() ?? 0,
        ),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, dynamic>> cancelPurchaseReceiving({
    required String receivingId,
    required String reason,
  }) => _mutate(PosInventoryQueries.cancelPurchaseReceiving, {
    'input': {'receiving_id': receivingId, 'reason': reason},
  }, 'CancelInventoryReceiving');

  (String, String, bool) _actionEntry(
    PosInventoryDocumentType type,
    String action,
  ) => switch ((type, action)) {
    (PosInventoryDocumentType.purchase, 'submit') => (
      PosInventoryQueries.submitPurchase,
      'SubmitInventoryPurchase',
      false,
    ),
    (PosInventoryDocumentType.purchase, 'approve') => (
      PosInventoryQueries.approvePurchase,
      'ApproveInventoryPurchase',
      false,
    ),
    (PosInventoryDocumentType.purchase, 'reject') => (
      PosInventoryQueries.rejectPurchase,
      'RejectInventoryPurchase',
      true,
    ),
    (PosInventoryDocumentType.purchase, 'delete') => (
      PosInventoryQueries.deletePurchase,
      'DeleteInventoryPurchase',
      true,
    ),
    (PosInventoryDocumentType.opname, 'submit') => (
      PosInventoryQueries.submitOpname,
      'SubmitInventoryOpname',
      false,
    ),
    (PosInventoryDocumentType.opname, 'approve') => (
      PosInventoryQueries.approveOpname,
      'ApproveInventoryOpname',
      false,
    ),
    (PosInventoryDocumentType.opname, 'reject') => (
      PosInventoryQueries.rejectOpname,
      'RejectInventoryOpname',
      true,
    ),
    (PosInventoryDocumentType.opname, 'post') => (
      PosInventoryQueries.postOpname,
      'PostInventoryOpname',
      false,
    ),
    (PosInventoryDocumentType.opname, 'cancel') => (
      PosInventoryQueries.cancelOpname,
      'CancelInventoryOpname',
      true,
    ),
    (PosInventoryDocumentType.opname, 'delete') => (
      PosInventoryQueries.deleteOpname,
      'DeleteInventoryOpname',
      false,
    ),
    (PosInventoryDocumentType.transfer, 'submit') => (
      PosInventoryQueries.submitTransfer,
      'SubmitInventoryTransfer',
      false,
    ),
    (PosInventoryDocumentType.transfer, 'approve') => (
      PosInventoryQueries.approveTransfer,
      'ApproveInventoryTransfer',
      false,
    ),
    (PosInventoryDocumentType.transfer, 'reject') => (
      PosInventoryQueries.rejectTransfer,
      'RejectInventoryTransfer',
      true,
    ),
    (PosInventoryDocumentType.transfer, 'post') => (
      PosInventoryQueries.postTransfer,
      'PostInventoryTransfer',
      false,
    ),
    (PosInventoryDocumentType.transfer, 'receive') => (
      PosInventoryQueries.receiveTransfer,
      'ReceiveInventoryTransfer',
      false,
    ),
    (PosInventoryDocumentType.transfer, 'cancel') => (
      PosInventoryQueries.cancelTransfer,
      'CancelInventoryTransfer',
      true,
    ),
    (PosInventoryDocumentType.transfer, 'retry_journal') => (
      PosInventoryQueries.retryTransferJournal,
      'RetryInventoryTransferJournal',
      false,
    ),
    (PosInventoryDocumentType.transfer, 'retry_cancel_journal') => (
      PosInventoryQueries.retryTransferCancelJournal,
      'RetryInventoryTransferCancelJournal',
      false,
    ),
    (PosInventoryDocumentType.transfer, 'delete') => (
      PosInventoryQueries.deleteTransfer,
      'DeleteInventoryTransfer',
      false,
    ),
    (PosInventoryDocumentType.scrap, 'approve') => (
      PosInventoryQueries.approveScrap,
      'ApproveInventoryScrap',
      false,
    ),
    (PosInventoryDocumentType.scrap, 'reject') => (
      PosInventoryQueries.rejectScrap,
      'RejectInventoryScrap',
      true,
    ),
    (PosInventoryDocumentType.scrap, 'process') => (
      PosInventoryQueries.processScrap,
      'ProcessInventoryScrap',
      false,
    ),
    (PosInventoryDocumentType.scrap, 'delete') => (
      PosInventoryQueries.deleteScrap,
      'DeleteInventoryScrap',
      false,
    ),
    _ => throw ArgumentError('Aksi inventori tidak didukung: $type/$action'),
  };

  Future<Either<Failure, dynamic>> _mutate(
    String document,
    Map<String, dynamic> variables,
    String key,
  ) async {
    try {
      final result = await _provider.client.mutate(
        MutationOptions(document: gql(document), variables: variables),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final data = result.data?[key];
      if (data == null) {
        return const Left(ServerFailure('Operasi inventori gagal'));
      }
      return Right(data);
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }
}
