import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'form outlet mengambil warehouse dinamis dan selalu mengirim lokasi',
    () {
      final source = File(
        'lib/presentation/pages/pos/pos_outlet_page.dart',
      ).readAsStringSync();
      final repository = File(
        'lib/domain/repositories/pos_repository.dart',
      ).readAsStringSync();

      expect(source, contains('getStoreWarehouseOptions'));
      expect(source, contains("'lokasi_cabang_id': selectedWarehouseId"));
      expect(source, contains('Lokasi penjualan / warehouse'));
      expect(source, contains('SingleChildScrollView'));
      expect(source, contains('Duration(milliseconds: 400)'));
      expect(repository, contains('PosQueries.getPOSWarehouseOptions'));
    },
  );

  test('penutupan shift menolak antrean offline yang belum selesai', () {
    final source = File(
      'lib/domain/repositories/pos_repository.dart',
    ).readAsStringSync();
    expect(source, contains("status IN ('pending','syncing','needs_review')"));
    expect(source, contains('masih ada transaksi offline'));
  });
}
