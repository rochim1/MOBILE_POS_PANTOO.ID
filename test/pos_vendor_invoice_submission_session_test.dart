import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_vendor_invoice_submission_session.dart';

void main() {
  test(
    'retry keys stay stable for the same content but change for edited invoice data',
    () {
      final session = PosVendorInvoiceSubmissionSession('purchase-1');
      String key({
        String hash = 'hash',
        String number = 'INV-1',
        String date = '2026-10-27',
        String note = 'Bukti asli',
      }) => session.requestId(
        fileHash: hash,
        invoiceNumber: number,
        invoiceDate: date,
        note: note,
      );
      final first = key();
      expect(key(), first);
      expect(key(number: ' inv-1 '), first);
      expect(key(hash: 'new-file'), isNot(first));
      expect(key(number: 'INV-2'), isNot(first));
      expect(key(note: 'Bukti koreksi'), isNot(first));
      expect(key(), first);
    },
  );
  test('upload reference is reused without retaining image bytes', () {
    final session = PosVendorInvoiceSubmissionSession('purchase-1');
    expect(session.uploadedUrl('hash'), isNull);
    session.rememberUpload('hash', '/static/qa/invoice.png');
    expect(session.uploadedUrl('hash'), '/static/qa/invoice.png');
    expect(
      PosVendorInvoiceSubmissionSession('purchase-2').uploadedUrl('hash'),
      isNull,
    );
  });
  test('calendar validation rejects normalized invalid days before upload', () {
    expect(
      PosVendorInvoiceSubmissionSession.validInvoiceDate('2026-02-30'),
      isFalse,
    );
    expect(
      PosVendorInvoiceSubmissionSession.validInvoiceDate('2026-2-01'),
      isFalse,
    );
    expect(
      PosVendorInvoiceSubmissionSession.validInvoiceDate('2024-02-29'),
      isTrue,
    );
    expect(PosVendorInvoiceSubmissionSession.validInvoiceDate(''), isTrue);
  });
}
