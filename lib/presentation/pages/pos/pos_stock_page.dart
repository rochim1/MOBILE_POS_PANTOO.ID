import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import '../../bloc/pos_stock/pos_stock_bloc.dart';
import '../../bloc/pos_stock/pos_stock_event.dart';
import '../../bloc/pos_stock/pos_stock_state.dart';
import '../../../domain/models/pos_stock.dart';
import '../../../domain/repositories/pos_stock_repository.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_ui.dart';
import '../../bloc/pos/pos_bloc.dart';

class PosStockPage extends StatelessWidget {
  final bool isGridView;

  const PosStockPage({super.key, this.isGridView = true});

  @override
  Widget build(BuildContext context) {
    final config = context.read<PosBloc>().state.runtimeConfig;
    final features = config['features'] as Map?;
    final permissions = config['permissions'] as Map?;
    final trackStock = features?['track_stock'] != false;
    final canViewStock =
        permissions?['view_stock'] == true ||
        permissions?['adjust_stock'] == true;
    if (!trackStock || !canViewStock) {
      return _StockAccessMessage(
        icon: trackStock ? Icons.lock_outline : Icons.inventory_2_outlined,
        title: trackStock
            ? 'Akses stok tidak tersedia'
            : 'Tracking stok nonaktif',
        message: trackStock
            ? 'Hubungi admin untuk mendapatkan izin melihat stok toko.'
            : 'Profil POS ini tidak melacak stok. Aktifkan Tracking Stok melalui Pengaturan POS jika produk perlu dikurangi saat transaksi.',
      );
    }
    return BlocProvider(
      create: (_) =>
          sl<PosStockBloc>()..add(const LoadStocks(stockFilter: 'all')),
      child: _PosStockView(isGridView: isGridView),
    );
  }
}

class _StockAccessMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _StockAccessMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Colors.grey.shade500),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PosStockView extends StatefulWidget {
  final bool isGridView;

  const _PosStockView({required this.isGridView});

  @override
  State<_PosStockView> createState() => _PosStockViewState();
}

