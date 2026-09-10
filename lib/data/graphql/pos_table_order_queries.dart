class PosTableOrderQueries {
  static const String getActiveOrders = r'''
    query GetActivePOSOrders($filter: POSOrderFilter, $pagination: pagination) {
      GetAllPOSOrder(
        filter: $filter
        sorting: { createdAt: desc }
        pagination: $pagination
      ) {
        items {
          _id order_no pelanggan_nama status status_pembayaran grand_total
          table_id table { _id name }
          items { _id nama qty harga_satuan subtotal catatan }
          createdAt
        }
      }
    }
  ''';

  static const String getOrdersByTable = r'''
    query GetPOSOrderByTable($tableId: ID!) {
      GetPOSOrderByTable(table_id: $tableId) {
        _id
        order_no
        pelanggan_nama
        status
        grand_total
        table_id
        items {
          _id
          produk_id
          nama
          qty
          harga_satuan
          catatan
        }
        createdAt
      }
    }
  ''';

  static const String updateOrderItemStatus = r'''
    mutation UpdatePOSOrderStatus($orderId: ID!, $status: String!) {
      UpdatePOSOrderStatus(_id: $orderId, status: $status) {
        _id
        status
      }
    }
  ''';
}
