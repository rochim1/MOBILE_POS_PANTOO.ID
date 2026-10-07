import 'pos_product.dart';

/// Computes base-unit leaf consumption, including nested BOM/bundles.
/// Missing recipes/ingredients cannot safely be guessed while offline.
Map<String, double> offlineStockConsumption(
  Map<String, PosProduct> catalog,
  Iterable<Map<String, dynamic>> items, {
  bool validateStock = true,
  bool trackStock = true,
}) {
  final result = <String, double>{};
  void consume(String id, double qty, Set<String> path) {
    final product = catalog[id];
    if (product == null) {
      throw StateError(
        'Data bahan/produk belum lengkap. Muat katalog saat online terlebih dahulu.',
      );
    }
    if (!qty.isFinite || qty <= 0 || path.contains(id)) {
      throw StateError('Komposisi atau jumlah produk tidak valid.');
    }
    if (!trackStock) return;
    if (product.packageComponents.isNotEmpty) {
      for (final component in product.packageComponents) {
        final factor = (component['qty_base'] as num?)?.toDouble() ?? 0;
        consume(component['inventaris_id']?.toString() ?? '', qty * factor, {
          ...path,
          id,
        });
      }
    } else if (product.compositionType.isNotEmpty ||
        product.productType == 'package') {
      throw StateError(
        'Resep/paket belum tersedia untuk transaksi offline. Sambungkan ke server.',
      );
    } else if (product.tracksStock) {
      result.update(id, (value) => value + qty, ifAbsent: () => qty);
    }
  }

  for (final item in items) {
    final id = item['inventaris_id']?.toString() ?? '';
    final product = catalog[id];
    if (product == null) {
      throw StateError('Produk belum tersimpan untuk transaksi offline.');
    }
    final unit =
        item['unit']?.toString().trim().toLowerCase() ?? product.saleUnit;
    final conversion = product.unitConversions
        .where((row) => row['unit']?.toString().toLowerCase() == unit)
        .firstOrNull;
    final factor = unit == product.saleUnit
        ? 1.0
        : (conversion?['factor'] as num?)?.toDouble();
    if (factor == null || !factor.isFinite || factor <= 0) {
      throw StateError(
        'Konversi satuan belum tersedia untuk transaksi offline.',
      );
    }
    consume(id, ((item['qty'] as num?)?.toDouble() ?? 0) * factor, {});
  }
  for (final entry in result.entries) {
    if (validateStock && entry.value > catalog[entry.key]!.stock + 0.000001) {
      throw StateError(
        'Stok lokal ${catalog[entry.key]!.name} tidak mencukupi. Periksa stok saat online.',
      );
    }
  }
  return result;
}
