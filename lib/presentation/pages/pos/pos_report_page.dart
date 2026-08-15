import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/_core.dart';
import '../../../../injections.dart';
import '../../bloc/pos_report/pos_report_bloc.dart';
import '../../bloc/pos_report/pos_report_event.dart';
import '../../bloc/pos_report/pos_report_state.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_ui.dart';
import '../../../../domain/models/pos_report.dart';

class PosReportPage extends StatelessWidget {
  const PosReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          sl<PosReportBloc>()
            ..add(const LoadReport(days: 7, periodLabel: 'Minggu Ini')),
      child: const _PosReportView(),
    );
  }
}

class _PosReportView extends StatefulWidget {
  const _PosReportView();

  @override
  State<_PosReportView> createState() => _PosReportViewState();
}

class _PosReportViewState extends State<_PosReportView> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<Map<String, dynamic>> _periods = [
    {'label': 'Hari Ini', 'days': 1},
    {'label': 'Minggu Ini', 'days': 7},
    {'label': 'Bulan Ini', 'days': 30},
    {'label': 'Tahun Ini', 'days': 365},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const PosAppBarTitle(
          title: 'Laporan Penjualan',
          subtitle: 'Ringkasan performa transaksi',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<PosReportBloc, PosReportState>(
        listener: (context, state) {
          if (state.status == PosReportStatus.failure) {
            AppToast.error(context, state.errorMessage);
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              final selectedDays =
                  _periods.firstWhere(
                        (p) => p['label'] == state.selectedPeriod,
                      )['days']
                      as int;
              context.read<PosReportBloc>().add(
                LoadReport(
                  days: selectedDays,
                  periodLabel: state.selectedPeriod,
                ),
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPeriodFilter(context, state),
                const SizedBox(height: 16),
                if (state.status == PosReportStatus.loading ||
                    state.status == PosReportStatus.initial)
                  const _ReportSkeleton()
                else if (state.reportData != null) ...[
                  _buildSummaryCards(state.reportData!.stats),
                  const SizedBox(height: 24),
                  _buildPaymentBreakdown(state.reportData!.paymentBreakdown),
                  const SizedBox(height: 24),
                  _buildTopProducts(state.reportData!.topProducts),
                  const SizedBox(height: 40),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodFilter(BuildContext context, PosReportState state) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _periods.map((period) {
            final isSelected = state.selectedPeriod == period['label'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(period['label'] as String),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected && !isSelected) {
                    context.read<PosReportBloc>().add(
                      LoadReport(
                        days: period['days'] as int,
                        periodLabel: period['label'] as String,
                      ),
                    );
                  }
                },
                showCheckmark: false,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(PosReportStats? stats) {
    if (stats == null) return const SizedBox.shrink();

    final cards = [
      (
        'Total Transaksi',
        stats.todayTransactions?.toString() ?? '0',
        Icons.receipt_long,
        const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
      ),
      (
        'Pendapatan',
        _currencyFormat.format(stats.todayRevenue ?? 0),
        Icons.account_balance_wallet,
        const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
      ),
      (
        'Rata-rata/Trx',
        _currencyFormat.format(stats.todayAvgOrder ?? 0),
        Icons.analytics,
        const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
      ),
      (
        'Pertumbuhan',
        '${(stats.revenueGrowth ?? 0).toStringAsFixed(1)}%',
        (stats.revenueGrowth ?? 0) >= 0
            ? Icons.trending_up
            : Icons.trending_down,
        const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final width = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: width,
                  height: 128,
                  child: _buildStatCard(card.$1, card.$2, card.$3, card.$4),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    LinearGradient gradient,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown(List<PosPaymentBreakdown> breakdown) {
    return _buildSection(
      title: 'Metode Pembayaran',
      icon: Icons.payments_outlined,
      child: breakdown.isEmpty
          ? const _SectionEmpty(
              icon: Icons.payments_outlined,
              message: 'Belum ada pembayaran pada periode ini',
            )
          : Column(
              children: breakdown.map((item) {
                final color = _getPaymentColor(item.method ?? '');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.label ?? '-'} · ${item.count ?? 0} trx',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _currencyFormat.format(item.total ?? 0),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (item.percentage ?? 0) / 100,
                                backgroundColor: Colors.grey.shade200,
                                color: color,
                                minHeight: 8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 40,
                            child: Text(
                              '${(item.percentage ?? 0).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildTopProducts(List<PosTopProduct> products) {
    return _buildSection(
      title: 'Produk Terlaris',
      icon: Icons.star_outline,
      child: products.isEmpty
          ? const _SectionEmpty(
              icon: Icons.inventory_2_outlined,
              message: 'Belum ada produk terjual pada periode ini',
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final product = products[index];
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      foregroundColor: AppColors.primary,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(
                      product.nama ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('${product.qtySold} terjual'),
                    trailing: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        _currencyFormat.format(product.revenue ?? 0),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Color _getPaymentColor(String method) {
    switch (method.toLowerCase()) {
      case 'tunai':
        return Colors.green;
      case 'qris':
        return Colors.blue;
      case 'transfer':
        return Colors.purple;
      case 'kartu_debit':
        return Colors.amber;
      case 'kartu_kredit':
        return Colors.red;
      case 'e_wallet':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

class _SectionEmpty extends StatelessWidget {
  final IconData icon;
  final String message;

  const _SectionEmpty({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(icon, color: Colors.grey.shade300, size: 36),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ReportSkeleton extends StatelessWidget {
  const _ReportSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(
            4,
            (_) => Container(
              width: (MediaQuery.sizeOf(context).width - 44) / 2,
              height: 128,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        for (var index = 0; index < 2; index++) ...[
          Container(
            height: 190,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
