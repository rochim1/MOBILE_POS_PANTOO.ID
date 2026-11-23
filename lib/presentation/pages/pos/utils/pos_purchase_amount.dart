/// Formats purchase amounts shown while the operator is editing a document.
/// An incomplete numeric field can temporarily produce a non-finite preview.
String formatPosPurchaseCurrency(double value) {
  if (!value.isFinite) return '—';
  final digits = value.round().toString();
  return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}

/// Prices on a PO are per selected purchase unit, not always per base unit.
/// Rescale the current price so a cashier's negotiated price is retained.
bool changePosPurchaseUnit(Map<String, dynamic> item, String nextUnit) {
  final base = (item['base_unit'] ?? 'unit').toString();
  final factors = <String, double>{base: 1};
  for (final row in item['unit_conversions'] as List? ?? const []) {
    if (row is! Map) continue;
    final factor = (row['factor'] as num?)?.toDouble() ?? 0;
    final unit = row['unit']?.toString() ?? '';
    if (unit.isNotEmpty && unit != base && factor.isFinite && factor > 0) {
      factors[unit] = factor;
    }
  }
  final previous = (item['unit'] ?? base).toString();
  final from = factors[previous], to = factors[nextUnit];
  if (from == null || to == null) return false;
  final price = (item['input_price'] as num?)?.toDouble() ?? 0;
  item['unit'] = nextUnit;
  item['input_price'] = price / from * to;
  return true;
}
