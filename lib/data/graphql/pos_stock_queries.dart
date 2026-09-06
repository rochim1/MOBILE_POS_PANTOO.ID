class PosStockQueries {
  static const String getStockLocations = r'''
    query GetPOSStockLocationOptions {
      getAllCabangs(
        filter: { status: "active", has_warehouse: true }
        pagination: { page: 0, limit: 200 }
      ) {
        cabang {
          _id
          branch_code
          nama_cabang
          warehouse_type
          is_sellable_location
          status
        }
      }
    }
  ''';

  static const String getStockByStore = r'''
    query GetInventarisAvailableInLocation($cabangId: ID!) {
      GetInventarisAvailableInLocation(cabang_id: $cabangId) {
        inventaris_id
        _id
        kode_inventaris
        nama_inventaris
        kategori
        harga_jual
        harga_beli
        stok_minimum
        sku
        unit
        qty
        stock_balance_id
        location_count
        requires_batch_adjustment
      }
    }
  ''';

  static const String getAllStock = r'''
    query GetAllPOSInventoryStock {
      GetAllInventarisUmum(
        filter: { status: "active" }
        sorting: { nama_inventaris: asc }
        pagination: { page: 0, limit: 1000 }
      ) {
        items {
          _id kode_inventaris nama_inventaris kategori harga_jual harga_beli
          stok_minimum sku unit stok wajib_batch_number
          expiry_batches { qty aktif }
        }
      }
    }
  ''';

  static const String adjustStock = r'''
    mutation UpdateStokInventarisUmum($id: ID!, $input: StokMovementInput!) {
      UpdateStokInventarisUmum(_id: $id, input: $input) {
        _id
        stok
      }
    }
  ''';

  static const String getLocationBalances = r'''
    query GetPOSStockLocationBalances($inventoryId: ID!, $warehouseId: ID) {
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

  static const String getAdjustmentReasons = r'''
    query GetManualStockAdjustmentReasons {
      GetManualStockAdjustmentReasons { value label description }
    }
  ''';

  static const String getActiveStockLocation = r'''
    query GetPOSStockLocationContext {
      GetMyActiveKasirShift {
        toko {
          lokasi_cabang_id
        }
      }
      GetAllPOSToko(pagination: { page: 0, limit: 100 }) {
        items {
          status
          lokasi_cabang_id
        }
      }
    }
  ''';

  static const String getStockMovements = r'''
    query GetMyPOSStockMovements($search: String, $jenis: String, $pagination: pagination) {
      GetMyPOSStockMovements(search: $search, jenis: $jenis, pagination: $pagination) {
        items {
          inventaris_id
          kode_inventaris
          nama_inventaris
          tanggal
          jenis
          jumlah
          saldo_lokasi_sebelum
          saldo_lokasi_sesudah
          alasan
          keterangan
          sumber
          referensi
          lokasi_gedung_kode
          lokasi_ruangan_kode
          lokasi_rak_nama
          user_id { name username }
        }
        info_page { count }
      }
    }
  ''';
}
