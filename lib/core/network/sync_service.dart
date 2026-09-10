import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../data/datasources/local/pos_local_database.dart';
import '../../data/graphql/pos_queries.dart';
import '../error/error_handler.dart';
import 'graphql_client_provider.dart';
import '../utils/logger.dart';
import '../database/database_platform_initializer.dart';

String classifyOfflineGraphQLErrors(List<GraphQLError> errors) {
  for (final error in errors) {
    final code = error.extensions?['code']?.toString().toUpperCase();
    final message = error.message.toLowerCase();
    if (code == 'CONFLICT' ||
        message.contains('harga') ||
        message.contains('promo') ||
        message.contains('stok') ||
        message.contains('shift') ||
        message.contains('kadaluarsa') ||
        message.contains('sudah ditutup')) {
      return 'needs_review';
    }
  }
  return 'rejected';
}

class SyncService {
  final GraphQLClientProvider _clientProvider;
  bool _isSyncing = false;

  SyncService(this._clientProvider);

  Future<Map<String, dynamic>> getQueueSummary() async {
    if (!supportsOfflineDatabase) {
      return const {
        'pending': 0,
        'needs_review': 0,
        'rejected': 0,
        'synced': 0,
        'unresolved': 0,
        'oldest_pending_at': null,
      };
    }
    final instansiId =
        _clientProvider.sharedPreferences.getString('instansi_id') ?? '';
    if (instansiId.isEmpty) return const {};
    final db = await PosLocalDatabase.instance.database;
    final grouped = await db.rawQuery(
      'SELECT status, COUNT(*) AS total FROM offline_transactions '
      'WHERE instansi_id = ? GROUP BY status',
      [instansiId],
    );
    final counts = <String, int>{};
    for (final row in grouped) {
      counts[row['status']?.toString() ?? 'pending'] =
          (row['total'] as num?)?.toInt() ?? 0;
    }
    final oldest = await db.query(
      'offline_transactions',
      columns: const ['timestamp'],
      where:
          "instansi_id = ? AND status IN ('pending','syncing','needs_review')",
      whereArgs: [instansiId],
      orderBy: 'timestamp ASC',
      limit: 1,
    );
    return {
      ...counts,
      'unresolved':
          (counts['pending'] ?? 0) +
          (counts['syncing'] ?? 0) +
          (counts['needs_review'] ?? 0),
      'oldest_pending_at': oldest.isEmpty ? null : oldest.first['timestamp'],
    };
  }

