import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_table.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_table_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_table/pos_table_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_table/pos_table_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_table/pos_table_state.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/app_toast.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_keyboard_stable_dialog.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_keyboard_stable_sheet.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_ui.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'utils/pos_table_qr_document.dart';
import 'utils/pos_table_qr_branding.dart';
import 'utils/pos_table_qr_link.dart';
import 'utils/pos_table_qr_print_settings.dart';
import 'widgets/pos_table_qr_print_settings_dialog.dart';
import 'widgets/pos_table_qr_sheet.dart';

class PosTableManagementPage extends StatelessWidget {
  final bool? _isGridView;
  final VoidCallback? onOpenOrders;
  bool get isGridView => _isGridView ?? true;

  const PosTableManagementPage({super.key, bool? isGridView, this.onOpenOrders})
    : _isGridView = isGridView;

  @override
  Widget build(BuildContext context) {
    final config = context.read<PosBloc>().state.runtimeConfig;
    final useTables = (config['features'] as Map?)?['use_tables'] == true;
    final canManage = (config['permissions'] as Map?)?['manage_tables'] == true;
    final posState = context.read<PosBloc>().state;
    final allowOutOfShift = config['allow_out_of_shift'] == true;
    final storeId =
        posState.activeShift?['toko_id']?.toString() ??
        (allowOutOfShift
            ? posState.stores
                      .where((store) => store.status.toLowerCase() == 'active')
                      .firstOrNull
                      ?.id ??
                  ''
            : '');
    if (!useTables || !canManage || storeId.isEmpty) {
      return _TableAccessMessage(
        title: !useTables
            ? 'Fitur meja nonaktif'
            : !canManage
            ? 'Akses manajemen meja ditolak'
            : allowOutOfShift
            ? 'Toko aktif belum tersedia'
            : 'Shift kasir belum dibuka',
        message: !useTables
            ? 'Aktifkan fitur Meja / Ruangan melalui Pengaturan POS terlebih dahulu.'
            : !canManage
            ? 'Hubungi admin untuk mendapatkan izin mengelola meja.'
            : allowOutOfShift
            ? 'Aktifkan minimal satu toko agar meja dapat dikelola.'
            : 'Buka shift pada toko yang akan dikelola agar meja tidak tercampur antar toko.',
      );
    }
    return BlocProvider(
      create: (_) =>
          PosTableBloc(repository: sl())..add(LoadTables(storeId: storeId)),
      child: _PosTableManagementView(
        storeId: storeId,
        isGridView: isGridView,
        onOpenOrders: onOpenOrders,
      ),
    );
  }
}

class _TableAccessMessage extends StatelessWidget {
  final String title;
  final String message;

  const _TableAccessMessage({required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.table_restaurant_outlined,
            size: 52,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}

class _PosTableManagementView extends StatefulWidget {
  final String storeId;
  final bool? _isGridView;
  final VoidCallback? onOpenOrders;
  bool get isGridView => _isGridView ?? true;

  const _PosTableManagementView({
    required this.storeId,
    bool? isGridView,
    this.onOpenOrders,
  }) : _isGridView = isGridView;

  @override
  State<_PosTableManagementView> createState() =>
      _PosTableManagementViewState();
}

class _PosTableManagementViewState extends State<_PosTableManagementView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  Timer? _durationTicker;
  Timer? _occupancyRefreshTimer;
  int? _selectedCapacity;
  String _statusFilter = '';
  String _locationFilter = '';
  String _sort = 'occupied_first';
  bool _printingAllQr = false;

  bool get _isTablet => MediaQuery.of(context).size.width >= 600;

  @override
  void initState() {
    super.initState();
    _durationTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _occupancyRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _reload();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _durationTicker?.cancel();
    _occupancyRefreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _reload);
  }

  void _reload() => context.read<PosTableBloc>().add(
    LoadTables(storeId: widget.storeId, search: _searchController.text),
  );

  String get _instansiId =>
      sl<SharedPreferences>().getString('instansi_id')?.trim() ?? '';

  String get _storeName =>
      context
          .read<PosBloc>()
          .state
          .stores
          .where((store) => store.id == widget.storeId)
          .firstOrNull
          ?.name ??
      'Toko';

