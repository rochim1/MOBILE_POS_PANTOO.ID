class PurchaseReturnQueries {
  static const list = r'''
    query GetAllPurchaseReturns($filter: PurchaseReturnFilterInput, $pagination: PaginationInput) {
      GetAllPurchaseReturns(filter: $filter, pagination: $pagination) {
        totalCount
        items {
          _id no_return purchase_id no_po supplier_name tanggal_return
          lokasi_cabang_nama return_reason return_reason_label catatan
          return_method return_method_label approval_status
          grand_total_return journal_status journal_error createdAt
          items { nama_inventaris qty_return unit harga_beli subtotal alasan }
        }
      }
    }
  ''';

  static const detail = r'''
    query GetOnePurchaseReturn($_id: ID!) {
      GetOnePurchaseReturn(_id: $_id) {
        _id no_return purchase_id no_po supplier_id supplier_name tanggal_return
        lokasi_cabang_id lokasi_cabang_nama return_reason return_reason_label
        catatan return_method return_method_label approval_status approved_at
        rejected_reason total_return_amount ppn_amount grand_total_return
        journal_id journal_status journal_error createdAt updatedAt
        lokasi { cabang_id cabang_nama gedung_kode gedung_nama ruangan_kode ruangan_nama rak_nama label }
        items {
          purchase_item_id receiving_item_id inventaris_id kode_inventaris
          nama_inventaris unit base_unit conversion_factor qty_return
          qty_return_base harga_beli subtotal no_batch alasan
        }
      }
    }
  ''';

  static const searchPurchases = r'''
    query SearchPurchaseOrdersForReturn($search: String!, $limit: Int) {
      SearchPurchaseOrdersForReturn(search: $search, limit: $limit) {
        _id no_po supplier_name grand_total status
      }
    }
  ''';

  static const availability = r'''
    query GetPurchaseReturnSourceAvailability($purchase_id: ID!) {
      GetPurchaseReturnSourceAvailability(purchase_id: $purchase_id) {
        lokasi { cabang_id cabang_nama gedung_kode gedung_nama ruangan_kode ruangan_nama rak_nama label }
        items {
          purchase_item_id inventaris_id kode_inventaris nama_inventaris
          unit base_unit conversion_factor harga_beli no_batch
          available_qty available_qty_base
        }
      }
    }
  ''';

  static const create = r'''
    mutation CreatePurchaseReturn($input: CreatePurchaseReturnInput!) {
      CreatePurchaseReturn(input: $input) { _id no_return approval_status grand_total_return }
    }
  ''';
  static const submit = r'''
    mutation SubmitPurchaseReturnForApproval($_id: ID!) {
      SubmitPurchaseReturnForApproval(_id: $_id) { _id approval_status }
    }
  ''';
  static const approve = r'''
    mutation ApprovePurchaseReturn($_id: ID!, $notes: String) {
      ApprovePurchaseReturn(_id: $_id, notes: $notes) { _id approval_status approved_at }
    }
  ''';
  static const reject = r'''
    mutation RejectPurchaseReturn($_id: ID!, $reason: String!) {
      RejectPurchaseReturn(_id: $_id, reason: $reason) { _id approval_status rejected_reason }
    }
  ''';
  static const process = r'''
    mutation ProcessPurchaseReturn($_id: ID!) {
      ProcessPurchaseReturn(_id: $_id) { _id approval_status journal_id journal_status journal_error }
    }
  ''';
  static const retryJournal = r'''
    mutation RetryPurchaseReturnJournal($_id: ID!) {
      RetryPurchaseReturnJournal(_id: $_id) { _id journal_id journal_status journal_error }
    }
  ''';
  static const update = r'''
    mutation UpdatePurchaseReturn($_id: ID!, $input: UpdatePurchaseReturnInput!) {
      UpdatePurchaseReturn(_id: $_id, input: $input) { _id approval_status return_reason return_method catatan }
    }
  ''';
  static const delete = r'''
    mutation DeletePurchaseReturn($_id: ID!, $reason: String) {
      DeletePurchaseReturn(_id: $_id, reason: $reason)
    }
  ''';
}
