import 'pos_order_workspace_policy.dart';

/// Navbar controls describe the visible workspace, never a hidden page behind
/// a setup/subscription overlay. UI visibility is not an authorization bypass.
class PosNavbarActionPolicy {
  const PosNavbarActionPolicy(
    this.runtime, {
    required this.page,
    this.showSetupGuide = false,
    this.locked = false,
    this.pageBodyEnabled = true,
    this.inventorySection = 'stock',
  });
  final Map<String, dynamic> runtime;
  final int page;
  final bool showSetupGuide, locked, pageBodyEnabled;
  final String? inventorySection;
  Map get _permissions => runtime['permissions'] as Map? ?? const {};
  Map get _features => runtime['features'] as Map? ?? const {};
  bool _can(String name) => _permissions[name] == true;
  bool get _pageVisible => !locked && pageBodyEnabled && !showSetupGuide;
  bool get _cashier => _pageVisible && page == 1 && _can('use_cashier');
  bool get keyboardHelp => _cashier;
  bool get customerDisplay => _cashier;
  bool get setupGuide => !locked && pageBodyEnabled && showSetupGuide;
  bool get notifications => !locked;
  bool get lock => !locked && runtime['pos_lock_enabled'] != false;
  bool get hasOverflow => keyboardHelp || customerDisplay || setupGuide || lock;
  bool get layoutToggle =>
      _pageVisible &&
      switch (page) {
        1 => _can('use_cashier'),
        2 => _can('view_products'),
        3 => _can('view_transactions'),
        5 || 6 =>
          _can('view_tables') ||
              (_features['use_tables'] == true && _can('manage_tables')),
        7 =>
          inventorySection == 'stock' &&
              _features['track_stock'] != false &&
              (_can('view_stock') || _can('adjust_stock')),
        _ => false,
      };
  int? get orderDestination {
    if (!_cashier) return null;
    if (_can('view_tables') && PosOrderWorkspacePolicy(runtime).visible) {
      return 5;
    }
    return _can('view_transactions') ? 3 : null;
  }
}