class _PosStockViewState extends State<_PosStockView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<PosStockBloc>().add(
        LoadStocks(
          search: query.isEmpty ? null : query,
          stockFilter: context.read<PosStockBloc>().state.currentFilter,
        ),
      );
    });
  }

  void _onFilterChanged(String filter) {
    context.read<PosStockBloc>().add(
      LoadStocks(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        stockFilter: filter,
      ),
    );
  }

  bool get _canAdjustStock {
    final permissions =
        context.read<PosBloc>().state.runtimeConfig['permissions'] as Map?;
    return permissions?['adjust_stock'] == true;
  }

  bool get _canViewStock {
    final permissions =
        context.read<PosBloc>().state.runtimeConfig['permissions'] as Map?;
    return permissions?['view_stock'] == true || _canAdjustStock;
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<PosStockBloc>();
    bloc.add(
      LoadStocks(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        stockFilter: bloc.state.currentFilter,
      ),
    );
    bloc.add(const LoadStatistics());
    // Wait a tick for the bloc to emit
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: BlocConsumer<PosStockBloc, PosStockState>(
        listener: (context, state) {
          if (state.status == PosStockStatus.failure &&
              state.errorMessage.isNotEmpty) {
            AppToast.error(context, state.errorMessage);
          } else if (state.status == PosStockStatus.success &&
              state.successMessage.isNotEmpty) {
            AppToast.success(context, state.successMessage);
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _onRefresh,
            child: CustomScrollView(
              slivers: [
                // Statistics cards
                SliverToBoxAdapter(
                  child: _buildStatisticsCards(state.statistics),
                ),
                SliverToBoxAdapter(
                  child: _buildStockToolbar(state.currentFilter),
                ),
                // Content
                if (state.status == PosStockStatus.loading &&
                    state.stocks.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList.builder(
                      itemCount: 5,
                      itemBuilder: (_, __) => const _StockCardSkeleton(),
                    ),
                  )
                else if (state.stocks.isEmpty)
                  const SliverFillRemaining(
                    child: PosEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Stok tidak ditemukan',
                      message:
                          'Ubah pencarian atau filter. Produk yang terhubung ke toko akan tampil di sini.',
                    ),
                  )
                else if (widget.isGridView)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 460,
                            mainAxisExtent: 218,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildStockCard(state.stocks[index]),
                        childCount: state.stocks.length,
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(child: _buildStockTable(state.stocks)),
                // Bottom spacing
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showMovementHistory() => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _StockMovementSheet(repository: sl<PosStockRepository>()),
  );

  Widget _buildStatisticsCards(PosStockStatistics? stats) {
    final formatter = NumberFormat('#,###', 'id_ID');
    final cards = [
      (
        'Total Produk',
        stats != null ? formatter.format(stats.totalInventaris) : '-',
        Icons.inventory_2,
        const Color(0xFF7C3AED),
      ),
      (
        'Nilai Stok',
        stats != null
            ? 'Rp ${_formatCurrency(stats.totalNilaiInventaris)}'
            : '-',
        Icons.account_balance_wallet,
        const Color(0xFF2563EB),
      ),
      (
        'Stok Rendah',
        stats != null ? formatter.format(stats.lowStockCount) : '-',
        Icons.warning_amber_rounded,
        const Color(0xFFD97706),
      ),
      (
        'Stok Habis',
        stats != null ? formatter.format(stats.outOfStockCount) : '-',
        Icons.error_outline,
        const Color(0xFFDC2626),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 760
              ? 4
              : constraints.maxWidth >= 420
              ? 2
              : 1;
          const spacing = 12.0;
          final width =
              (constraints.maxWidth - (spacing * (columns - 1))) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: cards
                .map(
                  (card) => SizedBox(
                    width: width,
                    height: 116,
                    child: _buildStatCard(card.$1, card.$2, card.$3, card.$4),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
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
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Container(height: 2, color: color),
        ],
      ),
    );
  }

  Widget _buildStockToolbar(String currentFilter) {
    const filters = <String, String>{
      'all': 'Semua Stok',
      'low': 'Stok Rendah',
      'out': 'Stok Habis',
    };

    final searchField = TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {});
        _onSearchChanged(value);
      },
      decoration: InputDecoration(
        hintText: 'Cari produk...',
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                  _onSearchChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      ),
    );

    final filterDropdown = DropdownButtonFormField<String>(
      initialValue: filters.containsKey(currentFilter) ? currentFilter : 'all',
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.filter_list_rounded, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      items: filters.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) _onFilterChanged(value);
      },
    );

    final historyButton = OutlinedButton.icon(
      onPressed: _canViewStock ? _showMovementHistory : null,
      icon: const Icon(Icons.history, size: 18),
      label: const Text('Riwayat Stok'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 680) {
            return Row(
              children: [
                Expanded(child: SizedBox(height: 48, child: searchField)),
                const SizedBox(width: 10),
                SizedBox(width: 190, height: 48, child: filterDropdown),
                if (_canViewStock) ...[
                  const SizedBox(width: 10),
                  historyButton,
                ],
              ],
            );
          }

          return Column(
            children: [
              SizedBox(height: 48, child: searchField),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: SizedBox(height: 48, child: filterDropdown)),
                  if (_canViewStock) ...[
                    const SizedBox(width: 8),
                    historyButton,
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStockTable(List<PosStock> stocks) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
                columns: const [
                  DataColumn(label: Text('SKU')),
                  DataColumn(label: Text('Produk')),
                  DataColumn(label: Text('Kategori')),
                  DataColumn(label: Text('Stok'), numeric: true),
                  DataColumn(label: Text('Minimum'), numeric: true),
                  DataColumn(label: Text('Harga Jual'), numeric: true),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Aksi')),
                ],
                rows: stocks.map((stock) {
                  final color = _getStockColor(stock);
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          stock.sku.isNotEmpty
                              ? stock.sku
                              : stock.kodeInventaris,
                        ),
                      ),
                      DataCell(Text(stock.namaInventaris)),
                      DataCell(Text(stock.kategori)),
                      DataCell(
                        Text('${_formatStock(stock.stok)} ${stock.unit}'),
                      ),
                      DataCell(Text(_formatStock(stock.stokMinimum))),
                      DataCell(Text('Rp ${_formatCurrency(stock.hargaJual)}')),
                      DataCell(
                        Text(
                          _getStockLabel(stock),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DataCell(
                        _canAdjustStock
                            ? IconButton(
                                tooltip: 'Koreksi stok',
                                onPressed: () => _handleAdjustment(stock),
                                icon: const Icon(Icons.tune, size: 19),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockCard(PosStock stock) {
    final stockColor = _getStockColor(stock);
    final stockLabel = _getStockLabel(stock);
    final stockRatio = _getStockRatio(stock);
    final formatter = NumberFormat('#,###', 'id_ID');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 90),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      stock.sku.isNotEmpty ? stock.sku : stock.kodeInventaris,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stock.namaInventaris,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: stockColor.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    stockLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: stockColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_formatStock(stock.stok)} ${stock.unit}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: stockColor,
                            ),
                          ),
                          Text(
                            'Minimum ${_formatStock(stock.stokMinimum)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: stockRatio.clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(stockColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              stock.kategori,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Rp ${formatter.format(stock.hargaJual.toInt())}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_canAdjustStock)
                  OutlinedButton.icon(
                    onPressed: () => _handleAdjustment(stock),
                    icon: const Icon(Icons.tune, size: 17),
                    label: const Text('Koreksi Stok'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAdjustment(PosStock stock) async {
    if (stock.requiresBatchAdjustment) {
      await _showAdjustmentInfo(
        'Stok dilacak per batch',
        'Koreksi produk ini harus dilakukan melalui Stock Opname di Web Admin agar jumlah setiap batch dan tanggal kedaluwarsa tetap konsisten.',
      );
      return;
    }
    if (stock.locationCount != 1 ||
        stock.stockBalanceId == null ||
        stock.stockBalanceId!.isEmpty) {
      await _showAdjustmentInfo(
        'Stok berada di beberapa lokasi',
        'Pilih saldo rak/lokasi melalui halaman Stok Inventory di Web Admin. Total stok cabang tidak boleh dikoreksi sebagai satu saldo.',
      );
      return;
    }
    await _showAdjustmentDialog(stock);
  }

  Future<void> _showAdjustmentInfo(String title, String message) =>
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.info_outline, color: AppColors.primary),
          title: Text(title),
          content: Text(message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );

  Future<void> _showAdjustmentDialog(PosStock stock) async {
    final stockController = TextEditingController(
      text: _formatStock(stock.stok),
    );
    final noteController = TextEditingController();
    var reason = 'koreksi_audit';
    final formKey = GlobalKey<FormState>();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Sesuaikan stok ${stock.namaInventaris}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: stockController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Stok fisik terbaru',
                      suffixText: stock.unit,
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(
                        (value ?? '').replaceAll(',', '.'),
                      );
                      if (parsed == null || parsed < 0) {
                        return 'Masukkan stok yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: reason,
                    decoration: const InputDecoration(labelText: 'Alasan'),
                    items: const [
                      DropdownMenuItem(
                        value: 'koreksi_audit',
                        child: Text('Koreksi audit'),
                      ),
                      DropdownMenuItem(
                        value: 'selisih_hitung',
                        child: Text('Selisih hitung'),
                      ),
                      DropdownMenuItem(
                        value: 'salah_input',
                        child: Text('Salah input'),
                      ),
                      DropdownMenuItem(
                        value: 'migrasi_data',
                        child: Text('Migrasi data'),
                      ),
                      DropdownMenuItem(
                        value: 'lainnya',
                        child: Text('Lainnya'),
                      ),
                    ],
                    onChanged: (value) => setDialogState(() => reason = value!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                    ),
                    validator: (value) {
                      if (reason == 'lainnya' && (value ?? '').trim().isEmpty) {
                        return 'Catatan wajib diisi untuk alasan lainnya';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (submitted == true && mounted) {
      context.read<PosStockBloc>().add(
        AdjustStock(
          id: stock.id,
          newStock: double.parse(stockController.text.replaceAll(',', '.')),
          reason: reason,
          note: noteController.text,
          stockBalanceId: stock.stockBalanceId!,
        ),
      );
    }
    stockController.dispose();
    noteController.dispose();
  }

  // --- Helpers ---

  Color _getStockColor(PosStock stock) {
    if (stock.stok <= 0) return AppColors.danger;
    if (stock.stok <= stock.stokMinimum) return AppColors.warning;
    return const Color(0xFF64748B);
  }

  String _getStockLabel(PosStock stock) {
    if (stock.stok <= 0) return 'Habis';
    if (stock.stok <= stock.stokMinimum) return 'Rendah';
    return 'Tersedia';
  }

  double _getStockRatio(PosStock stock) {
    if (stock.stokMinimum <= 0) {
      return stock.stok > 0 ? 1.0 : 0.0;
    }
    return stock.stok / stock.stokMinimum;
  }

  String _formatStock(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _formatCurrency(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}M';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}Jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}Rb';
    }
    return NumberFormat('#,###', 'id_ID').format(value.toInt());
  }
}

class _StockCardSkeleton extends StatelessWidget {
  const _StockCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 168,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _block(42, 42, radius: 11),
              const SizedBox(width: 11),
              Expanded(child: _block(double.infinity, 16)),
              const SizedBox(width: 16),
              _block(62, 22, radius: 10),
            ],
          ),
          const SizedBox(height: 14),
          _block(120, 11),
          const SizedBox(height: 14),
          _block(double.infinity, 7),
          const Spacer(),
          Row(
            children: [
              Expanded(child: _block(100, 14)),
              _block(96, 32, radius: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _block(double width, double height, {double radius = 5}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _StockMovementSheet extends StatefulWidget {
  final PosStockRepository repository;

  const _StockMovementSheet({required this.repository});

  @override
  State<_StockMovementSheet> createState() => _StockMovementSheetState();
}

class _StockMovementSheetState extends State<_StockMovementSheet> {
  static const _pageSize = 20;
  List<PosStockMovement> _items = const [];
  bool _loading = true;
  bool _loadingMore = false;
  String _error = '';
  String? _type;
  int _page = 0;
  int _totalCount = 0;
  Timer? _searchDebounce;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool append = false}) async {
    if (append) {
      setState(() => _loadingMore = true);
    } else {
      _page = 0;
      setState(() {
        _loading = true;
        _error = '';
      });
    }
    final result = await widget.repository.getMovements(
      search: _searchController.text,
      type: _type,
      page: _page,
      limit: _pageSize,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _loadingMore = false;
        _error = failure.message;
      }),
      (resultPage) => setState(() {
        _loading = false;
        _loadingMore = false;
        _items = append ? [..._items, ...resultPage.items] : resultPage.items;
        _totalCount = resultPage.totalCount;
      }),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), _load);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _items.length >= _totalCount) return;
    _page += 1;
    await _load(append: true);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .88,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Riwayat Stok Toko',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama atau kode produk',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                        icon: const Icon(Icons.clear),
                      ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children:
                  [
                    (null, 'Semua'),
                    ('penyesuaian', 'Koreksi'),
                    ('masuk', 'Masuk'),
                    ('keluar', 'Keluar'),
                    ('retur', 'Retur'),
                  ].map((filter) {
                    final selected = _type == filter.$1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter.$2),
                        selected: selected,
                        onSelected: (_) {
                          _type = filter.$1;
                          _load();
                        },
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _StockCardSkeleton(),
        ),
      );
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
                color: AppColors.danger,
              ),
              const SizedBox(height: 12),
              Text(_error, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('Belum ada pergerakan stok pada toko ini'),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _items.length + (_items.length < _totalCount ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          if (index < _items.length) return _movementCard(_items[index]);
          return Center(
            child: _loadingMore
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  )
                : OutlinedButton.icon(
                    onPressed: _loadMore,
                    icon: const Icon(Icons.expand_more),
                    label: Text('Muat lagi (${_items.length}/$_totalCount)'),
                  ),
          );
        },
      ),
    );
  }

  Widget _movementCard(PosStockMovement item) {
    final date = item.date?.toLocal();
    final formattedDate = date == null
        ? '-'
        : DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.productName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  item.type.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '${item.productCode} • $formattedDate',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const Divider(height: 20),
            Text(
              'Saldo lokasi: ${_number(item.balanceBefore)} → ${_number(item.balanceAfter)}  •  Jumlah ${_number(item.quantity)}',
            ),
            const SizedBox(height: 5),
            Text(
              'Oleh ${item.cashierName}${item.location.isEmpty ? '' : '  •  ${item.location}'}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (item.reason.isNotEmpty || item.note.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                [
                  item.reason.replaceAll('_', ' '),
                  item.note,
                ].where((value) => value.isNotEmpty).join(' — '),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _number(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}
