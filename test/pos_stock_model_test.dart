import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_stock.dart';

void main() {
  test('metadata keamanan koreksi stok bertahan saat model disalin', () {
    final stock = PosStock.fromJson({
      '_id': 'inventory-1',
      'nama_inventaris': 'Produk Uji',
      'qty': 8,
      'stok': 8,
      'stock_balance_id': 'balance-1',
      'location_count': 1,
      'requires_batch_adjustment': false,
    });

    final updated = PosStock.fromJson({...stock.toJson(), 'stok': 5});

    expect(updated.stok, 5);
    expect(updated.stockBalanceId, 'balance-1');
    expect(updated.locationCount, 1);
    expect(updated.requiresBatchAdjustment, isFalse);
  });

  test('riwayat stok membaca pelaku dan jalur lokasi', () {
    final movement = PosStockMovement.fromJson({
      'nama_inventaris': 'Produk Uji',
      'kode_inventaris': 'SKU-1',
      'tanggal': '2026-08-13T10:00:00.000Z',
      'jenis': 'penyesuaian',
      'jumlah': 2,
      'saldo_lokasi_sebelum': 3,
      'saldo_lokasi_sesudah': 5,
      'lokasi_gedung_kode': 'G1',
      'lokasi_ruangan_kode': 'R1',
      'lokasi_rak_nama': 'Rak A',
      'user_id': {'name': 'Kasir Uji'},
    });

    expect(movement.cashierName, 'Kasir Uji');
    expect(movement.location, 'G1 / R1 / Rak A');
    expect(movement.balanceAfter, 5);
  });
}
