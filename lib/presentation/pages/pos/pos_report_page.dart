import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/_core.dart';
import '../../../../domain/models/pos_report.dart';
import '../../../../injections.dart';
import '../../bloc/pos_report/pos_report_bloc.dart';
import '../../bloc/pos_report/pos_report_event.dart';
import '../../bloc/pos_report/pos_report_state.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_category_navigation.dart';
import '../../widgets/pos_ui.dart';

class PosReportPage extends StatelessWidget {
  const PosReportPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        sl<PosReportBloc>()
          ..add(const LoadReport(days: 7, periodLabel: '7 Hari Terakhir')),
    child: const _ReportView(),
  );
}

enum _Section {
  summary,
  topReports,
  commission,
  voidSales,
  cashier,
  cash,
  products,
  payments,
  satisfaction,
  others,
  deposits,
}

class _ReportView extends StatefulWidget {
  const _ReportView();
  @override
  State<_ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<_ReportView> {
  final _money = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _compactMoney = NumberFormat.compactCurrency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );
  static const _periods = <({String label, int days})>[
    (label: 'Hari Ini', days: 1),
    (label: '7 Hari Terakhir', days: 7),
    (label: '30 Hari Terakhir', days: 30),
    (label: 'Tahun Ini', days: 365),
  ];
  _Section _section = _Section.summary;
  bool _revenueChart = true;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xFFF6F8FA),
    child: BlocConsumer<PosReportBloc, PosReportState>(
      listener: (context, state) {
        if (state.status == PosReportStatus.failure) {
          AppToast.error(context, state.errorMessage);
        }
      },
      builder: (context, state) {
        final wide = MediaQuery.sizeOf(context).width >= 900;
        final content = _content(context, state, wide);
        return RefreshIndicator(
          onRefresh: () => _reload(context, state),
          child: wide
              ? Row(
                  children: [
                    _categories(),
                    Expanded(child: content),
                  ],
                )
              : content,
        );
      },
    ),
  );

  Widget _content(
    BuildContext context,
    PosReportState state,
    bool wide,
  ) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: EdgeInsets.fromLTRB(wide ? 24 : 16, 16, wide ? 24 : 16, 40),
    children: [
      if (!wide) ...[_mobileCategories(), const SizedBox(height: 14)],
      _header(),
      const SizedBox(height: 16),
      _filters(context, state),
      const SizedBox(height: 18),
      if (state.status == PosReportStatus.loading ||
          state.status == PosReportStatus.initial)
        const _Skeleton()
      else if (state.reportData case final data?)
        switch (_section) {
          _Section.summary => _summary(data, state.selectedPeriod, wide),
          _Section.topReports => _topReports(data),
          _Section.commission => _notAvailable(
            icon: Icons.percent_rounded,
            title: 'Laporan Komisi',
            message: 'Komisi belum tercatat pada transaksi POS di periode ini.',
          ),
          _Section.voidSales => _notAvailable(
            icon: Icons.block_outlined,
            title: 'Laporan Void',
            message:
                'Belum ada data transaksi void yang tersedia pada laporan.',
          ),
          _Section.cashier => _notAvailable(
            icon: Icons.person_outline_rounded,
            title: 'Laporan Kasir',
            message:
                'Rincian performa per kasir belum tersedia dari server laporan.',
          ),
          _Section.cash => _cashReport(data.paymentBreakdown),
          _Section.products => _products(data.topProducts),
          _Section.payments => _payments(data.paymentBreakdown),
          _Section.satisfaction => _notAvailable(
            icon: Icons.sentiment_satisfied_alt_outlined,
            title: 'Kepuasan Pelanggan',
            message:
                'Belum ada penilaian pelanggan yang tercatat pada transaksi POS.',
          ),
          _Section.others => _otherReport(data),
          _Section.deposits => _notAvailable(
            icon: Icons.savings_outlined,
            title: 'Penjualan Deposit',
            message:
                'Belum ada transaksi deposit yang tercatat pada periode ini.',
          ),
        }
      else
        _error(context, state),
    ],
  );

  Widget _header() {
    final title = switch (_section) {
      _Section.summary => 'Ringkasan Penjualan',
      _Section.topReports => '10 Laporan Teratas',
      _Section.commission => 'Komisi',
      _Section.voidSales => 'Void',
      _Section.cashier => 'Kasir',
      _Section.cash => 'Kas Kasir',
      _Section.products => 'Produk Terjual',
      _Section.payments => 'Jenis Pembayaran',
      _Section.satisfaction => 'Kepuasan Pelanggan',
      _Section.others => 'Lainnya',
      _Section.deposits => 'Penjualan Deposit',
    };
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.query_stats_rounded, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Data langsung dari transaksi POS',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _filters(BuildContext context, PosReportState state) {
    final selected = _periods.any((p) => p.label == state.selectedPeriod)
        ? state.selectedPeriod
        : _periods.first.label;
    return LayoutBuilder(
      builder: (context, box) {
        final picker = DropdownButtonFormField<String>(
          initialValue: selected,
          isExpanded: true,
          decoration: _decoration('Periode', Icons.calendar_today_outlined),
          items: _periods
              .map(
                (p) => DropdownMenuItem(value: p.label, child: Text(p.label)),
              )
              .toList(),
          onChanged: (value) {
            if (value == null || value == state.selectedPeriod) return;
            final period = _periods.firstWhere((p) => p.label == value);
            context.read<PosReportBloc>().add(
              LoadReport(days: period.days, periodLabel: period.label),
            );
          },
        );
        final range = Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDDE2E7)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.date_range_outlined,
                size: 19,
                color: AppColors.primary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _rangeLabel(_days(selected)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
        if (box.maxWidth < 560) {
          return Row(
            children: [
              Expanded(child: picker),
              const SizedBox(width: 10),
              Expanded(child: range),
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: 210, child: picker),
            const SizedBox(width: 12),
            SizedBox(width: 260, child: range),
            const Spacer(),
            IconButton.filledTonal(
              onPressed: () => _reload(context, state),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 19),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDDE2E7)),
    ),
  );

  Widget _summary(PosReportData data, String period, bool wide) {
    final stats = data.stats ?? const PosReportStats();
    final topQty = data.topProducts.fold<int>(
      0,
      (sum, item) => sum + (item.qtySold ?? 0),
    );
    final metrics =
        <
          ({
            String title,
            String value,
            IconData icon,
            Color color,
            double? growth,
          })
        >[
          (
            title: 'Total Penjualan',
            value: _money.format(stats.todayRevenue ?? 0),
            icon: Icons.payments_outlined,
            color: const Color(0xFF08B89D),
            growth: stats.revenueGrowth,
          ),
          (
            title: 'Total Transaksi',
            value: '${stats.todayTransactions ?? 0}',
            icon: Icons.receipt_long_outlined,
            color: const Color(0xFFE53FA8),
            growth: stats.transactionGrowth,
          ),
          (
            title: 'Rata-rata / Transaksi',
            value: _money.format(stats.todayAvgOrder ?? 0),
            icon: Icons.analytics_outlined,
            color: const Color(0xFF7C3AED),
            growth: null,
          ),
          (
            title: 'Item Produk Teratas',
            value: '$topQty item',
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFFE5C000),
            growth: null,
          ),
          (
            title: 'Pertumbuhan Omzet',
            value: '${(stats.revenueGrowth ?? 0).toStringAsFixed(1)}%',
            icon: Icons.trending_up,
            color: const Color(0xFF0EA5E9),
            growth: null,
          ),
          (
            title: 'Pertumbuhan Transaksi',
            value: '${(stats.transactionGrowth ?? 0).toStringAsFixed(1)}%',
            icon: Icons.show_chart_rounded,
            color: const Color(0xFFF97316),
            growth: null,
          ),
        ];
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final columns = box.maxWidth >= 1000 ? 3 : 2;
            const gap = 12.0;
            final width = (box.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: metrics
                  .map(
                    (m) => SizedBox(
                      width: width,
                      child: _Metric(data: m),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const SizedBox(height: 18),
        _chart(data.dailySales, period),
        const SizedBox(height: 18),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _payments(data.paymentBreakdown)),
              const SizedBox(width: 16),
              Expanded(child: _products(data.topProducts)),
            ],
          )
        else ...[
          _payments(data.paymentBreakdown),
          const SizedBox(height: 18),
          _products(data.topProducts),
        ],
      ],
    );
  }

  Widget _chart(List<PosDailySales> sales, String period) {
    final values = sales
        .map((e) => _revenueChart ? e.revenue : e.transactions.toDouble())
        .toList();
    final peak = values.isEmpty ? 0.0 : values.reduce(math.max);
    final maxY = peak <= 0 ? 10.0 : peak * 1.2;
    final interval = maxY / 4;
    final labelStep = math.max(1, (sales.length / 6).ceil());
    return _Card(
      title: 'Tren Penjualan',
      subtitle: period,
      trailing: SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: true, label: Text('Omzet')),
          ButtonSegment(value: false, label: Text('Transaksi')),
        ],
        selected: {_revenueChart},
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        onSelectionChanged: (v) => setState(() => _revenueChart = v.first),
      ),
      child: SizedBox(
        height: 240,
        child: sales.isEmpty
            ? const _Empty(
                icon: Icons.show_chart,
                text: 'Belum ada tren penjualan',
              )
            : LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        interval: interval,
                        getTitlesWidget: (v, _) => Text(
                          _revenueChart
                              ? _compactMoney.format(v)
                              : '${v.toInt()}',
                          style: const TextStyle(fontSize: 9),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 ||
                              i >= sales.length ||
                              (i % labelStep != 0 && i != sales.length - 1)) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              sales[i].label ?? '',
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < values.length; i++)
                          FlSpot(i.toDouble(), values[i]),
                      ],
                      isCurved: sales.length > 2,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: sales.length <= 14),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withValues(alpha: .12),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _payments(List<PosPaymentBreakdown> items) => _Card(
    title: 'Jenis Pembayaran',
    subtitle:
        '${items.fold<int>(0, (sum, e) => sum + (e.count ?? 0))} transaksi',
    child: items.isEmpty
        ? const _Empty(
            icon: Icons.payments_outlined,
            text: 'Belum ada pembayaran pada periode ini',
          )
        : Column(
            children: items.map((item) {
              final color = _payColor(item.method ?? '');
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.label ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          '${item.count ?? 0} trx',
                          style: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _money.format(item.total ?? 0),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ((item.percentage ?? 0) / 100).clamp(0, 1),
                        color: color,
                        backgroundColor: color.withValues(alpha: .1),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
  );

  Widget _products(List<PosTopProduct> items) => _Card(
    title: 'Produk Terlaris',
    subtitle: 'Diurutkan berdasarkan omzet',
    child: items.isEmpty
        ? const _Empty(
            icon: Icons.inventory_2_outlined,
            text: 'Belum ada produk terjual pada periode ini',
          )
        : Column(
            children: items.asMap().entries.map((entry) {
              final item = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: entry.key == items.length - 1
                      ? null
                      : const Border(
                          bottom: BorderSide(color: Color(0xFFEEF1F3)),
                        ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: AppColors.primary.withValues(alpha: .1),
                      foregroundColor: AppColors.primary,
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nama ?? '-',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${item.qtySold ?? 0} item · ${item.kode ?? 'Tanpa kode'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _money.format(item.revenue ?? 0),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
  );

  Widget _topReports(PosReportData data) => Column(
    children: [
      _products(data.topProducts),
      const SizedBox(height: 18),
      _payments(data.paymentBreakdown),
    ],
  );

  Widget _cashReport(List<PosPaymentBreakdown> items) {
    final cash = items
        .where((item) => item.method?.toLowerCase() == 'tunai')
        .toList();
    final total = cash.fold<double>(0, (sum, item) => sum + (item.total ?? 0));
    final count = cash.fold<int>(0, (sum, item) => sum + (item.count ?? 0));
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: PosStatCard(
                label: 'Penerimaan Tunai',
                value: _money.format(total),
                icon: Icons.payments_outlined,
                color: const Color(0xFF059669),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PosStatCard(
                label: 'Transaksi Tunai',
                value: '$count',
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _payments(cash),
      ],
    );
  }

  Widget _otherReport(PosReportData data) => _Card(
    title: 'Aktivitas Penjualan Harian',
    subtitle: '${data.dailySales.length} hari tercatat',
    child: data.dailySales.isEmpty
        ? const _Empty(
            icon: Icons.event_note_outlined,
            text: 'Belum ada aktivitas penjualan',
          )
        : Column(
            children: data.dailySales.reversed.take(10).map((day) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: .1),
                  foregroundColor: AppColors.primary,
                  child: const Icon(Icons.calendar_today_outlined, size: 17),
                ),
                title: Text(day.label ?? day.date ?? '-'),
                subtitle: Text('${day.transactions} transaksi'),
                trailing: Text(
                  _money.format(day.revenue),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              );
            }).toList(),
          ),
  );

  Widget _notAvailable({
    required IconData icon,
    required String title,
    required String message,
  }) => _Card(
    title: title,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B), height: 1.5),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _categories() => PosCategorySidebar<_Section>(
    title: 'Kategori Laporan',
    items: _categoryItems,
    selected: _section,
    onSelected: (value) => setState(() => _section = value),
    footer: 'Laporan diperbarui langsung dari transaksi POS.',
  );

  Widget _mobileCategories() => PosCategoryDropdown<_Section>(
    label: 'Kategori laporan',
    items: _categoryItems,
    selected: _section,
    onSelected: (value) => setState(() => _section = value),
  );

  List<PosCategoryItem<_Section>> get _categoryItems => _sectionOptions
      .map(
        (item) => PosCategoryItem<_Section>(
          value: item.$1,
          icon: item.$2,
          label: item.$3,
        ),
      )
      .toList();

  List<(_Section, IconData, String)> get _sectionOptions => const [
    (_Section.summary, Icons.dashboard_outlined, 'Ringkasan Penjualan'),
    (_Section.topReports, Icons.leaderboard_outlined, '10 Laporan Teratas'),
    (_Section.commission, Icons.percent_rounded, 'Komisi'),
    (_Section.voidSales, Icons.block_outlined, 'Void'),
    (_Section.cashier, Icons.person_outline_rounded, 'Kasir'),
    (_Section.cash, Icons.point_of_sale_outlined, 'Kas Kasir'),
    (_Section.products, Icons.inventory_2_outlined, 'Produk Terjual'),
    (_Section.payments, Icons.wallet_outlined, 'Jenis Pembayaran'),
    (
      _Section.satisfaction,
      Icons.sentiment_satisfied_alt_outlined,
      'Kepuasan Pelanggan',
    ),
    (_Section.others, Icons.more_horiz_rounded, 'Lainnya'),
    (_Section.deposits, Icons.savings_outlined, 'Penjualan Deposit'),
  ];

  Widget _error(BuildContext context, PosReportState state) => _Card(
    title: 'Laporan tidak dapat dimuat',
    child: Column(
      children: [
        const Icon(Icons.cloud_off_outlined, size: 44, color: Colors.grey),
        const SizedBox(height: 10),
        Text(state.errorMessage, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _reload(context, state),
          icon: const Icon(Icons.refresh),
          label: const Text('Coba lagi'),
        ),
      ],
    ),
  );

  Future<void> _reload(BuildContext context, PosReportState state) async {
    final period = _periods.firstWhere(
      (p) => p.label == state.selectedPeriod,
      orElse: () => _periods.first,
    );
    final bloc = context.read<PosReportBloc>()
      ..add(LoadReport(days: period.days, periodLabel: period.label));
    await bloc.stream.firstWhere((s) => s.status != PosReportStatus.loading);
  }

  int _days(String label) => _periods
      .firstWhere((p) => p.label == label, orElse: () => _periods.first)
      .days;
  String _rangeLabel(int days) {
    final end = DateTime.now(), start = end.subtract(Duration(days: days - 1));
    final fmt = DateFormat('dd MMM yyyy', 'id_ID');
    return days == 1
        ? fmt.format(end)
        : '${fmt.format(start)} – ${fmt.format(end)}';
  }

  Color _payColor(String method) => switch (method.toLowerCase()) {
    'tunai' => const Color(0xFF10B981),
    'qris' => const Color(0xFF3B82F6),
    'transfer' => const Color(0xFF8B5CF6),
    'debit' || 'kartu_debit' => const Color(0xFFF59E0B),
    'kartu_kredit' => const Color(0xFFEF4444),
    'e_wallet' => const Color(0xFF14B8A6),
    _ => Colors.grey,
  };
}

class _Metric extends StatelessWidget {
  final ({
    String title,
    String value,
    IconData icon,
    Color color,
    double? growth,
  })
  data;
  const _Metric({required this.data});
  @override
  Widget build(BuildContext context) => Container(
    height: 116,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(data.icon, color: data.color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (data.growth case final growth?)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      (growth >= 0
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626))
                          .withValues(alpha: .09),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${growth >= 0 ? '+' : '-'}${growth.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: growth >= 0
                        ? const Color(0xFF047857)
                        : const Color(0xFFB91C1C),
                  ),
                ),
              ),
          ],
        ),
        const Spacer(),
        Text(
          data.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 7),
        Container(height: 2, color: data.color),
      ],
    ),
  );
}

class _Card extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  const _Card({
    required this.title,
    this.subtitle,
    this.trailing,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE5E9EC)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const Divider(height: 24),
        child,
      ],
    ),
  );
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Empty({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade300, size: 38),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

class _Skeleton extends StatefulWidget {
  const _Skeleton();

  @override
  State<_Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<_Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final color = Color.lerp(
        const Color(0xFFE7EBEF),
        const Color(0xFFF5F7F9),
        _controller.value,
      )!;
      Widget bar(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      );
      Widget stat() => Container(
        height: 116,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 10),
                bar(90, 12),
              ],
            ),
            const Spacer(),
            bar(120, 20),
            const SizedBox(height: 7),
            bar(double.infinity, 2),
          ],
        ),
      );
      return Column(
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final columns = box.maxWidth >= 1000 ? 3 : 2;
              const gap = 12.0;
              final width = (box.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: List.generate(
                  6,
                  (_) => SizedBox(width: width, child: stat()),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(130, 16),
                const SizedBox(height: 8),
                bar(80, 10),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
