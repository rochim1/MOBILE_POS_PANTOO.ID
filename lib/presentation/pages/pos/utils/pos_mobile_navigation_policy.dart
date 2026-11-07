/// Tujuan tombol kembali di shell mobile. Null berarti halaman utama boleh
/// ditutup oleh sistem.
int? mobilePosBackDestination(int selectedIndex, int secondaryOriginIndex) {
  if (selectedIndex == 0) return null;
  if (selectedIndex < 5) return 0;
  if (secondaryOriginIndex < 0 || secondaryOriginIndex > 4) return 4;
  return secondaryOriginIndex;
}

int mobilePosUnlockDestination(
  Map<String, dynamic> runtime, {
  required bool hasStore,
  required bool hasShift,
  required bool offline,
}) {
  final p = runtime['permissions'] as Map? ?? const {};
  final fallback = p['view_dashboard'] == true ? 0 : 4;
  final withoutShift = runtime['allow_out_of_shift'] == true;
  if (p['use_cashier'] != true || (p['view_shifts'] != true && !withoutShift)) {
    return fallback;
  }
  if (!hasStore) return p['view_stores'] == true ? 10 : fallback;
  if (!hasShift && offline) return fallback;
  if (!hasShift && !withoutShift) return 11;
  return 1;
}
