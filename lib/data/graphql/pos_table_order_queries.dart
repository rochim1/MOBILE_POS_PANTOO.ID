class PosTableOrderQueries {
  static const String getActiveOrders = r'''
    query GetActivePOSOrders($filter: POSOrderFilter, $pagination: pagination) {
      GetAllPOSOrder(
        filter: $filter
        sorting: { createdAt: desc }
        pagination: $pagination
      ) {
        items {
          _id order_no pelanggan_id pelanggan_nama status status_pembayaran
          subtotal diskon_amount pajak_amount grand_total catatan kitchen_note handover_note internal_note tipe_pesanan source
          status_history { status at actor_id actor_name note }
          table_id table { _id name }
          items { _id produk_id nama kode qty unit harga_satuan subtotal catatan }
          service_order {
            service_type service_subject service_mode weight_kg item_count promised_at
            bag_tag fragrance finishing condition_notes status
            status_history { status at actor_id actor_name note }
            service_lines { line_id product_id name object_type pricing_basis quantity weight_kg unit unit_price minimum_charge subtotal tag_code brand color material size condition_notes risk_consent promised_at status addons { product_id name qty unit_price subtotal } media { url category note } status_history { status at actor_id actor_name note } }
          }
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
        pelanggan_id
        status
        status_pembayaran
        subtotal
        diskon_amount
        pajak_amount
        grand_total
        catatan kitchen_note handover_note internal_note
        status_history { status at actor_id actor_name note }
        tipe_pesanan
        source
        table_id
        items {
          _id
          produk_id
          nama
          qty
          harga_satuan
          catatan
        }
        service_order {
          service_type service_subject service_mode weight_kg item_count promised_at
          bag_tag fragrance finishing condition_notes status
          status_history { status at actor_id actor_name note }
          service_lines { line_id product_id name object_type pricing_basis quantity weight_kg unit unit_price minimum_charge subtotal tag_code brand color material size condition_notes risk_consent promised_at status addons { product_id name qty unit_price subtotal } media { url category note } status_history { status at actor_id actor_name note } }
        }
        createdAt
      }
    }
  ''';

  static const String updateOrderItemStatus = r'''
    mutation UpdatePOSOrderStatus($orderId: ID!, $status: String!, $note: String) {
      UpdatePOSOrderStatus(_id: $orderId, status: $status, note: $note) {
        _id
        status
      }
    }
  ''';

  static const String updateOrderItems = r'''
    mutation UpdatePOSOrderItems($orderId: ID!, $items: [POSOrderItemInput!]!) {
      UpdatePOSOrderItems(_id: $orderId, items: $items) {
        _id subtotal diskon_amount pajak_amount grand_total
        items { _id produk_id nama kode qty unit harga_satuan subtotal catatan }
      }
    }
  ''';

  static const String updateServiceOrderStatus = r'''
    mutation UpdatePOSServiceOrderStatus($orderId: ID!, $status: String!, $note: String) {
      UpdatePOSServiceOrderStatus(_id: $orderId, status: $status, note: $note) {
        _id
        service_order { status status_history { status at actor_id actor_name note } }
      }
    }
  ''';

  static const String updateServiceLineStatus = r'''
    mutation UpdatePOSServiceLineStatus($orderId: ID!, $lineId: String!, $status: String!, $note: String) {
      UpdatePOSServiceLineStatus(_id: $orderId, line_id: $lineId, status: $status, note: $note) {
        _id
        service_order { status service_lines { line_id name status status_history { status at actor_id actor_name note } } }
      }
    }
  ''';
}
