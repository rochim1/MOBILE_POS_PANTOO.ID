class PosTableQueries {
  static const String getAll = r'''
    query GetAllPOSTable($tokoId: ID!, $search: String, $limit: Int, $page: Int) {
      GetAllPOSTable(toko_id: $tokoId, search: $search, limit: $limit, page: $page) {
        items {
          _id
          toko_id
          name
          capacity
          status
          status_aktif
          active_order_id
          active_order_no
          active_order_status
          active_order_source
          active_customer_name
          active_order_created_at
          active_order_total
          active_order_item_count
          createdAt
          updatedAt
        }
        info_page {
          count
        }
      }
    }
  ''';

  static const String getOne = r'''
    query GetOnePOSTable($_id: ID!, $tokoId: ID!) {
      GetOnePOSTable(_id: $_id, toko_id: $tokoId) {
        _id
        toko_id
        name
        capacity
        status
        status_aktif
        active_order_id
        active_order_no
        active_order_status
        active_order_source
        active_customer_name
        active_order_created_at
        active_order_total
        active_order_item_count
        createdAt
        updatedAt
      }
    }
  ''';

  static const String create = r'''
    mutation CreatePOSTable($tokoId: ID!, $name: String!, $capacity: Int) {
      CreatePOSTable(toko_id: $tokoId, name: $name, capacity: $capacity) {
        _id
        toko_id
        name
        capacity
        status
        status_aktif
        createdAt
        updatedAt
      }
    }
  ''';

  static const String update = r'''
    mutation UpdatePOSTable($_id: ID!, $tokoId: ID!, $name: String, $capacity: Int, $status: String) {
      UpdatePOSTable(_id: $_id, toko_id: $tokoId, name: $name, capacity: $capacity, status: $status) {
        _id
        toko_id
        name
        capacity
        status
        status_aktif
        createdAt
        updatedAt
      }
    }
  ''';

  static const String delete = r'''
    mutation DeletePOSTable($_id: ID!, $tokoId: ID!) {
      DeletePOSTable(_id: $_id, toko_id: $tokoId)
    }
  ''';
}
