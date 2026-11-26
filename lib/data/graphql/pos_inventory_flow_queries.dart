class PosInventoryFlowQueries {
  static const fields = '''
    revision
    pos_defaults { enabled_features { track_stock } }
    inventory_operation_defaults {
      inventory_profile use_central_warehouse use_transfer_request
      use_transfer_approval use_in_transit use_store_warehouse use_display_stock
      allow_direct_purchase_to_store allow_over_receipt over_receipt_tolerance_percent
      default_receiving_location_id default_transfer_transit_location_id
      transfer_cross_branch_rule transfer_same_branch_rule transfer_store_display_rule
    }
  ''';
  // No app_tab filter: inventory_settings is an Inventory permission, not POS.
  static const permissions = '''query InventoryFlowPermissions {
    GetMyPermissions { is_full_access merged_permissions { module actions } }
  }''';
  static const settings =
      '''
    query InventoryFlowSettings { GetInventorySettings { $fields } }
  ''';
  static const save =
      '''mutation InventoryFlowSave(\$input: InventorySettingsInput!) {
    UpdateInventorySettings(input: \$input) { $fields }
  }''';
  static const locations = '''query InventoryFlowLocations(\$page: Int!) {
    getAllCabangs(filter: {status: "active", has_warehouse: true}, pagination: {page: \$page, limit: 200}) {
      info_page { count }
      cabang { _id nama_cabang warehouse_type status is_warehouse is_receiving_location }
    }
  }''';
}
