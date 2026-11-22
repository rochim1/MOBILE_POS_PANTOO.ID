import '../../../../domain/models/pos_product.dart';

String posServiceIntakeMode(PosProduct product, String profile) {
  if (product.productType != 'service') return 'none';
  if (product.serviceIntakeMode != 'auto') return product.serviceIntakeMode;
  return switch (profile) {
    'bengkel' => 'work_order',
    'laundry' => 'laundry',
    _ => 'none',
  };
}

bool posRequiresWorkIntake(Map<PosProduct, double> cart, String profile) => cart
    .keys
    .any((product) => posServiceIntakeMode(product, profile) == 'work_order');

String? posServiceQuantityProblem(
  Map<PosProduct, double> cart,
  Map<String, dynamic>? data,
) {
  final pieces = (data?['item_count'] as num? ?? 0).toDouble();
  if (!pieces.isFinite || pieces != pieces.truncateToDouble()) {
    return 'Jumlah cucian satuan/paket harus bilangan bulat. Gunakan satuan kg untuk berat pecahan.';
  }
  final lines = (data?['service_lines'] as List? ?? const []).whereType<Map>();
  for (final entry in cart.entries.where(
    (e) => e.key.productType == 'service',
  )) {
    final rows = lines
        .where((row) => row['product_id']?.toString() == entry.key.id)
        .toList();
    if (rows.length < 2) continue;
    final field = rows.first['pricing_basis'] == 'per_kg'
        ? 'weight_kg'
        : 'quantity';
    final quantities = rows
        .map((row) => num.tryParse('${row[field]}')?.toDouble() ?? 0)
        .toList();
    final total = quantities.fold<double>(0, (a, b) => a + b);
    if (quantities.any((q) => !q.isFinite || q <= 0) ||
        (total - entry.value).abs() > .000001) {
      return 'Jumlah objek ${entry.key.name} tidak sesuai keranjang. Periksa detail masing-masing objek.';
    }
  }
  return null;
}

bool posHasWorkDetails(
  Map<PosProduct, double> cart,
  String profile,
  Map<String, dynamic>? data,
) {
  final work = cart.keys
      .where(
        (product) => posServiceIntakeMode(product, profile) == 'work_order',
      )
      .toList();
  if (work.isEmpty) return true;
  if ([
    'service_subject',
    'complaint',
    'vehicle_no',
  ].any((field) => data?[field]?.toString().trim().isNotEmpty == true)) {
    return true;
  }
  final lines = (data?['service_lines'] as List? ?? const []).whereType<Map>();
  return work.every((product) {
    final rows = lines
        .where((line) => line['product_id']?.toString() == product.id)
        .toList();
    return rows.isNotEmpty &&
        rows.every(
          (line) => [
            'tag_code',
            'condition_notes',
          ].any((field) => line[field]?.toString().trim().isNotEmpty == true),
        );
  });
}

Map<String, dynamic>? buildPosServiceIntake(
  Map<PosProduct, double> cart,
  String profile, {
  Map<String, dynamic>? existing,
  bool reservation = false,
  Map<String, String> selectedUnits = const {},
}) {
  final services = cart.entries
      .where((entry) => entry.key.productType == 'service')
      .toList();
  if (services.isEmpty && !reservation) return null;
  final data = <String, dynamic>{...existing ?? {}};
  if (!reservation) data.remove('appointment_at');
  final previous = (data['service_lines'] as List? ?? const [])
      .whereType<Map>()
      .toList();
  final lines = <Map<String, dynamic>>[];
  double kg = 0;
  double pieces = 0;
  for (final entry in services) {
    final product = entry.key;
    final mode = posServiceIntakeMode(product, profile);
    final unit = (selectedUnits[product.id] ?? product.saleUnit)
        .trim()
        .toLowerCase();
    final perKg =
        mode == 'laundry' && const {'kg', 'kilogram', 'kilo'}.contains(unit);
    final basis = perKg
        ? 'per_kg'
        : mode == 'laundry' && const {'paket', 'package'}.contains(unit)
        ? 'package'
        : 'per_item';
    final rows = previous
        .where((line) => line['product_id']?.toString() == product.id)
        .toList();
    for (final old in rows.isEmpty ? <Map>[{}] : rows) {
      lines.add({
        ...old,
        'product_id': product.id,
        'name': product.name,
        'object_type': mode == 'laundry'
            ? 'laundry'
            : mode == 'work_order'
            ? 'service'
            : 'jasa',
        'pricing_basis': basis,
        'quantity': perKg
            ? 0
            : rows.length > 1
            ? old['quantity'] ?? 0
            : entry.value,
        'weight_kg': perKg
            ? rows.length > 1
                  ? old['weight_kg'] ?? 0
                  : entry.value
            : 0,
        'unit': unit,
        'status': old['status'] ?? 'diterima',
      });
    }
    if (mode == 'laundry') {
      if (perKg) {
        kg += entry.value;
      } else {
        pieces += entry.value;
      }
    }
  }
  data['service_type'] ??= profile == 'laundry' ? 'Laundry' : 'Service';
  data['service_lines'] = lines;
  data['weight_kg'] = kg;
  data['item_count'] = pieces;
  data['service_mode'] = kg > 0
      ? 'kiloan'
      : pieces > 0
      ? 'satuan'
      : '';
  return data;
}
