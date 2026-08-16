import 'package:equatable/equatable.dart';

class PosReportStats extends Equatable {
  final double? todayRevenue;
  final int? todayTransactions;
  final double? todayAvgOrder;
  final double? revenueGrowth;
  final double? transactionGrowth;

  const PosReportStats({
    this.todayRevenue,
    this.todayTransactions,
    this.todayAvgOrder,
    this.revenueGrowth,
    this.transactionGrowth,
  });

  factory PosReportStats.fromJson(Map<String, dynamic> json) {
    return PosReportStats(
      todayRevenue: (json['today_revenue'] as num?)?.toDouble(),
      todayTransactions: json['today_transactions'] as int?,
      todayAvgOrder: (json['today_avg_order'] as num?)?.toDouble(),
      revenueGrowth: (json['revenue_growth'] as num?)?.toDouble(),
      transactionGrowth: (json['transaction_growth'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    todayRevenue,
    todayTransactions,
    todayAvgOrder,
    revenueGrowth,
    transactionGrowth,
  ];
}

class PosPaymentBreakdown extends Equatable {
  final String? method;
  final String? label;
  final int? count;
  final double? total;
  final double? percentage;

  const PosPaymentBreakdown({
    this.method,
    this.label,
    this.count,
    this.total,
    this.percentage,
  });

  factory PosPaymentBreakdown.fromJson(Map<String, dynamic> json) {
    return PosPaymentBreakdown(
      method: json['method'] as String?,
      label: json['label'] as String?,
      count: json['count'] as int?,
      total: (json['total'] as num?)?.toDouble(),
      percentage: (json['percentage'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [method, label, count, total, percentage];
}

class PosTopProduct extends Equatable {
  final String? id;
  final String? nama;
  final String? kode;
  final int? qtySold;
  final double? revenue;
  final double? percentage;

  const PosTopProduct({
    this.id,
    this.nama,
    this.kode,
    this.qtySold,
    this.revenue,
    this.percentage,
  });

  factory PosTopProduct.fromJson(Map<String, dynamic> json) {
    return PosTopProduct(
      id: json['_id'] as String?,
      nama: json['nama'] as String?,
      kode: json['kode'] as String?,
      qtySold: json['qty_sold'] as int?,
      revenue: (json['revenue'] as num?)?.toDouble(),
      percentage: (json['percentage'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, nama, kode, qtySold, revenue, percentage];
}

class PosDailySales extends Equatable {
  final String? date;
  final String? label;
  final double revenue;
  final int transactions;

  const PosDailySales({
    this.date,
    this.label,
    this.revenue = 0,
    this.transactions = 0,
  });

  factory PosDailySales.fromJson(Map<String, dynamic> json) {
    return PosDailySales(
      date: json['date'] as String?,
      label: json['label'] as String?,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      transactions: (json['transactions'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [date, label, revenue, transactions];
}

class PosReportData extends Equatable {
  final PosReportStats? stats;
  final List<PosDailySales> dailySales;
  final List<PosPaymentBreakdown> paymentBreakdown;
  final List<PosTopProduct> topProducts;

  const PosReportData({
    this.stats,
    this.dailySales = const [],
    this.paymentBreakdown = const [],
    this.topProducts = const [],
  });

  factory PosReportData.fromJson(Map<String, dynamic> json) {
    return PosReportData(
      stats: json['stats'] != null
          ? PosReportStats.fromJson(json['stats'])
          : null,
      dailySales:
          (json['daily_sales'] as List<dynamic>?)
              ?.map((e) => PosDailySales.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      paymentBreakdown:
          (json['payment_breakdown'] as List<dynamic>?)
              ?.map(
                (e) => PosPaymentBreakdown.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      topProducts:
          (json['top_products'] as List<dynamic>?)
              ?.map((e) => PosTopProduct.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [stats, dailySales, paymentBreakdown, topProducts];
}