  String? _webOrderUrl() {
    final value = PosTableQrLink.configuredBaseUrl;
    if (PosTableQrLink.parseBaseUrl(value) != null) return value;
    AppToast.error(context, 'URL Web Order pada build aplikasi tidak valid.');
    return null;
  }

  PosTableQrEntry? _qrEntry(PosTableModel table, String baseUrl) {
    if (!table.statusAktif || table.storeId != widget.storeId) return null;
    final url = PosTableQrLink.forTable(
      baseUrl: baseUrl,
      instansiId: _instansiId,
      storeId: widget.storeId,
      tableId: table.id,
    );
    if (url == null) return null;
    return PosTableQrEntry(
      storeName: _storeName,
      tableName: table.name,
      capacity: table.capacity,
      area: table.area,
      floor: table.floor,
      url: url,
    );
  }

  Future<void> _showTableQr(PosTableModel table) async {
    final baseUrl = _webOrderUrl();
    if (baseUrl == null) return;
    final entry = _qrEntry(table, baseUrl);
    if (entry == null) {
      AppToast.error(context, 'Data toko atau meja tidak valid untuk QR.');
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PosTableQrSheet(
        entry: entry,
        preferences: sl<SharedPreferences>(),
        instansiId: _instansiId,
      ),
    );
  }

