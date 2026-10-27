import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobile_pos_pantoo/data/datasources/local/pos_catalog_filter.dart';

void main() {
  test(
    '5,005 cached products: SQLite filters before bounded pages and escapes search',
    () async {
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      try {
        await db.execute(
          'CREATE TABLE products (id TEXT PRIMARY KEY, name TEXT, code TEXT, sku TEXT, barcode TEXT, category TEXT, product_type TEXT, promo_eligible INTEGER)',
        );
        final batch = db.batch();
        for (var i = 0; i < 5005; i++) {
          batch.insert('products', {
            'id': '$i',
            'name': 'Product ${i.toString().padLeft(5, '0')}',
            'code': 'QA-$i',
            'sku': '',
            'barcode': '',
            'category': i < 5000 ? 'Early' : 'Late',
            'product_type': 'product',
            'promo_eligible': 0,
          });
        }
        await batch.commit(noResult: true);
        Future<List<Map<String, Object?>>> page(PosCatalogFilter f, int page) =>
            db.query(
              'products',
              where: f.where,
              whereArgs: f.args,
              limit: 30,
              offset: (page - 1) * 30,
              orderBy: 'name COLLATE NOCASE, id',
            );
        final all = PosCatalogFilter('', 'Semua Kategori', {});
        expect((await page(all, 1)).length, 30);
        expect((await page(all, 167)).length, 25);
        expect((await page(PosCatalogFilter('', 'Late', {}), 1)).length, 5);
        expect(
          (await page(
            PosCatalogFilter('05004', 'Semua Kategori', {}),
            1,
          )).single['id'],
          '5004',
        );
        expect(
          await page(PosCatalogFilter('%', 'Semua Kategori', {}), 1),
          isEmpty,
        );
        final favorites = PosCatalogFilter(
          '',
          'Favorit',
          Set.from(List.generate(5005, (i) => '$i')),
        );
        expect((await page(favorites, 167)).length, 25);
      } finally {
        await db.close();
      }
    },
  );
}
