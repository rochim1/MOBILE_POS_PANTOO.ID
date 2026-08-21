import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

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
  const PosInventoryLookups({
    required this.suppliers,
    required this.warehouses,
    required this.activeWarehouseId,
    required this.inventoryItems,
  });
}

class PosInventoryRepository {
  final GraphQLClientProvider _provider;
  PosInventoryRepository(this._provider);

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
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final filter = <String, dynamic>{
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (status.isNotEmpty) 'status': status,
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
  ) async {
    try {
      final result = await _provider.client.mutate(
        MutationOptions(
          document: gql(PosInventoryQueries.receiveTransfer),
          variables: {'id': id},
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

  Future<Either<Failure, PosInventoryLookups>> getLookups() async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(PosInventoryQueries.lookups),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final supplierRoot = result.data?['GetAllSupplier'] as Map?;
      final branchRoot = result.data?['getAllCabangs'] as Map?;
      final shift = result.data?['GetMyActiveKasirShift'] as Map?;
      final inventoryRoot = result.data?['GetAllInventarisUmum'] as Map?;
      final toko = shift?['toko'] as Map?;
      return Right(
        PosInventoryLookups(
          suppliers: (supplierRoot?['suppliers'] as List? ?? const [])
              .map((value) => Map<String, dynamic>.from(value as Map))
              .toList(),
          warehouses: (branchRoot?['cabang'] as List? ?? const [])
              .map((value) => Map<String, dynamic>.from(value as Map))
              .toList(),
          activeWarehouseId: toko?['lokasi_cabang_id']?.toString() ?? '',
          inventoryItems: (inventoryRoot?['items'] as List? ?? const [])
              .map((value) => Map<String, dynamic>.from(value as Map))
              .toList(),
        ),
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
