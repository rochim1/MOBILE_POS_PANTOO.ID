import 'dart:convert';
import 'package:crypto/crypto.dart';

double transferNumber(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? double.nan;
List<Map<String, dynamic>> transferMaps(dynamic value) => (value as List? ?? [])
    .whereType<Map>()
    .map((v) => Map<String, dynamic>.from(v))
    .toList();
Map<String, dynamic> transferLocation(Map location) => {
  for (final key in const [
    'cabang_id',
    'cabang_nama',
    'gedung_kode',
    'gedung_nama',
    'ruangan_kode',
    'ruangan_nama',
    'rak_nama',
  ])
    if (location[key] != null) key: location[key],
};
Map<String, dynamic> _fields(Map source, List<String> keys) => {
  for (final key in keys)
    if (source.containsKey(key)) key: source[key],
};
Map<String, dynamic> transferInput(Map document) => {
  ..._fields(document, [
    'tanggal_transfer',
    'requires_approval',
    'catatan',
    'biaya_mode',
    'biaya_alokasi',
    'payment_bank_account_id',
    'payment_branch_id',
    'branch_id',
    'project_id',
  ]),
  'dari': transferLocation(document['dari'] as Map? ?? {}),
  'ke': transferLocation(document['ke'] as Map? ?? {}),
  'items': transferMaps(document['items'])
      .map(
        (row) => {
          ..._fields(row, [
            'inventaris_id',
            'nama_inventaris',
            'kode_inventaris',
            'unit',
            'qty',
            'batch_id',
            'no_batch',
            'tanggal_kadaluarsa',
            'serial_numbers',
            'catatan_item',
          ]),
          'unit_breakdown': transferMaps(
            row['unit_breakdown'],
          ).map((u) => _fields(u, ['unit', 'factor', 'input_qty'])).toList(),
        },
      )
      .toList(),
  'biaya_transfer': transferMaps(document['biaya_transfer'])
      .map(
        (row) => _fields(row, [
          'jenis_biaya',
          'deskripsi',
          'nominal',
          'akun_beban',
          'akun_beban_nama',
        ]),
      )
      .toList(),
};
String transferBatchKey(Map row) =>
    '${row['batch_id'] ?? row['no_batch']}::${row['tanggal_kadaluarsa'] ?? ''}';

List<Map<String, dynamic>> transferRemainingRows(Map document) {
  return transferMaps(document['items'])
      .map((item) {
        final pending = transferMaps(document['discrepancies'])
            .where((d) => d['status'] == 'pending')
            .expand((d) => transferMaps(d['items']))
            .where((r) => '${r['item_id']}' == '${item['_id']}')
            .toList();
        final allSerials = (item['serial_numbers'] as List? ?? [])
            .map((s) => '$s')
            .toList();
        final received = (item['received_serial_numbers'] as List? ?? []);
        final used = <dynamic>[
          ...(received.isNotEmpty
              ? received.cast<String>()
              : allSerials.take(
                  transferNumber(item['received_qty'] ?? 0).toInt(),
                )),
          ...(item['resolved_serial_numbers'] as List? ?? []),
          ...pending.expand((r) => r['serial_numbers'] as List? ?? []),
        ].map((s) => '$s'.toLowerCase()).toSet();
        final taken = <String, double>{};
        for (final row in [
          ...transferMaps(item['received_batch_allocations']),
          ...transferMaps(item['resolved_batch_allocations']),
          ...pending.expand((r) => transferMaps(r['batch_allocations'])),
        ]) {
          final key = transferBatchKey(row);
          taken[key] = (taken[key] ?? 0) + transferNumber(row['qty'] ?? 0);
        }
        return <String, dynamic>{
          'item_id': item['_id'],
          'name':
              item['nama_inventaris'] ?? item['kode_inventaris'] ?? 'Barang',
          'unit': item['unit'] ?? 'unit',
          'qty':
              (transferNumber(item['qty'] ?? 0) -
                      transferNumber(item['received_qty'] ?? 0) -
                      transferNumber(item['resolved_qty'] ?? 0) -
                      pending.fold<double>(
                        0,
                        (n, r) => n + transferNumber(r['qty'] ?? 0),
                      ))
                  .clamp(0, double.infinity),
          'serials': allSerials
              .where((s) => !used.contains(s.toLowerCase()))
              .toList(),
          'batches': transferMaps(item['batch_allocations'])
              .map(
                (b) => {
                  ...b,
                  'qty':
                      (transferNumber(b['qty']) -
                              (taken[transferBatchKey(b)] ?? 0))
                          .clamp(0, double.infinity),
                },
              )
              .where((b) => (b['qty'] as num) > 0.000001)
              .toList(),
        };
      })
      .where((r) => (r['qty'] as num) > 0.000001)
      .toList();
}

String? validateTransferSelection(
  Map remaining,
  double qty,
  List<String> serials,
  List<Map<String, dynamic>> batches,
) {
  if (!qty.isFinite ||
      qty < 0 ||
      qty > transferNumber(remaining['qty']) + 0.000001) {
    return 'Jumlah harus nol atau positif dan tidak melebihi sisa tersedia.';
  }
  if (qty == 0) return null;
  final allowedSerials = (remaining['serials'] as List? ?? [])
      .map((s) => '$s'.toLowerCase())
      .toSet();
  final selectedSerials = serials.map((s) => s.toLowerCase()).toSet();
  if (allowedSerials.isNotEmpty &&
      (qty != qty.truncateToDouble() ||
          serials.length != qty ||
          selectedSerials.length != serials.length ||
          !allowedSerials.containsAll(selectedSerials))) {
    return 'Pilih nomor seri aktual, satu seri per unit, dari sisa transfer.';
  }
  if (allowedSerials.isEmpty && serials.isNotEmpty) {
    return 'Nomor seri tidak termasuk transfer.';
  }
  final allowed = {
    for (final b in transferMaps(remaining['batches']))
      transferBatchKey(b): transferNumber(b['qty']),
  };
  if (allowed.isNotEmpty || batches.isNotEmpty) {
    final seen = <String>{};
    var total = 0.0;
    for (final batch in batches) {
      final key = transferBatchKey(batch),
          amount = transferNumber(batch['qty']);
      if (!seen.add(key) ||
          !allowed.containsKey(key) ||
          !amount.isFinite ||
          amount <= 0 ||
          amount > allowed[key]! + 0.000001) {
        return 'Identitas/jumlah batch tidak sesuai sisa transfer.';
      }
      total += amount;
    }
    if ((total - qty).abs() > 0.000001) {
      return 'Total jumlah batch harus sama dengan jumlah diterima/dilaporkan.';
    }
  }
  return null;
}

String? validateTransferDraft(Map draft) {
  final from = transferLocation(draft['dari'] as Map? ?? {}),
      to = transferLocation(draft['ke'] as Map? ?? {});
  if ('${from['cabang_id'] ?? ''}'.isEmpty ||
      '${to['cabang_id'] ?? ''}'.isEmpty) {
    return 'Pilih lokasi asal dan tujuan.';
  }
  if ([
    'cabang_id',
    'gedung_kode',
    'ruangan_kode',
    'rak_nama',
  ].every((k) => (from[k] ?? '') == (to[k] ?? ''))) {
    return 'Lokasi asal dan tujuan harus berbeda.';
  }
  final items = transferMaps(draft['items']);
  if (items.isEmpty) return 'Tambahkan minimal satu barang.';
  final sentSerials = <String>{};
  for (final row in items) {
    final qty = transferNumber(row['qty']);
    if (!qty.isFinite || qty <= 0) return 'Jumlah barang harus positif.';
    final serials = (row['serial_numbers'] as List? ?? [])
        .map((s) => '$s'.toLowerCase())
        .toList();
    for (final serial in serials) {
      if (!sentSerials.add('${row['inventaris_id']}:$serial')) {
        return 'Nomor seri barang tidak boleh dipakai di dua baris.';
      }
    }
    final conversions = transferMaps(row['unit_breakdown']);
    if (conversions.isNotEmpty) {
      var total = 0.0;
      for (final conversion in conversions) {
        final factor = transferNumber(conversion['factor']);
        final amount = transferNumber(conversion['input_qty']);
        if (!factor.isFinite || factor <= 0 || !amount.isFinite || amount < 0) {
          return 'Konversi satuan tidak valid.';
        }
        total += factor * amount;
      }
      if ((total - qty).abs() > 0.000001) {
        return 'Total konversi satuan harus sama dengan jumlah barang.';
      }
    }
    if ((serials.isNotEmpty || row['wajib_serial_number'] == true) &&
        (serials.length != qty || serials.toSet().length != serials.length)) {
      return 'Jumlah nomor seri unik harus sesuai jumlah barang.';
    }
  }
  var cost = 0.0;
  for (final row in transferMaps(draft['biaya_transfer'])) {
    final amount = transferNumber(row['nominal']);
    if (!amount.isFinite || amount < 0 || amount != amount.truncateToDouble()) {
      return 'Biaya harus Rupiah bulat, nol atau positif.';
    }
    cost += amount;
  }
  if (cost > 0 && '${draft['payment_bank_account_id'] ?? ''}'.isEmpty) {
    return 'Pilih rekening pembayaran biaya transfer.';
  }
  return null;
}

String transferRequestId(
  String action,
  String id,
  dynamic revision,
  Object payload,
) {
  dynamic canonical(dynamic value) {
    if (value is Map) {
      final keys = value.keys.map((k) => '$k').toList()..sort();
      return {for (final key in keys) key: canonical(value[key])};
    }
    if (value is List) return value.map(canonical).toList();
    return value;
  }

  return 'mobile-transfer-$action-${sha256.convert(utf8.encode(jsonEncode(canonical([id, revision, payload]))))}';
}

String transferToday([DateTime? now]) => (now ?? DateTime.now())
    .toUtc()
    .add(const Duration(hours: 7))
    .toIso8601String()
    .split('T')
    .first;

String? transferReceiptDatesError(
  Map document,
  String received,
  String posting, {
  String? today,
}) {
  bool valid(String raw) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(raw)) return false;
    final value = DateTime.tryParse('${raw}T00:00:00Z');
    return value != null && value.toIso8601String().substring(0, 10) == raw;
  }

  if (!valid(received) || !valid(posting)) {
    return 'Isi tanggal fisik dan pembukuan yang valid (YYYY-MM-DD).';
  }
  final current = today ?? transferToday();
  if (received.compareTo(current) > 0 || posting.compareTo(current) > 0) {
    return 'Tanggal tidak boleh di masa depan.';
  }
  final sent =
      (document['dispatch_posting_date'] ?? document['tanggal_transfer'])
          ?.toString();
  if (sent != null && received.compareTo(sent) < 0) {
    return 'Tanggal fisik tidak boleh sebelum pengiriman $sent.';
  }
  if (posting.compareTo(received) < 0) {
    return 'Tanggal pembukuan tidak boleh sebelum penerimaan fisik.';
  }
  final dates = <String>[if (sent != null) sent];
  for (final row in [
    ...transferMaps(document['receipts']),
    ...transferMaps(
      document['discrepancies'],
    ).where((r) => r['status'] == 'approved'),
  ]) {
    final stored = row['posting_date']?.toString();
    if (stored != null && stored.isNotEmpty) {
      dates.add(stored);
      continue;
    }
    final raw = (row['received_at'] ?? row['decided_at'])?.toString();
    final epoch = int.tryParse(raw ?? '');
    final date = epoch != null && epoch.abs() <= 8640000000000000
        ? DateTime.fromMillisecondsSinceEpoch(epoch, isUtc: true)
        : DateTime.tryParse(raw ?? '');
    if (date != null) dates.add(transferToday(date));
  }
  dates.sort();
  if (dates.isNotEmpty && posting.compareTo(dates.last) < 0) {
    return 'Tanggal pembukuan mendahului perpindahan/penyelesaian sebelumnya (${dates.last}).';
  }
  return null;
}
