import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_purchase_payment_proof_document.dart';

void main() {
  final payable = <String, dynamic>{
    'no_po': 'PO-001',
    'supplier_name': 'Supplier Utama',
    'total_amount': 150000,
    'paid_amount': 50000,
    'outstanding_amount': 100000,
  };
  final company = <String, String>{'nama_instansi': 'Toko Pantoo'};
  Map<String, dynamic> payment(String status) => {
    '_id': 'PAY-001',
    'status': status,
    'amount': 50000,
    'payment_date': '2026-10-10',
    'recorded_at': '2026-10-10T10:00:00.000Z',
    'payment_method': 'transfer',
    'bank_account_name': 'Bank Contoh 1234567890',
    'reference_number': 'REF-001',
    'recorded_by': {'name': 'Kasir Pantoo'},
    'cancellation_reason': 'Pembayaran duplikat',
  };

  test('cancelled and pending cancellation cannot be distributed', () {
    expect(
      PosPurchasePaymentProofDocument.canDistribute(payment('active')),
      isTrue,
    );
    expect(
      PosPurchasePaymentProofDocument.canDistribute(payment('cancelled')),
      isFalse,
    );
    expect(
      PosPurchasePaymentProofDocument.canDistribute(
        payment('cancellation_pending'),
      ),
      isFalse,
    );
  });

  test('bank account number is masked even when grouped with spaces', () {
    expect(
      PosPurchasePaymentProofDocument.maskBankAccount('Bank 1234 5678 9012'),
      'Bank **** **** 9012',
    );
  });

  test('builds active and cancelled payment proof PDFs', () async {
    for (final status in ['active', 'cancelled']) {
      final bytes = await PosPurchasePaymentProofDocument.build(
        payable: payable,
        payment: payment(status),
        company: company,
      );
      expect(bytes.length, greaterThan(1000));
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    }
  });
}
