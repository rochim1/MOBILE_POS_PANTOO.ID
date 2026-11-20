import '../../widgets/pos_metric_card.dart';
import 'package:mobile_pos_pantoo/l10n/app_language_controller.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
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
import '../../../domain/models/pos_opname.dart';
import '../../../domain/repositories/pos_stock_repository.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_keyboard_stable_dialog.dart';
import '../../widgets/pos_keyboard_stable_sheet.dart';
import '../../widgets/pos_ui.dart';
import '../../widgets/skeleton_loading.dart';
import '../../widgets/inventory_action_style.dart';
import '../../bloc/pos/pos_bloc.dart';
import 'widgets/pos_stock_barcode_sheet.dart';
import 'pos_opening_stock_page.dart';

class PosStockPage extends StatelessWidget {
  final bool isGridView;
  final VoidCallback? onOpenStockOpname;
  final ValueChanged<PosOpnameTarget>? onCountStock;
  final ValueChanged<PosStock>? onCreatePurchase;
  final GlobalKey? locationTourKey;
  final GlobalKey? contentTourKey;
  final GlobalKey? adjustmentTourKey;

  const PosStockPage({
    super.key,
    this.isGridView = true,
    this.onOpenStockOpname,
    this.onCountStock,
    this.onCreatePurchase,
    this.locationTourKey,
    this.contentTourKey,
    this.adjustmentTourKey,
  });

