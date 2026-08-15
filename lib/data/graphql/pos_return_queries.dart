class PosReturnQueries {
  static const String getAllSalesReturns = r'''
    query GetAllSalesReturns($filter: SalesReturnFilterInput, $pagination: PaginationInput) {
      GetAllSalesReturns(filter: $filter, pagination: $pagination) {
        items {
          _id
          no_retur
          tanggal_retur
          sumber
          sumber_no
          customer_name
          total_refund
          alasan
          metode_refund
          status
          items {
            _id
            inventaris_id
            nama_inventaris
            qty_returned
            qty_original
            unit
            harga_jual
            kondisi
            masuk_ke_stok
            subtotal_refund
          }
        }
        totalCount
      }
    }
  ''';

  static const String createSalesReturn = r'''
    mutation CreateSalesReturn($input: SalesReturnInput!) {
      CreateSalesReturn(input: $input) {
        _id
        no_retur
        status
        total_refund
      }
    }
  ''';

  static const String approveSalesReturn = r'''
    mutation ApproveSalesReturn($_id: ID!, $catatan: String) {
      ApproveSalesReturn(_id: $_id, catatan: $catatan) {
        _id
        status
      }
    }
  ''';

  static const String rejectSalesReturn = r'''
    mutation RejectSalesReturn($_id: ID!, $catatan: String!) {
      RejectSalesReturn(_id: $_id, catatan: $catatan) {
        _id
        status
      }
    }
  ''';

  static const String processSalesReturn = r'''
    mutation ProcessSalesReturn($_id: ID!) {
      ProcessSalesReturn(_id: $_id) {
        _id
        status
      }
    }
  ''';

  static const String deleteSalesReturn = r'''
    mutation DeleteSalesReturn($_id: ID!) {
      DeleteSalesReturn(_id: $_id) {
        success
        message
      }
    }
  ''';
}
