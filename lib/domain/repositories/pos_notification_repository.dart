import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../core/error/error_handler.dart';
import '../../core/error/failures.dart';
import '../../core/network/graphql_client_provider.dart';

class PosNotificationRepository {
  final GraphQLClientProvider _provider;
  PosNotificationRepository(this._provider);

  static const _listQuery = r'''
    query GetPOSNotifications($filter: FilterNotif, $pagination: pagination) {
      GetAllNotifikasi(filter: $filter, pagination: $pagination) {
        notifikasi {
          _id title body tipe_notif module_type is_read
          tanggal_notifikasi createdAt
          link { mobile web }
        }
        info_page
      }
      CountUnreadNotifikasi
    }
  ''';

  static const _readMutation = r'''
    mutation ReadPOSNotification($id: ID!) {
      readThisNotif(_id: $id)
    }
  ''';

  static const _readAllMutation = r'''
    mutation ReadAllPOSNotifications {
      ReadAllMyNotif
    }
  ''';

  Future<Either<Failure, PosNotificationResult>> getNotifications({
    int page = 0,
    int limit = 20,
    String? module,
  }) async {
    try {
      final result = await _provider.client.query(
        QueryOptions(
          document: gql(_listQuery),
          variables: {
            'filter': {
              'is_myNotif': true,
              if (module != null && module.isNotEmpty) 'module_type': module,
            },
            'pagination': {'page': page, 'limit': limit},
          },
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      final root = result.data?['GetAllNotifikasi'] as Map?;
      final items = (root?['notifikasi'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      return Right(
        PosNotificationResult(
          items: items,
          unreadCount: module == null || module.isEmpty
              ? (result.data?['CountUnreadNotifikasi'] as num?)?.toInt() ??
                    items.where((row) => row['is_read'] != true).length
              : items.where((row) => row['is_read'] != true).length,
          pageCount: (root?['info_page'] as num?)?.toInt() ?? 1,
        ),
      );
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, PosNotificationResult>> getOperationalNotifications({
    int limit = 50,
  }) async {
    final posResult = await getNotifications(limit: limit, module: 'POS');
    if (posResult.isLeft()) {
      return posResult;
    }
    final inventoryResult = await getNotifications(
      limit: limit,
      module: 'inventory',
    );
    if (inventoryResult.isLeft()) {
      return inventoryResult;
    }
    final pos = posResult.getOrElse(
      () =>
          const PosNotificationResult(items: [], unreadCount: 0, pageCount: 1),
    );
    final inventory = inventoryResult.getOrElse(
      () =>
          const PosNotificationResult(items: [], unreadCount: 0, pageCount: 1),
    );
    final unique = <String, Map<String, dynamic>>{};
    for (final item in [...pos.items, ...inventory.items]) {
      unique[item['_id']?.toString() ?? '${unique.length}'] = item;
    }
    final items = unique.values.toList()
      ..sort((a, b) => _notificationDate(b).compareTo(_notificationDate(a)));
    return Right(
      PosNotificationResult(
        items: items,
        unreadCount: items.where((item) => item['is_read'] != true).length,
        pageCount: pos.pageCount > inventory.pageCount
            ? pos.pageCount
            : inventory.pageCount,
      ),
    );
  }

  static DateTime _notificationDate(Map<String, dynamic> item) =>
      DateTime.tryParse(
        (item['tanggal_notifikasi'] ?? item['createdAt'])?.toString() ?? '',
      ) ??
      DateTime.fromMillisecondsSinceEpoch(0);

  Future<Either<Failure, void>> markAsRead(String id) =>
      _mutate(_readMutation, {'id': id}, 'readThisNotif');

  Future<Either<Failure, void>> markAllAsRead() =>
      _mutate(_readAllMutation, const {}, 'ReadAllMyNotif');

  Future<Either<Failure, void>> _mutate(
    String document,
    Map<String, dynamic> variables,
    String field,
  ) async {
    try {
      final result = await _provider.client.mutate(
        MutationOptions(document: gql(document), variables: variables),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      if (result.data?[field] == null) {
        return const Left(ServerFailure('Notifikasi gagal diperbarui'));
      }
      return const Right(null);
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }
}

class PosNotificationResult {
  final List<Map<String, dynamic>> items;
  final int unreadCount;
  final int pageCount;
  const PosNotificationResult({
    required this.items,
    required this.unreadCount,
    required this.pageCount,
  });
}
