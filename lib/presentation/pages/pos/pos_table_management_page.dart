import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_table.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_table/pos_table_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_table/pos_table_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_table/pos_table_state.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/app_toast.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_ui.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';

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
    final storeId =
        context.read<PosBloc>().state.activeShift?['toko_id']?.toString() ?? '';
    if (!useTables || !canManage || storeId.isEmpty) {
      return _TableAccessMessage(
        title: !useTables
            ? 'Fitur meja nonaktif'
            : !canManage
            ? 'Akses manajemen meja ditolak'
            : 'Shift kasir belum dibuka',
        message: !useTables
            ? 'Aktifkan fitur Meja / Ruangan melalui Pengaturan POS terlebih dahulu.'
            : !canManage
            ? 'Hubungi admin untuk mendapatkan izin mengelola meja.'
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
  String _sort = 'occupied_first';

  bool get _isTablet => MediaQuery.of(context).size.width >= 600;

  @override
  void initState() {
    super.initState();
    _durationTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _occupancyRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) _reload();
      },
    );
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
          final visibleTables = _visibleTables(state.tables, activeCapacity);
          return Column(
            children: [
              _buildSearchBar(),
              if (state.tables.isNotEmpty)
                _buildCapacityTabs(
                  sortedCapacities,
                  activeCapacity,
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

  Widget _buildCapacityTabs(
    List<int> capacities,
    int? activeCapacity,
    int totalTables,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _capacityChip('Semua ($totalTables)', null, activeCapacity),
            for (final capacity in capacities) ...[
              const SizedBox(width: 8),
              _capacityChip('$capacity kursi', capacity, activeCapacity),
            ],
          ],
        ),
      ),
    );
  }

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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final search = TextField(
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
          );
          final filters = Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              SizedBox(
                width: 145,
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  isDense: true,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status meja',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Semua')),
                    DropdownMenuItem(value: 'Terisi', child: Text('Terisi')),
                    DropdownMenuItem(
                      value: 'Tersedia',
                      child: Text('Tersedia'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _statusFilter = value ?? ''),
                ),
              ),
              SizedBox(
                width: 168,
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
                    DropdownMenuItem(value: 'name', child: Text('Nama meja')),
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
                  _buildStatusBadge(table.status, compact: true),
                ],
              ),
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
                ? 'Kapasitas: ${table.capacity} kursi'
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
    if (table.status.toLowerCase() == 'terisi') {
      _showOccupiedTable(context, table);
      return;
    }
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
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: 420,
            child: _TableFormContent(table: table, bloc: bloc),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
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
  late int _selectedCapacity;
  bool get _isEditing => widget.table != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.table?.name ?? '');
    _selectedCapacity = widget.table?.capacity ?? 4;
  }

  @override
  void dispose() {
    _nameController.dispose();
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
        ),
      );
    } else {
      widget.bloc.add(CreateTable(name: name, capacity: _selectedCapacity));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
