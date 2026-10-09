/// Formats purchase amounts shown while the operator is editing a document.
/// An incomplete numeric field can temporarily produce a non-finite preview.
String formatPosPurchaseCurrency(double value) {
  if (!value.isFinite) return '—';
  final digits = value.round().toString();
  return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}
