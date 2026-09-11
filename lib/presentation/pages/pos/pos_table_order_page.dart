import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/_core.dart';
import '../../../../injections.dart';
import '../../bloc/pos_table/pos_table_bloc.dart';
import '../../bloc/pos_table/pos_table_event.dart';
import '../../bloc/pos_table/pos_table_state.dart';
import '../../bloc/pos_order_management/pos_order_management_bloc.dart';
import '../../bloc/pos_order_management/pos_order_management_event.dart';
import '../../bloc/pos_order_management/pos_order_management_state.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_ui.dart';
import '../../widgets/loading_indicator_widget.dart';
import '../../../../domain/models/pos_table.dart';
import '../../../../domain/models/pos_order_detail.dart';
import '../../bloc/pos/pos_bloc.dart';

class PosTableOrderPage extends StatelessWidget {
  final bool? _isGridView;
  bool get isGridView => _isGridView ?? true;

  const PosTableOrderPage({super.key, bool? isGridView})
    : _isGridView = isGridView;

  @override
  Widget build(BuildContext context) {
    final config = context.read<PosBloc>().state.runtimeConfig;
    final useTables = (config['features'] as Map?)?['use_tables'] == true;
    final canView = (config['permissions'] as Map?)?['view_tables'] == true;
    final storeId =
        context.read<PosBloc>().state.activeShift?['toko_id']?.toString() ?? '';
    if (!useTables || !canView || storeId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            !useTables
                ? 'Fitur meja tidak aktif untuk profil POS ini.'
                : !canView
                ? 'Anda tidak memiliki izin melihat table order.'
                : 'Buka shift kasir untuk menampilkan meja toko aktif.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<PosTableBloc>()..add(LoadTables(storeId: storeId)),
        ),
        BlocProvider(
          create: (_) =>
              sl<PosOrderManagementBloc>()
                ..add(LoadActiveOrders(storeId: storeId)),
        ),
      ],
      child: _ActiveOrderListView(storeId: storeId, isGridView: isGridView),
    );
  }
}

class _ActiveOrderListView extends StatefulWidget {
  final String storeId;
  final bool? _isGridView;
  bool get isGridView => _isGridView ?? true;

  const _ActiveOrderListView({required this.storeId, bool? isGridView})
    : _isGridView = isGridView;

  @override
  State<_ActiveOrderListView> createState() => _ActiveOrderListViewState();
}

