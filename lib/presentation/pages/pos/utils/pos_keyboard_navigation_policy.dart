/// Mirrors the visible sidebar destinations so keyboard shortcuts cannot
/// reveal a page that is hidden for the current operator or POS profile.
bool canOpenPosKeyboardDestination(
  Map<String, dynamic> runtimeConfig,
  int index,
) {
  final permissions = Map<String, dynamic>.from(
    runtimeConfig['permissions'] as Map? ?? const {},
  );
  final features = Map<String, dynamic>.from(
    runtimeConfig['features'] as Map? ?? const {},
  );
  bool can(String key) => permissions[key] == true;

  return switch (index) {
    0 => can('view_dashboard'),
    1 => can('use_cashier'),
    2 => can('view_products'),
    3 => can('view_transactions'),
    5 =>
      features['use_tables'] == true &&
          (can('view_tables') || can('manage_tables')),
    7 =>
      (features['track_stock'] != false &&
              (can('view_stock') || can('adjust_stock'))) ||
          can('view_inventory_purchases') ||
          can('view_inventory_opnames') ||
          can('view_inventory_transfers') ||
          can('view_inventory_scraps') ||
          can('view_purchase_returns'),
    _ => false,
  };
}
