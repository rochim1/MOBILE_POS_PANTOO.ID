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

  test('struk final memuat shift dan referensi transaksi idempoten', () {
    final renderer = File(
      'lib/core/receipt/pos_receipt_document_builder.dart',
    ).readAsStringSync();
    final query = File('lib/data/graphql/pos_queries.dart').readAsStringSync();

    expect(renderer, contains("pw.Text('Shift: \${data.shiftReference}')"));
    expect(
      renderer,
      contains("pw.Text('Referensi: \${data.transactionReference}')"),
    );
    expect(renderer, contains("add('Shift: \${data.shiftReference}')"));
    expect(
      renderer,
      contains("add('Referensi: \${data.transactionReference}')"),
    );
    expect(query, contains('client_transaction_id'));
    expect(query, contains('kasir_shift_id'));
    expect(query, contains('kasir_name'));
  });

  test('penjualan tempo memakai aksi invoice kredit yang eksplisit', () {
    final repository = File(
      'lib/domain/repositories/pos_repository.dart',
    ).readAsStringSync();
    final query = File('lib/data/graphql/pos_queries.dart').readAsStringSync();

    expect(query, contains('mutation IssuePOSCreditInvoice'));
    expect(repository, contains("paymentMethod == 'tempo'"));
    expect(repository, contains('PosQueries.issuePOSCreditInvoice'));
    expect(repository, contains("'IssuePOSCreditInvoice'"));
  });
}
