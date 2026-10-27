import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_purchase_payable_page.dart';

class _Inventory extends Fake implements PosInventoryRepository {
  @override
  Future<Either<Failure, Map<String, dynamic>?>> getPayableForPurchase(
    String purchaseId,
  ) async => const Right({
    '_id': 'payable-1',
    'outstanding_amount': 1000000.25,
    'total_amount': 1000000.25,
    'paid_amount': 0,
    'status': 'unpaid',
  });

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
  getActiveBankAccounts() async => const Right([]);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getVendorBillsForPurchase(
    String purchaseId,
  ) async => const Right([
    {
      '_id': 'bill-1',
      'supplier_invoice_number': 'INV-001',
      'due_date': '2026-11-01',
      'status': 'posted',
      'total_amount': 1000000.25,
      'items': [
        {'matching_status': 'matched'},
      ],
      'payable': {'outstanding_amount': 1000000.25},
    },
  ]);
}

void main() {
  tearDown(() async => sl.reset());
  testWidgets(
    'supplier payable is visible but payment stays read-only in Mobile Purchasing',
    (tester) async {
      final repo = _Inventory();
      sl.registerSingleton<PosInventoryRepository>(repo);
      await tester.pumpWidget(
        const MaterialApp(
          home: PosPurchasePayablePage(
            purchase: {'_id': 'purchase-1', 'no_po': 'PO-TEST'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Tagihan ini bersifat baca-saja di workspace PO. Kelola pembayaran di Finance Web.',
        ),
        findsOneWidget,
      );
      expect(find.text('Simpan pembayaran'), findsNothing);
      expect(find.text('Jumlah pembayaran *'), findsNothing);
      expect(find.text('INV-001'), findsOneWidget);
      expect(find.textContaining('Matching: matched'), findsOneWidget);
    },
  );
}
