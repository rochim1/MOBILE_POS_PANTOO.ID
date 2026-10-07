import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../data/datasources/local/pos_local_database.dart';
import '../../data/graphql/pos_queries.dart';
import '../error/error_handler.dart';
import 'graphql_client_provider.dart';
import 'offline_network_failure.dart';
import 'pos_operator_identity.dart';
import '../utils/logger.dart';
import '../database/database_platform_initializer.dart';

String classifyOfflineGraphQLErrors(List<GraphQLError> errors) {
  for (final error in errors) {
    final code = error.extensions?['code']?.toString().toUpperCase();
    final message = error.message.toLowerCase();
    if (code == 'UNAUTHORIZED' ||
        code == 'UNAUTHENTICATED' ||
        code == 'CONFLICT' ||
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

bool offlineSaleNeedsReview({
  required String serverStatus,
  num? expectedTotal,
  num? actualTotal,
}) =>
    serverStatus != 'synced' ||
    (expectedTotal != null &&
        actualTotal != null &&
        (expectedTotal - actualTotal).abs() > 0.01);

class SyncService {
  final GraphQLClientProvider _clientProvider;
  bool _isSyncing = false;
  String _operatorToken = '';

  void setOperatorSessionToken(String token) => _operatorToken = token.trim();

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
    final unresolvedRejected = await db.rawQuery(
      "SELECT COUNT(*) AS total FROM offline_transactions WHERE instansi_id = ? AND status = 'rejected' AND (resolution IS NULL OR resolution != 'rejected_by_operator')",
      [instansiId],
    );
    counts['rejected_unresolved'] =
        (unresolvedRejected.first['total'] as num?)?.toInt() ?? 0;
    final oldest = await db.query(
      'offline_transactions',
      columns: const ['timestamp'],
      where:
          "instansi_id = ? AND (status IN ('pending','syncing','needs_review') OR (status = 'rejected' AND (resolution IS NULL OR resolution != 'rejected_by_operator')))",
      whereArgs: [instansiId],
      orderBy: 'timestamp ASC',
      limit: 1,
    );
    return {
      ...counts,
      'unresolved':
          (counts['pending'] ?? 0) +
          (counts['syncing'] ?? 0) +
          (counts['needs_review'] ?? 0) +
          (counts['rejected_unresolved'] ?? 0),
      'oldest_pending_at': oldest.isEmpty ? null : oldest.first['timestamp'],
    };
  }

  /// Menjalankan proses sinkronisasi transaksi offline ke server.
  Future<void> syncOfflineTransactions({bool force = false}) async {
    if (!supportsOfflineDatabase) return;
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        appLogger.w(
          'SyncService: Tidak ada koneksi internet. Sinkronisasi dibatalkan.',
        );
        return;
      }

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
        orderBy: 'timestamp ASC, id ASC',
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
        final operationKind = tx['operation_kind']?.toString() ?? 'sale';

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
          final payload = Map<String, dynamic>.from(
            jsonDecode(payloadString) as Map,
          );
          final originalShiftId = tx['shift_id']?.toString() ?? '';
          if ((payload['shift_id']?.toString() ?? '').isEmpty &&
              originalShiftId.isNotEmpty) {
            payload['shift_id'] = originalShiftId;
          }
          final savedToken =
              payload['operator_session_token']?.toString() ?? '';
          final snapshot = tx['client_snapshot'] == null
              ? <String, dynamic>{}
              : Map<String, dynamic>.from(
                  jsonDecode(tx['client_snapshot'] as String) as Map,
                );
          final operatorId =
              snapshot['operator_user_id']?.toString() ??
              operatorIdFromToken(savedToken);
          payload.remove('operator_session_token');
          if (savedToken.isNotEmpty) {
            await db.update(
              'offline_transactions',
              {
                'payload': jsonEncode(payload),
                'client_snapshot': jsonEncode({
                  ...snapshot,
                  if (operatorId.isNotEmpty) 'operator_user_id': operatorId,
                }),
              },
              where: 'id = ?',
              whereArgs: [id],
            );
          }
          if (operatorId.isNotEmpty) {
            final renewed = operatorTokenForSync(
              'offline_operator:$operatorId',
              _operatorToken,
            );
            if (renewed != null) {
              payload['operator_session_token'] = renewed;
            } else {
              await db.update(
                'offline_transactions',
                {
                  'status': 'needs_review',
                  'error':
                      'Verifikasi PIN kasir asal saat online, lalu kirim ulang. Transaksi tetap tersimpan.',
                  'resolution': 'operator_reauthentication_required',
                },
                where: 'id = ?',
                whereArgs: [id],
              );
              continue;
            }
          }

          if (operationKind != 'sale' && operationKind != 'create_order') {
            await db.update(
              'offline_transactions',
              {
                'status': 'needs_review',
                'error': 'Jenis operasi antrean tidak dikenal: $operationKind',
              },
              where: 'id = ?',
              whereArgs: [id],
            );
            continue;
          }
          final isOrder = operationKind == 'create_order';

          final MutationOptions options = MutationOptions(
            document: gql(
              isOrder
                  ? PosQueries.createPOSInvoice
                  : PosQueries.processPOSPenjualan,
            ),
            variables: {'input': payload},
          );

          final QueryResult result = await _clientProvider.client.mutate(
            options,
          );

          final resultKey = isOrder ? 'CreatePOSOrder' : 'ProcessPOSPenjualan';
          if (result.data != null && result.data![resultKey] != null) {
            final serverTransaction = Map<String, dynamic>.from(
              result.data![resultKey] as Map,
            );
            // Berhasil tersinkron, update status di lokal menjadi synced
            final String serverSyncStatus = isOrder
                ? 'synced'
                : serverTransaction['sync_status']?.toString() ?? '';
            final String serverSyncConflictReason =
                serverTransaction['sync_conflict_reason']?.toString() ?? '';
            final expectedTotal = (snapshot['total'] as num?)?.toDouble();
            final actualTotal =
                (serverTransaction[isOrder ? 'grand_total' : 'total'] as num?)
                    ?.toDouble();
            final totalChanged =
                expectedTotal != null &&
                actualTotal != null &&
                (expectedTotal - actualTotal).abs() > 0.01;
            final requiresReview = isOrder
                ? totalChanged
                : offlineSaleNeedsReview(
                    serverStatus: serverSyncStatus,
                    expectedTotal: expectedTotal,
                    actualTotal: actualTotal,
                  );
            await db.update(
              'offline_transactions',
              {
                'status': requiresReview ? 'needs_review' : 'synced',
                'error': requiresReview
                    ? (totalChanged
                          ? isOrder
                                ? 'Total pesanan server berbeda dari estimasi perangkat. Periksa pesanan sebelum menerima pembayaran.'
                                : 'Total server berbeda dari uang yang dicatat offline. Cocokkan invoice dan kas fisik.'
                          : serverSyncConflictReason.isNotEmpty
                          ? serverSyncConflictReason
                          : 'Status sinkronisasi server perlu diperiksa')
                    : null,
                'server_response': jsonEncode({
                  'id': serverTransaction['_id']?.toString(),
                  'invoice': serverTransaction[isOrder ? 'order_no' : 'invoice']
                      ?.toString(),
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
    return isRetryableOfflineNetworkFailure(exception);
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
          '(resolution IS NULL OR resolution NOT IN (?, ?))',
      whereArgs: [
        id,
        instansiId,
        'pending',
        'needs_review',
        'rejected',
        'rejected_by_operator',
        'accepted_by_server',
      ],
    );
    await syncOfflineTransactions(force: true);
  }

  Future<void> acknowledgeAcceptedTransaction(int id) async {
    final instansiId =
        _clientProvider.sharedPreferences.getString('instansi_id') ?? '';
    if (instansiId.isEmpty || !supportsOfflineDatabase) return;
    final db = await PosLocalDatabase.instance.database;
    await db.update(
      'offline_transactions',
      {
        'status': 'synced',
        'resolution': 'reviewed_after_server_acceptance',
        'resolved_at': DateTime.now().toIso8601String(),
        'next_retry_at': null,
      },
      where:
          'id = ? AND instansi_id = ? AND status = ? AND resolution = ? AND server_response IS NOT NULL',
      whereArgs: [id, instansiId, 'needs_review', 'accepted_by_server'],
    );
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
      where:
          'id = ? AND instansi_id = ? AND status = ? AND (resolution IS NULL OR resolution != ?)',
      whereArgs: [id, instansiId, 'needs_review', 'accepted_by_server'],
    );
  }

  Future<void> resolveRejectedTransaction(int id) async {
    final instansiId =
        _clientProvider.sharedPreferences.getString('instansi_id') ?? '';
    if (instansiId.isEmpty || !supportsOfflineDatabase) return;
    final db = await PosLocalDatabase.instance.database;
    await db.update(
      'offline_transactions',
      {
        'resolution': 'rejected_by_operator',
        'resolved_at': DateTime.now().toIso8601String(),
      },
      where:
          'id = ? AND instansi_id = ? AND status = ? AND (resolution IS NULL OR resolution != ?)',
      whereArgs: [id, instansiId, 'rejected', 'accepted_by_server'],
    );
  }
}
