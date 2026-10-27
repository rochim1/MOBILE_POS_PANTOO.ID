/// Tujuan tombol kembali di shell mobile. Null berarti halaman utama boleh
/// ditutup oleh sistem.
int? mobilePosBackDestination(int selectedIndex, int secondaryOriginIndex) {
  if (selectedIndex == 0) return null;
  if (selectedIndex < 5) return 0;
  if (secondaryOriginIndex < 0 || secondaryOriginIndex > 4) return 4;
  return secondaryOriginIndex;
}
