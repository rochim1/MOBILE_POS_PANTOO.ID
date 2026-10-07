List<Map<String, dynamic>> matchInventoryBarcode(
  Iterable<Map<String, dynamic>> items,
  String rawCode,
) {
  final code = rawCode.trim().toLowerCase();
  if (code.isEmpty) return const [];
  return items.where((item) {
    return [
      item['barcode'],
      item['sku'],
      item['kode_inventaris'],
    ].any((value) => value?.toString().trim().toLowerCase() == code);
  }).toList();
}
