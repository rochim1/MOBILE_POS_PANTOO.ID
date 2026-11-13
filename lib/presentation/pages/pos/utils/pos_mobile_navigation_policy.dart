/// Tujuan tombol kembali di shell mobile. Null berarti halaman utama boleh
/// ditutup oleh sistem.
int? mobilePosBackDestination(
  int selectedIndex,
  int secondaryOriginIndex, {
  int primaryIndex = 1,
}) {
  if (selectedIndex == primaryIndex) return null;
  if (selectedIndex < 5 || selectedIndex == 12) return primaryIndex;
  if (secondaryOriginIndex == 0) return primaryIndex;
  if (secondaryOriginIndex == 12) return 12;
  if (secondaryOriginIndex < 1 || secondaryOriginIndex > 4) return 4;
  return secondaryOriginIndex;
}

int mobilePosUnlockDestination(
  Map<String, dynamic> runtime, {
  required bool hasStore,
  required bool hasShift,
  required bool offline,
}) {
  final p = runtime['permissions'] as Map? ?? const {};
  const fallback = 4;
  final withoutShift = runtime['allow_out_of_shift'] == true;
  if (p['use_cashier'] != true || (p['view_shifts'] != true && !withoutShift)) {
    return fallback;
  }
  if (!hasStore) return p['view_stores'] == true ? 10 : fallback;
  if (!hasShift && offline) return fallback;
  if (!hasShift && !withoutShift) return 11;
  return 1;
}
