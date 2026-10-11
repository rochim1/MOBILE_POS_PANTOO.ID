import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_purchase_thermal_document.dart';

void main() {
  test('thermal PO includes complete commercial details', () {
    final text = PosPurchaseThermalDocument.purchaseOrder(
      purchase: {
        'no_po': 'PO-123',
        'supplier_name': 'Supplier A',
        'tanggal_po': '2026-10-11',
        'status': 'approved',
        'items': [
          {
            'nama_inventaris': 'Beras',
            'kode_inventaris': 'BR-1',
            'qty_ordered': 2,
            'unit': 'kg',
            'harga_beli': 10000,
            'subtotal': 20000,
            'catatan_item': 'Kemasan utuh',
          },
        ],
        'total_amount': 20000,
        'grand_total': 22000,
        'biaya_pengiriman': 2000,
        'catatan': 'Kirim pagi',
      },
      company: const {'nama_instansi': 'Toko Pantoo'},
      charactersPerLine: 32,
    );
    expect(text, contains('PURCHASE ORDER'));
    expect(text, contains('PO-123'));
    expect(text, contains('Supplier A'));
    expect(text, contains('Kemasan utuh'));
    expect(text, contains('GRAND TOTAL'));
    expect(text, contains('Kirim pagi'));
  });

  test(
    'thermal proof identifies payment without pretending to be supplier receipt',
    () {
      final text = PosPurchaseThermalDocument.paymentProof(
        payable: {
          'no_po': 'PO-123',
          'supplier_name': 'Supplier A',
          'outstanding_amount': 5000,
        },
        payment: {
          'payment_date': '2026-10-11',
          'payment_method': 'transfer',
          'amount': 15000,
        },
        company: const {'nama_resmi': 'Pantoo Retail'},
        charactersPerLine: 48,
      );
      expect(text, contains('Pantoo Retail'));
      expect(text, contains('DIBAYAR'));
      expect(text, contains('bukan kuitansi supplier'));
    },
  );
}
