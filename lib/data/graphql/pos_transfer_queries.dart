class PosTransferQueries {
  static const location =
      r'''cabang_id cabang_nama gedung_kode gedung_nama ruangan_kode ruangan_nama rak_nama''';
  static const allocation = r'''batch_id no_batch tanggal_kadaluarsa qty''';
  static const fields =
      '''
    _id no_transfer status tanggal_transfer catatan updatedAt
    requires_approval approval_auto_approved my_pending_approval approval_history_id alasan_penolakan
    routing_snapshot { version category rule mode reason source_branch_id destination_branch_id locked_at }
    routing_preview { version category rule mode reason source_branch_id destination_branch_id locked_at }
    dari {$location} ke {$location} transit {$location}
    branch_id branch_code branch_name project_id project_code project_name
    payment_bank_account_id payment_account_code payment_account_name payment_branch_id payment_branch_code payment_branch_name
    biaya_mode biaya_alokasi total_biaya biaya_transfer {jenis_biaya deskripsi nominal akun_beban akun_beban_nama}
    journal_status journal_error journal_id cancel_journal_status cancel_journal_error
    dispatch_posting_date completion_posting_date cost_posting_date
    created_by created_by_name submitted_by submitted_at approved_by approved_at dispatched_by dispatched_at
    received_by received_at posted_by posted_at cancelled_by cancelled_at
    items { _id inventaris_id nama_inventaris kode_inventaris unit qty catatan_item
      batch_id no_batch tanggal_kadaluarsa serial_numbers received_qty resolved_qty
      unit_breakdown {unit factor input_qty} batch_allocations {$allocation}
      received_serial_numbers resolved_serial_numbers received_batch_allocations {$allocation} resolved_batch_allocations {$allocation}
    }
    receipts { _id request_id received_at received_date posting_date received_by
      items {item_id qty location {$location} serial_numbers batch_allocations {$allocation}}
    }
    discrepancies { _id request_id kind reason evidence_url status reported_by reported_at decided_by decided_at decision_note
      posting_date scrap_number scrap_id journal_id quarantine {$location}
      items {item_id qty serial_numbers batch_allocations {$allocation}}
    }
  ''';
  static const list =
      '''query MobileTransferList(\$filter:InventoryTransferFilter,\$page:Int,\$limit:Int) {
    GetAllInventoryTransfers(filter:\$filter,page:\$page,limit:\$limit) {total page limit data {$fields}}
  }''';
  static const detail =
      '''query MobileTransferDetail(\$id:ID!) {GetOneInventoryTransfer(id:\$id) {$fields}}''';
  static const create =
      '''mutation MobileTransferCreate(\$input:CreateInventoryTransferInput!,\$request_id:String) {CreateInventoryTransfer(input:\$input,request_id:\$request_id) {$fields}}''';
  static const update =
      '''mutation MobileTransferUpdate(\$id:ID!,\$input:UpdateInventoryTransferInput!) {UpdateInventoryTransfer(id:\$id,input:\$input) {$fields}}''';
  static const receive =
      '''mutation MobileTransferReceive(\$id:ID!,\$items:[InventoryTransferReceiptItemInput!],\$request_id:String,\$received_date:String,\$posting_date:String) {ReceiveInventoryTransfer(id:\$id,items:\$items,request_id:\$request_id,received_date:\$received_date,posting_date:\$posting_date) {$fields}}''';
  static const report =
      '''mutation MobileTransferReport(\$id:ID!,\$input:InventoryTransferDiscrepancyInput!) {ReportInventoryTransferDiscrepancy(id:\$id,input:\$input) {$fields}}''';
  static const decide =
      '''mutation MobileTransferDecide(\$id:ID!,\$discrepancy_id:ID!,\$approve:Boolean!,\$note:String!,\$quarantine:InventoryTransferLocationInput,\$loss_account_code:String) {DecideInventoryTransferDiscrepancy(id:\$id,discrepancy_id:\$discrepancy_id,approve:\$approve,note:\$note,quarantine:\$quarantine,loss_account_code:\$loss_account_code) {$fields}}''';
  static const warehouses = r'''query MobileTransferWarehouses($page:Int=0) {
    getAllCabangs(filter:{status:"active",has_warehouse:true},pagination:{page:$page,limit:200}) {info_page {count} cabang {
      _id nama_cabang warehouse_type linked_toko_id is_transfer_source is_transfer_destination
      gedung {kode_gedung nama_gedung ruangan {kode_ruangan nama_ruangan rak {nama_rak}}}
    }}
  }''';
  static const itemsPage =
      r'''query MobileTransferProductPage($id:ID!,$building:String,$room:String,$rack:String,$search:String,$page:Int!) {
    GetInventoryTransferProductPage(cabang_id:$id,gedung_kode:$building,ruangan_kode:$room,rak_nama:$rack,search:$search,pagination:{page:$page,limit:30}) {
      totalCount items {inventaris_id nama_inventaris kode_inventaris unit base_unit qty wajib_batch_number wajib_serial_number unit_conversions {unit factor}}
    }
  }''';
  static const items =
      r'''query MobileTransferAvailable($id:ID!,$building:String,$room:String,$rack:String,$search:String) {
    GetInventarisAvailableInLocation(cabang_id:$id,gedung_kode:$building,ruangan_kode:$room,rak_nama:$rack,search:$search,limit:100,include_non_sellable:true) {
      _id inventaris_id nama_inventaris kode_inventaris unit base_unit qty sku barcode wajib_batch_number wajib_serial_number unit_conversions {unit factor}
    }
  }''';
  static const batches =
      r'''query MobileTransferBatches($id:ID!,$location:ID!,$search:String,$page:Int!) {
    SearchInventoryBatchOptions(inventaris_id:$id,purpose:"transfer",location_id:$location,search:$search,pagination:{page:$page,limit:30}) {totalCount items {_id inventaris_id no_batch tanggal_kadaluarsa qty}}
  }''';
  static const units = r'''query MobileTransferUnits($id:ID!) {
    GetOneInventarisUmum(_id:$id) {_id unit base_unit unit_conversions {unit factor}}
  }''';
  static const paymentRefs = r'''query MobileTransferPaymentRefs {
    GetInventoryTransferPaymentAccounts {_id label coa_code}
    GetFinanceDimensionOptions(purpose:"transfer") {_id kind code name is_active}
  }''';
}
