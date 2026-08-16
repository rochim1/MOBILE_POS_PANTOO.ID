import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/data/graphql/pos_inventory_queries.dart';

void main() {
  group('Kontrak hub Inventori Mobile', () {
    test('menyediakan dokumen inventori inti', () {
      expect(
        PosInventoryQueries.purchases,
        contains('GetAllInventoryPurchases'),
      );
      expect(PosInventoryQueries.opnames, contains('GetAllInventoryOpnames'));
      expect(
        PosInventoryQueries.transfers,
        contains('GetAllInventoryTransfers'),
      );
      expect(PosInventoryQueries.scraps, contains('GetAllInventoryScraps'));
    });

    test('penerimaan mutasi diproses backend', () {
      expect(
        PosInventoryQueries.receiveTransfer,
        contains('ReceiveInventoryTransfer'),
      );
      expect(
        PosInventoryQueries.receiveTransfer,
        isNot(contains('UpdateStokInventarisUmum')),
      );
    });

    test('CRUD dan lifecycle setiap dokumen tersedia', () {
      expect(
        PosInventoryQueries.createPurchase,
        contains('AddInventoryPurchase'),
      );
      expect(
        PosInventoryQueries.updatePurchase,
        contains('UpdateInventoryPurchase'),
      );
      expect(
        PosInventoryQueries.deletePurchase,
        contains('DeleteInventoryPurchase'),
      );
      expect(
        PosInventoryQueries.receivePurchase,
        contains('AddInventoryReceiving'),
      );
      expect(
        PosInventoryQueries.createOpname,
        contains('CreateInventoryOpname'),
      );
      expect(
        PosInventoryQueries.updateOpname,
        contains('UpdateInventoryOpname'),
      );
      expect(
        PosInventoryQueries.deleteOpname,
        contains('DeleteInventoryOpname'),
      );
      expect(
        PosInventoryQueries.createTransfer,
        contains('CreateInventoryTransfer'),
      );
      expect(
        PosInventoryQueries.updateTransfer,
        contains('UpdateInventoryTransfer'),
      );
      expect(
        PosInventoryQueries.deleteTransfer,
        contains('DeleteInventoryTransfer'),
      );
      expect(PosInventoryQueries.createScrap, contains('CreateInventoryScrap'));
      expect(PosInventoryQueries.updateScrap, contains('UpdateInventoryScrap'));
      expect(PosInventoryQueries.deleteScrap, contains('DeleteInventoryScrap'));
    });

    test('list membawa status, lokasi, nilai, dan item untuk UI', () {
      expect(PosInventoryQueries.purchases, contains('grand_total'));
      expect(PosInventoryQueries.opnames, contains('qty_fisik'));
      expect(PosInventoryQueries.transfers, contains('dari'));
      expect(PosInventoryQueries.transfers, contains('ke'));
      expect(PosInventoryQueries.scraps, contains('total_nilai_scrap'));
    });
  });
}
