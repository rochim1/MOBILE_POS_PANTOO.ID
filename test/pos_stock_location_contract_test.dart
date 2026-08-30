import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/data/graphql/pos_stock_queries.dart';

void main() {
  test('query lokasi stok hanya mengambil warehouse aktif', () {
    expect(PosStockQueries.getStockLocations, contains('getAllCabangs'));
    expect(PosStockQueries.getStockLocations, contains('has_warehouse: true'));
    expect(PosStockQueries.getStockLocations, contains('status: "active"'));
  });

  test('halaman stok menyediakan filter lokasi dan detail item', () {
    final source = File(
      'lib/presentation/pages/pos/pos_stock_page.dart',
    ).readAsStringSync();

    expect(source, contains("labelText: 'Warehouse / Lokasi'"));
    expect(source, contains('_showStockDetail(stock)'));
    expect(source, contains("tooltip: 'Lihat detail'"));
    expect(source, contains('locationId: value'));
  });
}
