import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobile_pos_pantoo/data/datasources/local/pos_store_cache.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';

void main() {
  test(
    'legacy cache upgrade preserves pending rows and per-operator/shared store identity after reload',
    () async {
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute(
        'CREATE TABLE stores(id TEXT PRIMARY KEY, name TEXT NOT NULL, status TEXT NOT NULL, address TEXT NOT NULL, phone TEXT NOT NULL, branchName TEXT NOT NULL, branchId TEXT NOT NULL)',
      );
      await db.execute(
        'CREATE TABLE offline_transactions(id INTEGER PRIMARY KEY, payload TEXT)',
      );
      await db.insert('offline_transactions', {
        'id': 1,
        'payload': 'immutable-pending',
      });
      await db.insert('stores', {
        'id': 'old',
        'name': 'Old',
        'status': 'active',
        'address': '',
        'phone': '',
        'branchName': '',
        'branchId': 'w',
      });
      await upgradePosStoreMetadata(db);
      expect(
        (await PosStoreCache.read(db)).single.shiftMode,
        '',
      ); // unknown is not guessed as shared
      await PosStoreCache.save(db, const [
        PosStore(
          id: 'a',
          name: 'A',
          status: 'active',
          code: 'A1',
          branchId: 'w',
          shiftMode: 'per_operator',
        ),
        PosStore(
          id: 'b',
          name: 'B',
          status: 'active',
          code: 'B1',
          branchId: 'x',
          shiftMode: 'shared_register',
        ),
      ]);
      final restored = await PosStoreCache.read(db);
      expect(restored.map((s) => s.shiftMode), [
        'per_operator',
        'shared_register',
      ]);
      expect(restored.map((s) => s.code), ['A1', 'B1']);
      expect(
        (await db.query('offline_transactions')).single['payload'],
        'immutable-pending',
      );
    },
  );
}
