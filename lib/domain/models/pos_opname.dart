import 'pos_stock.dart';

class PosOpnameTarget {
  final String inventoryId;
  final String balanceId;
  final String name;
  final Map<String, dynamic> location;
  const PosOpnameTarget({
    required this.inventoryId,
    required this.balanceId,
    required this.name,
    required this.location,
  });

  factory PosOpnameTarget.fromBalance(
    PosStock stock,
    Map<String, dynamic> balance,
  ) {
    if (stock.id.isEmpty ||
        (balance['_id']?.toString() ?? '').isEmpty ||
        (balance['lokasi_cabang_id']?.toString() ?? '').isEmpty) {
      throw const FormatException('Pilih barang dan saldo lokasi yang valid.');
    }
    return PosOpnameTarget(
      inventoryId: stock.id,
      balanceId: balance['_id'].toString(),
      name: stock.namaInventaris,
      location: {
        for (final key in [
          'cabang_id',
          'cabang_nama',
          'gedung_kode',
          'gedung_nama',
          'ruangan_kode',
          'ruangan_nama',
          'rak_nama',
        ])
          key: balance['lokasi_$key'] ?? '',
      },
    );
  }
}

double opnameNumber(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? double.nan;

String opnameRowKey(Map<String, dynamic> item, int index) =>
    (item['stock_balance_id']?.toString().isNotEmpty ?? false)
    ? 'balance:${item['stock_balance_id']}'
    : 'legacy:${item['_id'] ?? item['inventaris_id']}:$index';

Map<String, dynamic> editableOpnameRow(Map<String, dynamic> item) {
  final batches = (item['batch_counts'] as List? ?? [])
      .whereType<Map>()
      .map((b) => Map<String, dynamic>.from(b))
      .toList();
  final system = opnameNumber(item['qty_system'] ?? 0);
  final tracked = batches.fold<double>(
    0,
    (n, b) => n + opnameNumber(b['qty_system'] ?? 0),
  );
  final unbatched = opnameNumber(
    item['qty_unbatched_system'] ??
        (system - tracked).clamp(0, double.infinity),
  );
  return {
    ...item,
    'batch_counts': batches,
    'input_qty': opnameNumber(item['qty_fisik'] ?? system),
    'qty_unbatched_system': unbatched,
    'qty_unbatched_fisik': opnameNumber(
      item['qty_unbatched_fisik'] ?? unbatched,
    ),
  };
}

double opnamePhysicalTotal(Map<String, dynamic> item) =>
    (item['batch_counts'] as List? ?? []).whereType<Map>().fold<double>(
      opnameNumber(item['qty_unbatched_fisik'] ?? 0),
      (n, b) => n + opnameNumber(b['qty_fisik']),
    );

bool opnameHasDifference(Map<String, dynamic> item) =>
    (opnameNumber(item['input_qty']) - opnameNumber(item['qty_system'] ?? 0))
            .abs() >
        0.000001 ||
    (item['batch_counts'] as List? ?? []).whereType<Map>().any(
      (b) =>
          (opnameNumber(b['qty_fisik']) - opnameNumber(b['qty_system'] ?? 0))
              .abs() >
          0.000001,
    );

String? validateOpnameRows(Iterable<Map<String, dynamic>> rows) {
  final list = rows.toList(), balances = <String>{}, products = <String, int>{};
  for (final row in list) {
    final id = row['inventaris_id']?.toString() ?? '';
    products[id] = (products[id] ?? 0) + 1;
  }
  for (final row in list) {
    final balance = row['stock_balance_id']?.toString() ?? '',
        product = row['inventaris_id']?.toString() ?? '';
    if (product.isEmpty || (balance.isEmpty && products[product]! > 1)) {
      return 'Snapshot rak ambigu. Buat opname baru sebelum menghitung.';
    }
    if (balance.isNotEmpty && !balances.add(balance)) {
      return 'Saldo rak tidak boleh duplikat.';
    }
    final batches = (row['batch_counts'] as List? ?? [])
        .whereType<Map>()
        .toList();
    final quantities = [
      row['input_qty'],
      ...batches.map((b) => b['qty_fisik']),
      if (batches.isNotEmpty) row['qty_unbatched_fisik'] ?? 0,
    ];
    if (quantities.any(
      (q) => !opnameNumber(q).isFinite || opnameNumber(q) < 0,
    )) {
      return 'Isi semua jumlah fisik dengan angka nol atau lebih.';
    }
    if (row['use_conversion'] == true &&
        (row['available_units'] as List? ?? []).whereType<Map>().any((unit) {
          final qty = opnameNumber(unit['input_qty']);
          final factor = opnameNumber(unit['factor']);
          return !qty.isFinite || qty < 0 || !factor.isFinite || factor <= 0;
        })) {
      return 'Isi jumlah kemasan nol atau lebih dan faktor konversi yang valid.';
    }
    if (opnameHasDifference(row) &&
        (row['catatan_item']?.toString().trim().length ?? 0) < 3) {
      return 'Isi alasan selisih ${row['nama_inventaris'] ?? 'barang'} minimal 3 karakter.';
    }
  }
  return null;
}

Map<String, dynamic> opnameCountInput(Map<String, dynamic> item) => {
  'inventaris_id': item['inventaris_id'],
  if (item['stock_balance_id'] != null)
    'stock_balance_id': item['stock_balance_id'],
  'qty_system': item['qty_system'] ?? 0,
  'qty_fisik': item['input_qty'],
  if ((item['batch_counts'] as List? ?? []).isNotEmpty)
    'qty_unbatched_fisik': item['qty_unbatched_fisik'] ?? 0,
  'nama_inventaris': item['nama_inventaris'],
  'kode_inventaris': item['kode_inventaris'],
  'unit': item['base_unit'] ?? item['unit'],
  'batch_counts': (item['batch_counts'] as List? ?? [])
      .whereType<Map>()
      .map(
        (b) => {
          if (b['batch_id'] != null) 'batch_id': b['batch_id'],
          'no_batch': b['no_batch'],
          'tanggal_kadaluarsa': b['tanggal_kadaluarsa'] ?? '',
          'qty_system': b['qty_system'] ?? 0,
          'qty_fisik': b['qty_fisik'],
        },
      )
      .toList(),
  if (item['use_conversion'] == true)
    'unit_breakdown': (item['available_units'] as List? ?? [])
        .whereType<Map>()
        .where((u) => opnameNumber(u['input_qty'] ?? 0) > 0)
        .map(
          (u) => {
            'unit': u['unit'],
            'factor': u['factor'],
            'input_qty': u['input_qty'],
          },
        )
        .toList(),
  'catatan_item': item['catatan_item'] ?? '',
};

String opnameLocationLabel(Map? location) =>
    ['cabang_nama', 'gedung_kode', 'ruangan_kode', 'rak_nama']
        .map((key) => location?[key]?.toString() ?? '')
        .where((text) => text.isNotEmpty)
        .join(' / ');

// GraphQL response maps include __typename; input objects accept only these fields.
Map<String, dynamic> opnameLocationInput(Map location) => {
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

List<Map<String, dynamic>> opnameScanCatalog(
  Iterable<Map<String, dynamic>> rows,
) {
  final unique = <String, Map<String, dynamic>>{};
  for (final row in rows) {
    unique.putIfAbsent(row['inventaris_id'].toString(), () => row);
  }
  return unique.values.toList();
}
