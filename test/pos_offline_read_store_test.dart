import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobile_pos_pantoo/data/datasources/local/pos_offline_read_store.dart';

void main() {
  sqfliteFfiInit();

  test('scoped snapshot keeps original timestamp and isolates keys', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    await db.execute('''
CREATE TABLE read_snapshots (
  scope_key TEXT PRIMARY KEY,
  payload TEXT NOT NULL,
  cached_at TEXT NOT NULL
)
''');
    final store = PosOfflineReadStore(databaseProvider: () async => db);
    final savedAt = DateTime.utc(2026, 10, 1, 10);
    await store.save('tenant-a:user-a:7', {
      'revenue': 12000,
    }, cachedAt: savedAt);

    final snapshot = await store.read('tenant-a:user-a:7');
    expect(snapshot?.data['revenue'], 12000);
    expect(snapshot?.cachedAt, savedAt);
    expect(await store.read('tenant-a:user-b:7'), isNull);

    await store.remove('tenant-a:user-a:7');
    expect(await store.read('tenant-a:user-a:7'), isNull);
  });

  test(
    'stock cache remains pinned only for unresolved sales in its branch',
    () async {
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute(
        'CREATE TABLE stores (id TEXT PRIMARY KEY, branchId TEXT)',
      );
      await db.execute('''
CREATE TABLE offline_transactions (
  id INTEGER PRIMARY KEY,
  instansi_id TEXT,
  toko_id TEXT,
  status TEXT,
  resolution TEXT,
  client_snapshot TEXT
)
''');
      await db.insert('stores', {'id': 'store-a', 'branchId': 'branch-a'});
      await db.insert('stores', {'id': 'store-b', 'branchId': 'branch-b'});
      await db.insert('offline_transactions', {
        'instansi_id': 'tenant-a',
        'toko_id': 'store-a',
        'status': 'pending',
        'client_snapshot': '{"stock_branch_id":"branch-a"}',
      });
      final store = PosOfflineReadStore(databaseProvider: () async => db);

      expect(
        await store.hasUnresolvedTransactionsForBranch(
          tenantId: 'tenant-a',
          branchId: 'branch-a',
        ),
        isTrue,
      );
      expect(
        await store.hasUnresolvedTransactionsForBranch(
          tenantId: 'tenant-b',
          branchId: 'branch-a',
        ),
        isFalse,
      );
      expect(
        await store.hasUnresolvedTransactionsForBranch(
          tenantId: 'tenant-a',
          branchId: 'branch-b',
        ),
        isFalse,
      );
      await db.update(
        'stores',
        {'branchId': 'branch-b'},
        where: 'id = ?',
        whereArgs: ['store-a'],
      );
      expect(
        await store.hasUnresolvedTransactionsForBranch(
          tenantId: 'tenant-a',
          branchId: 'branch-a',
        ),
        isTrue,
      );
      await db.transaction((txn) async {
        expect(
          await store.hasUnresolvedTransactionsForBranch(
            tenantId: 'tenant-a',
            branchId: 'branch-a',
            executor: txn,
          ),
          isTrue,
        );
      });
      expect(
        await store.hasUnresolvedTransactionsForBranch(
          tenantId: 'tenant-a',
          branchId: 'branch-b',
        ),
        isFalse,
      );
      await db.update('offline_transactions', {'status': 'synced'});
      expect(
        await store.hasUnresolvedTransactionsForBranch(
          tenantId: 'tenant-a',
          branchId: 'branch-a',
        ),
        isFalse,
      );
      await db.update('offline_transactions', {
        'status': 'rejected',
        'resolution': null,
      });
      expect(
        await store.hasUnresolvedTransactionsForBranch(
          tenantId: 'tenant-a',
          branchId: 'branch-a',
        ),
        isTrue,
      );
      await db.update('offline_transactions', {
        'resolution': 'rejected_by_operator',
      });
      expect(
        await store.hasUnresolvedTransactionsForBranch(
          tenantId: 'tenant-a',
          branchId: 'branch-a',
        ),
        isFalse,
      );
    },
  );
}
