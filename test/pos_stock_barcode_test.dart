import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_stock.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_stock_barcode_document.dart';

void main() {
  test('stock model preserves the inventory barcode', () {
    final stock = PosStock.fromJson(const {
      '_id': 'product-1',
      'kode_inventaris': 'INV-001',
      'nama_inventaris': 'Sabun Cair',
      'barcode': '8991234567890',
      'sku': 'SB-001',
    });
    expect(stock.barcode, '8991234567890');
    expect(stock.toJson()['barcode'], stock.barcode);
  });

  test('label PDF builds for each size and a full 50-label batch', () async {
    for (final size in ['small', 'medium', 'large']) {
      final bytes = await PosStockBarcodeDocument.build(
        name: 'Sabun Cair 450 ml',
        code: '8991234567890',
        quantity: 50,
        size: size,
      );
      expect(bytes.length, greaterThan(2000));
    }
  });

  test('label document rejects missing code and invalid quantity', () async {
    expect(
      () =>
          PosStockBarcodeDocument.build(name: 'Produk', code: '', quantity: 1),
      throwsArgumentError,
    );
    expect(
      () => PosStockBarcodeDocument.build(
        name: 'Produk',
        code: 'A1',
        quantity: 51,
      ),
      throwsArgumentError,
    );
    expect(PosStockBarcodeDocument.supportsCode('ABC-123'), isTrue);
    expect(PosStockBarcodeDocument.supportsCode('ABC\n123'), isFalse);
    expect(
      () => PosStockBarcodeDocument.build(
        name: 'Produk',
        code: 'ABC\n123',
        quantity: 1,
      ),
      throwsArgumentError,
    );
  });
}
