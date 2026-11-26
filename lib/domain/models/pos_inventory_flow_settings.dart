/// Shared wire values from InventorySettings, not a second POS configuration.
class PosInventoryFlowPolicy {
  static const profiles = ['simple', 'centralized', 'advanced', 'custom'];
  static const flowFlags = [
    'use_central_warehouse',
    'use_transfer_request',
    'use_transfer_approval',
    'use_in_transit',
    'use_store_warehouse',
    'use_display_stock',
  ];
  static const ruleFields = [
    'transfer_cross_branch_rule',
    'transfer_same_branch_rule',
    'transfer_store_display_rule',
  ];
  static const fields = [
    'inventory_profile',
    ...flowFlags,
    'allow_direct_purchase_to_store',
    'allow_over_receipt',
    'over_receipt_tolerance_percent',
    'default_receiving_location_id',
    'default_transfer_transit_location_id',
    ...ruleFields,
  ];
  final Map<String, dynamic> values;

  PosInventoryFlowPolicy(Map<String, dynamic> json)
    : values = Map.unmodifiable(_normalize(json));

  static Map<String, dynamic> _normalize(Map<String, dynamic> json) {
    final profile = json['inventory_profile'] ?? 'simple';
    if (!profiles.contains(profile)) {
      throw const FormatException('inventoryProfile');
    }
    final flags = <String, dynamic>{
      for (final key in flowFlags)
        key: profile == 'custom'
            ? json[key] == true
            : profile != 'simple' &&
                  (key != 'use_display_stock' || profile == 'advanced'),
    };
    return {
      'inventory_profile': profile,
      ...flags,
      'allow_direct_purchase_to_store': profile == 'custom'
          ? json['allow_direct_purchase_to_store'] != false
          : profile == 'simple',
      'allow_over_receipt': json['allow_over_receipt'] == true,
      'over_receipt_tolerance_percent':
          json['over_receipt_tolerance_percent'] ?? 0,
      for (final key in [
        'default_receiving_location_id',
        'default_transfer_transit_location_id',
      ])
        key: (json[key]?.toString().trim().isEmpty ?? true)
            ? null
            : json[key].toString(),
      for (final key in ruleFields) key: json[key] ?? 'system_default',
    };
  }

  PosInventoryFlowPolicy withProfile(String profile) =>
      PosInventoryFlowPolicy({...values, 'inventory_profile': profile});

  PosInventoryFlowPolicy withValue(String field, dynamic value) {
    if (!fields.contains(field) || field == 'inventory_profile') {
      throw ArgumentError.value(field);
    }
    return PosInventoryFlowPolicy({
      ...values,
      if (flowFlags.contains(field) ||
          field == 'allow_direct_purchase_to_store')
        'inventory_profile': 'custom',
      field: field == 'over_receipt_tolerance_percent' && value == null
          ? double.nan
          : value,
    });
  }

  Map<String, dynamic> patchFrom(PosInventoryFlowPolicy baseline) => {
    for (final key in fields)
      if (values[key] != baseline.values[key]) key: values[key],
  };

  String? validationError({
    required bool trackStock,
    required List<PosInventoryFlowLocation> locations,
    bool prepareTransit = false,
  }) {
    bool enabled(String key) => values[key] == true;
    if (enabled('use_display_stock') && !enabled('use_store_warehouse')) {
      return 'displayRequiresStore';
    }
    if (enabled('use_transfer_approval') && !enabled('use_transfer_request')) {
      return 'approvalRequiresRequest';
    }
    if (enabled('use_in_transit') && !enabled('use_transfer_request')) {
      return 'transitRequiresRequest';
    }
    if (enabled('use_transfer_request') &&
        !enabled('use_central_warehouse') &&
        !enabled('use_store_warehouse')) {
      return 'requestRequiresWarehouse';
    }
    if (!trackStock && flowFlags.any(enabled)) return 'trackingRequired';
    final tolerance = values['over_receipt_tolerance_percent'];
    if (tolerance is! num ||
        !tolerance.isFinite ||
        tolerance < 0 ||
        tolerance > 100) {
      return 'invalidTolerance';
    }
    if (ruleFields.any(
      (key) => !['system_default', 'direct', 'transit'].contains(values[key]),
    )) {
      return 'invalidRule';
    }
    if (!prepareTransit &&
        (enabled('use_in_transit') ||
            ruleFields.any((key) => values[key] == 'transit')) &&
        !locations.any(
          (row) =>
              row.id == values['default_transfer_transit_location_id'] &&
              row.isTransit,
        )) {
      return 'transitRequired';
    }
    if (enabled('use_central_warehouse') &&
        !locations.any(
          (row) => row.active && row.warehouse && row.type == 'central',
        )) {
      return 'centralRequired';
    }
    final receiving = values['default_receiving_location_id'];
    if (receiving != null &&
        !locations.any(
          (row) =>
              row.id == receiving &&
              row.canReceive(
                allowStore: enabled('allow_direct_purchase_to_store'),
              ),
        )) {
      return 'receivingInvalid';
    }
    if (values['inventory_profile'] == 'simple' &&
        receiving == null &&
        locations.where((row) => row.active && row.warehouse).length > 1) {
      return 'receivingRequired';
    }
    return null;
  }
}

class PosInventoryFlowLocation {
  final String id, name, type;
  final bool active, warehouse, receiving;
  const PosInventoryFlowLocation({
    required this.id,
    required this.name,
    required this.type,
    this.active = true,
    this.warehouse = true,
    this.receiving = true,
  });
  factory PosInventoryFlowLocation.fromJson(Map<String, dynamic> json) =>
      PosInventoryFlowLocation(
        id: json['_id'].toString(),
        name: json['nama_cabang']?.toString() ?? '-',
        type: json['warehouse_type']?.toString() ?? '',
        active: json['status'] == 'active',
        warehouse: json['is_warehouse'] == true,
        receiving: json['is_receiving_location'] != false,
      );
  bool get isTransit => active && warehouse && type == 'in_transit';
  bool canReceive({required bool allowStore}) =>
      active &&
      warehouse &&
      receiving &&
      !['display', 'in_transit', 'quarantine'].contains(type) &&
      (allowStore || type != 'store');
}

class PosInventoryFlowSnapshot {
  final String revision, scope;
  final bool canUpdate, trackStock, canCreateLocations;
  final PosInventoryFlowPolicy policy;
  final List<PosInventoryFlowLocation> locations;
  PosInventoryFlowSnapshot.fromJson(
    Map<String, dynamic> json, {
    required this.scope,
    required this.canUpdate,
    this.canCreateLocations = false,
    required List<PosInventoryFlowLocation> locations,
  }) : revision = json['revision']?.toString() ?? '',
       policy = PosInventoryFlowPolicy(
         Map<String, dynamic>.from(
           json['inventory_operation_defaults'] as Map? ?? {},
         ),
       ),
       trackStock = (json['pos_defaults'] as Map?)?['enabled_features'] is Map
           ? ((json['pos_defaults'] as Map)['enabled_features']
                     as Map)['track_stock'] !=
                 false
           : true,
       locations = List.unmodifiable(locations) {
    if (revision.isEmpty) throw const FormatException('missingRevision');
    if (json['inventory_operation_defaults'] is! Map) {
      throw const FormatException('missingPolicy');
    }
  }
}
