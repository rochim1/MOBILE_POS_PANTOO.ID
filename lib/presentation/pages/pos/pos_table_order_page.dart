import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  const PosTableOrderPage({super.key});

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
        BlocProvider(create: (_) => sl<PosOrderManagementBloc>()),
      ],
      child: _PosTableOrderView(storeId: storeId),
    );
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
                  'Tambahkan meja dari Manajemen Meja agar order dine-in dapat diproses.',
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
    final accent = isOccupied ? Colors.orange.shade700 : AppColors.primary;

    return Material(
      color: isOccupied ? Colors.orange.shade50 : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isOccupied ? Colors.orange.shade300 : Colors.grey.shade200,
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
                      color: isOccupied ? Colors.orange : Colors.green,
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
