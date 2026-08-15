class PosTableOrderQueries {
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
