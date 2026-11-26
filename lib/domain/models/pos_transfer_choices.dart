import 'pos_transfer.dart';

enum TransferEditorMode { between, internal }

/// Presentation-only filtering. The server still owns permission, approval,
/// transit, stock allocation and tenant/outlet validation at submission time.
class TransferLocationChoices {
  const TransferLocationChoices({this.policy});
  final Map<String, dynamic>? policy;

  String get _profile => '${policy?['inventory_profile'] ?? 'simple'}';
  bool _uses(String flag) {
    if (policy == null) return true;
    if (_profile == 'custom') return policy?[flag] == true;
    return switch (flag) {
      'use_display_stock' => _profile == 'advanced',
      _ => ['centralized', 'advanced'].contains(_profile),
    };
  }

  bool usable(Map w, {required bool source}) {
    if (policy != null &&
        !['centralized', 'advanced', 'custom'].contains(_profile)) {
      return false;
    }
    if (w['is_active'] == false ||
        w[source ? 'is_transfer_source' : 'is_transfer_destination'] == false) {
      return false;
    }
    final type = w['warehouse_type'];
    if (['in_transit', 'quarantine'].contains(type)) return false;
    if (type == 'store' && !_uses('use_store_warehouse')) return false;
    if (type == 'display' && !_uses('use_display_stock')) return false;
    return '${w['_id'] ?? ''}'.isNotEmpty;
  }

  TransferEditorMode infer(Map? source, Map? destination) {
    final types = [source?['warehouse_type'], destination?['warehouse_type']];
    return (source != null &&
                destination != null &&
                source['_id'] == destination['_id']) ||
            (types.contains('store') && types.contains('display'))
        ? TransferEditorMode.internal
        : TransferEditorMode.between;
  }

  bool allows(Map? source, Map? destination, TransferEditorMode mode) {
    if (source == null ||
        destination == null ||
        !usable(source, source: true) ||
        !usable(destination, source: false)) {
      return false;
    }
    if (transferOutletPairError(source, destination) != null) return false;
    if (infer(source, destination) != mode) return false;
    if (source['_id'] == destination['_id'] &&
        !transferMaps(
          source['gedung'],
        ).any((g) => '${g['kode_gedung'] ?? ''}'.isNotEmpty)) {
      return false;
    }
    final types = [source['warehouse_type'], destination['warehouse_type']];
    final ownDisplay = types.contains('store') && types.contains('display');
    // Match the central warehouse exception exactly; same warehouse rack moves
    // do not create an exception for non-central warehouses.
    if (policy != null &&
        _uses('use_central_warehouse') &&
        !ownDisplay &&
        !types.contains('central')) {
      return false;
    }
    return true;
  }

  List<Map<String, dynamic>> sources(
    List<Map<String, dynamic>> all,
    TransferEditorMode mode,
  ) => all.where((s) => all.any((d) => allows(s, d, mode))).toList();

  List<Map<String, dynamic>> destinations(
    List<Map<String, dynamic>> all,
    Map? source,
    TransferEditorMode mode,
  ) => all.where((d) => allows(source, d, mode)).toList();
}
