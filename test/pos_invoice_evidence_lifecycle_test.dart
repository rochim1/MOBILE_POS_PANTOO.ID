import 'dart:async';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/utils/product_image_picker.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_purchase_payable_page.dart';

class _Repo extends Fake implements PosInventoryRepository {
  final pending = Completer<Either<Failure, String>>();
  int uploads = 0, submissions = 0;
  final List<Map<String, dynamic>> inputs = [];
  bool waitForUpload = false;
  @override
  Future<Either<Failure, Map<String, dynamic>?>> getPayableForPurchase(
    String id,
  ) async => const Right(null);
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getVendorBillsForPurchase(
    String id,
  ) async => const Right([]);
  @override
  Future<Either<Failure, String>> uploadVendorInvoiceEvidence(
    Uint8List bytes,
    String filename, {
    String folderName = 'vendor-invoice-submissions',
    String prefix = 'invoice',
    String label = 'Foto invoice',
  }) async {
    uploads++;
    return waitForUpload
        ? pending.future
        : const Right('/static/qa/invoice.png');
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> submitVendorInvoiceEvidence(
    Map<String, dynamic> input,
  ) async {
    submissions++;
    inputs.add(Map.of(input));
    return const Left(ServerFailure('Koneksi terputus, coba lagi'));
  }
}

Future<void> openForm(WidgetTester tester) async {
  await tester.tap(find.text('Kirim foto invoice'));
  // The page intentionally animates a busy indicator behind the open dialog.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.text('Kirim').last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  tearDown(() => sl.reset());
  Future<void> mount(WidgetTester tester, _Repo repo) async {
    sl.registerSingleton<PosInventoryRepository>(repo);
    await tester.pumpWidget(
      MaterialApp(
        home: PosPurchasePayablePage(
          purchase: const {'_id': 'po-1'},
          pickInvoiceImage: () async => PickedProductImage(
            name: 'invoice.png',
            bytes: Uint8List.fromList([137, 80, 78, 71]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'closing page during upload never submits or touches a disposed context',
    (tester) async {
      final repo = _Repo()..waitForUpload = true;
      await mount(tester, repo);
      await openForm(tester);
      expect(repo.uploads, 1);
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      repo.pending.complete(const Right('/static/qa/invoice.png'));
      await tester.pumpAndSettle();
      expect(repo.submissions, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('submission retry reuses upload and the same request key', (
    tester,
  ) async {
    final repo = _Repo();
    await mount(tester, repo);
    await openForm(tester);
    await tester.pumpAndSettle();
    expect(repo.submissions, 1);
    await openForm(tester);
    await tester.pumpAndSettle();
    expect(repo.uploads, 1);
    expect(repo.submissions, 2);
    expect(repo.inputs[0]['request_id'], repo.inputs[1]['request_id']);
    await tester.pump(const Duration(seconds: 5));
  });
}