class _ActiveOrderListViewState extends State<_ActiveOrderListView> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  Timer? _durationTicker;
  String _status = '';
  String _sort = 'newest';

  @override
  void initState() {
    super.initState();
    _durationTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _durationTicker?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    context.read<PosOrderManagementBloc>().add(
      LoadActiveOrders(
        storeId: widget.storeId,
        search: _searchController.text,
        status: _status,
      ),
    );
  }

  void _search(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          _toolbar(),
          Expanded(
            child: BlocConsumer<PosOrderManagementBloc, PosOrderManagementState>(
              listener: (context, state) {
                if (state.status == PosOrderManagementStatus.failure) {
                  AppToast.error(context, state.errorMessage);
                } else if (state.status ==
                    PosOrderManagementStatus.actionSuccess) {
                  AppToast.success(context, state.successMessage);
                }
              },
              builder: (context, state) {
                if (state.status == PosOrderManagementStatus.loading &&
                    state.orders.isEmpty) {
                  return const Center(child: LoadingIndicatorWidget());
                }
                if (state.orders.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        PosEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Tidak ada pesanan aktif',
                          message:
                              'Pesanan yang selesai atau lunas tersedia di Riwayat Transaksi.',
                        ),
                      ],
                    ),
                  );
                }
                final orders = _sortedOrders(state.orders);
                return RefreshIndicator(
                  onRefresh: () async => _reload(),
                  child: widget.isGridView
                      ? _orderCards(orders)
                      : _orderTable(orders),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbar() {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final search = TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: const InputDecoration(
                hintText: 'Cari nomor order atau pelanggan…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
            );
            final controls = Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Semua aktif')),
                      DropdownMenuItem(value: 'Baru', child: Text('Baru')),
                      DropdownMenuItem(
                        value: 'Diproses',
                        child: Text('Diproses'),
                      ),
                      DropdownMenuItem(value: 'Siap', child: Text('Siap')),
                    ],
                    onChanged: (value) {
                      setState(() => _status = value ?? '');
                      _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 170,
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
                        value: 'newest',
                        child: Text(
                          'Pesanan terbaru',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'oldest',
                        child: Text(
                          'Pesanan terlama',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'longest',
                        child: Text(
                          'Durasi terlama',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'highest_total',
                        child: Text(
                          'Total terbesar',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _sort = value ?? 'newest'),
                  ),
                ),
              ],
            );
            if (constraints.maxWidth < 650) {
              return Column(
                children: [
                  search,
                  const SizedBox(height: 10),
                  Align(alignment: Alignment.centerRight, child: controls),
                ],
              );
            }
            return Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 12),
                controls,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _orderCards(List<PosOrderDetail> orders) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 650
            ? 2
            : 1;
        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 166,
          ),
          itemCount: orders.length,
          itemBuilder: (_, index) => _activeOrderCard(orders[index], index),
        );
      },
    );
  }

  Widget _activeOrderCard(PosOrderDetail order, int index) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showActiveOrder(order),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${index + 1}.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.orderNumber ?? '-',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _statusBadge(order.status),
                ],
              ),
              const SizedBox(height: 9),
              Text(order.customerName ?? 'Pelanggan umum'),
              const SizedBox(height: 4),
              Text(
                '${order.tableName ?? 'Tanpa meja'} · ${order.items.length} item',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '${_orderDate(order.createdAt)} · ${_orderTime(order.createdAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _duration(order.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currency(order.totalAmount ?? 0),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orderTable(List<PosOrderDetail> orders) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth - 32,
                ),
                child: DataTable(
                  showCheckboxColumn: false,
                  columns: const [
                    DataColumn(label: Text('No.')),
                    DataColumn(label: Text('No. Order')),
                    DataColumn(label: Text('Pelanggan / Meja')),
                    DataColumn(label: Text('Tanggal Pesan')),
                    DataColumn(label: Text('Jam Pesan')),
                    DataColumn(label: Text('Durasi')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Total'), numeric: true),
                  ],
                  rows: orders.indexed
                      .map(
                        (entry) => DataRow(
                          key: ValueKey(entry.$2.id),
                          onSelectChanged: (_) => _showActiveOrder(entry.$2),
                          cells: [
                            DataCell(Text('${entry.$1 + 1}')),
                            DataCell(Text(entry.$2.orderNumber ?? '-')),
                            DataCell(
                              Text(
                                '${entry.$2.customerName ?? 'Pelanggan umum'}\n${entry.$2.tableName ?? 'Tanpa meja'}',
                              ),
                            ),
                            DataCell(Text(_orderDate(entry.$2.createdAt))),
                            DataCell(Text(_orderTime(entry.$2.createdAt))),
                            DataCell(Text(_duration(entry.$2.createdAt))),
                            DataCell(_statusBadge(entry.$2.status)),
                            DataCell(
                              Text(_currency(entry.$2.totalAmount ?? 0)),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String? status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      status ?? 'Aktif',
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  void _showActiveOrder(PosOrderDetail order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                order.orderNumber ?? 'Detail Pesanan',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              Text(
                '${order.customerName ?? 'Pelanggan umum'} · ${order.tableName ?? 'Tanpa meja'}',
              ),
              const SizedBox(height: 4),
              Text(
                'Dipesan ${_orderDate(order.createdAt)} pukul ${_orderTime(order.createdAt)} · ${_duration(order.createdAt)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Divider(height: 24),
              ...order.items.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.productName ?? '-'),
                  leading: Text('${item.quantity ?? 0}×'),
                  trailing: Text(
                    _currency((item.price ?? 0) * (item.quantity ?? 0)),
                  ),
                ),
              ),
              if (_nextStatus(order.status) case final next?) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.read<PosOrderManagementBloc>().add(
                      UpdateItemStatus(
                        orderId: order.id ?? '',
                        itemId: '',
                        newStatus: next,
                        tableId: order.tableId ?? '',
                        storeId: widget.storeId,
                        search: _searchController.text,
                        statusFilter: _status,
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(_nextStatusLabel(next)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _nextStatus(String? current) => switch (current) {
    'Baru' => 'preparing',
    'Diproses' => 'served',
    'Siap' => 'completed',
    _ => null,
  };

  String _nextStatusLabel(String status) => switch (status) {
    'preparing' => 'Mulai proses',
    'served' => 'Tandai siap',
    'completed' => 'Selesaikan pesanan',
    _ => 'Perbarui status',
  };

  String _currency(num value) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(value);

  DateTime? _parseTimestamp(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
    final milliseconds = int.tryParse(value);
    if (milliseconds == null) return null;
    final epochMilliseconds = value.length <= 10
        ? milliseconds * 1000
        : milliseconds;
    return DateTime.fromMillisecondsSinceEpoch(epochMilliseconds).toLocal();
  }

  List<PosOrderDetail> _sortedOrders(List<PosOrderDetail> source) {
    final orders = List<PosOrderDetail>.of(source);
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    final unknownLast = DateTime(9999);
    switch (_sort) {
      case 'oldest':
        orders.sort(
          (a, b) => (_parseTimestamp(a.createdAt) ?? unknownLast).compareTo(
            _parseTimestamp(b.createdAt) ?? unknownLast,
          ),
        );
      case 'longest':
        orders.sort(
          (a, b) => (_parseTimestamp(a.createdAt) ?? unknownLast).compareTo(
            _parseTimestamp(b.createdAt) ?? unknownLast,
          ),
        );
      case 'highest_total':
        orders.sort(
          (a, b) => (b.totalAmount ?? 0).compareTo(a.totalAmount ?? 0),
        );
      default:
        orders.sort(
          (a, b) => (_parseTimestamp(b.createdAt) ?? epoch).compareTo(
            _parseTimestamp(a.createdAt) ?? epoch,
          ),
        );
    }
    return orders;
  }

  String _orderDate(String? raw) {
    final date = _parseTimestamp(raw);
    return date == null ? '-' : DateFormat('dd/MM/yyyy').format(date);
  }

  String _orderTime(String? raw) {
    final date = _parseTimestamp(raw);
    return date == null ? '-' : DateFormat('HH:mm').format(date);
  }

  String _duration(String? raw) {
    final startedAt = _parseTimestamp(raw);
    if (startedAt == null) return 'Baru saja';
    final elapsed = DateTime.now().difference(startedAt);
    if (elapsed.isNegative || elapsed.inMinutes < 1) return '< 1 menit';
    if (elapsed.inDays > 0) {
      return '${elapsed.inDays} hari ${elapsed.inHours.remainder(24)} jam';
    }
    if (elapsed.inHours > 0) {
      return '${elapsed.inHours} jam ${elapsed.inMinutes.remainder(60)} menit';
    }
    return '${elapsed.inMinutes} menit';
  }
}

class _PosTableOrderView extends StatefulWidget {
  final String storeId;

  const _PosTableOrderView({required this.storeId});

  @override
  State<_PosTableOrderView> createState() => _PosTableOrderViewState();
}

class _PosTableOrderViewState extends State<_PosTableOrderView> {
  int? _selectedCapacity;

  void _showOrderDetails(BuildContext context, PosTableModel table) {
    context.read<PosOrderManagementBloc>().add(LoadTableOrders(table.id));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<PosOrderManagementBloc>(),
          child: _OrderDetailsSheet(table: table),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: BlocConsumer<PosTableBloc, PosTableState>(
        listener: (context, state) {
          if (state.status == PosTableStatus.failure) {
            AppToast.error(context, state.errorMessage);
          }
        },
        builder: (context, state) {
          if (state.status == PosTableStatus.loading ||
              state.status == PosTableStatus.initial) {
            return const Center(child: LoadingIndicatorWidget());
          }

          if (state.tables.isEmpty) {
            return const PosEmptyState(
              icon: Icons.table_restaurant_outlined,
              title: 'Belum ada meja',
              message:
                  'Tambahkan meja dari tab Peta & Pengaturan Meja agar order dine-in dapat diproses.',
            );
          }

          final capacities = state.tables.map((table) => table.capacity).toSet()
            ..removeWhere((capacity) => capacity <= 0);
          final sortedCapacities = capacities.toList()..sort();
          final activeCapacity = sortedCapacities.contains(_selectedCapacity)
              ? _selectedCapacity
              : null;
          final filteredTables = activeCapacity == null
              ? state.tables
              : state.tables
                    .where((table) => table.capacity == activeCapacity)
                    .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CapacityTabs(
                capacities: sortedCapacities,
                selectedCapacity: activeCapacity,
                totalTables: state.tables.length,
                onSelected: (capacity) =>
                    setState(() => _selectedCapacity = capacity),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => context.read<PosTableBloc>().add(
                    LoadTables(storeId: widget.storeId),
                  ),
                  child: filteredTables.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Icon(
                              Icons.table_restaurant_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Center(
                              child: Text(
                                'Tidak ada meja dengan kapasitas ini.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final columnCount = (constraints.maxWidth / 170)
                                .floor()
                                .clamp(2, 6);
                            return GridView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columnCount,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.35,
                                  ),
                              itemCount: filteredTables.length,
                              itemBuilder: (context, index) => _TableCard(
                                table: filteredTables[index],
                                onTap: () => _showOrderDetails(
                                  context,
                                  filteredTables[index],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CapacityTabs extends StatelessWidget {
  final List<int> capacities;
  final int? selectedCapacity;
  final int totalTables;
  final ValueChanged<int?> onSelected;

  const _CapacityTabs({
    required this.capacities,
    required this.selectedCapacity,
    required this.totalTables,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _tab(label: 'Semua ($totalTables)', capacity: null),
            for (final capacity in capacities) ...[
              const SizedBox(width: 8),
              _tab(label: '$capacity kursi', capacity: capacity),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tab({required String label, required int? capacity}) {
    final selected = selectedCapacity == capacity;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(capacity),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.bgPrimary,
      side: BorderSide(
        color: selected ? AppColors.primary : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    );
  }
}

class _TableCard extends StatelessWidget {
  final PosTableModel table;
  final VoidCallback onTap;

  const _TableCard({required this.table, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOccupied = table.status.toLowerCase() == 'terisi';
    final accent = isOccupied ? AppColors.warning : AppColors.primary;

    return Material(
      color: isOccupied ? AppColors.warningBackground : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isOccupied
                  ? AppColors.warningBorder
                  : Colors.grey.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.table_restaurant, size: 23, color: accent),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isOccupied ? AppColors.warning : AppColors.success,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isOccupied ? 'Terisi' : 'Tersedia',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                table.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.chair_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${table.capacity} kursi',
                    style: TextStyle(color: Colors.grey[700], fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderDetailsSheet extends StatelessWidget {
  final PosTableModel table;

  const _OrderDetailsSheet({required this.table});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child:
                BlocConsumer<PosOrderManagementBloc, PosOrderManagementState>(
                  listener: (context, state) {
                    if (state.status ==
                        PosOrderManagementStatus.actionSuccess) {
                      AppToast.success(context, state.successMessage);
                    } else if (state.status ==
                        PosOrderManagementStatus.failure) {
                      AppToast.error(context, state.errorMessage);
                    }
                  },
                  builder: (context, state) {
                    if (state.status == PosOrderManagementStatus.loading &&
                        state.orders.isEmpty) {
                      return const Center(child: LoadingIndicatorWidget());
                    }

                    if (state.orders.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return _buildOrderCard(context, state.orders[index]);
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.table_restaurant, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Pesanan Meja ${table.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Belum ada pesanan aktif di meja ini',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, PosOrderDetail order) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      order.customerName ?? 'Guest',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status ?? 'active',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: order.items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, idx) {
              final item = order.items[idx];
              return _buildOrderItem(item);
            },
          ),
          if (_nextOrderStatus(order.status) case final nextStatus?)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: FilledButton.icon(
                onPressed: () => context.read<PosOrderManagementBloc>().add(
                  UpdateItemStatus(
                    orderId: order.id!,
                    itemId: '',
                    newStatus: nextStatus,
                    tableId: table.id,
                  ),
                ),
                icon: const Icon(Icons.arrow_forward),
                label: Text(_nextOrderStatusLabel(nextStatus)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(PosOrderItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${item.quantity}x',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName ?? '-'),
              if (item.notes != null && item.notes!.isNotEmpty)
                Text(
                  item.notes!,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String? _nextOrderStatus(String? current) => switch (current) {
    'Baru' => 'preparing',
    'Diproses' => 'served',
    'Siap' => 'completed',
    _ => null,
  };

  String _nextOrderStatusLabel(String status) => switch (status) {
    'preparing' => 'Mulai proses',
    'served' => 'Tandai siap',
    'completed' => 'Selesaikan order',
    _ => 'Perbarui status',
  };
}
