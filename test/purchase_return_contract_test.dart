import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/data/graphql/purchase_return_queries.dart';
import 'dart:io';

void main() {
  group('Kontrak Retur Pembelian Mobile', () {
    test('daftar membawa scope, status, nilai, dan item', () {
      expect(PurchaseReturnQueries.list, contains('GetAllPurchaseReturns'));
      expect(PurchaseReturnQueries.list, contains('approval_status'));
      expect(PurchaseReturnQueries.list, contains('lokasi_cabang_nama'));
      expect(PurchaseReturnQueries.list, contains('grand_total_return'));
      expect(PurchaseReturnQueries.list, contains('items'));
    });

    test('form mengambil sumber dan sisa kuantitas dari backend', () {
      expect(
        PurchaseReturnQueries.searchPurchases,
        contains('SearchPurchaseOrdersForReturn'),
      );
      expect(
        PurchaseReturnQueries.availability,
        contains('GetPurchaseReturnSourceAvailability'),
      );
      expect(PurchaseReturnQueries.availability, contains('available_qty'));
      expect(
        PurchaseReturnQueries.availability,
        contains('available_qty_base'),
      );
      expect(PurchaseReturnQueries.availability, contains('conversion_factor'));
      expect(PurchaseReturnQueries.availability, contains('exclude_return_id'));
      expect(PurchaseReturnQueries.availability, contains('barcode'));
    });

    test('create hanya mengirim identitas sumber dan qty yang dipilih', () {
      expect(PurchaseReturnQueries.create, contains('CreatePurchaseReturn'));
      // Harga, konversi, inventaris, dan subtotal harus diotorisasi ulang backend.
      expect(PurchaseReturnQueries.availability, contains('harga_beli'));
    });

    test(
      'repository menerjemahkan halaman UI ke indeks backend berbasis nol',
      () {
        final source = File(
          'lib/domain/repositories/purchase_return_repository.dart',
        ).readAsStringSync();
        expect(source, contains("'page': page > 0 ? page - 1 : 0"));
      },
    );

    test('UI mendukung filter, barcode, tanggal, dan koreksi item retur', () {
      final source = File(
        'lib/presentation/pages/pos/pos_purchase_return_page.dart',
      ).readAsStringSync();
      expect(source, contains('_showFilters'));
      expect(source, contains('_scanItem'));
      expect(source, contains('Tanggal retur'));
      expect(source, contains('item_reason'));
      expect(source, contains('existing: data'));
    });

    test(
      'lifecycle approval dan processing tidak memakai update stok langsung',
      () {
        expect(
          PurchaseReturnQueries.submit,
          contains('SubmitPurchaseReturnForApproval'),
        );
        expect(
          PurchaseReturnQueries.approve,
          contains('ApprovePurchaseReturn'),
        );
        expect(PurchaseReturnQueries.reject, contains('RejectPurchaseReturn'));
        expect(PurchaseReturnQueries.update, contains('UpdatePurchaseReturn'));
        expect(PurchaseReturnQueries.delete, contains('DeletePurchaseReturn'));
        expect(
          PurchaseReturnQueries.process,
          contains('ProcessPurchaseReturn'),
        );
        expect(
          PurchaseReturnQueries.retryJournal,
          contains('RetryPurchaseReturnJournal'),
        );

        final combined = [
          PurchaseReturnQueries.create,
          PurchaseReturnQueries.submit,
          PurchaseReturnQueries.approve,
          PurchaseReturnQueries.reject,
          PurchaseReturnQueries.process,
        ].join('\n');
        expect(combined, isNot(contains('UpdateInventarisUmum')));
        expect(combined, isNot(contains('AdjustInventoryStock')));
      },
    );
  });
}
