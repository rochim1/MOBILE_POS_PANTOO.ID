import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nota pembayaran dapat dibagikan sebagai PNG dan PDF', () {
    final source = File(
      'lib/presentation/pages/pos/pos_success_page.dart',
    ).readAsStringSync();

    expect(source, contains('Bagikan sebagai PNG'));
    expect(source, contains('Bagikan sebagai PDF'));
    expect(
      source,
      contains("mimeType = isPng ? 'image/png' : 'application/pdf'"),
    );
    expect(source, contains('SharePlus.instance.share'));
    expect(source, contains('XFile.fromData'));
  });

  test('print PDF dan share menggunakan receipt renderer yang sama', () {
    final success = File(
      'lib/presentation/pages/pos/pos_success_page.dart',
    ).readAsStringSync();
    final history = File(
      'lib/presentation/pages/pos/pos_order_page.dart',
    ).readAsStringSync();
    final renderer = File(
      'lib/core/receipt/pos_receipt_document_builder.dart',
    ).readAsStringSync();

    expect(success, contains('PosReceiptDocumentBuilder.build'));
    expect(history, contains('PosReceiptDocumentBuilder.build'));
    expect(success, contains('Printing.raster'));
    expect(renderer, contains("_totalRow('Subtotal'"));
    expect(renderer, contains("_totalRow('Diskon'"));
    expect(renderer, contains("_totalRow('Promo'"));
    expect(renderer, contains("_totalRow('Pajak'"));
  });
}
