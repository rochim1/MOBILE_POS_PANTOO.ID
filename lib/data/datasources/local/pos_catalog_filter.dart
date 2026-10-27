import 'dart:convert';

/// Only constant SQL fragments are generated; user text remains bound values.
class PosCatalogFilter {
  final List<String> clauses = [];
  final List<Object?> args = [];
  PosCatalogFilter(String search, String category, Set<String> favorites) {
    final term = search.trim();
    if (term.isNotEmpty) {
      final escaped = term
          .replaceAll('\\', '\\\\')
          .replaceAll('%', '\\%')
          .replaceAll('_', '\\_');
      clauses.add(
        "(name LIKE ? ESCAPE '\\' OR code LIKE ? ESCAPE '\\' OR sku LIKE ? ESCAPE '\\' OR barcode LIKE ? ESCAPE '\\')",
      );
      args.addAll(List.filled(4, '%$escaped%'));
    }
    switch (category) {
      case 'Semua Kategori':
        break;
      case 'Favorit':
        // Avoid SQLite's parameter limit for large favorite sets.
        clauses.add('id IN (SELECT value FROM json_each(?))');
        args.add(jsonEncode(favorites.toList()));
        break;
      case 'Produk Paket':
        clauses.add('product_type = ?');
        args.add('package');
        break;
      case 'Produk Layanan':
        clauses.add('product_type = ?');
        args.add('service');
        break;
      case 'Deposit':
        clauses.add('product_type = ?');
        args.add('deposit');
        break;
      case 'Promo':
        clauses.add('promo_eligible = 1');
        break;
      default:
        clauses.add('category = ?');
        args.add(category);
    }
  }
  String get where => clauses.isEmpty ? '1=1' : clauses.join(' AND ');
}
