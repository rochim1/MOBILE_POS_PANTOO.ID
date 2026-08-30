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

  static const String adjustStock = r'''
    mutation UpdateStokInventarisUmum($id: ID!, $input: StokMovementInput!) {
      UpdateStokInventarisUmum(_id: $id, input: $input) {
        _id
        stok
      }
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
