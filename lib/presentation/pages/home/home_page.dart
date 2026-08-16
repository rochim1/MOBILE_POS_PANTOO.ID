import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/auth_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/auth_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_state.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order.dart';

class HomePage extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const HomePage({super.key, this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    if (context.read<AppLockCubit>().state.status == AppLockStatus.unlocked) {
      context.read<PosBloc>().add(LoadDashboardData());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        final data = state.dashboardData;
        final stats = data?['stats'] as Map<String, dynamic>?;
        final dailySales =
            (data?['daily_sales'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final paymentBreakdown =
            (data?['payment_breakdown'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        final topProducts =
            (data?['top_products'] as List?)?.cast<Map<String, dynamic>>() ??
            [];

        // Fallback values from existing state
        final todayOrders = state.orders.where((o) {
          final date = o.dateTime;
          final now = DateTime.now();
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        }).toList();
        final todayRevenue =
            stats?['today_revenue']?.toDouble() ??
            todayOrders.fold(0.0, (sum, o) => sum + o.total);
        final todayTransactions =
            stats?['today_transactions'] ?? todayOrders.length;
        final todayAvgOrder =
            stats?['today_avg_order']?.toDouble() ??
            (todayOrders.isNotEmpty ? todayRevenue / todayOrders.length : 0.0);
        final revenueGrowth = stats?['revenue_growth']?.toDouble();
        final transactionGrowth = stats?['transaction_growth']?.toDouble();
        final totalProducts = state.products.length;

        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                context.read<PosBloc>().add(LoadPosData());
                context.read<PosBloc>().add(LoadDashboardData());
                await Future.delayed(const Duration(seconds: 1));
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 600;

                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(isTablet ? 24 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  BlocBuilder<AuthCubit, AuthState>(
                                    builder: (context, authState) {
                                      final name = authState.username?.trim();
                                      return Text(
                                        'Halo, ${name == null || name.isEmpty ? 'Pengguna' : name} 👋',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ringkasan data POS Anda hari ini.',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Hari Ini',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const Icon(Icons.arrow_drop_down),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        if ((state.runtimeConfig['configuration_health']
                                as Map?)?['valid'] ==
                            false) ...[
                          _buildConfigurationWarning(state.runtimeConfig),
                          const SizedBox(height: 16),
                        ],

                        // Low Stock Alert
                        if ((state.runtimeConfig['features']
                                    as Map?)?['track_stock'] !=
                                false &&
                            (((state.runtimeConfig['permissions']
                                        as Map?)?['view_stock'] ==
                                    true) ||
                                ((state.runtimeConfig['permissions']
                                        as Map?)?['adjust_stock'] ==
                                    true)))
                          _buildLowStockAlert(state.products, isTablet),

                        // Section 1: Compact Stat Cards
                        _buildStatCardsSection(
                          isTablet: isTablet,
                          todayRevenue: todayRevenue,
                          todayTransactions: todayTransactions,
                          todayAvgOrder: todayAvgOrder,
                          totalProducts: totalProducts,
                          revenueGrowth: revenueGrowth,
                          transactionGrowth: transactionGrowth,
                          isLoading:
                              data == null && state.status == PosStatus.loading,
                        ),
                        const SizedBox(height: 20),

                        // Section 2: Sales Chart
                        _buildSalesChart(dailySales, isTablet),
                        const SizedBox(height: 20),

                        // Section 3: Payment Breakdown + Top Products
                        if (isTablet)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildPaymentBreakdown(
                                  paymentBreakdown,
                                  isTablet,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTopProducts(topProducts, isTablet),
                              ),
                            ],
                          )
                        else ...[
                          _buildPaymentBreakdown(paymentBreakdown, isTablet),
                          const SizedBox(height: 20),
                          _buildTopProducts(topProducts, isTablet),
                        ],
                        const SizedBox(height: 20),

                        // Recent Orders
                        _buildRecentOrders(state.orders, isTablet),
                        const SizedBox(height: 20),

                        // Section 4: Active Shift
                        if (state.activeShift != null)
                          _buildActiveShiftCard(state),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Section 1: Stat Cards ─────────────────────────────────────────────

  Widget _buildConfigurationWarning(Map<String, dynamic> runtimeConfig) {
    final health = runtimeConfig['configuration_health'] as Map?;
    final issues = (health?['issues'] as List? ?? const [])
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        border: Border.all(color: const Color(0xFFFDBA74)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFC2410C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              issues.isEmpty
                  ? 'Konfigurasi POS belum siap. Tarik untuk mencoba memuat ulang.'
                  : issues.join('\n'),
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardsSection({
    required bool isTablet,
    required double todayRevenue,
    required int todayTransactions,
    required double todayAvgOrder,
    required int totalProducts,
    required double? revenueGrowth,
    required double? transactionGrowth,
    required bool isLoading,
  }) {
    final cards = [
      _StatCardData(
        title: 'Pendapatan Hari Ini',
        value: _formatCurrency(todayRevenue),
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF059669),
        growth: revenueGrowth,
      ),
      _StatCardData(
        title: 'Transaksi Hari Ini',
        value: '$todayTransactions',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF2563EB),
        growth: transactionGrowth,
      ),
      _StatCardData(
        title: 'Rata-rata Order',
        value: _formatCurrency(todayAvgOrder),
        icon: Icons.show_chart_outlined,
        color: const Color(0xFFD97706),
        growth: null,
      ),
      _StatCardData(
        title: 'Total Produk',
        value: '$totalProducts',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF7C3AED),
        growth: null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 4
            : constraints.maxWidth >= 420
            ? 2
            : 1;
        const spacing = 12.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(4, (index) {
            return SizedBox(
              width: cardWidth,
              height: 116,
              child: isLoading
                  ? _buildShimmerCard()
                  : _buildStatCard(cards[index]),
            );
          }),
        );
      },
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 100,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(_StatCardData data) {
    return Container(
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
                  color: data.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (data.growth != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (data.growth! >= 0
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626))
                            .withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${data.growth! >= 0 ? '+' : '-'}${data.growth!.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: data.growth! >= 0
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
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 7),
          Container(height: 2, color: data.color),
        ],
      ),
    );
  }

  // ─── Section 2: Sales Chart ────────────────────────────────────────────

  Widget _buildSalesChart(
    List<Map<String, dynamic>> dailySales,
    bool isTablet,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Penjualan 7 Hari Terakhir',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: isTablet ? 250 : 200,
            child: dailySales.isEmpty
                ? Center(
                    child: Text(
                      'Belum ada data penjualan',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      maxY: _getMaxRevenue(dailySales) * 1.2,
                      minY: 0,
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final label =
                                  dailySales[spot.x.toInt()]['label'] ?? '';
                              return LineTooltipItem(
                                '$label\n${_formatCurrency(spot.y)}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= dailySales.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  dailySales[idx]['label']?.toString() ?? '',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _formatCompact(value),
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _getMaxRevenue(dailySales) / 4 > 0
                            ? _getMaxRevenue(dailySales) / 4
                            : 1,
                        getDrawingHorizontalLine: (value) =>
                            FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: dailySales.asMap().entries.map((entry) {
                            final revenue =
                                (entry.value['revenue'] as num?)?.toDouble() ??
                                0;
                            return FlSpot(entry.key.toDouble(), revenue);
                          }).toList(),
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.3),
                                AppColors.primary.withValues(alpha: 0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── Section 3a: Payment Breakdown ─────────────────────────────────────

  Widget _buildPaymentBreakdown(
    List<Map<String, dynamic>> paymentBreakdown,
    bool isTablet,
  ) {
    final colors = <String, Color>{
      'tunai': const Color(0xFF10B981),
      'qris': const Color(0xFF3B82F6),
      'debit': const Color(0xFFF59E0B),
      'transfer': const Color(0xFF8B5CF6),
      'e-wallet': const Color(0xFF14B8A6),
      'kredit': const Color(0xFFEF4444),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Metode Pembayaran',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          if (paymentBreakdown.isEmpty)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'Belum ada data pembayaran',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: paymentBreakdown.map((item) {
                    final method = (item['method']?.toString() ?? '')
                        .toLowerCase();
                    final percentage =
                        (item['percentage'] as num?)?.toDouble() ?? 0;
                    final color = colors[method] ?? Colors.grey.shade400;
                    return PieChartSectionData(
                      color: color,
                      value: percentage,
                      title: '${percentage.toStringAsFixed(0)}%',
                      radius: 28,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: paymentBreakdown.map((item) {
                final method = (item['method']?.toString() ?? '').toLowerCase();
                final label = item['label']?.toString() ?? method;
                final color = colors[method] ?? Colors.grey.shade400;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Section 3b: Top Products ──────────────────────────────────────────

  Widget _buildTopProducts(
    List<Map<String, dynamic>> topProducts,
    bool isTablet,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Produk Terlaris',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          if (topProducts.isEmpty)
            SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'Belum ada data produk',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ),
            )
          else
            ...topProducts.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final product = entry.value;
              final name = product['nama']?.toString() ?? '-';
              final qtySold = product['qty_sold'] ?? 0;
              final revenue = (product['revenue'] as num?)?.toDouble() ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: rank <= 3
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: rank <= 3
                              ? AppColors.primary
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$qtySold terjual',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(revenue),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ─── Section 4: Active Shift ───────────────────────────────────────────

  Widget _buildActiveShiftCard(PosState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shift Aktif',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.activeShift!['toko']?['nama_toko'] ?? 'Toko Kasir',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Waktu Buka: ${state.activeShift!['opened_at'] ?? '-'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Aktif',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp ${value.toStringAsFixed(0)}';
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}rb';
    }
    return value.toStringAsFixed(0);
  }

  double _getMaxRevenue(List<Map<String, dynamic>> dailySales) {
    if (dailySales.isEmpty) return 100;
    double max = 0;
    for (final s in dailySales) {
      final revenue = (s['revenue'] as num?)?.toDouble() ?? 0;
      if (revenue > max) max = revenue;
    }
    return max > 0 ? max : 100;
  }

  // ─── Section 5: Low Stock Alert ──────────────────────────────────────────

  Widget _buildLowStockAlert(List<PosProduct> products, bool isTablet) {
    final lowStockProducts = products
        .where((PosProduct p) => p.stock > 0 && p.stock <= 5)
        .toList();
    if (lowStockProducts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // Red 50
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)), // Red 200
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Peringatan Stok Menipis',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${lowStockProducts.length} produk memiliki stok kurang dari 5. Segera lakukan re-stock.',
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => widget.onNavigate?.call(7),
            child: const Text(
              'Lihat',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section 6: Recent Orders ─────────────────────────────────────────────

  Widget _buildRecentOrders(List<PosOrder> orders, bool isTablet) {
    if (orders.isEmpty) return const SizedBox.shrink();

    // Limit to 5 most recent orders
    final recentOrders = orders.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaksi Terakhir',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              TextButton(
                onPressed: () => widget.onNavigate?.call(3),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentOrders.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final order = recentOrders[index];
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  onTap: () => widget.onNavigate?.call(3),
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.receipt,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    order.invoice,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    order.customer,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatCurrency(order.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.status,
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double? growth;

  const _StatCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.growth,
  });
}