  /// Menjalankan proses sinkronisasi transaksi offline ke server.
  Future<void> syncOfflineTransactions({bool force = false}) async {
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
      // Receipt resmi sudah berada di server. Pertahankan histori sinkron lokal
      // selama 90 hari untuk audit perangkat, lalu bersihkan agar SQLite tidak
      // tumbuh tanpa batas pada terminal yang jarang logout.
      await db.delete(
        'offline_transactions',
        where: 'instansi_id = ? AND status = ? AND timestamp < ?',
        whereArgs: [
          instansiId,
          'synced',
          DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
        ],
      );
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
        where: force
            ? 'status = ? AND instansi_id = ?'
            : 'status = ? AND instansi_id = ? AND '
                  '(next_retry_at IS NULL OR next_retry_at <= ?)',
        whereArgs: force
            ? ['pending', instansiId]
            : ['pending', instansiId, DateTime.now().toIso8601String()],
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
            final serverTransaction = Map<String, dynamic>.from(
              result.data!['ProcessPOSPenjualan'] as Map,
            );
            // Berhasil tersinkron, update status di lokal menjadi synced
            await db.update(
              'offline_transactions',
              {
                'status': 'synced',
                'error': null,
                'server_response': jsonEncode({
                  'id': serverTransaction['_id']?.toString(),
                  'invoice': serverTransaction['invoice']?.toString(),
                }),
                'resolution': 'accepted_by_server',
                'resolved_at': DateTime.now().toIso8601String(),
                'next_retry_at': null,
              },
              where: 'id = ?',
              whereArgs: [id],
            );
            appLogger.i('SyncService: Transaksi $id berhasil disinkron.');
          } else if (_isRetryableNetworkFailure(result.exception)) {
            final attempts = (tx['attempts'] as int? ?? 0) + 1;
            await db.update(
              'offline_transactions',
              {
                'status': 'pending',
                'error': result.exception.toString(),
                'server_response': null,
                'next_retry_at': _nextRetryAt(attempts).toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [id],
            );
            appLogger.w(
              'SyncService: Koneksi gagal saat sinkron transaksi $id.',
            );
          } else {
            final exception = result.exception;
            if (exception == null) {
              await db.update(
                'offline_transactions',
                {
                  'status': 'needs_review',
                  'error': 'Server tidak mengembalikan hasil transaksi',
                  'server_response': jsonEncode(result.data),
                },
                where: 'id = ?',
                whereArgs: [id],
              );
              continue;
            }
            final failure = AppErrorHandler.handle(exception);
            final status = classifyOfflineGraphQLErrors(
              _allGraphQLErrors(exception),
            );
            await db.update(
              'offline_transactions',
              {
                'status': status,
                'error': failure.message,
                'server_response': _encodeServerErrors(exception),
              },
              where: 'id = ?',
              whereArgs: [id],
            );
            appLogger.e(
              'SyncService: Transaksi $id berstatus $status: ${failure.message}',
            );
          }
        } catch (e) {
          final attempts = (tx['attempts'] as int? ?? 0) + 1;
          await db.update(
            'offline_transactions',
            {
              'status': 'pending',
              'error': e.toString(),
              'next_retry_at': _nextRetryAt(attempts).toIso8601String(),
            },
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

  DateTime _nextRetryAt(int attempts) {
    // 15 dtk, 30 dtk, 1 mnt ... maksimal 30 menit. Retry manual tetap langsung.
    final exponent = attempts.clamp(1, 8) - 1;
    final seconds = (15 * (1 << exponent)).clamp(15, 1800);
    return DateTime.now().add(Duration(seconds: seconds));
  }

  bool _isRetryableNetworkFailure(OperationException? exception) {
    final linkException = exception?.linkException;
    if (linkException == null || _allGraphQLErrors(exception).isNotEmpty) {
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

  String _encodeServerErrors(OperationException? exception) {
    final errors = _allGraphQLErrors(exception);
    return jsonEncode(
      errors
          .map(
            (error) => {
              'message': error.message,
              'code': error.extensions?['code']?.toString(),
            },
          )
          .toList(),
    );
  }

  List<GraphQLError> _allGraphQLErrors(OperationException? exception) {
    if (exception == null) return const [];
    final errors = <GraphQLError>[...exception.graphqlErrors];
    final linkException = exception.linkException;
    if (linkException is ServerException) {
      for (final error in linkException.parsedResponse?.errors ?? const []) {
        if (!errors.any(
          (existing) =>
              existing.message == error.message &&
              existing.extensions?['code'] == error.extensions?['code'],
        )) {
          errors.add(error);
        }
      }
    }
    return errors;
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
      {
        'status': 'pending',
        'error': null,
        'server_response': null,
        'resolution': 'retry_after_review',
        'resolved_at': DateTime.now().toIso8601String(),
        'next_retry_at': null,
      },
      where:
          'id = ? AND instansi_id = ? AND status IN (?, ?, ?) AND '
          '(resolution IS NULL OR resolution != ?)',
      whereArgs: [
        id,
        instansiId,
        'pending',
        'needs_review',
        'rejected',
        'rejected_by_operator',
      ],
    );
    await syncOfflineTransactions(force: true);
  }

  Future<int> retryAllRejected() async {
    final instansiId =
        _clientProvider.sharedPreferences.getString('instansi_id') ?? '';
    if (instansiId.isEmpty) return 0;
    final db = await PosLocalDatabase.instance.database;
    return db.update(
      'offline_transactions',
      {
        'status': 'pending',
        'error': null,
        'resolution': 'bulk_retry_rejected',
        'resolved_at': DateTime.now().toIso8601String(),
        'next_retry_at': null,
      },
      where:
          'instansi_id = ? AND status = ? AND '
          '(resolution IS NULL OR resolution != ?)',
      whereArgs: [instansiId, 'rejected', 'rejected_by_operator'],
    );
  }

  Future<void> rejectTransaction(int id, {String? reason}) async {
    final instansiId =
        _clientProvider.sharedPreferences.getString('instansi_id') ?? '';
    if (instansiId.isEmpty) return;
    final db = await PosLocalDatabase.instance.database;
    await db.update(
      'offline_transactions',
      {
        'status': 'rejected',
        'resolution': reason?.trim().isNotEmpty == true
            ? reason!.trim()
            : 'rejected_by_operator',
        'resolved_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND instansi_id = ? AND status = ?',
      whereArgs: [id, instansiId, 'needs_review'],
    );
  }
}
