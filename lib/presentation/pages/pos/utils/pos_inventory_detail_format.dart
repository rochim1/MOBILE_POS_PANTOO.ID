import 'package:intl/intl.dart';

String inventoryDocumentDate(dynamic value) {
  final raw = value?.toString() ?? '';
  var parsed = value is DateTime ? value : DateTime.tryParse(raw);
  // The server's GraphQL Date may serialize as a millisecond timestamp string.
  if (parsed == null) {
    final milliseconds = int.tryParse(raw);
    if (milliseconds != null && milliseconds.abs() <= 8640000000000000) {
      parsed = DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
    }
  }
  return parsed == null
      ? (raw.isEmpty ? '-' : raw)
      : DateFormat('dd MMM yyyy', 'id_ID').format(parsed.toLocal());
}

String opnameRowsSummary(Iterable<Map> rows) {
  final list = rows.toList();
  final products = list
      .map((row) => row['inventaris_id']?.toString() ?? '')
      .where((id) => id.isNotEmpty)
      .toSet();
  return '${list.length} saldo lokasi • ${products.length} jenis barang';
}
