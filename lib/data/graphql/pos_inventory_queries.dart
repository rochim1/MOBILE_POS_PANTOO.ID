class PosInventoryQueries {
  static const warehouses = r'''
    query GetPOSWarehouses($search: String) {
      getAllCabangs(
        filter: { nama_cabang: $search, status: "active", has_warehouse: true }
        sorting: { nama_cabang: asc }
        pagination: { page: 0, limit: 200 }
      ) {
        cabang {
          _id branch_code nama_cabang alamat_cabang no_telp status
          is_warehouse warehouse_type is_sellable_location
          is_receiving_location is_transfer_source is_transfer_destination
        }
      }
    }
  ''';

  static const createWarehouse = r'''
    mutation CreatePOSWarehouse($input: CabangInput) {
      createCabang(input: $input) { _id nama_cabang }
    }
  ''';

  static const updateWarehouse = r'''
    mutation UpdatePOSWarehouse($id: ID!, $input: CabangInput) {
      updateCabang(id: $id, input: $input) { _id nama_cabang }
    }
  ''';

  static const deleteWarehouse = r'''
    mutation DeletePOSWarehouse($id: ID!) {
      deleteCabang(id: $id) { _id }
    }
  ''';

  static const purchases = r'''
    query GetAllInventoryPurchases($filter: InventoryPurchaseFilter, $pagination: pagination) {
      GetAllInventoryPurchases(filter: $filter, pagination: $pagination) {
        totalCount
        items { _id no_po supplier_id supplier_name tanggal_po tanggal_pengiriman alamat_pengiriman metode_pembayaran syarat_pembayaran prioritas status catatan diskon_persen ppn_persen biaya_pengiriman grand_total items { _id inventaris_id kode_inventaris nama_inventaris qty_ordered qty_received harga_beli unit diskon_item diskon_item_type catatan_item } }
      }
    }
  ''';

  static const opnames = r'''
    query GetAllInventoryOpnames($filter: InventoryOpnameFilter, $page: Int, $limit: Int) {
      GetAllInventoryOpnames(filter: $filter, page: $page, limit: $limit) {
        total page limit
        data {
          _id no_opname tanggal_opname status catatan alasan_penolakan
          approval_required_level approval_current_level approval_history_id
          lokasi { cabang_id cabang_nama gedung_kode gedung_nama ruangan_kode ruangan_nama rak_nama }
          items {
            _id inventaris_id stock_balance_id snapshot_updated_at
            kode_inventaris nama_inventaris qty_system qty_fisik selisih unit catatan_item
            batch_counts { no_batch tanggal_kadaluarsa qty_system qty_fisik }
          }
        }
      }
    }
  ''';

  static const transfers = r'''
    query GetAllInventoryTransfers($filter: InventoryTransferFilter, $page: Int, $limit: Int) {
      GetAllInventoryTransfers(filter: $filter, page: $page, limit: $limit) {
        total page limit
        data { _id no_transfer tanggal_transfer status catatan biaya_transfer { jenis_biaya deskripsi nominal akun_beban akun_beban_nama } biaya_mode biaya_alokasi dari { cabang_id cabang_nama gedung_kode gedung_nama ruangan_kode ruangan_nama rak_nama } ke { cabang_id cabang_nama gedung_kode gedung_nama ruangan_kode ruangan_nama rak_nama } items { _id inventaris_id kode_inventaris nama_inventaris qty unit } }
      }
    }
  ''';

  static const scraps = r'''
    query GetAllInventoryScraps($filter: ScrapFilterInput, $pagination: PaginationInput) {
      GetAllInventoryScraps(filter: $filter, pagination: $pagination) {
        totalCount
        items { _id no_scrap tanggal_scrap status alasan alasan_detail jenis_insiden lokasi_kejadian catatan total_nilai_scrap createdAt updatedAt tanggal_disetujui journal_id diajukan_oleh { _id name } disetujui_oleh { _id name } items { _id inventaris_id stock_balance_id kode_inventaris nama_inventaris qty unit nilai_per_unit total_nilai no_batch catatan_item lokasi_cabang_id lokasi_cabang_nama lokasi_gedung_kode lokasi_gedung_nama lokasi_ruangan_kode lokasi_ruangan_nama lokasi_rak_nama tindakan jumlah_hasil_recycle jumlah_hilang stok_sebelum stok_sesudah saldo_lokasi_sebelum saldo_lokasi_sesudah } }
      }
    }
  ''';

  static const receiveTransfer = r'''
    mutation ReceiveInventoryTransfer($id: ID!) {
      ReceiveInventoryTransfer(id: $id) { _id no_transfer status received_at }
    }
  ''';

  static const lookups = r'''
    query GetPOSInventoryFormLookups {
      GetAllSupplier(filter: { status: active }, pagination: { page: 0, limit: 100 }) {
        suppliers { _id kode_supplier nama_supplier is_pkp default_ppn_persen }
      }
      getAllCabangs(filter: { status: "active", has_warehouse: true }, pagination: { page: 0, limit: 100 }) {
        cabang { _id nama_cabang is_receiving_location is_transfer_source is_transfer_destination }
      }
      GetMyActiveKasirShift { toko { lokasi_cabang_id } }
      GetAllInventarisUmum(filter: { status: "active" }, pagination: { page: 0, limit: 200 }) {
        items { _id kode_inventaris nama_inventaris unit harga_beli stok }
      }
    }
  ''';

  static const locationItems = r'''
    query GetPOSInventoryLocationItems($cabangId: ID!) {
      GetInventarisAvailableInLocation(cabang_id: $cabangId, limit: 1000, include_non_sellable: true) {
        inventaris_id _id stock_balance_id kode_inventaris nama_inventaris unit qty harga_beli
        sku barcode
        batches { no_batch tanggal_kadaluarsa qty aktif }
      }
    }
  ''';

  static const locationBalances = r'''
    query GetPOSInventoryLocationBalances($inventoryId: ID!, $warehouseId: ID) {
      GetInventoryLocationBalances(
        inventaris_id: $inventoryId
        filter: { lokasi_cabang_id: $warehouseId }
        sorting: { qty: "desc" }
        pagination: { page: 0, limit: 200 }
      ) {
        items {
          _id inventaris_id qty
          lokasi_cabang_id lokasi_cabang_nama
          lokasi_gedung_kode lokasi_gedung_nama
          lokasi_ruangan_kode lokasi_ruangan_nama lokasi_rak_nama
          batches { no_batch tanggal_kadaluarsa qty aktif }
        }
      }
    }
  ''';

  static const createPurchase =
      r'''mutation AddInventoryPurchase($input: InventoryPurchaseInput!) { AddInventoryPurchase(input: $input) { _id no_po status } }''';
  static const updatePurchase =
      r'''mutation UpdateInventoryPurchase($id: ID!, $input: InventoryPurchaseInput!) { UpdateInventoryPurchase(_id: $id, input: $input) { _id no_po status } }''';
  static const submitPurchase =
      r'''mutation SubmitInventoryPurchase($id: ID!) { SubmitInventoryPurchase(_id: $id) { _id no_po status } }''';
  static const approvePurchase =
      r'''mutation ApproveInventoryPurchase($id: ID!) { ApproveInventoryPurchase(_id: $id) { _id no_po status } }''';
  static const rejectPurchase =
      r'''mutation RejectInventoryPurchase($id: ID!, $reason: String!) { RejectInventoryPurchase(_id: $id, alasan_penolakan: $reason) { _id no_po status } }''';
  static const deletePurchase =
      r'''mutation DeleteInventoryPurchase($id: ID!, $reason: String) { DeleteInventoryPurchase(_id: $id, delete_reason: $reason) { _id status } }''';
  static const receivePurchase =
      r'''mutation AddInventoryReceiving($input: InventoryReceivingInput!) { AddInventoryReceiving(input: $input) { _id no_grn purchase_id status } }''';

  static const createOpname =
      r'''mutation CreateInventoryOpname($input: CreateInventoryOpnameInput!) { CreateInventoryOpname(input: $input) { _id no_opname status } }''';
  static const updateOpname =
      r'''mutation UpdateInventoryOpname($id: ID!, $input: UpdateInventoryOpnameInput!) { UpdateInventoryOpname(id: $id, input: $input) { _id no_opname status } }''';
  static const submitOpname =
      r'''mutation SubmitInventoryOpname($id: ID!) { SubmitInventoryOpname(id: $id) { _id no_opname status } }''';
  static const approveOpname =
      r'''mutation ApproveInventoryOpname($id: ID!) { ApproveInventoryOpname(id: $id) { _id no_opname status } }''';
  static const rejectOpname =
      r'''mutation RejectInventoryOpname($id: ID!, $reason: String!) { RejectInventoryOpname(id: $id, alasan_penolakan: $reason) { _id no_opname status } }''';
  static const postOpname =
      r'''mutation PostInventoryOpname($id: ID!) { PostInventoryOpname(id: $id) { _id no_opname status } }''';
  static const cancelOpname =
      r'''mutation CancelInventoryOpname($id: ID!, $reason: String) { CancelInventoryOpname(id: $id, alasan: $reason) { _id no_opname status } }''';
  static const deleteOpname =
      r'''mutation DeleteInventoryOpname($id: ID!) { DeleteInventoryOpname(id: $id) { _id no_opname status } }''';

  static const createTransfer =
      r'''mutation CreateInventoryTransfer($input: CreateInventoryTransferInput!) { CreateInventoryTransfer(input: $input) { _id no_transfer status } }''';
  static const updateTransfer =
      r'''mutation UpdateInventoryTransfer($id: ID!, $input: UpdateInventoryTransferInput!) { UpdateInventoryTransfer(id: $id, input: $input) { _id no_transfer status } }''';
  static const submitTransfer =
      r'''mutation SubmitInventoryTransfer($id: ID!) { SubmitInventoryTransfer(id: $id) { _id no_transfer status } }''';
  static const approveTransfer =
      r'''mutation ApproveInventoryTransfer($id: ID!) { ApproveInventoryTransfer(id: $id) { _id no_transfer status } }''';
  static const rejectTransfer =
      r'''mutation RejectInventoryTransfer($id: ID!, $reason: String!) { RejectInventoryTransfer(id: $id, alasan_penolakan: $reason) { _id no_transfer status } }''';
  static const postTransfer =
      r'''mutation PostInventoryTransfer($id: ID!) { PostInventoryTransfer(id: $id) { _id no_transfer status } }''';
  static const cancelTransfer =
      r'''mutation CancelInventoryTransfer($id: ID!, $reason: String) { CancelInventoryTransfer(id: $id, alasan: $reason) { _id no_transfer status } }''';
  static const deleteTransfer =
      r'''mutation DeleteInventoryTransfer($id: ID!) { DeleteInventoryTransfer(id: $id) { _id no_transfer status } }''';

  static const createScrap =
      r'''mutation CreateInventoryScrap($input: InventoryScrapInput!) { CreateInventoryScrap(input: $input) { _id no_scrap status } }''';
  static const updateScrap =
      r'''mutation UpdateInventoryScrap($id: ID!, $input: InventoryScrapInput!) { UpdateInventoryScrap(_id: $id, input: $input) { _id no_scrap status } }''';
  static const approveScrap =
      r'''mutation ApproveInventoryScrap($id: ID!) { ApproveInventoryScrap(_id: $id) { _id no_scrap status } }''';
  static const rejectScrap =
      r'''mutation RejectInventoryScrap($id: ID!, $reason: String!) { RejectInventoryScrap(_id: $id, catatan: $reason) { _id no_scrap status } }''';
  static const processScrap =
      r'''mutation ProcessInventoryScrap($id: ID!) { ProcessInventoryScrap(_id: $id) { _id no_scrap status } }''';
  static const deleteScrap =
      r'''mutation DeleteInventoryScrap($id: ID!) { DeleteInventoryScrap(_id: $id) { success message } }''';
}
