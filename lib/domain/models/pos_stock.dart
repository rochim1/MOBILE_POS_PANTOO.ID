import 'package:equatable/equatable.dart';

class PosStock extends Equatable {
  final String id;
  final String kodeInventaris;
  final String namaInventaris;
  final String kategori;
  final double hargaJual;
  final double hargaPokok;
  final double stok;
  final double stokMinimum;
  final String sku;
  final String unit;
  final String status;
  final String? stockBalanceId;
  final int locationCount;
  final bool requiresBatchAdjustment;

  const PosStock({
    required this.id,
    required this.kodeInventaris,
    required this.namaInventaris,
    required this.kategori,
    required this.hargaJual,
    required this.hargaPokok,
    required this.stok,
    required this.stokMinimum,
    required this.sku,
    required this.unit,
    required this.status,
    this.stockBalanceId,
    this.locationCount = 0,
    this.requiresBatchAdjustment = false,
  });

  factory PosStock.fromJson(Map<String, dynamic> json) {
    return PosStock(
      id: json['_id']?.toString() ?? '',
      kodeInventaris: json['kode_inventaris']?.toString() ?? '',
      namaInventaris: json['nama_inventaris']?.toString() ?? '',
      kategori: json['kategori']?.toString() ?? '',
      hargaJual: double.tryParse(json['harga_jual']?.toString() ?? '0') ?? 0,
      hargaPokok: double.tryParse(json['harga_beli']?.toString() ?? '0') ?? 0,
      stok: double.tryParse(json['stok']?.toString() ?? '0') ?? 0,
      stokMinimum:
          double.tryParse(json['stok_minimum']?.toString() ?? '0') ?? 0,
      sku: json['sku']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'pcs',
      status: json['status']?.toString() ?? '',
      stockBalanceId: json['stock_balance_id']?.toString(),
      locationCount:
          int.tryParse(json['location_count']?.toString() ?? '0') ?? 0,
      requiresBatchAdjustment: json['requires_batch_adjustment'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'kode_inventaris': kodeInventaris,
      'nama_inventaris': namaInventaris,
      'kategori': kategori,
      'harga_jual': hargaJual,
      'harga_pokok': hargaPokok,
      'stok': stok,
      'stok_minimum': stokMinimum,
      'sku': sku,
      'unit': unit,
      'status': status,
      'stock_balance_id': stockBalanceId,
      'location_count': locationCount,
      'requires_batch_adjustment': requiresBatchAdjustment,
    };
  }

  @override
  List<Object?> get props => [
    id,
    kodeInventaris,
    namaInventaris,
    kategori,
    hargaJual,
    hargaPokok,
    stok,
    stokMinimum,
    sku,
    unit,
    status,
    stockBalanceId,
    locationCount,
    requiresBatchAdjustment,
  ];
}

class PosStockStatistics extends Equatable {
  final int totalInventaris;
  final double totalNilaiInventaris;
  final int lowStockCount;
  final int outOfStockCount;

  const PosStockStatistics({
    required this.totalInventaris,
    required this.totalNilaiInventaris,
    required this.lowStockCount,
    required this.outOfStockCount,
  });

  factory PosStockStatistics.fromJson(Map<String, dynamic> json) {
    return PosStockStatistics(
      totalInventaris:
          int.tryParse(json['total_inventaris']?.toString() ?? '0') ?? 0,
      totalNilaiInventaris:
          double.tryParse(json['total_nilai_inventaris']?.toString() ?? '0') ??
          0,
      lowStockCount:
          int.tryParse(json['low_stock_count']?.toString() ?? '0') ?? 0,
      outOfStockCount:
          int.tryParse(json['out_of_stock_count']?.toString() ?? '0') ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    totalInventaris,
    totalNilaiInventaris,
    lowStockCount,
    outOfStockCount,
  ];
}

class PosStockMovement extends Equatable {
  final String productName;
  final String productCode;
  final DateTime? date;
  final String type;
  final double quantity;
  final double balanceBefore;
  final double balanceAfter;
  final String reason;
  final String note;
  final String source;
  final String reference;
  final String location;
  final String cashierName;

  const PosStockMovement({
    required this.productName,
    required this.productCode,
    required this.date,
    required this.type,
    required this.quantity,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.reason,
    required this.note,
    required this.source,
    required this.reference,
    required this.location,
    required this.cashierName,
  });

  factory PosStockMovement.fromJson(Map<String, dynamic> json) {
    final user = json['user_id'] is Map
        ? Map<String, dynamic>.from(json['user_id'] as Map)
        : const <String, dynamic>{};
    final location =
        [
              json['lokasi_gedung_kode'],
              json['lokasi_ruangan_kode'],
              json['lokasi_rak_nama'],
            ]
            .map((value) => value?.toString().trim() ?? '')
            .where((value) => value.isNotEmpty)
            .join(' / ');
    return PosStockMovement(
      productName: json['nama_inventaris']?.toString() ?? '-',
      productCode: json['kode_inventaris']?.toString() ?? '-',
      date: DateTime.tryParse(json['tanggal']?.toString() ?? ''),
      type: json['jenis']?.toString() ?? '-',
      quantity: double.tryParse(json['jumlah']?.toString() ?? '0') ?? 0,
      balanceBefore:
          double.tryParse(json['saldo_lokasi_sebelum']?.toString() ?? '0') ?? 0,
      balanceAfter:
          double.tryParse(json['saldo_lokasi_sesudah']?.toString() ?? '0') ?? 0,
      reason: json['alasan']?.toString() ?? '',
      note: json['keterangan']?.toString() ?? '',
      source: json['sumber']?.toString() ?? '',
      reference: json['referensi']?.toString() ?? '',
      location: location,
      cashierName:
          user['name']?.toString() ?? user['username']?.toString() ?? 'Sistem',
    );
  }

  @override
  List<Object?> get props => [
    productName,
    productCode,
    date,
    type,
    quantity,
    balanceBefore,
    balanceAfter,
    reason,
    note,
    source,
    reference,
    location,
    cashierName,
  ];
}

class PosStockMovementPage extends Equatable {
  final List<PosStockMovement> items;
  final int totalCount;

  const PosStockMovementPage({required this.items, required this.totalCount});

  @override
  List<Object?> get props => [items, totalCount];
}
