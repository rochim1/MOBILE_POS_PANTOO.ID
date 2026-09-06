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
    expect(source, contains("child: Text('Semua Cabang')"));
    expect(source, contains("'Rincian saldo per lokasi'"));
    expect(source, contains('belum dirinci ke gedung/ruangan/rak'));
    expect(source, contains('batch aktif'));
    expect(source, contains("'Cabang: \${branch.isEmpty ? '-' : branch}'"));
    expect(
      source,
      contains("'Gedung: \${building.isEmpty ? 'belum tercatat' : building}'"),
    );
    expect(
      source,
      contains("'Ruangan: \${room.isEmpty ? 'belum tercatat' : room}'"),
    );
    expect(source, contains("'Rak: \$rack'"));
  });

  test('koreksi langsung dibatasi sebagai darurat dan diarahkan ke opname', () {
    final stockSource = File(
      'lib/presentation/pages/pos/pos_stock_page.dart',
    ).readAsStringSync();
    final inventorySource = File(
      'lib/presentation/pages/pos/pos_inventory_page.dart',
    ).readAsStringSync();

    expect(stockSource, contains("Text('Koreksi Darurat')"));
    expect(
      PosStockQueries.getAdjustmentReasons,
      contains('GetManualStockAdjustmentReasons'),
    );
    expect(stockSource, contains('getAdjustmentReasons'));
    expect(stockSource, isNot(contains("value: 'selisih_hitung'")));
    expect(stockSource, contains("labelText: 'Referensi / tiket *'"));
    expect(stockSource, contains("labelText: 'Keterangan *'"));
    expect(stockSource, contains('Buka Stock Opname'));
    expect(stockSource, contains("labelText: 'Saldo warehouse / lokasi *'"));
    expect(stockSource, contains('getLocationBalances'));
    expect(stockSource, contains("selectedBalance['lokasi_gedung_kode']"));
    expect(
      inventorySource,
      contains('setState(() => _selected = _InventorySection.opname)'),
    );
  });
}
