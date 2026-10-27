class PosInventoryQueries {
  static const purchaseAdvanceWorkspace = r'''
    query GetPOSPurchaseAdvanceWorkspace($search:String,$pagination:pagination) {
      GetPurchaseAdvancePage(search:$search,pagination:$pagination) { totalCount items {
        _id purchase_id no_po supplier_name amount status purpose proforma_url proforma_hash requested_at
        approved_at approval_reason rejection_reason paid_amount allocated_amount
        refunded_amount transferred_amount written_off_amount balance
      } }
    }
  ''';
  static const eligibleAdvancePurchases=r'''
    query($search:String,$pagination:pagination){GetEligibleAdvancePurchasePage(search:$search,pagination:$pagination){totalCount items{_id no_po supplier_name status accounting_flow grand_total down_payment_amount down_payment_percent advance_available_amount}}}
  ''';

  static const requestPurchaseAdvance = r'''
    mutation RequestPOSPurchaseAdvance($input: RequestPurchaseAdvanceInput!) {
      RequestPurchaseAdvance(input: $input) {
        _id purchase_id no_po supplier_name amount status purpose proforma_url proforma_hash requested_at balance
      }
    }
  ''';

  static const markPurchaseSent = r'''
    mutation MarkPOSPurchaseSent($input: MarkInventoryPurchaseSentInput!) {
      MarkInventoryPurchaseSentToSupplier(input: $input) {
        _id status supplier_status supplier_contact sent_channel sent_at sent_by
      }
    }
  ''';

  static const acknowledgePurchase = r'''
    mutation AcknowledgePOSPurchase($input: SupplierPurchaseAcknowledgementInput!) {
      RecordSupplierPurchaseAcknowledgement(input: $input) {
        _id status supplier_status supplier_ack_status supplier_ack_note supplier_ack_at supplier_ack_by
      }
    }
  ''';

  static const closePurchaseWithVariance = r'''
    mutation ClosePOSPurchaseWithVariance($input: CloseInventoryPurchaseWithVarianceInput!) {
      CloseInventoryPurchaseWithVariance(input: $input) {
        _id status receiving_status closed_with_variance close_variance_reason closed_at closed_by remaining_qty_at_close
      }
    }
  ''';

  static const uploadVendorInvoiceEvidence = r'''
    mutation UploadVendorInvoiceEvidence($file: Upload!, $folderName: String!, $prefix: String) {
      UploadQuestionImage(file: $file, folder_name: $folderName, prefix: $prefix) {
        success media_url mime_type
      }
    }
  ''';

  static const submitVendorInvoiceEvidence = r'''
    mutation SubmitVendorInvoiceEvidence($input: VendorInvoiceSubmissionInput!) {
      SubmitVendorInvoiceEvidence(input: $input) {
        _id request_id status evidence_url submitted_at
      }
    }
  ''';

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
        items {
          _id no_po supplier_id supplier_name tanggal_po tanggal_pengiriman estimated_arrival_date alamat_pengiriman supplier_contact
          metode_pembayaran payment_method syarat_pembayaran tipe_kredit payment_term_type term_days due_date due_date_basis payment_term_note down_payment_amount down_payment_percent
          jumlah_termin jadwal_termin { no_termin amount due_date status paid_date paid_amount }
          prioritas status receiving_status supplier_status supplier_contact sent_channel sent_at supplier_ack_status supplier_ack_note supplier_ack_at closed_with_variance close_variance_reason closed_at remaining_qty_at_close payable_status payable_outstanding_amount catatan alasan_penolakan total_amount
          approval_history_id my_pending_approval createdAt created_by { _id name }
          sent_by supplier_ack_by closed_by
          diskon_persen diskon_type diskon_fixed ppn_persen ppn_amount ppn_source supplier_is_pkp
          biaya_pengiriman biaya_tambahan { _id jenis_biaya deskripsi nominal }
          total_biaya_tambahan biaya_mode biaya_alokasi grand_total
          items {
            _id inventaris_id kode_inventaris nama_inventaris
            qty_ordered qty_ordered_base qty_received qty_received_base
            harga_beli unit base_unit conversion_factor subtotal
            kategori wajib_batch_number wajib_serial_number
            diskon_item diskon_item_type catatan_item
          }
        }
      }
    }
  ''';

  static const purchaseDetail = r'''
    query GetOneInventoryPurchaseForPrint($id: ID!) {
      GetOneInventoryPurchase(_id: $id) {
        _id no_po supplier_name tanggal_po tanggal_pengiriman estimated_arrival_date alamat_pengiriman
        metode_pembayaran payment_method syarat_pembayaran payment_term_type term_days due_date due_date_basis payment_term_note down_payment_amount down_payment_percent status receiving_status supplier_status supplier_contact sent_channel sent_at supplier_ack_status supplier_ack_note supplier_ack_at closed_with_variance close_variance_reason closed_at remaining_qty_at_close catatan total_amount grand_total
        diskon_persen diskon_type diskon_fixed ppn_persen ppn_amount
        biaya_pengiriman biaya_tambahan { jenis_biaya deskripsi nominal }
        jadwal_termin { no_termin amount due_date status paid_date paid_amount }
        created_by { _id name username }
        createdAt updatedAt
        items {
          _id inventaris_id kode_inventaris nama_inventaris qty_ordered qty_ordered_base
          qty_received qty_received_base unit base_unit conversion_factor harga_beli
          diskon_item diskon_item_type subtotal catatan_item
        }
      }
    }
  ''';

  static const opnames = r'''
    query GetAllInventoryOpnames($filter: InventoryOpnameFilter, $page: Int, $limit: Int) {
      GetAllInventoryOpnames(filter: $filter, page: $page, limit: $limit) {
        total page limit
        data {
          _id no_opname tanggal_opname status catatan alasan_penolakan
          approval_required_level approval_current_level approval_history_id my_pending_approval
          approval_logs { action level note by at }
          lokasi { cabang_id cabang_nama gedung_kode gedung_nama ruangan_kode ruangan_nama rak_nama }
          items {
            _id inventaris_id stock_balance_id snapshot_updated_at
            kode_inventaris nama_inventaris qty_system qty_fisik selisih unit catatan_item
            batch_counts { no_batch tanggal_kadaluarsa qty_system qty_fisik }
            unit_breakdown { unit input_qty factor }
          }
        }
      }
    }
  ''';

  static const transfers = r'''
    query GetAllInventoryTransfers($filter: InventoryTransferFilter, $page: Int, $limit: Int) {
      GetAllInventoryTransfers(filter: $filter, page: $page, limit: $limit) {
        total page limit
        data { _id no_transfer tanggal_transfer status catatan approval_history_id my_pending_approval total_biaya journal_status journal_error cancel_journal_status cancel_journal_error biaya_transfer { jenis_biaya deskripsi nominal akun_beban akun_beban_nama } biaya_mode biaya_alokasi dari { cabang_id cabang_nama gedung_kode gedung_nama ruangan_kode ruangan_nama rak_nama } ke { cabang_id cabang_nama gedung_kode gedung_nama ruangan_kode ruangan_nama rak_nama } items { _id inventaris_id kode_inventaris nama_inventaris qty received_qty unit } }
      }
    }
  ''';

  static const scraps = r'''
    query GetAllInventoryScraps($filter: ScrapFilterInput, $pagination: PaginationInput) {
      GetAllInventoryScraps(filter: $filter, pagination: $pagination) {
        totalCount
        items { _id no_scrap tanggal_scrap status alasan alasan_detail jenis_insiden lokasi_kejadian catatan total_nilai_scrap createdAt updatedAt tanggal_disetujui journal_id journal_status journal_error diajukan_oleh { _id name } disetujui_oleh { _id name } items { _id inventaris_id stock_balance_id kode_inventaris nama_inventaris qty unit nilai_per_unit total_nilai no_batch catatan_item lokasi_cabang_id lokasi_cabang_nama lokasi_gedung_kode lokasi_gedung_nama lokasi_ruangan_kode lokasi_ruangan_nama lokasi_rak_nama tindakan jumlah_hasil_recycle jumlah_hilang stok_sebelum stok_sesudah saldo_lokasi_sebelum saldo_lokasi_sesudah } }
      }
    }
  ''';

  static const receiveTransfer = r'''
    mutation ReceiveInventoryTransfer($id: ID!, $items: [InventoryTransferReceiptItemInput!], $request_id: String) {
      ReceiveInventoryTransfer(id: $id, items: $items, request_id: $request_id) { _id no_transfer status received_at journal_status journal_error }
    }
  ''';

  static const lookups = r'''
    query GetPOSInventoryFormLookups {
      getAllCabangs(filter: { status: "active", has_warehouse: true }, pagination: { page: 0, limit: 100 }) {
        cabang {
          _id nama_cabang is_receiving_location is_transfer_source is_transfer_destination
          gedung {
            kode_gedung nama_gedung
            ruangan { kode_ruangan nama_ruangan rak { nama_rak } }
          }
        }
      }
      GetMyActiveKasirShift { toko { lokasi_cabang_id } }
      GetInventorySettings {
        inventory_operation_defaults { default_receiving_location_id }
      }
      GetInventoryTransactionOptions {
        scrap_reasons { value label description }
        scrap_incident_types { value label description }
        scrap_occurrence_locations { value label description }
        purchase_return_reasons { value label description }
        purchase_return_methods { value label description }
      }
      GetAllInventarisUmum(filter: { status: "active" }, pagination: { page: 0, limit: 200 }) {
        items {
          _id kode_inventaris nama_inventaris unit base_unit harga_beli stok
          unit_conversions { unit factor }
        }
      }
    }
  ''';

  static const purchaseLookups = r'''
    query GetPOSPurchaseFormLookups {
      getAllCabangs(
        filter: { status: "active" }
        sorting: { nama_cabang: asc }
        pagination: { page: 0, limit: 100 }
      ) {
        cabang {
          _id branch_code nama_cabang alamat_cabang no_telp status
          is_warehouse warehouse_type is_sellable_location
          is_receiving_location is_transfer_source is_transfer_destination
        }
      }
      GetPOSPurchaseInventory(limit: 200) {
        _id kode_inventaris nama_inventaris unit base_unit harga_beli stok
        unit_conversions { unit factor }
      }
    }
  ''';

  static const purchaseSuppliers = r'''
    query GetPOSPurchaseSuppliers($search: String, $limit: Int) {
      GetPOSPurchaseSuppliers(search: $search, limit: $limit) {
        _id kode_supplier nama_supplier telepon is_pkp default_ppn_persen
      }
    }
  ''';

  static const createPurchaseSupplierQuick = r'''
    mutation AddPOSPurchaseSupplierQuick($input: POSPurchaseSupplierQuickInput!) {
      AddPOSPurchaseSupplierQuick(input: $input) {
        _id kode_supplier nama_supplier telepon is_pkp default_ppn_persen
      }
    }
  ''';

  static const purchaseInventorySearch = r'''
    query SearchPOSPurchaseInventory($search: String!) {
      GetPOSPurchaseInventory(search: $search, limit: 30) {
        _id kode_inventaris nama_inventaris sku barcode unit base_unit harga_beli stok
        unit_conversions { unit factor }
      }
    }
  ''';

  static const purchaseInventoryById = r'''
    query GetPOSPurchaseInventoryById($inventoryId: ID!) {
      GetPOSPurchaseInventory(inventaris_id: $inventoryId, limit: 1) {
        _id kode_inventaris nama_inventaris sku barcode unit base_unit harga_beli stok
        unit_conversions { unit factor }
      }
    }
  ''';

  static const purchaseInventoryByCode = r'''
    query GetPOSPurchaseInventoryByCode($code: String!) {
      GetPOSPurchaseInventory(exact_code: $code, limit: 30) {
        _id kode_inventaris nama_inventaris sku barcode unit base_unit
      }
    }
  ''';

  static const locationItems = r'''
    query GetPOSInventoryLocationItems($cabangId: ID!) {
      GetInventarisAvailableInLocation(cabang_id: $cabangId, limit: 1000, include_non_sellable: true) {
        inventaris_id _id stock_balance_id kode_inventaris nama_inventaris unit base_unit qty harga_beli
        unit_conversions { unit factor }
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
          _id inventaris_id qty reserved_qty available_qty
          lokasi_cabang_id lokasi_cabang_nama
          lokasi_gedung_kode lokasi_gedung_nama
          lokasi_ruangan_kode lokasi_ruangan_nama lokasi_rak_nama
          batches { no_batch tanggal_kadaluarsa qty aktif }
        }
      }
    }
  ''';

  static const createPurchase =
      r'''mutation AddInventoryPurchase($input: InventoryPurchaseInput!) { AddInventoryPurchase(input: $input) { _id no_po status client_request_id } }''';
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
      r'''mutation AddInventoryReceiving($input: InventoryReceivingInput!) { AddInventoryReceiving(input: $input) { _id no_grn purchase_id status journal_status journal_error } }''';

  static const directPurchases = r'''
    query GetDirectPurchasesForPOS {
      GetDirectPurchasePolicy { enabled amount_limit receipt_required_from allowed_categories }
      GetDirectPurchases { _id number supplier_name date status total_amount receipt_url receipt_hash note request_id createdAt }
      GetDirectPurchaseOptions { banks { _id name account_number_last4 coa_code } accounts { code name type } }
    }
  ''';

  static const createDirectPurchase = r'''
    mutation CreateDirectPurchaseForPOS($input: CreateDirectPurchaseInput!) {
      CreateDirectPurchase(input: $input) { _id number supplier_name date status total_amount receipt_url receipt_hash note request_id }
    }
  ''';

  static const payableForPurchase = r'''
    query GetInventoryPayablesForPurchase($filter: InventoryPayableFilter, $pagination: pagination) {
      GetAllInventoryPayables(filter: $filter, pagination: $pagination) {
        items {
          _id purchase_id no_po supplier_name bill_date due_date due_date_basis
          payment_term_type term_days total_amount paid_amount outstanding_amount
          status notes jadwal_termin {
            no_termin amount due_date status paid_date paid_amount
          } payment_history {
            _id amount payment_date payment_method bank_account_name
            reference_number notes no_termin recorded_at status
            cancellation_reason cancelled_at reversal_journal_id
            recorded_by { _id name username }
            cancelled_by { _id name username }
          }
        }
      }
    }
  ''';

  static const vendorBillsForPurchase = r'''
    query GetVendorBillsForPurchase($purchaseId: ID!, $page: Int, $limit: Int) {
      GetVendorBills(purchase_id: $purchaseId, page: $page, limit: $limit) {
        totalCount
        items {
          _id supplier_invoice_number invoice_date due_date status total_amount
          items { matching_status }
          payable { _id status paid_amount outstanding_amount due_date }
        }
      }
    }
  ''';

  static const payableForPaymentProof = r'''
    query GetOneInventoryPayableForProof($id: ID!) {
      GetOneInventoryPayable(_id: $id) {
        _id purchase_id no_po supplier_name total_amount paid_amount
        outstanding_amount status
        payment_history {
          _id amount payment_date payment_method bank_account_name
          reference_number notes no_termin recorded_at status
          cancellation_reason cancelled_at
          recorded_by { _id name username }
          cancelled_by { _id name username }
        }
      }
    }
  ''';

  static const activeBankAccounts = r'''
    query GetActiveBankAccountsForPayable {
      GetAllBankAccounts(filter: { is_active: true }, pagination: { page: 0, limit: 100 }) {
        items { _id bank_name account_number account_holder is_active }
      }
    }
  ''';

  static const payInventoryPayable = r'''
    mutation PayInventoryPayable($input: PayInventoryPayableInput!) {
      PayInventoryPayable(input: $input) {
        _id purchase_id no_po supplier_name bill_date due_date due_date_basis
        payment_term_type term_days total_amount paid_amount outstanding_amount
        status notes
        payment_history {
          _id amount payment_date payment_method bank_account_name
          reference_number notes no_termin recorded_at status
          cancellation_reason cancelled_at
        }
      }
    }
  ''';

  static const cancelInventoryPayablePayment = r'''
    mutation CancelInventoryPayablePayment($input: CancelInventoryPayablePaymentInput!) {
      CancelInventoryPayablePayment(input: $input) {
        _id purchase_id no_po supplier_name bill_date due_date due_date_basis
        payment_term_type term_days total_amount paid_amount outstanding_amount
        status notes jadwal_termin {
          no_termin amount due_date status paid_date paid_amount
        }
        payment_history {
          _id amount payment_date payment_method bank_account_name
          reference_number notes no_termin recorded_at status
          cancellation_reason cancelled_at reversal_journal_id
          recorded_by { _id name username }
          cancelled_by { _id name username }
        }
      }
    }
  ''';

  static const purchaseReceivings = r'''
    query GetAllInventoryReceivings($purchaseId: ID!, $pagination: pagination) {
      GetAllInventoryReceivings(purchase_id: $purchaseId, pagination: $pagination) {
        totalCount
        items {
          _id no_grn client_request_id tanggal_terima no_surat_jalan status catatan foto_bukti journal_status journal_error cancel_journal_status cancel_journal_error
          cancel_reason cancelled_at createdAt
          created_by { _id name username }
          cancelled_by { _id name username }
          items {
            _id purchase_item_id inventaris_id nama_inventaris unit base_unit
            conversion_factor qty_received qty_received_base no_batch
            tanggal_kadaluarsa keterangan
            allocations {
              lokasi_cabang_id lokasi_cabang_nama lokasi_gedung_kode
              lokasi_gedung_nama lokasi_ruangan_kode lokasi_ruangan_nama
              lokasi_rak_nama qty
            }
          }
        }
      }
    }
  ''';

  static const globalPurchaseReceivings = r'''
    query GetAllInventoryReceivingsGlobal($filter: InventoryReceivingFilter, $pagination: pagination) {
      GetAllInventoryReceivingsGlobal(filter: $filter, pagination: $pagination) {
        totalCount
        items {
          _id no_grn purchase_id no_po supplier_name tanggal_terima
          no_surat_jalan status catatan foto_bukti cancel_reason cancelled_at createdAt
          created_by { _id name username }
          cancelled_by { _id name username }
          items {
            _id purchase_item_id inventaris_id nama_inventaris unit base_unit
            conversion_factor qty_received qty_received_base no_batch
            tanggal_kadaluarsa keterangan
            allocations {
              lokasi_cabang_id lokasi_cabang_nama lokasi_gedung_kode
              lokasi_gedung_nama lokasi_ruangan_kode lokasi_ruangan_nama
              lokasi_rak_nama qty
            }
          }
        }
      }
    }
  ''';

  static const pendingPurchaseApprovals = r'''
    query GetMyPendingInventoryPurchaseApprovals($pagination: pagination) {
      GetMyPendingApprovals(
        request_type: "inventory_purchase"
        pagination: $pagination
      ) { request_id }
    }
  ''';

  static const cancelPurchaseReceiving = r'''
    mutation CancelInventoryReceiving($input: CancelInventoryReceivingInput!) {
      CancelInventoryReceiving(input: $input) {
        _id no_grn status cancel_reason cancelled_at cancel_journal_status cancel_journal_error
      }
    }
  ''';

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
      r'''mutation PostInventoryTransfer($id: ID!) { PostInventoryTransfer(id: $id) { _id no_transfer status journal_status journal_error } }''';
  static const cancelTransfer =
      r'''mutation CancelInventoryTransfer($id: ID!, $reason: String) { CancelInventoryTransfer(id: $id, alasan: $reason) { _id no_transfer status cancel_journal_status cancel_journal_error } }''';
  static const retryTransferJournal =
      r'''mutation RetryInventoryTransferJournal($id: ID!) { RetryInventoryTransferJournal(id: $id) { _id status journal_status journal_error } }''';
  static const retryTransferCancelJournal =
      r'''mutation RetryInventoryTransferCancelJournal($id: ID!) { RetryInventoryTransferCancelJournal(id: $id) { _id status cancel_journal_status cancel_journal_error } }''';
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
      r'''mutation ProcessInventoryScrap($id: ID!) { ProcessInventoryScrap(_id: $id) { _id no_scrap status journal_status journal_error } }''';
  static const retryScrapJournal =
      r'''mutation RetryInventoryScrapJournal($id: ID!) { RetryInventoryScrapJournal(_id: $id) { _id status journal_status journal_error } }''';
  static const retryReceivingJournal =
      r'''mutation RetryInventoryReceivingJournal($id: ID!) { RetryInventoryReceivingJournal(_id: $id) { _id journal_status journal_error } }''';
  static const retryReceivingCancelJournal =
      r'''mutation RetryInventoryReceivingCancelJournal($id: ID!) { RetryInventoryReceivingCancelJournal(_id: $id) { _id cancel_journal_status cancel_journal_error } }''';
  static const deleteScrap =
      r'''mutation DeleteInventoryScrap($id: ID!) { DeleteInventoryScrap(_id: $id) { success message } }''';
}
