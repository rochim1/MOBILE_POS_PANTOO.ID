import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/data/graphql/pos_inventory_queries.dart';

void main() {
  group('Kontrak hub Inventori Mobile', () {
    test('menu operasional mengikuti tracking stok dan profil transfer', () {
      final source = File(
        'lib/presentation/pages/pos/pos_inventory_page.dart',
      ).readAsStringSync();
      expect(
        source,
        contains("final trackStock = features['track_stock'] != false"),
      );
      expect(
        source,
        contains("inventoryPolicy['use_transfer_request'] == true"),
      );
      expect(source, contains('trackStock && permissions'));
      expect(source, contains("'Mutasi Stok'"));
    });

    test('menyediakan dokumen inventori inti', () {
      expect(PosInventoryQueries.warehouses, contains('getAllCabangs'));
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
      expect(PosInventoryQueries.createWarehouse, contains('createCabang'));
      expect(PosInventoryQueries.updateWarehouse, contains('updateCabang'));
      expect(PosInventoryQueries.deleteWarehouse, contains('deleteCabang'));
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
      expect(PosInventoryQueries.opnames, contains('batch_counts'));
      expect(
        PosInventoryQueries.locationItems,
        contains('include_non_sellable: true'),
      );
      expect(PosInventoryQueries.locationItems, contains('barcode'));
      expect(PosInventoryQueries.transfers, contains('dari'));
      expect(PosInventoryQueries.transfers, contains('ke'));
      expect(PosInventoryQueries.scraps, contains('total_nilai_scrap'));
      expect(PosInventoryQueries.scraps, contains('jumlah_hilang'));
      expect(PosInventoryQueries.scraps, contains('saldo_lokasi_sebelum'));
    });

    test('disposal memakai saldo lokasi, batch, dan kerugian bersih', () {
      final source = File(
        'lib/presentation/pages/pos/pos_inventory_editor_page.dart',
      ).readAsStringSync();
      expect(PosInventoryQueries.locationBalances, contains('batches'));
      expect(source, contains("'stock_balance_id'"));
      expect(source, contains("'no_batch'"));
      expect(source, contains("'jumlah_hasil_recycle'"));
      expect(source, contains('_scanScrapBarcode'));
      expect(source, contains('melebihi saldo batch'));
    });
  });
}