  @override
  Widget build(BuildContext context) {
    posLocale(context); // Refresh formatted dates when the language changes.
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
            ? ('Akses stok tidak tersedia').tr(context)
            : ('Tracking stok nonaktif').tr(context),
        message: trackStock
            ? 'Hubungi admin untuk mendapatkan izin melihat stok toko.'
            : 'Profil POS ini tidak melacak stok. Aktifkan Tracking Stok melalui Pengaturan POS jika produk perlu dikurangi saat transaksi.',
      );
    }
    return BlocProvider(
      create: (_) =>
          sl<PosStockBloc>()..add(const LoadStocks(stockFilter: 'all')),
      child: _PosStockView(
        isGridView: isGridView,
        onOpenStockOpname: onOpenStockOpname,
        onCountStock: onCountStock,
        onCreatePurchase: onCreatePurchase,
        locationTourKey: locationTourKey,
        contentTourKey: contentTourKey,
        adjustmentTourKey: adjustmentTourKey,
      ),
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
            PosText(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            PosText(
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
  final VoidCallback? onOpenStockOpname;
  final ValueChanged<PosOpnameTarget>? onCountStock;
  final ValueChanged<PosStock>? onCreatePurchase;
  final GlobalKey? locationTourKey;
  final GlobalKey? contentTourKey;
  final GlobalKey? adjustmentTourKey;

  const _PosStockView({
    required this.isGridView,
    this.onOpenStockOpname,
    this.onCountStock,
    this.onCreatePurchase,
    this.locationTourKey,
    this.contentTourKey,
    this.adjustmentTourKey,
  });

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
          locationId: context.read<PosStockBloc>().state.selectedLocationId,
        ),
      );
    });
  }

  void _onFilterChanged(String filter) {
    context.read<PosStockBloc>().add(
      LoadStocks(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        stockFilter: filter,
        locationId: context.read<PosStockBloc>().state.selectedLocationId,
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

  bool _needsRestock(PosStock stock) => stock.needsRestock;

  void _createPurchase(PosStock stock, {BuildContext? sheetContext}) {
    if (sheetContext != null) Navigator.pop(sheetContext);
    widget.onCreatePurchase?.call(stock);
  }

  void _showBarcodeLabels(PosStock stock) {
    if (stock.barcode.isEmpty &&
        stock.sku.isEmpty &&
        stock.kodeInventaris.isEmpty) {
      AppToast.error(context, 'Produk belum memiliki kode untuk label.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => MediaQuery.sizeOf(sheetContext).width < 700
          ? PosKeyboardStableSheet(
              heightFactor: .68,
              child: PosStockBarcodeSheet(stock: stock),
            )
          : PosStockBarcodeSheet(stock: stock),
    );
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<PosStockBloc>();
    bloc.add(
      LoadStocks(
        search: _searchController.text.isEmpty ? null : _searchController.text,
        stockFilter: bloc.state.currentFilter,
        locationId: bloc.state.selectedLocationId,
      ),
    );
    bloc.add(const LoadStatistics());
    // Wait a tick for the bloc to emit
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    posLocale(context); // Refresh formatted dates when the language changes.
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
                SliverToBoxAdapter(child: _buildStockToolbar(state)),
                // Content
                if (state.status == PosStockStatus.loading &&
                    state.stocks.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: widget.isGridView
                        ? SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 460,
                                  mainAxisExtent: 218,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (_, __) => const _StockCardSkeleton(),
                              childCount: 6,
                            ),
                          )
                        : const SliverToBoxAdapter(
                            child: _StockTableSkeleton(),
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
                        (context, index) => KeyedSubtree(
                          key: index == 0 ? widget.contentTourKey : null,
                          child: _buildStockCard(
                            state.stocks[index],
                            adjustmentTourKey: index == 0
                                ? widget.adjustmentTourKey
                                : null,
                          ),
                        ),
                        childCount: state.stocks.length,
                      ),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: KeyedSubtree(
                      key: widget.contentTourKey,
                      child: _buildStockTable(state.stocks),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: ('Halaman sebelumnya').tr(context),
                          icon: const Icon(Icons.chevron_left),
                          onPressed:
                              state.page <= 1 ||
                                  state.status == PosStockStatus.loading
                              ? null
                              : () => context.read<PosStockBloc>().add(
                                  LoadStocks(
                                    search: state.search,
                                    stockFilter: state.currentFilter,
                                    locationId: state.selectedLocationId,
                                    page: state.page - 1,
                                  ),
                                ),
                        ),
                        Expanded(
                          child: Text(
                            posLocale(context).posddeedb7fc620((state.page).toString(), (state.total).toString()),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: ('Halaman berikutnya').tr(context),
                          icon: const Icon(Icons.chevron_right),
                          onPressed:
                              state.page * 20 >= state.total ||
                                  state.status == PosStockStatus.loading
                              ? null
                              : () => context.read<PosStockBloc>().add(
                                  LoadStocks(
                                    search: state.search,
                                    stockFilter: state.currentFilter,
                                    locationId: state.selectedLocationId,
                                    page: state.page + 1,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
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
      ),
      (
        'Nilai Stok',
        stats != null
            ? 'Rp ${_formatCurrency(stats.totalNilaiInventaris)}'
            : '-',
        Icons.account_balance_wallet,
      ),
      (
        'Stok Rendah',
        stats != null ? formatter.format(stats.lowStockCount) : '-',
        Icons.warning_amber_rounded,
      ),
      (
        'Stok Habis',
        stats != null ? formatter.format(stats.outOfStockCount) : '-',
        Icons.error_outline,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: PosMetricGrid(
        children: [
          for (final card in cards)
            PosMetricCard(
              title: card.$1.tr(context),
              value: card.$2,
              icon: card.$3,
              isLoading: stats == null,
            ),
        ],
      ),
    );
  }

  Widget _buildStockToolbar(PosStockState state) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    final controlHeight = compact ? 40.0 : 48.0;
    final locationHeight = compact ? 44.0 : 54.0;
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
        hintText: ('Cari produk...').tr(context),
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
      initialValue: filters.containsKey(state.currentFilter)
          ? state.currentFilter
          : 'all',
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
              child: PosText(entry.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) _onFilterChanged(value);
      },
    );

    final locationIds = state.locations
        .map((item) => item['_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final selectedLocation = state.selectedLocationId.isEmpty
        ? ''
        : locationIds.contains(state.selectedLocationId)
        ? state.selectedLocationId
        : '';
    final locationDropdown = DropdownButtonFormField<String>(
      key:
          widget.locationTourKey ??
          ValueKey('stock-location-${state.selectedLocationId}'),
      initialValue: selectedLocation,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: InputDecoration(
        labelText: ('Warehouse / Lokasi').tr(context),
        prefixIcon: const Icon(Icons.warehouse_outlined, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      items: [
        const DropdownMenuItem(value: '', child: PosText('Semua Cabang')),
        ...state.locations.map((location) {
          final id = location['_id']?.toString() ?? '';
          final name = location['nama_cabang']?.toString().trim() ?? '';
          final code = location['branch_code']?.toString().trim() ?? '';
          final label = name.isNotEmpty ? name : (code.isNotEmpty ? code : id);
          return DropdownMenuItem(
            value: id,
            child: Text(
              code.isNotEmpty && code != label ? '$label · $code' : label,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
      ],
      onChanged: state.locations.isEmpty
          ? null
          : (value) {
              if (value == null || value == state.selectedLocationId) return;
              context.read<PosStockBloc>().add(
                LoadStocks(
                  search: _searchController.text.isEmpty
                      ? null
                      : _searchController.text,
                  stockFilter: state.currentFilter,
                  locationId: value,
                ),
              );
            },
    );

    final historyButton = OutlinedButton.icon(
      onPressed: _canViewStock ? _showMovementHistory : null,
      icon: const Icon(Icons.history, size: 18),
      label: const PosText('Riwayat Shift'),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(0, controlHeight),
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 16,
        compact ? 6 : 8,
        compact ? 12 : 16,
        compact ? 8 : 12,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return Row(
              children: [
                Expanded(
                  child: SizedBox(height: controlHeight, child: searchField),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 250,
                  height: locationHeight,
                  child: locationDropdown,
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 190,
                  height: controlHeight,
                  child: filterDropdown,
                ),
                if (_canViewStock) ...[
                  const SizedBox(width: 10),
                  historyButton,
                ],
              ],
            );
          }

          return Column(
            children: [
              SizedBox(height: controlHeight, child: searchField),
              SizedBox(height: compact ? 6 : 8),
              SizedBox(height: locationHeight, child: locationDropdown),
              SizedBox(height: compact ? 6 : 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: controlHeight,
                      child: filterDropdown,
                    ),
                  ),
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
                  DataColumn(label: PosText('SKU')),
                  DataColumn(label: PosText('Produk')),
                  DataColumn(label: PosText('Kategori')),
                  DataColumn(label: PosText('Stok'), numeric: true),
                  DataColumn(label: PosText('Minimum'), numeric: true),
                  DataColumn(label: PosText('Harga Jual'), numeric: true),
                  DataColumn(label: PosText('Status')),
                  DataColumn(label: PosText('Aksi')),
                ],
                rows: stocks.indexed.map((entry) {
                  final index = entry.$1;
                  final stock = entry.$2;
                  final color = _getStockColor(stock);
                  return DataRow(
                    onSelectChanged: (_) => _showStockDetail(stock),
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
                        Text(
                          stock.tracksStock
                              ? '${_formatStock(stock.stok)} ${stock.unit}'
                              : ('Tidak dilacak').tr(context),
                        ),
                      ),
                      DataCell(
                        Text(
                          stock.tracksStock
                              ? _formatStock(stock.stokMinimum)
                              : '-',
                        ),
                      ),
                      DataCell(Text(posLocale(context).pos70272f418def((_formatCurrency(stock.hargaJual)).toString()))),
                      DataCell(
                        PosText(
                          _getStockLabel(stock),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: ('Lihat detail').tr(context),
                              onPressed: () => _showStockDetail(stock),
                              icon: const Icon(
                                Icons.visibility_outlined,
                                size: 19,
                              ),
                            ),
                            IconButton(
                              tooltip: ('Cetak label barcode').tr(context),
                              onPressed: () => _showBarcodeLabels(stock),
                              icon: const Icon(Icons.barcode_reader, size: 19),
                            ),
                            if (widget.onCreatePurchase != null &&
                                _needsRestock(stock))
                              IconButton(
                                tooltip: ('Buat PO untuk stok ini').tr(context),
                                onPressed: () => _createPurchase(stock),
                                icon: const Icon(
                                  Icons.add_shopping_cart,
                                  size: 19,
                                ),
                              ),
                            if ((_canAdjustStock ||
                                    widget.onCountStock != null) &&
                                stock.tracksStock)
                              IconButton(
                                key: index == 0
                                    ? widget.adjustmentTourKey
                                    : null,
                                tooltip: ('Koreksi stok').tr(context),
                                onPressed: () => _handleAdjustment(stock),
                                icon: const Icon(Icons.tune, size: 19),
                              ),
                          ],
                        ),
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

  Widget _buildStockCard(PosStock stock, {GlobalKey? adjustmentTourKey}) {
    final stockColor = _getStockColor(stock);
    final stockLabel = _getStockLabel(stock);
    final stockRatio = _getStockRatio(stock);
    final formatter = NumberFormat('#,###', 'id_ID');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _showStockDetail(stock),
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
                          stock.sku.isNotEmpty
                              ? stock.sku
                              : stock.kodeInventaris,
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
                      child: PosText(
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
                if (stock.tracksStock)
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
                                  posLocale(context).pos543e961a6128((_formatStock(stock.stokMinimum)).toString()),
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  stockColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  const PosText(
                    'Produk ini tidak menggunakan saldo stok.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 10),
                if (widget.onCreatePurchase != null &&
                    _needsRestock(stock)) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _createPurchase(stock),
                      icon: const Icon(Icons.add_shopping_cart, size: 17),
                      label: const PosText('Buat PO'),
                    ),
                  ),
                ],
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
                            posLocale(context).pos70272f418def((formatter.format(stock.hargaJual.toInt())).toString()),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: ('Cetak label barcode').tr(context),
                      onPressed: () => _showBarcodeLabels(stock),
                      icon: const Icon(Icons.barcode_reader, size: 18),
                      visualDensity: VisualDensity.compact,
                    ),
                    if ((_canAdjustStock || widget.onCountStock != null) &&
                        stock.tracksStock)
                      OutlinedButton.icon(
                        key: adjustmentTourKey,
                        onPressed: () => _handleAdjustment(stock),
                        icon: const Icon(Icons.tune, size: 17),
                        label: stock.requiresBatchAdjustment || !_canAdjustStock
                            ? const PosText('Hitung stok')
                            : const PosText('Koreksi Darurat'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    if (!_canAdjustStock || !stock.tracksStock)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _selectedLocationName() {
    final state = context.read<PosStockBloc>().state;
    for (final location in state.locations) {
      if (location['_id']?.toString() == state.selectedLocationId) {
        return location['nama_cabang']?.toString().trim().isNotEmpty == true
            ? location['nama_cabang'].toString()
            : location['branch_code']?.toString() ?? '-';
      }
    }
    return '-';
  }

  Future<void> _showStockDetail(PosStock stock) async {
    final warehouseId = context.read<PosStockBloc>().state.selectedLocationId;
    final balanceResult = await sl<PosStockRepository>().getLocationBalances(
      inventoryId: stock.id,
      warehouseId: warehouseId,
    );
    if (!mounted) return;
    final balanceFailure = balanceResult.fold(
      (failure) => failure,
      (_) => null,
    );
    final balances = balanceResult.getOrElse(() => const []);
    final stockColor = _getStockColor(stock);
    final selectedBalance = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          14,
          0,
          14,
          14 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.namaInventaris,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stock.sku.isNotEmpty ? stock.sku : stock.kodeInventaris,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 18),
                _stockDetailRow('Warehouse / Lokasi', _selectedLocationName()),
                _stockDetailRow(
                  'Kategori',
                  stock.kategori.isEmpty ? '-' : stock.kategori,
                ),
                _stockDetailRow(
                  'Stok tersedia',
                  stock.tracksStock
                      ? '${_formatStock(stock.stok)} ${stock.unit}'
                      : 'Tidak dilacak',
                ),
                _stockDetailRow(
                  'Stok minimum',
                  stock.tracksStock
                      ? '${_formatStock(stock.stokMinimum)} ${stock.unit}'
                      : '-',
                ),
                _stockDetailRow(
                  'Status stok',
                  _getStockLabel(stock),
                  valueColor: stockColor,
                ),
                _stockDetailRow(
                  'Harga jual',
                  'Rp ${_formatCurrency(stock.hargaJual)}',
                ),
                _stockDetailRow(
                  'Harga pokok',
                  'Rp ${_formatCurrency(stock.hargaPokok)}',
                ),
                _stockDetailRow(
                  'Jumlah saldo lokasi',
                  balances.length.toString(),
                ),
                const Divider(height: 28),
                Row(
                  children: [
                    const Expanded(
                      child: PosText(
                        'Rincian saldo per lokasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      posLocale(sheetContext).poscd596d982fc7((balances.length).toString()),
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (balanceFailure != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.dangerBorder),
                    ),
                    child: Text(
                      posLocale(sheetContext).pos8e1dc55435c2((balanceFailure.message).toString()),
                      style: TextStyle(color: AppColors.danger),
                    ),
                  )
                else if (balances.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const PosText(
                      'Belum ada saldo lokasi. Gunakan Stok Awal untuk barang yang sudah dimiliki, atau Penerimaan untuk barang baru datang. Opname hanya menghitung saldo yang sudah tercatat.',
                    ),
                  )
                else
                  ...balances.map(
                    (balance) => _buildLocationBalanceCard(balance, stock),
                  ),
                if (stock.requiresBatchAdjustment)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: PosText(
                      'Produk ini dilacak per batch. Koreksi stok dilakukan melalui Stock Opname agar batch dan kedaluwarsa tetap konsisten.',
                      style: TextStyle(color: AppColors.warning),
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (balances.isEmpty && (context.read<PosBloc>().state.runtimeConfig['permissions'] as Map?)?['initialize_stock'] == true)
                      TextButton(onPressed: () => Navigator.pop(sheetContext, {'_opening_stock': true}), child: const Text('Isi stok awal')),
                    if (widget.onCreatePurchase != null && _needsRestock(stock))
                      TextButton.icon(
                        onPressed: () =>
                            _createPurchase(stock, sheetContext: sheetContext),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const PosText('Buat PO'),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const PosText('Tutup'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || selectedBalance == null) return;
    if (selectedBalance['_opening_stock'] == true) { await _openOpeningStock(stock); return; }
    if (selectedBalance['_count_opname'] == true) {
      _openCountForBalance(stock, selectedBalance);
    } else {
      await _handleAdjustment(stock, knownBalances: [selectedBalance]);
    }
  }

  Widget _stockDetailRow(String label, String value, {Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: PosText(label, style: TextStyle(color: Colors.grey.shade600)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildLocationBalanceCard(
    Map<String, dynamic> balance,
    PosStock stock,
  ) {
    final unit = stock.unit;
    final physicalQty = (balance['qty'] as num? ?? 0).toDouble();
    final reservedQty = (balance['reserved_qty'] as num? ?? 0).toDouble();
    final availableQty =
        (balance['available_qty'] as num? ?? (physicalQty - reservedQty))
            .toDouble();
    final batches = (balance['batches'] as List? ?? const [])
        .whereType<Map>()
        .where(
          (batch) =>
              batch['aktif'] != false &&
              ((batch['qty'] as num?)?.toDouble() ?? 0) > 0,
        )
        .toList();
    final hasDetailedPath = [
      balance['lokasi_gedung_kode'],
      balance['lokasi_ruangan_kode'],
      balance['lokasi_rak_nama'],
    ].any((value) => value?.toString().trim().isNotEmpty == true);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 19,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _balanceLocation(balance),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (!hasDetailedPath)
                        const PosText(
                          'Lokasi utama • belum dirinci ke gedung/ruangan/rak',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      posLocale(context).pos8e2e32f18621((_formatStock(availableQty)).toString(), (unit).toString()),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      posLocale(context).posb3eb03dd1e68((_formatStock(physicalQty)).toString(), (_formatStock(reservedQty)).toString()),
                      style: TextStyle(
                        fontSize: 11,
                        color: reservedQty > 0
                            ? AppColors.warning
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (batches.isNotEmpty) ...[
              const Divider(height: 20),
              Text(
                posLocale(context).pos784f6f055869((batches.length).toString()),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              ...batches.map((batch) {
                final expiry = DateTime.tryParse(
                  batch['tanggal_kadaluarsa']?.toString() ?? '',
                );
                final expiryLabel = expiry == null
                    ? 'tanpa kedaluwarsa'
                    : DateFormat(
                        'dd MMM yyyy',
                        AppLanguageController.instance.effectiveLocale.languageCode,
                      ).format(expiry.toLocal());
                return Text(
                  posLocale(context).pos08ea63214a56((batch['no_batch'] ?? '-').toString(), (_formatStock((batch['qty'] as num? ?? 0).toDouble())).toString(), (unit).toString(), (expiryLabel).toString()),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                );
              }),
            ],
            if ((_canAdjustStock || widget.onCountStock != null) &&
                stock.tracksStock) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context, {
                      ...balance,
                      if (!_canAdjustStock || stock.needsBatchCountAt(balance))
                        '_count_opname': true,
                    });
                  },
                  icon: const Icon(Icons.tune, size: 17),
                  label: Text(
                    stock.needsBatchCountAt(balance)
                        ? ('Hitung/koreksi per batch').tr(context)
                        : !_canAdjustStock
                        ? ('Hitung stok').tr(context)
                        : ('Koreksi saldo ini').tr(context),
                  ),
                ),
              ),
            ],
            if (widget.onCountStock != null &&
                _canAdjustStock &&
                !stock.needsBatchCountAt(balance))
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context, {
                    ...balance,
                    '_count_opname': true,
                  }),
                  icon: const Icon(Icons.fact_check_outlined, size: 17),
                  label: const PosText('Hitung stok di lokasi ini'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAdjustment(
    PosStock stock, {
    List<Map<String, dynamic>>? knownBalances,
  }) async {
    if (!stock.tracksStock) return;
    if (stock.requiresSerial) {
      await _showAdjustmentInfo(
        'Stok dilacak per nomor seri',
        'Gunakan penerimaan, retur, atau scrap dengan nomor seri yang jelas. Koreksi jumlah serial belum didukung pada opname.',
      );
      return;
    }
    final warehouseId = context.read<PosStockBloc>().state.selectedLocationId;
    var balances = knownBalances;
    if (balances == null) {
      final result = await sl<PosStockRepository>().getLocationBalances(
        inventoryId: stock.id,
        warehouseId: warehouseId,
      );
      if (!mounted) return;
      final failure = result.fold((value) => value, (_) => null);
      if (failure != null) {
        AppToast.error(context, failure.message);
        return;
      }
      balances = result.getOrElse(() => const []);
    }
    if (balances.isEmpty) {
      if ((context.read<PosBloc>().state.runtimeConfig['permissions'] as Map?)?['initialize_stock'] == true) {
        await _openOpeningStock(stock);
        return;
      }
      await _showAdjustmentInfo(
        'Saldo lokasi tidak ditemukan',
        'Produk belum memiliki saldo pada warehouse ini. Minta pengelola mengisi Stok Awal untuk barang yang sudah dimiliki, atau gunakan Penerimaan untuk barang baru datang. Opname memerlukan saldo lokasi yang tercatat.',
      );
      return;
    }
    if (balances.length > 1) {
      await _showStockDetail(stock);
      return;
    }
    if (stock.needsBatchCountAt(balances.single) ||
        stock.valuationMethod == 'fifo' ||
        !_canAdjustStock) {
      _openCountForBalance(stock, balances.single);
      return;
    }
    await _showAdjustmentDialog(stock, balances);
  }

  void _openCountForBalance(PosStock stock, Map<String, dynamic> balance) {
    if (stock.requiresSerial) {
      _showAdjustmentInfo(
        'Barang berserial',
        'Gunakan penerimaan/retur/scrap dengan nomor seri.',
      );
      return;
    }
    if (widget.onCountStock == null) {
      _showAdjustmentInfo(
        'Perlu akses Stock Opname',
        'Minta petugas yang memiliki akses membuat opname untuk lokasi ini.',
        openOpname: true,
      );
      return;
    }
    widget.onCountStock!(PosOpnameTarget.fromBalance(stock, balance));
  }

  Future<void> _openOpeningStock(PosStock stock) async {
    final bloc = context.read<PosBloc>();
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => BlocProvider.value(
      value: bloc,
      child: Scaffold(appBar: AppBar(title: const Text('Stok Awal')), body: PosOpeningStockPage(
        initialProductId: stock.id,
        initialLocationId: context.read<PosStockBloc>().state.selectedLocationId,
        onComplete: () async { Navigator.of(context).pop(); },
      )),
    )));
    if (mounted) context.read<PosStockBloc>().add(LoadStocks(locationId: context.read<PosStockBloc>().state.selectedLocationId));
  }

  Future<void> _showAdjustmentInfo(
    String title,
    String message, {
    bool openOpname = false,
  }) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.info_outline, color: AppColors.primary),
      title: PosText(title),
      content: PosText(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const PosText('Mengerti'),
        ),
        if (openOpname && widget.onOpenStockOpname != null)
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onOpenStockOpname!();
            },
            style: InventoryActionStyle.primary(),
            icon: const Icon(Icons.fact_check_outlined, size: 18),
            label: const PosText('Buka Stock Opname'),
          ),
      ],
    ),
  );

  String _balanceLocation(Map<String, dynamic> balance) {
    String text(dynamic value) => value?.toString().trim() ?? '';
    final branch = text(balance['lokasi_cabang_nama']).isNotEmpty
        ? text(balance['lokasi_cabang_nama'])
        : _selectedLocationName();
    final building = text(
      balance['lokasi_gedung_nama'] ?? balance['lokasi_gedung_kode'],
    );
    final room = text(
      balance['lokasi_ruangan_nama'] ?? balance['lokasi_ruangan_kode'],
    );
    final rack = text(balance['lokasi_rak_nama']);

    // Jangan pernah menampilkan rak tanpa induknya. Data lama mungkin hanya
    // menyimpan sebagian jalur, jadi placeholder audit tetap mempertahankan
    // urutan Cabang -> Gedung -> Ruangan -> Rak.
    final parts = <String>[posLocale(context).pos58c6df885eda(branch.isEmpty ? '-' : branch)];
    if (building.isNotEmpty || room.isNotEmpty || rack.isNotEmpty) {
      parts.add(posLocale(context).pos786a448f1a32(building.isEmpty ? 'belum tercatat'.tr(context) : building));
    }
    if (room.isNotEmpty || rack.isNotEmpty) {
      parts.add(posLocale(context).pos085e03d813e0(room.isEmpty ? 'belum tercatat'.tr(context) : room));
    }
    if (rack.isNotEmpty) parts.add(posLocale(context).pos1af981c59b08(rack));
    return parts.join('  →  ');
  }

  Future<void> _showAdjustmentDialog(
    PosStock stock,
    List<Map<String, dynamic>> balances,
  ) async {
    var selectedBalance = balances.first;
    final stockController = TextEditingController(
      text: _formatStock((selectedBalance['qty'] as num? ?? 0).toDouble()),
    );
    final noteController = TextEditingController();
    final referenceController = TextEditingController();
    final reasonResult = await sl<PosStockRepository>().getAdjustmentReasons();
    if (!mounted) return;
    final reasonFailure = reasonResult.fold((failure) => failure, (_) => null);
    if (reasonFailure != null) {
      AppToast.error(context, reasonFailure.message);
      return;
    }
    final reasonOptions = reasonResult.getOrElse(() => const []);
    if (reasonOptions.isEmpty) {
      AppToast.error(context, 'Daftar alasan koreksi belum tersedia');
      return;
    }
    var reason = '';
    final formKey = GlobalKey<FormState>();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => PosKeyboardStableFormDialog(
          width: 540,
          height: 620,
          contentPadding: EdgeInsets.zero,
          insetPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width < 600 ? 12 : 40,
            vertical: 24,
          ),
          title: Text(posLocale(context).pos886f4075bfac((stock.namaInventaris).toString())),
          content: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: PosText(
                      'Pilih saldo lokasi fisik yang benar. Koreksi hanya untuk salah input teknis atau migrasi; hasil hitung fisik diproses melalui Stock Opname.',
                      style: const TextStyle(
                        color: AppColors.warning,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (balances.length > 1)
                    DropdownButtonFormField<String>(
                      initialValue: selectedBalance['_id']?.toString(),
                      isExpanded: true,
                      decoration:  InputDecoration(
                        labelText: ('Pilih saldo lokasi *').tr(context),
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: balances
                          .map(
                            (balance) => DropdownMenuItem(
                              value: balance['_id']?.toString(),
                              child: Text(
                                '${_balanceLocation(balance)} • ${_formatStock((balance['qty'] as num? ?? 0).toDouble())} ${stock.unit}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        final next = balances.firstWhere(
                          (balance) => balance['_id']?.toString() == value,
                        );
                        setDialogState(() => selectedBalance = next);
                        stockController.text = _formatStock(
                          (next['qty'] as num? ?? 0).toDouble(),
                        );
                      },
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: .07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _balanceLocation(selectedBalance),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    posLocale(context).poscb93757b9cc2((_formatStock((selectedBalance['qty'] as num? ?? 0).toDouble())).toString(), (stock.unit).toString()),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _adjustmentLocationSummary(selectedBalance),
                  const SizedBox(height: 12),
                  TextFormField(
errorBuilder: posValidationError,
                    controller: stockController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: ('Stok fisik terbaru').tr(context),
                      suffixText: stock.unit,
                    ),
                    validator: (value) {
                      final parsed = double.tryParse(
                        (value ?? '').replaceAll(',', '.'),
                      );
                      if (parsed == null || parsed < 0) {
                        return ('Masukkan stok yang valid').tr(context);
                      }
                      if ((parsed -
                                  ((selectedBalance['qty'] as num? ?? 0)
                                      .toDouble()))
                              .abs() <
                          .000001) {
                        return ('Nilai baru sama dengan saldo saat ini').tr(context);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: reason.isEmpty ? null : reason,
                    decoration:  InputDecoration(
                      labelText: ('Alasan koreksi *').tr(context),
                      border: OutlineInputBorder(),
                    ),
                    items: reasonOptions
                        .map(
                          (option) => DropdownMenuItem(
                            value: option['value']?.toString(),
                            child: Text(option['label']?.toString() ?? '-'),
                          ),
                        )
                        .toList(),
                    validator: (value) => value == null || value.isEmpty
                        ? ('Pilih alasan koreksi').tr(context)
                        : null,
                    onChanged: (value) =>
                        setDialogState(() => reason = value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: referenceController,
                    decoration:  InputDecoration(
                      labelText: ('Referensi / tiket (opsional)').tr(context),
                      hintText: ('Kosongkan untuk nomor otomatis').tr(context),
                      helperText: ('Sistem tetap membuat referensi internal.').tr(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
errorBuilder: posValidationError,
                    controller: noteController,
                    maxLines: 2,
                    decoration:  InputDecoration(
                      labelText: ('Keterangan *').tr(context),
                    ),
                    validator: (value) {
                      if ((value ?? '').trim().length < 5) {
                        return ('Keterangan minimal 5 karakter').tr(context);
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
              child: const PosText('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const PosText('Simpan'),
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
          reference: referenceController.text,
          stockBalanceId: selectedBalance['_id'].toString(),
          locationId: selectedBalance['lokasi_cabang_id']?.toString(),
          buildingCode: selectedBalance['lokasi_gedung_kode']?.toString() ?? '',
          roomCode: selectedBalance['lokasi_ruangan_kode']?.toString() ?? '',
          rackName: selectedBalance['lokasi_rak_nama']?.toString() ?? '',
        ),
      );
    }
    await Future<void>.delayed(kThemeAnimationDuration);
    stockController.dispose();
    noteController.dispose();
    referenceController.dispose();
  }

  Widget _adjustmentLocationSummary(Map<String, dynamic> balance) {
    String label(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? 'Belum dirinci' : text;
    }

    final rows = <(String, String)>[
      (
        'Cabang / Gudang',
        label(
          (balance['lokasi_cabang_nama']?.toString().trim() ?? '').isEmpty
              ? _selectedLocationName()
              : balance['lokasi_cabang_nama'],
        ),
      ),
      (
        'Gedung',
        label(balance['lokasi_gedung_nama'] ?? balance['lokasi_gedung_kode']),
      ),
      (
        'Ruangan',
        label(balance['lokasi_ruangan_nama'] ?? balance['lokasi_ruangan_kode']),
      ),
      ('Rak', label(balance['lokasi_rak_nama'])),
    ];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    SizedBox(
                      width: 112,
                      child: PosText(
                        row.$1,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.$2,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // --- Helpers ---

  Color _getStockColor(PosStock stock) {
    if (!stock.tracksStock) return const Color(0xFF737B89);
    if (stock.stok <= 0) return AppColors.danger;
    if (_needsRestock(stock)) return AppColors.warning;
    return const Color(0xFF737B89);
  }

  String _getStockLabel(PosStock stock) {
    if (!stock.tracksStock) return ('Tidak dilacak').trCurrent();
    if (stock.stok <= 0) return ('Habis').trCurrent();
    if (_needsRestock(stock)) return ('Pesan ulang').trCurrent();
    return ('Tersedia').trCurrent();
  }

  double _getStockRatio(PosStock stock) {
    final threshold = stock.titikReorder > 0
        ? stock.titikReorder
        : stock.stokMinimum;
    if (threshold <= 0) {
      return stock.stok > 0 ? 1.0 : 0.0;
    }
    return stock.stok / threshold;
  }

  String _formatStock(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _formatCurrency(double value) => formatRupiahAmount(value);
}

class _StockCardSkeleton extends StatelessWidget {
  const _StockCardSkeleton();

  @override
  Widget build(BuildContext context) {
    posLocale(context); // Refresh formatted dates when the language changes.
    return Container(
      height: 218,
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
    return SkeletonBox(width: width, height: height, borderRadius: radius);
  }
}

class _StockTableSkeleton extends StatelessWidget {
  const _StockTableSkeleton();

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          6,
          (index) => Padding(
            padding: EdgeInsets.only(bottom: index == 5 ? 0 : 14),
            child: Row(
              children: [
                const SkeletonBox(width: 72, height: 14, borderRadius: 4),
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: const SkeletonBox(height: 14, borderRadius: 4),
                ),
                const SizedBox(width: 20),
                Expanded(child: const SkeletonBox(height: 14, borderRadius: 4)),
                const SizedBox(width: 20),
                const SkeletonBox(width: 64, height: 24, borderRadius: 8),
              ],
            ),
          ),
        ),
      ),
    ),
  );
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
    posLocale(context); // Refresh formatted dates when the language changes.
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .88,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              children: [
                const Expanded(
                  child: PosText(
                    'Riwayat Stok Shift Aktif',
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
                hintText: ('Cari nama atau kode produk').tr(context),
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
                        label: Text(posStockMovementLabel(filter.$1 ?? '', context)),
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
              PosText(_error, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const PosText('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: PosText('Belum ada pergerakan stok pada toko ini'),
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
                    label: Text(posLocale(context).pos3bcc4a44a905((_items.length).toString(), (_totalCount).toString())),
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
        : DateFormat('dd MMM yyyy, HH:mm', AppLanguageController.instance.effectiveLocale.languageCode).format(date);
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
                  posStockMovementLabel(item.type, context),
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
              posLocale(context).pos21462b1cd3e9((_number(item.balanceBefore)).toString(), (_number(item.balanceAfter)).toString(), (_number(item.quantity)).toString()),
            ),
            const SizedBox(height: 5),
            Text(
              posLocale(context).posfd312a360b1e((item.cashierName).toString(), (item.location.isEmpty ? '' : ('  •  ${item.location}').tr(context)).toString()),
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
