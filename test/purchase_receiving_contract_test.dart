import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String readProjectFile(String path) => File(path).readAsStringSync();

void main() {
  test('penerimaan parsial membawa metadata dan riwayat dari backend', () {
    final query = readProjectFile(
      'lib/data/graphql/pos_inventory_queries.dart',
    );
    final repository = readProjectFile(
      'lib/domain/repositories/pos_inventory_repository.dart',
    );
    expect(query, contains('wajib_batch_number wajib_serial_number'));
    expect(query, contains('query GetAllInventoryReceivings'));
    expect(repository, contains('getPurchaseReceivings'));
    expect(repository, contains('FetchPolicy.networkOnly'));
  });

  test(
    'form menerima sebagian dan memvalidasi batch serial serta kedaluwarsa',
    () {
      final page = readProjectFile(
        'lib/presentation/pages/pos/pos_purchase_receiving_page.dart',
      );
      expect(page, contains("item['receive_qty']"));
      expect(page, contains("item['remaining']"));
      expect(page, contains("item['wajib_batch_number'] == true"));
      expect(page, contains("item['wajib_serial_number'] == true"));
      expect(page, contains('showDatePicker'));
      expect(page, contains('Riwayat penerimaan'));
      expect(page, contains("item['receive_qty'] = 0.0"));
      expect(page, contains('Terima Semua'));
      expect(page, contains('Konfirmasi penerimaan'));
      expect(page, contains('cancelPurchaseReceiving'));
      expect(page, contains('PosPurchaseProgress.remainingInOrderedUnit'));
    },
  );

  test(
    'daftar PO memulihkan status completed lama berdasarkan progres aktual',
    () {
      final page = readProjectFile(
        'lib/presentation/pages/pos/pos_inventory_page.dart',
      );
      final progress = readProjectFile(
        'lib/presentation/pages/pos/utils/pos_purchase_progress.dart',
      );
      expect(page, contains('PosPurchaseProgress.effectiveStatus'));
      expect(page, contains('Status lama tidak sesuai progres'));
      expect(
        progress,
        contains("raw == 'completed' && hasRemaining(purchase)"),
      );
      expect(progress, contains("item['qty_ordered_base']"));
      expect(progress, contains("item['qty_received_base']"));
    },
  );

  test('draft receiving offline terisolasi dan refresh sebelum retry', () {
    final page = readProjectFile(
      'lib/presentation/pages/pos/pos_purchase_receiving_page.dart',
    );
    final query = readProjectFile(
      'lib/data/graphql/pos_inventory_queries.dart',
    );
    expect(page, contains("'operation_kind': 'purchase_receiving_draft'"));
    expect(page, contains("'instansi_id': tenantId"));
    expect(page, contains("'user_id': userId"));
    expect(page, contains("'payload_hash': _payloadHash(payload)"));
    expect(page, contains("status: 'retry_required'"));
    expect(page, contains('getPurchaseReceivings'));
    expect(page, contains('getPurchaseForPrint'));
    expect(page, contains('Penerimaan sebelumnya sudah tercatat'));
    expect(page, contains('Sisa PO berubah sejak request disimpan'));
    expect(query, contains('client_request_id'));
  });

  test('over receipt dan pembatalan mengikuti policy serta permission', () {
    final page = readProjectFile(
      'lib/presentation/pages/pos/pos_purchase_receiving_page.dart',
    );
    final workspace = readProjectFile(
      'lib/presentation/pages/pos/pos_purchase_workspace.dart',
    );
    final runtimeQuery = readProjectFile('lib/data/graphql/pos_queries.dart');
    expect(page, contains('canOverrideReceivingTolerance'));
    expect(page, contains('overReceiptTolerancePercent'));
    expect(page, contains('Batas dengan toleransi'));
    expect(page, contains('widget.canCancelReceiving'));
    expect(page, contains('Alasan pembatalan *'));
    expect(workspace, contains("permissions['override_receiving_tolerance']"));
    expect(workspace, contains("permissions['cancel_inventory_receiving']"));
    expect(runtimeQuery, contains('over_receipt_tolerance_percent'));
  });
}
