String posServicePricingBasis(String profile, String mode) {
  if (profile != 'laundry') return 'per_item';
  return switch (mode) {
    'kiloan' => 'per_kg',
    'paket' => 'package',
    _ => 'per_item',
  };
}

String posServiceQuantitySummary(Map service) {
  final mode = service['service_mode']?.toString() ?? '';
  final count = '${service['item_count'] ?? 0} item';
  if (mode == 'satuan' || mode == 'paket') return count;
  return '${service['weight_kg'] ?? 0} kg · $count';
}
