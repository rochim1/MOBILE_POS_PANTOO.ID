import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'mobile PO separates commercial terms from supplier invoice accounting',
    () {
      final editor = File(
        'lib/presentation/pages/pos/pos_inventory_editor_page.dart',
      ).readAsStringSync();
      final receiving = File(
        'lib/presentation/pages/pos/pos_purchase_receiving_page.dart',
      ).readAsStringSync();
      final queries = File(
        'lib/data/graphql/pos_inventory_queries.dart',
      ).readAsStringSync();

      expect(editor, contains("'payment_method': _paymentMethod"));
      expect(editor, contains("'on_receipt'"));
      expect(
        editor,
        contains('tidak membentuk hutang atau mencatat pembayaran'),
      );
      expect(editor, isNot(contains('Dicatat sebagai hutang.')));
      expect(receiving, contains('Receiving posts stock and GRNI only'));
      expect(
        receiving,
        isNot(contains('Anda dapat melihat sisa hutang PO ini')),
      );
      expect(queries, contains('payment_method'));
    },
  );

  test('mobile purchasing only requests and reads supplier advances', () {
    final page = File(
      'lib/presentation/pages/pos/pos_purchase_advance_page.dart',
    ).readAsStringSync();
    final queries = File(
      'lib/data/graphql/pos_inventory_queries.dart',
    ).readAsStringSync();

    expect(queries, contains('GetPurchaseAdvanceRequests'));
    expect(queries, contains('RequestPurchaseAdvance(input: \$input)'));
    expect(queries, isNot(contains('PayPurchaseAdvance(')));
    expect(page, contains('Status pembayaran hanya dicatat oleh Finance'));
    expect(page, isNot(contains('Bayar DP')));
  });

  test('mobile supplier payable cannot enable payment mutation from PO routes', () {
    final page = File(
      'lib/presentation/pages/pos/pos_purchase_payable_page.dart',
    ).readAsStringSync();
    final workspace = File(
      'lib/presentation/pages/pos/pos_purchase_workspace.dart',
    ).readAsStringSync();
    final runtimeQuery = File(
      'lib/data/graphql/pos_queries.dart',
    ).readAsStringSync();

    expect(page, contains('final bool canRecordPayment = false;'));
    expect(page, isNot(contains('this.canRecordPayment')));
    expect(workspace, isNot(contains('canRecordPayment:')));
    expect(runtimeQuery, isNot(contains('record_payable_payment')));
  });

  test('direct purchase draft keeps idempotency and receipt sync metadata', () {
    final page = File(
      'lib/presentation/pages/pos/pos_direct_purchase_page.dart',
    ).readAsStringSync();
    final repository = File(
      'lib/domain/repositories/pos_inventory_repository.dart',
    ).readAsStringSync();

    expect(page, contains("'requestId': _requestId"));
    expect(page, contains("'syncStatus': _syncStatus"));
    expect(page, contains("'receipt_hash': _receiptHash"));
    expect(page, contains("_syncStatus = 'retry_required'"));
    expect(repository, contains("folderName: 'direct-purchase-receipts'"));
  });
}
