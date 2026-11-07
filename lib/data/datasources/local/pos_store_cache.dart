import 'package:sqflite/sqflite.dart';
import '../../../domain/models/pos_store.dart';

// Forward-only additive migration. Unknown legacy mode remains unknown until
// a successful online refresh; never infer shared-register ownership.
Future<void> upgradePosStoreMetadata(DatabaseExecutor db) async {
  await db.execute(
    'ALTER TABLE stores ADD COLUMN code TEXT NOT NULL DEFAULT ""',
  );
  await db.execute(
    'ALTER TABLE stores ADD COLUMN shiftMode TEXT NOT NULL DEFAULT ""',
  );
}

class PosStoreCache {
  static Future<List<PosStore>> read(DatabaseExecutor db) async =>
      (await db.query(
        'stores',
        orderBy: 'name, id',
      )).map(PosStore.fromJson).toList();

  static Future<void> save(Database db, List<PosStore> stores) async {
    await db.transaction((txn) async {
      await txn.delete('stores');
      for (final store in stores) {
        await txn.insert('stores', store.toJson());
      }
    });
  }
}
