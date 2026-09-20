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
          reservation_status reservation_start_at reservation_end_at reservation_guest_count reservation_deposit_amount reservation_deposit_paid
          status_history { status at actor_id actor_name note }
          table_id table { _id name }
          items { _id produk_id nama kode qty unit harga_satuan subtotal catatan preparation_mode production_station_id production_station_name prep_time_minutes production_status revision }
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
        reservation_status reservation_start_at reservation_end_at reservation_guest_count reservation_deposit_amount reservation_deposit_paid
        source
        table_id
        items {
          _id
          produk_id
          nama
          qty
          harga_satuan
          catatan
          preparation_mode
          production_station_id
          production_station_name
          prep_time_minutes
          production_status
          revision
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
    mutation UpdatePOSOrderItemProductionStatus($orderId: ID!, $itemId: ID!, $status: String!, $note: String, $expectedRevision: Int) {
      UpdatePOSOrderItemProductionStatus(_id: $orderId, item_id: $itemId, status: $status, note: $note, expected_revision: $expectedRevision) {
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

  static const String updateReservationStatus = r'''
    mutation UpdatePOSReservationStatus($orderId: ID!, $status: String!, $note: String) {
      UpdatePOSReservationStatus(_id: $orderId, status: $status, note: $note) {
        _id reservation_status status
      }
    }
  ''';

  static const String rescheduleReservation = r'''
    mutation ReschedulePOSReservation($orderId: ID!, $startAt: String!, $endAt: String!, $tableId: ID, $guestCount: Int) {
      ReschedulePOSReservation(_id: $orderId, start_at: $startAt, end_at: $endAt, table_id: $tableId, guest_count: $guestCount) {
        _id table_id reservation_status reservation_start_at reservation_end_at reservation_guest_count
      }
    }
  ''';
}
