import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../data/datasources/local/pos_local_database.dart';
import '../../data/graphql/pos_queries.dart';
import '../error/error_handler.dart';
import 'graphql_client_provider.dart';
import '../utils/logger.dart';
import '../database/database_platform_initializer.dart';

class SyncService {
  final GraphQLClientProvider _clientProvider;
  bool _isSyncing = false;

  SyncService(this._clientProvider);

  /// Menjalankan proses sinkronisasi transaksi offline ke server.
  Future<void> syncOfflineTransactions() async {
    if (!supportsOfflineDatabase) return;
    if (_isSyncing) return;
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      appLogger.w(
        'SyncService: Tidak ada koneksi internet. Sinkronisasi dibatalkan.',
      );
      return;
    }

    _isSyncing = true;
    try {
      final db = await PosLocalDatabase.instance.database;
      final instansiId =
          _clientProvider.sharedPreferences.getString('instansi_id') ?? '';
      if (instansiId.isEmpty) return;
      // Recover rows left in-flight when the app was killed mid-sync.
      await db.update(
        'offline_transactions',
        {'status': 'pending', 'error': 'Sinkronisasi sebelumnya terputus'},
        where: 'status = ? AND instansi_id = ?',
        whereArgs: ['syncing', instansiId],
      );

      // Ambil transaksi yang masih pending
      final pendingTransactions = await db.query(
        'offline_transactions',
        where: 'status = ? AND instansi_id = ?',
        whereArgs: ['pending', instansiId],
      );

      if (pendingTransactions.isEmpty) {
        appLogger.d('SyncService: Tidak ada transaksi pending.');
        return;
      }

      appLogger.i(
        'SyncService: Ditemukan ${pendingTransactions.length} transaksi pending. Mulai sinkronisasi...',
      );

      for (var tx in pendingTransactions) {
        final id = tx['id'] as int;
        final payloadString = tx['payload'] as String;

        try {
          await db.update(
            'offline_transactions',
            {
              'status': 'syncing',
              'error': null,
              'attempts': (tx['attempts'] as int? ?? 0) + 1,
            },
            where: 'id = ? AND status = ?',
            whereArgs: [id, 'pending'],
          );
          final payload = jsonDecode(payloadString);

          final MutationOptions options = MutationOptions(
            document: gql(PosQueries.processPOSPenjualan),
            variables: {'input': payload},
          );

          final QueryResult result = await _clientProvider.client.mutate(
            options,
          );

          if (result.data != null &&
              result.data!['ProcessPOSPenjualan'] != null) {
            // Berhasil tersinkron, update status di lokal menjadi synced
            await db.update(
              'offline_transactions',
              {'status': 'synced', 'error': null},
              where: 'id = ?',
              whereArgs: [id],
            );
            appLogger.i('SyncService: Transaksi $id berhasil disinkron.');
          } else if (_isRetryableNetworkFailure(result.exception)) {
            await db.update(
              'offline_transactions',
              {'status': 'pending', 'error': result.exception.toString()},
              where: 'id = ?',
              whereArgs: [id],
            );
            appLogger.w(
              'SyncService: Koneksi gagal saat sinkron transaksi $id.',
            );
          } else {
            final failure = AppErrorHandler.handle(result.exception!);
            await db.update(
              'offline_transactions',
              {'status': 'failed_permanent', 'error': failure.message},
              where: 'id = ?',
              whereArgs: [id],
            );
            appLogger.e(
              'SyncService: Transaksi $id ditolak: ${failure.message}',
            );
          }
        } catch (e) {
          await db.update(
            'offline_transactions',
            {'status': 'pending', 'error': e.toString()},
            where: 'id = ?',
            whereArgs: [id],
          );
          appLogger.e('SyncService: Gagal memproses transaksi $id', error: e);
        }
      }
      appLogger.i('SyncService: Proses sinkronisasi selesai.');
    } catch (e) {
      appLogger.e('SyncService: Terjadi kesalahan saat sinkronisasi', error: e);
    } finally {
      _isSyncing = false;
    }
  }

  bool _isRetryableNetworkFailure(OperationException? exception) {
    final linkException = exception?.linkException;
    if (linkException == null || exception?.graphqlErrors.isNotEmpty == true) {
      return false;
    }

    // A server response means the request reached the API. Client/schema
    // errors (4xx) must not be retried forever as connectivity failures.
    if (linkException is HttpLinkServerException) {
      final statusCode = linkException.response.statusCode;
      return statusCode >= 500 || statusCode == 408 || statusCode == 429;
    }

    return true;
  }

  Future<List<Map<String, dynamic>>> getOfflineTransactions({
    String? status,
  }) async {
    final instansiId =
        _clientProvider.sharedPreferences.getString('instansi_id') ?? '';
    if (instansiId.isEmpty) return [];
    if (!supportsOfflineDatabase) return const [];
    final db = await PosLocalDatabase.instance.database;
    return db.query(
      'offline_transactions',
      where: status == null
          ? 'instansi_id = ?'
          : 'instansi_id = ? AND status = ?',
      whereArgs: status == null ? [instansiId] : [instansiId, status],
      orderBy: 'id DESC',
    );
  }

  Future<void> retryTransaction(int id) async {
    final instansiId =
        _clientProvider.sharedPreferences.getString('instansi_id') ?? '';
    if (instansiId.isEmpty) return;
    final db = await PosLocalDatabase.instance.database;
    await db.update(
      'offline_transactions',
      {'status': 'pending', 'error': null},
      where: 'id = ? AND instansi_id = ? AND status != ?',
      whereArgs: [id, instansiId, 'synced'],
    );
    await syncOfflineTransactions();
  }

  Future<int> retryAllFailed() async {
    final instansiId =
        _clientProvider.sharedPreferences.getString('instansi_id') ?? '';
    if (instansiId.isEmpty) return 0;
    final db = await PosLocalDatabase.instance.database;
    return db.update(
      'offline_transactions',
      {'status': 'pending', 'error': null},
      where: 'instansi_id = ? AND status = ?',
      whereArgs: [instansiId, 'failed_permanent'],
    );
  }
}
