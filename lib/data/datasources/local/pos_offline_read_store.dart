import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'pos_local_database.dart';

/// Native-only snapshots. On Android/iOS the underlying SQLite DB is encrypted.
class PosOfflineReadStore {
  const PosOfflineReadStore({Future<Database> Function()? databaseProvider})
    : _databaseProvider = databaseProvider;

  final Future<Database> Function()? _databaseProvider;

  Future<Database> get _database =>
      _databaseProvider?.call() ?? PosLocalDatabase.instance.database;

  Future<void> save(
    String key,
    Map<String, dynamic> payload, {
    DateTime? cachedAt,
  }) async {
    final db = await _database;
    await db.insert('read_snapshots', {
      'scope_key': key,
      'payload': jsonEncode(payload),
      'cached_at': (cachedAt ?? DateTime.now()).toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<({Map<String, dynamic> data, DateTime cachedAt})?> read(
    String key,
  ) async {
    final db = await _database;
    final rows = await db.query(
      'read_snapshots',
      where: 'scope_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      final data = jsonDecode(rows.first['payload'] as String);
      final cachedAt = DateTime.tryParse(
        rows.first['cached_at']?.toString() ?? '',
      );
      if (data is! Map || cachedAt == null) return null;
      return (
        data: Map<String, dynamic>.from(data),
        cachedAt: cachedAt.toUtc(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) async {
    final db = await _database;
    await db.delete('read_snapshots', where: 'scope_key = ?', whereArgs: [key]);
  }

  /// Do not replace locally decremented stock with a server catalog while
  /// sales for this stock location may still be awaiting reconciliation.
  Future<bool> hasUnresolvedTransactionsForBranch({
    required String tenantId,
    required String branchId,
    DatabaseExecutor? executor,
  }) async {
    if (tenantId.isEmpty || branchId.isEmpty) return false;
    final db = executor ?? await _database;
    final rows = await db.rawQuery(
      '''
SELECT t.client_snapshot, s.branchId FROM offline_transactions AS t
LEFT JOIN stores AS s ON s.id = t.toko_id
WHERE t.instansi_id = ?
  AND (t.status IS NULL OR t.status NOT IN ('synced', 'rejected')
       OR (t.status = 'rejected'
           AND (t.resolution IS NULL OR t.resolution != 'rejected_by_operator')))
''',
      [tenantId],
    );
    for (final row in rows) {
      var originalBranch = '';
      try {
        final snapshot = jsonDecode(row['client_snapshot']?.toString() ?? '');
        if (snapshot is Map) {
          originalBranch = snapshot['stock_branch_id']?.toString() ?? '';
        }
      } catch (_) {
        // Legacy queue records can use the current store-to-branch mapping.
      }
      if ((originalBranch.isNotEmpty
              ? originalBranch
              : row['branchId']?.toString()) ==
          branchId) {
        return true;
      }
    }
    return false;
  }
}
