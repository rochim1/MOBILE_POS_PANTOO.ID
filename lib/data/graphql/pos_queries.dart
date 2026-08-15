class PosQueries {
  static const String getMyPOSFavoriteProductIds = r'''
    query GetMyPOSFavoriteProductIds {
      GetMyPOSFavoriteProductIds
    }
  ''';
  static const String saveMyPOSFavoriteProductIds = r'''
    mutation SaveMyPOSFavoriteProductIds($productIds: [ID!]!) {
      SaveMyPOSFavoriteProductIds(product_ids: $productIds)
    }
  ''';
  static const String getPOSDashboardData = r'''
    query GetPOSDashboardData($days: Int) {
      GetPOSDashboardData(days: $days) {
        stats {
          today_revenue today_transactions today_avg_order
          yesterday_revenue yesterday_transactions
          revenue_growth transaction_growth
        }
        daily_sales { date label revenue transactions }
        payment_breakdown { method label count total percentage }
        top_products { _id nama kode qty_sold revenue percentage }
      }
    }
  ''';
  static const String getPOSRuntimeConfig = r'''
    query GetPOSRuntimeConfig {
      GetPOSRuntimeConfig {
        instansi_id
        business_profile
        inventory_profile
        inventory_policy {
          inventory_profile
          use_central_warehouse
          use_transfer_request
          use_transfer_approval
          use_in_transit
          use_store_warehouse
          use_display_stock
          allow_direct_purchase_to_store
          default_receiving_location_id
          default_transfer_transit_location_id
        }
        configuration_health { valid issues }
        default_order_type
        default_sales_channel
        default_customer_segment
        default_price_level
        tax_percent
        expired_sale_policy
        features {
          use_tables
          use_kitchen_flow
          use_service_order
          use_appointments
          use_technicians
          use_vehicle_data
          use_delivery
          require_customer
          track_stock
        }
        permissions {
          view_dashboard
          use_cashier
          view_products
          view_promos
          view_customers
          view_stores
          view_shifts
          view_transactions
          view_reports
          view_returns
          view_settings
          view_receipt
          view_stock
          view_tables
          manage_products
          adjust_stock
          manage_tables
          manage_settings
        }
      }
    }
  ''';
  static const String createPOSInvoice = r'''
    mutation CreatePOSInvoice($input: POSOrderInput!) {
      CreatePOSOrder(input: $input) {
        _id
        order_no
        grand_total
        status
        status_pembayaran
        catatan
      }
    }
  ''';
  static const String getMyPOSLockStatus = r'''
    query GetMyPOSLockStatus {
      GetMyPOSLockStatus { enabled has_pin locked_until }
    }
  ''';

  static const String verifyMyPOSPin = r'''
    mutation VerifyMyPOSPin($pin: String!) {
      VerifyMyPOSPin(pin: $pin) { success message locked_until }
    }
  ''';
  static const String getPOSPinUsers = r'''
    query GetPOSPinUsers($search: String, $pagination: pagination) {
      GetPOSPinUsers(search: $search, pagination: $pagination) {
        items { _id name username has_pin failed_attempts locked_until }
      }
    }
  ''';
  static const String verifyPOSUserPin = r'''
    mutation VerifyPOSUserPin($userId: ID!, $pin: String!) {
      VerifyPOSUserPin(user_id: $userId, pin: $pin) {
        success message operator_token user_id name username locked_until
      }
    }
  ''';

  static const String login = r'''
    mutation Login($input: LoginInput!) {
      Login(input: $input) {
        token
        user {
          _id
          username
          name
          instansi_id {
            _id
          }
        }
      }
    }
  ''';

  static const String getAllPOSToko = r'''
    query GetAllPOSToko($search: String, $pagination: pagination) {
      GetAllPOSToko(search: $search, pagination: $pagination) {
        items {
          _id
          kode_toko
          nama_toko
          alamat
          telepon
          lokasi_cabang_nama
          lokasi_cabang_id
          status
        }
      }
    }
  ''';

  static const String getMyActiveKasirShift = r'''
    query GetMyActiveKasirShift($toko_id: ID) {
      GetMyActiveKasirShift(toko_id: $toko_id) {
        _id
        toko_id
        kasir_user_id
        opened_at
        opening_cash
        status
        toko {
          _id
          nama_toko
          kode_toko
          lokasi_cabang_id
          lokasi_cabang_nama
        }
      }
    }
  ''';

  static const String addPOSToko = r'''
    mutation AddPOSToko($input: POSTokoInput!) {
      AddPOSToko(input: $input) { _id kode_toko nama_toko alamat telepon lokasi_cabang_id lokasi_cabang_nama status }
    }
  ''';

  static const String updatePOSToko = r'''
    mutation UpdatePOSToko($_id: ID!, $input: POSTokoInput!) {
      UpdatePOSToko(_id: $_id, input: $input) { _id kode_toko nama_toko alamat telepon lokasi_cabang_id lokasi_cabang_nama status }
    }
  ''';

  static const String deletePOSToko = r'''
    mutation DeletePOSToko($_id: ID!) { DeletePOSToko(_id: $_id) { _id status } }
  ''';

  static const String openPOSKasirShift = r'''
    mutation OpenPOSKasirShift($input: POSKasirShiftOpenInput!) {
      OpenPOSKasirShift(input: $input) {
        _id
        toko_id
        opened_at
        opening_cash
        status
      }
    }
  ''';

  static const String closePOSKasirShift = r'''
    mutation ClosePOSKasirShift($input: POSKasirShiftCloseInput!) {
      ClosePOSKasirShift(input: $input) {
        _id
        closed_at
        closing_cash_actual
        status
      }
    }
  ''';

  static const String getAllInventarisUmum = r'''
    query GetAllInventarisUmum($filter: InventarisUmumFilter, $pagination: pagination) {
      GetAllInventarisUmum(filter: $filter, pagination: $pagination) {
        items {
          _id
          kode_inventaris
          nama_inventaris
          kategori
          pos_product_type
          sellable_in_pos
          tracks_stock
          harga_jual
          stok
          sku
          foto
          status
        }
      }
    }
  ''';

  static const String getInventarisAvailableInLocation = r'''
    query GetInventarisAvailableInLocation($cabang_id: ID!) {
      GetInventarisAvailableInLocation(cabang_id: $cabang_id) {
        inventaris_id
        _id
        kode_inventaris
        nama_inventaris
        kategori
        pos_product_type
        sellable_in_pos
        tracks_stock
        promo_eligible
        sku
        barcode
        foto
        brand
        harga_jual
        base_unit
        unit
        unit_conversions { unit factor }
        qty
      }
    }
  ''';

  static const String getAllPOSPelanggan = r'''
    query GetAllCrmContacts($filter: CrmContactFilterInput, $pagination: pagination) {
      getAllCrmContacts(filter: $filter, pagination: $pagination) {
        data {
          _id
          name
          phone
          email
          address
          price_level
          total_transaksi
          total_belanja
        }
      }
    }
  ''';

  static const String createPOSPelanggan = r'''
    mutation CreateCrmContact($input: CrmContactInput!) {
      createCrmContact(input: $input) { _id name phone email address price_level total_transaksi total_belanja }
    }
  ''';

  static const String updatePOSPelanggan = r'''
    mutation UpdateCrmContact($_id: ID!, $input: CrmContactUpdateInput!) {
      updateCrmContact(_id: $_id, input: $input) { _id name phone email address price_level total_transaksi total_belanja }
    }
  ''';

  static const String deletePOSPelanggan = r'''
    mutation DeleteCrmContact($_id: ID!) { deleteCrmContact(_id: $_id) }
  ''';

  static const String processPOSPenjualan = r'''
    mutation ProcessPOSPenjualan($input: ProcessPOSPenjualanInput!) {
      ProcessPOSPenjualan(input: $input) {
        _id
        invoice
        tanggal
        total
        subtotal
        diskon
        promo_discount
        pajak
        metode_pembayaran
        uang_diterima
        kembalian
        payments { metode jumlah }
        items { inventaris_id nama_inventaris qty unit harga_jual subtotal }
      }
    }
  ''';

  static const String previewPOSPricing = r'''
    query PreviewPOSPricing($input: POSPricingPreviewInput!) {
      PreviewPOSPricing(input: $input) {
        subtotal
        promo_code
        promo_discount
        manual_discount_applied
        discount_policy
        promo_applied
        promo_message
        total_after_discount
        items {
          inventaris_id
          harga_jual
          subtotal
          qty_base
          stok_tersedia_base
          stok_cukup
        }
      }
    }
  ''';

  static const String getPOSPenjualan = r'''
    query GetPOSPenjualan($filter: POSPenjualanFilter, $sorting: POSPenjualanSorting, $pagination: pagination) {
      GetPOSPenjualan(filter: $filter, sorting: $sorting, pagination: $pagination) {
        items {
          _id
          invoice
          tanggal
          toko_nama
          kasir_name
          pelanggan
          metode_pembayaran
          subtotal
          diskon
          pajak
          total
          items {
            inventaris_id
            kode_inventaris
            nama_inventaris
            qty
            unit
            harga_jual
            subtotal
          }
          createdAt
        }
        info_page { count }
      }
    }
  ''';

  static const String getPendingPOSOrders = r'''
    query GetPendingPOSOrders($filter: POSOrderFilter, $sorting: POSOrderSorting, $pagination: pagination) {
      GetAllPOSOrder(filter: $filter, sorting: $sorting, pagination: $pagination) {
        items {
          _id
          order_no
          pelanggan_nama
          subtotal
          diskon_persen
          diskon_amount
          pajak_persen
          pajak_amount
          grand_total
          metode_pembayaran
          status
          status_pembayaran
          source
          kasir_name
          catatan
          items { produk_id nama kode qty unit harga_satuan subtotal }
          createdAt
          toko { nama_toko }
        }
        info_page { count }
      }
    }
  ''';

  static const String payPOSOrder = r'''
    mutation PayPOSOrder(
      $id: ID!
      $method: String!
      $cashReceived: Float
      $splitPayments: [SplitPaymentInput]
    ) {
      PayPOSOrder(
        _id: $id
        metode_pembayaran: $method
        uang_diterima: $cashReceived
        split_payments: $splitPayments
      ) {
        _id
        order_no
        status
        status_pembayaran
        pos_transaction_invoice
      }
    }
  ''';

  static const String getInventarisUmumStatistics = r'''
    query GetInventarisUmumStatistics {
      GetInventarisUmumStatistics {
        total_inventaris
        total_nilai_inventaris
        low_stock_count
        out_of_stock_count
      }
    }
  ''';

  static const String getPOSKasirShifts = r'''
    query GetPOSKasirShifts($filter: POSKasirShiftFilter, $pagination: pagination) {
      GetPOSKasirShifts(filter: $filter, pagination: $pagination) {
        items {
          _id
          toko_id
          kasir_user_id
          opened_at
          closed_at
          opening_cash
          closing_cash_expected
          closing_cash_actual
          cash_difference
          total_transaksi
          total_penjualan
          status
          toko {
            _id
            nama_toko
          }
        }
      }
    }
  ''';

  static const String addPOSKasirPettyCash = r'''
    mutation AddPOSKasirPettyCash($input: POSKasirPettyCashInput!) {
      AddPOSKasirPettyCash(input: $input) {
        _id
        petty_cash_in
        petty_cash_out
        closing_cash_expected
      }
    }
  ''';

  static const String createInventarisUmum = r'''
    mutation AddInventarisUmum($input: InventarisUmumInput!) {
      AddInventarisUmum(input: $input) {
        _id
        kode_inventaris
        nama_inventaris
        kategori
        harga_jual
        stok
        sku
        status
      }
    }
  ''';

  static const String updateInventarisUmum = r'''
    mutation UpdateInventarisUmum($_id: ID!, $input: InventarisUmumInput!) {
      UpdateInventarisUmum(_id: $_id, input: $input) {
        _id
        kode_inventaris
        nama_inventaris
        kategori
        harga_jual
        stok
        sku
        status
      }
    }
  ''';

  static const String deleteInventarisUmum = r'''
    mutation DeleteInventarisUmum($_id: ID!, $deleteReason: String) {
      DeleteInventarisUmum(_id: $_id, delete_reason: $deleteReason) {
        _id
      }
    }
  ''';
}