  Future<void> _printAllTableQr() async {
    if (_printingAllQr) return;
    final baseUrl = _webOrderUrl();
    if (baseUrl == null) return;
    final preferences = sl<SharedPreferences>();
    final settings = await showDialog<PosTableQrPrintSettings>(
      context: context,
      builder: (_) => PosTableQrPrintSettingsDialog(
        initial: PosTableQrPrintSettings.load(preferences, _instansiId),
      ),
    );
    if (!mounted || settings == null) return;
    await settings.save(preferences, _instansiId);
    if (!mounted) return;
    setState(() => _printingAllQr = true);
    try {
      // Fetch without a search filter or pagination so "semua meja" really
      // includes every active table in the selected store.
      final result = await sl<PosTableRepository>().getTables(
        storeId: widget.storeId,
        limit: 0,
      );
      if (!mounted) return;
      final tables = result.fold<List<PosTableModel>>(
        (_) => const [],
        (items) => items,
      );
      if (result.isLeft()) {
        AppToast.error(context, 'Gagal memuat semua meja untuk dicetak.');
        return;
      }
      final entries = tables
          .map((table) => _qrEntry(table, baseUrl))
          .whereType<PosTableQrEntry>()
          .toList();
      if (entries.length != tables.length || entries.isEmpty) {
        AppToast.error(context, 'Tidak ada meja valid untuk dicetak.');
        return;
      }
      final logoBytes = settings.useLogo
          ? await PosTableQrBranding.loadLogoPng()
          : null;
      final bytes = await PosTableQrDocument.build(
        entries,
        settings: settings,
        logoBytes: logoBytes,
      );
      await Printing.layoutPdf(
        name: 'QR-Meja-$_storeName',
        onLayout: (_) async => bytes,
      );
    } catch (_) {
      if (mounted) AppToast.error(context, 'Gagal menyiapkan QR semua meja.');
    } finally {
      if (mounted) setState(() => _printingAllQr = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: BlocConsumer<PosTableBloc, PosTableState>(
        listener: (context, state) {
          if (state.status == PosTableStatus.actionSuccess) {
            AppToast.success(context, state.successMessage);
          } else if (state.status == PosTableStatus.failure) {
            AppToast.error(context, state.errorMessage);
          }
        },
        builder: (context, state) {
          final capacities = state.tables.map((table) => table.capacity).toSet()
            ..removeWhere((capacity) => capacity <= 0);
          final sortedCapacities = capacities.toList()..sort();
          final activeCapacity = sortedCapacities.contains(_selectedCapacity)
              ? _selectedCapacity
              : null;
          final locations =
              state.tables
                  .map(_tableLocation)
                  .where((location) => location.isNotEmpty)
                  .toSet()
                  .toList()
                ..sort();
          final visibleTables = _visibleTables(state.tables, activeCapacity);
          return Column(
            children: [
              _buildSearchBar(),
              if (state.tables.isNotEmpty)
                _buildFilterPills(
                  sortedCapacities,
                  activeCapacity,
                  locations,
                  state.tables.length,
                ),
              Expanded(child: _buildBody(state, visibleTables)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTableForm(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterPills(
    List<int> capacities,
    int? activeCapacity,
    List<String> locations,
    int totalTables,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _pillRow([
            _filterChip(
              'Semua ($totalTables)',
              selected: _statusFilter.isEmpty,
              onSelected: () => setState(() => _statusFilter = ''),
            ),
            _filterChip(
              'Tersedia',
              selected: _statusFilter == 'Tersedia',
              onSelected: () => setState(() => _statusFilter = 'Tersedia'),
              icon: Icons.check_circle_outline,
            ),
            _filterChip(
              'Terisi',
              selected: _statusFilter == 'Terisi',
              onSelected: () => setState(() => _statusFilter = 'Terisi'),
              icon: Icons.restaurant_outlined,
            ),
          ]),
          if (locations.isNotEmpty) ...[
            const SizedBox(height: 7),
            _pillRow([
              _filterChip(
                'Semua lokasi',
                selected: _locationFilter.isEmpty,
                onSelected: () => setState(() => _locationFilter = ''),
                icon: Icons.layers_outlined,
              ),
              for (final location in locations)
                _filterChip(
                  location,
                  selected: _locationFilter == location,
                  onSelected: () => setState(() => _locationFilter = location),
                  icon: Icons.location_on_outlined,
                ),
            ]),
          ],
          if (capacities.isNotEmpty) ...[
            const SizedBox(height: 7),
            _pillRow([
              _capacityChip('Semua kapasitas', null, activeCapacity),
              for (final capacity in capacities)
                _capacityChip('$capacity kursi', capacity, activeCapacity),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _pillRow(List<Widget> children) => SizedBox(
    height: 34,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, index) => children[index],
    ),
  );

  Widget _filterChip(
    String label, {
    required bool selected,
    required VoidCallback onSelected,
    IconData? icon,
  }) => ChoiceChip(
    avatar: icon == null
        ? null
        : Icon(
            icon,
            size: 15,
            color: selected ? Colors.white : Colors.grey[700],
          ),
    label: Text(label),
    selected: selected,
    onSelected: (_) => onSelected(),
    showCheckmark: false,
    visualDensity: VisualDensity.compact,
    selectedColor: AppColors.primary,
    backgroundColor: AppColors.bgPrimary,
    side: BorderSide(
      color: selected ? AppColors.primary : Colors.grey.shade300,
    ),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    labelStyle: TextStyle(
      color: selected ? Colors.white : Colors.black87,
      fontSize: 12,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    ),
  );

  Widget _capacityChip(String label, int? capacity, int? activeCapacity) {
    final selected = capacity == activeCapacity;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedCapacity = capacity),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.bgPrimary,
      side: BorderSide(
        color: selected ? AppColors.primary : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _buildSearchBar() {
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        final compact = outerConstraints.maxWidth < 600;
        final controlHeight = compact ? 40.0 : 48.0;
        return Container(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 16,
            compact ? 8 : 12,
            compact ? 12 : 16,
            compact ? 8 : 10,
          ),
          color: Colors.white,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final search = SizedBox(
                height: controlHeight,
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  decoration: const InputDecoration(
                    hintText: 'Cari meja...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              );
              final filters = Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  SizedBox(
                    width: 168,
                    height: controlHeight,
                    child: DropdownButtonFormField<String>(
                      initialValue: _sort,
                      isDense: true,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Urutkan',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'occupied_first',
                          child: Text(
                            'Terisi dahulu',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'name',
                          child: Text('Nama meja'),
                        ),
                        DropdownMenuItem(
                          value: 'longest',
                          child: Text(
                            'Durasi terlama',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'capacity',
                          child: Text('Kapasitas'),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _sort = value ?? 'occupied_first'),
                    ),
                  ),
                  SizedBox(
                    width: controlHeight,
                    height: controlHeight,
                    child: IconButton(
                      tooltip: 'Cetak QR semua meja',
                      icon: _printingAllQr
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.qr_code_2_outlined),
                      onPressed: _printingAllQr ? null : _printAllTableQr,
                    ),
                  ),
                ],
              );
              if (constraints.maxWidth < 650) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [search, const SizedBox(height: 8), filters],
                );
              }
              return Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 10),
                  filters,
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildBody(PosTableState state, List<PosTableModel> visibleTables) {
    if (state.status == PosTableStatus.loading && state.tables.isEmpty) {
      return const PosSkeletonList();
    }

    if (state.tables.isEmpty && state.status == PosTableStatus.success) {
      return PosEmptyState(
        icon: Icons.table_restaurant_outlined,
        title: 'Belum ada meja',
        message:
            'Tambahkan meja beserta kapasitas kursinya untuk mulai menerima order dine-in.',
        actionLabel: 'Tambah Meja',
        onAction: () => _showTableForm(context),
      );
    }

    if (visibleTables.isEmpty && state.tables.isNotEmpty) {
      return const Center(
        child: Text(
          'Tidak ada meja dengan kapasitas ini.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (widget.isGridView) {
      return _buildGridView(visibleTables);
    }
    return _buildListView(visibleTables);
  }

  Widget _buildGridView(List<PosTableModel> tables) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<PosTableBloc>().add(
          LoadTables(storeId: widget.storeId, search: _searchController.text),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) => GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (constraints.maxWidth / 170).floor().clamp(2, 6),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 184,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) => _buildGridCard(tables[index]),
        ),
      ),
    );
  }

  Widget _buildGridCard(PosTableModel table) {
    final isAvailable = table.status.toLowerCase() != 'terisi';
    final accent = isAvailable ? AppColors.primary : AppColors.warning;

    return Material(
      color: isAvailable ? Colors.white : AppColors.warningBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => isAvailable
            ? _showTableForm(context, table: table)
            : _showOccupiedTable(context, table),
        onLongPress: () => _showTableActions(context, table),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isAvailable
                  ? Colors.grey.shade200
                  : AppColors.warningBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.table_restaurant, size: 23, color: accent),
                  const Spacer(),
                  IconButton(
                    tooltip: 'QR ${table.name}',
                    onPressed: () => _showTableQr(table),
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.qr_code_2_outlined,
                      size: 19,
                      color: AppColors.primary,
                    ),
                  ),
                  _buildStatusBadge(table.status, compact: true),
                ],
              ),
              if (table.floor.isNotEmpty || table.area.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  [
                    table.floor,
                    table.area,
                  ].where((value) => value.isNotEmpty).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                table.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.chair_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${table.capacity} kursi',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
              if (!isAvailable) ...[
                const SizedBox(height: 5),
                Text(
                  '${table.activeOrderNo ?? 'Pesanan aktif'} · ${table.activeCustomerName?.trim().isNotEmpty == true ? table.activeCustomerName : 'Pelanggan umum'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_formatTime(table.activeOrderCreatedAt)} · ${_duration(table.activeOrderCreatedAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _currency(table.activeOrderTotal),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<PosTableModel> tables) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<PosTableBloc>().add(
          LoadTables(storeId: widget.storeId, search: _searchController.text),
        );
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tables.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _buildListTile(tables[index]),
      ),
    );
  }

  Widget _buildListTile(PosTableModel table) {
    final isAvailable = table.status == 'Tersedia';
    return Dismissible(
      key: Key(table.id),
      direction: isAvailable
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) => _confirmDelete(context, table),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: isAvailable
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.danger.withValues(alpha: 0.1),
            child: Icon(
              Icons.table_restaurant_rounded,
              color: isAvailable ? AppColors.primary : AppColors.danger,
            ),
          ),
          title: Text(
            table.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            isAvailable
                ? 'Kapasitas: ${table.capacity} kursi${table.floor.isNotEmpty || table.area.isNotEmpty ? ' · ${[table.floor, table.area].where((value) => value.isNotEmpty).join(' · ')}' : ''}'
                : '${table.activeOrderNo ?? 'Pesanan aktif'} · ${_formatTime(table.activeOrderCreatedAt)} · ${_duration(table.activeOrderCreatedAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusBadge(table.status),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                onSelected: (value) => _handleMenuAction(value, table),
                itemBuilder: (_) => isAvailable
                    ? const [
                        PopupMenuItem(
                          value: 'qr',
                          child: Text('Lihat / Cetak QR meja'),
                        ),
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Hapus',
                            style: TextStyle(color: AppColors.danger),
                          ),
                        ),
                      ]
                    : const [
                        PopupMenuItem(
                          value: 'qr',
                          child: Text('Lihat / Cetak QR meja'),
                        ),
                        PopupMenuItem(
                          value: 'order',
                          child: Text('Lihat pesanan aktif'),
                        ),
                      ],
              ),
            ],
          ),
          onTap: () => isAvailable
              ? _showTableForm(context, table: table)
              : _showOccupiedTable(context, table),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, {bool compact = false}) {
    final isAvailable = status.toLowerCase() != 'terisi';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.success : AppColors.warning,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
      ),
      child: Text(
        isAvailable ? 'Tersedia' : 'Terisi',
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 9 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<PosTableModel> _visibleTables(
    List<PosTableModel> source,
    int? capacity,
  ) {
    final result = source.where((table) {
      if (capacity != null && table.capacity != capacity) return false;
      if (_statusFilter.isNotEmpty && table.status != _statusFilter) {
        return false;
      }
      if (_locationFilter.isNotEmpty &&
          _tableLocation(table) != _locationFilter) {
        return false;
      }
      return true;
    }).toList();
    final farFuture = DateTime(9999);
    result.sort((a, b) {
      switch (_sort) {
        case 'name':
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case 'longest':
          return (_parseTimestamp(a.activeOrderCreatedAt) ?? farFuture)
              .compareTo(_parseTimestamp(b.activeOrderCreatedAt) ?? farFuture);
        case 'capacity':
          final byCapacity = b.capacity.compareTo(a.capacity);
          return byCapacity != 0
              ? byCapacity
              : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        default:
          final aOccupied = a.status.toLowerCase() == 'terisi' ? 0 : 1;
          final bOccupied = b.status.toLowerCase() == 'terisi' ? 0 : 1;
          final byStatus = aOccupied.compareTo(bOccupied);
          return byStatus != 0
              ? byStatus
              : a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });
    return result;
  }

  String _tableLocation(PosTableModel table) => [
    table.floor.trim(),
    table.area.trim(),
  ].where((value) => value.isNotEmpty).join(' · ');

  DateTime? _parseTimestamp(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
    final epoch = int.tryParse(value);
    if (epoch == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      value.length <= 10 ? epoch * 1000 : epoch,
    ).toLocal();
  }

  String _formatTime(String? raw) {
    final date = _parseTimestamp(raw);
    return date == null ? '-' : DateFormat('dd/MM, HH:mm').format(date);
  }

  String _duration(String? raw) {
    final date = _parseTimestamp(raw);
    if (date == null) return '-';
    final elapsed = DateTime.now().difference(date);
    if (elapsed.isNegative || elapsed.inMinutes < 1) return '< 1 menit';
    if (elapsed.inDays > 0) return '${elapsed.inDays} hari';
    if (elapsed.inHours > 0) {
      return '${elapsed.inHours}j ${elapsed.inMinutes.remainder(60)}m';
    }
    return '${elapsed.inMinutes} menit';
  }

  String _currency(num value) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(value);

  void _showOccupiedTable(BuildContext context, PosTableModel table) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                table.name,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${table.activeOrderNo ?? 'Pesanan aktif'} · ${table.activeCustomerName?.trim().isNotEmpty == true ? table.activeCustomerName : 'Pelanggan umum'}',
              ),
              const Divider(height: 24),
              _detailRow('Status pesanan', table.activeOrderStatus ?? 'Aktif'),
              _detailRow(
                'Waktu pesan',
                _formatTime(table.activeOrderCreatedAt),
              ),
              _detailRow('Durasi', _duration(table.activeOrderCreatedAt)),
              _detailRow('Jumlah item', '${table.activeOrderItemCount} item'),
              _detailRow('Total', _currency(table.activeOrderTotal)),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: widget.onOpenOrders == null
                    ? null
                    : () {
                        Navigator.pop(sheetContext);
                        widget.onOpenOrders!();
                      },
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Buka Pesanan Aktif'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  void _handleMenuAction(String action, PosTableModel table) {
    switch (action) {
      case 'qr':
        _showTableQr(table);
        break;
      case 'edit':
        _showTableForm(context, table: table);
        break;
      case 'delete':
        _confirmDelete(context, table);
        break;
      case 'order':
        _showOccupiedTable(context, table);
        break;
    }
  }

  void _showTableActions(BuildContext context, PosTableModel table) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2, color: AppColors.primary),
              title: const Text('Lihat / Cetak QR meja'),
              onTap: () {
                Navigator.pop(context);
                _showTableQr(table);
              },
            ),
            if (table.status.toLowerCase() == 'terisi')
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Lihat pesanan aktif'),
                onTap: () {
                  Navigator.pop(context);
                  _showOccupiedTable(context, table);
                },
              ),
            if (table.status.toLowerCase() != 'terisi') ...[
              ListTile(
                leading: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Edit Meja'),
                onTap: () {
                  Navigator.pop(context);
                  _showTableForm(context, table: table);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.danger,
                ),
                title: const Text(
                  'Hapus Meja',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, table);
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(
    BuildContext context,
    PosTableModel table,
  ) async {
    if (table.status.toLowerCase() == 'terisi' ||
        table.activeOrderId?.isNotEmpty == true) {
      AppToast.error(
        context,
        'Meja masih memiliki pesanan aktif dan tidak dapat dihapus.',
      );
      return false;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Meja'),
        content: Text('Apakah Anda yakin ingin menghapus "${table.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<PosTableBloc>().add(DeleteTable(id: table.id));
    }
    return confirmed;
  }

  void _showTableForm(BuildContext context, {PosTableModel? table}) {
    final bloc = context.read<PosTableBloc>();
    if (_isTablet) {
      showDialog(
        context: context,
        builder: (_) => PosKeyboardStableDialog(
          width: 420,
          height: 600,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: _TableFormContent(table: table, bloc: bloc),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => PosKeyboardStableSheet(
          heightFactor: .82,
          child: _TableFormContent(table: table, bloc: bloc),
        ),
      );
    }
  }
}

class _TableFormContent extends StatefulWidget {
  final PosTableModel? table;
  final PosTableBloc bloc;

  const _TableFormContent({this.table, required this.bloc});

  @override
  State<_TableFormContent> createState() => _TableFormContentState();
}

class _TableFormContentState extends State<_TableFormContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _floorController;
  late final TextEditingController _areaController;
  late final TextEditingController _locationNoteController;
  late int _selectedCapacity;
  bool get _isEditing => widget.table != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.table?.name ?? '');
    _floorController = TextEditingController(text: widget.table?.floor ?? '');
    _areaController = TextEditingController(text: widget.table?.area ?? '');
    _locationNoteController = TextEditingController(
      text: widget.table?.locationNote ?? '',
    );
    _selectedCapacity = widget.table?.capacity ?? 4;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _floorController.dispose();
    _areaController.dispose();
    _locationNoteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    if (_isEditing) {
      widget.bloc.add(
        UpdateTable(
          id: widget.table!.id,
          name: name,
          capacity: _selectedCapacity,
          floor: _floorController.text.trim(),
          area: _areaController.text.trim(),
          locationNote: _locationNoteController.text.trim(),
        ),
      );
    } else {
      widget.bloc.add(
        CreateTable(
          name: name,
          capacity: _selectedCapacity,
          floor: _floorController.text.trim(),
          area: _areaController.text.trim(),
          locationNote: _locationNoteController.text.trim(),
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle (for bottom sheet)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                _isEditing ? 'Edit Meja' : 'Tambah Meja Baru',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nama Meja',
                  hintText: 'Contoh: Meja 1',
                  prefixIcon: const Icon(Icons.table_restaurant_outlined),
                  filled: true,
                  fillColor: AppColors.bgSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama meja wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _floorController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Lantai / Level',
                        hintText: 'Lantai 2',
                        prefixIcon: Icon(Icons.layers_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _areaController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Area / Zona',
                        hintText: 'Outdoor',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationNoteController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Catatan Posisi',
                  hintText: 'Contoh: dekat taman',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: 16),

              // Capacity dropdown
              DropdownButtonFormField<int>(
                initialValue: _selectedCapacity,
                decoration: InputDecoration(
                  labelText: 'Kapasitas Kursi',
                  prefixIcon: const Icon(Icons.people_outline),
                  filled: true,
                  fillColor: AppColors.bgSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                items: List.generate(20, (i) => i + 1)
                    .map(
                      (n) =>
                          DropdownMenuItem(value: n, child: Text('$n kursi')),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCapacity = value);
                  }
                },
              ),
              const SizedBox(height: 28),

              // Submit button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isEditing ? 'Simpan Perubahan' : 'Tambah Meja',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
