import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_purchase_order_document.dart';

void main() {
  final company = <String, String>{
    'nama_instansi': 'Toko Pantoo',
    'alamat': 'Jalan Merdeka 1',
  };

  Map<String, dynamic> purchase(String status, {int itemCount = 1}) => {
    'no_po': 'PO-001',
    'supplier_name': 'Supplier Utama',
    'tanggal_po': '2026-10-10',
    'status': status,
    'total_amount': 15000 * itemCount,
    'grand_total': 15000 * itemCount,
    'items': List.generate(
      itemCount,
      (index) => {
        'kode_inventaris': 'SKU-$index',
        'nama_inventaris': 'Barang $index',
        'qty_ordered': 2,
        'unit': 'pcs',
        'harga_beli': 7500,
        'subtotal': 15000,
      },
    ),
  };

  test('only approved and subsequent purchase states permit official PO', () {
    expect(PosPurchaseOrderDocument.isApproved(purchase('draft')), isFalse);
    expect(PosPurchaseOrderDocument.isApproved(purchase('pending')), isFalse);
    expect(PosPurchaseOrderDocument.isApproved(purchase('rejected')), isFalse);
    expect(PosPurchaseOrderDocument.isApproved(purchase('approved')), isTrue);
    expect(
      PosPurchaseOrderDocument.isApproved(purchase('partially_received')),
      isTrue,
    );
    expect(PosPurchaseOrderDocument.isApproved(purchase('completed')), isTrue);
  });

  test('builds draft and long approved PO as A4 PDF', () async {
    for (final order in [
      purchase('draft'),
      purchase('approved', itemCount: 60),
    ]) {
      final bytes = await PosPurchaseOrderDocument.build(
        purchase: order,
        company: company,
      );
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    }
  });
}
