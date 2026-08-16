import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/pos/pos_bloc.dart';
import '../../bloc/pos/pos_event.dart';
import '../../bloc/pos/pos_state.dart';
import '../../../../domain/models/pos_order.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:intl/intl.dart';
import '../../../../domain/repositories/pos_repository.dart';
import '../../../../injections.dart';
import '../../widgets/app_toast.dart';
import 'pos_payment_page.dart';
import '../../widgets/pos_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PosOrderPage extends StatefulWidget {
  final bool isGridView;

  const PosOrderPage({super.key, this.isGridView = true});

  @override
  State<PosOrderPage> createState() => _PosOrderPageState();
}

class _PosOrderPageState extends State<PosOrderPage> {
  String _searchQuery = '';
  String _selectedStatus = 'Semua';
  String _selectedCashier = 'Semua';
  String _selectedPeriod = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PosBloc>().add(RefreshOrders());
    });
  }

  List<PosOrder> _getFilteredOrders(List<PosOrder> orders) {
    final query = _searchQuery.toLowerCase();
    return orders.where((order) {
      final matchesText =
          query.isEmpty ||
          order.invoice.toLowerCase().contains(query) ||
          order.customer.toLowerCase().contains(query);

      final matchesStatus =
          _selectedStatus == 'Semua' ||
          _displayStatus(order).toLowerCase() == _selectedStatus.toLowerCase();

      final matchesCashier =
          _selectedCashier == 'Semua' || order.cashierName == _selectedCashier;
      final orderDate = order.dateTime;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final matchesPeriod = switch (_selectedPeriod) {
        'Hari Ini' => !orderDate.isBefore(today),
        '7 Hari' => !orderDate.isBefore(
          today.subtract(const Duration(days: 6)),
        ),
        '30 Hari' => !orderDate.isBefore(
          today.subtract(const Duration(days: 29)),
        ),
        _ => true,
      };

      return matchesText && matchesStatus && matchesCashier && matchesPeriod;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        final filteredOrders = _getFilteredOrders(state.orders);
        final cashiers =
            state.orders
                .map((order) => order.cashierName)
                .where((name) => name.trim().isNotEmpty)
                .toSet()
                .toList()
              ..sort();

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final paid = state.orders
                      .where(
                        (order) => order.paymentStatus.toLowerCase() == 'lunas',
                      )
                      .toList();
                  final cards = [
                    PosStatCard(
                      label: 'Total Penjualan',
                      value:
                          'Rp ${formatRupiahInput(paid.fold<double>(0, (sum, order) => sum + order.total))}',
                      icon: Icons.payments_outlined,
                    ),
                    PosStatCard(
                      label: 'Total Transaksi',
                      value: '${paid.length}',
                      icon: Icons.receipt_long_outlined,
                      color: Colors.blue,
                    ),
                  ];
                  return constraints.maxWidth >= 620
                      ? Row(
                          children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 12),
                            Expanded(child: cards[1]),
                          ],
                        )
                      : Column(
                          children: [
                            cards[0],
                            const SizedBox(height: 10),
                            cards[1],
                          ],
                        );
                },
              ),
              const SizedBox(height: 14),
              _buildFilterPanel(cashiers),
              const SizedBox(height: 16),
              Expanded(
                child: widget.isGridView
                    ? _buildOrderCards(
                        filteredOrders,
                        hasMore: state.ordersHasMore,
                        loadingMore: state.ordersLoadingMore,
                      )
                    : _buildOrderTable(
                        filteredOrders,
                        hasMore: state.ordersHasMore,
                        loadingMore: state.ordersLoadingMore,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterPanel(List<String> cashiers) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = _buildSearchField();
        final status = _buildStatusDropdown(width: double.infinity);
        final cashier = _buildCashierDropdown(cashiers);
        final period = _buildPeriodDropdown();

        if (constraints.maxWidth >= 860) {
          return Row(
            children: [
              Expanded(flex: 3, child: search),
              const SizedBox(width: 10),
              Expanded(child: status),
              const SizedBox(width: 10),
              Expanded(child: cashier),
              const SizedBox(width: 10),
              Expanded(child: period),
            ],
          );
        }

        return Column(
          children: [
            search,
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: status),
                const SizedBox(width: 8),
                Expanded(child: period),
              ],
            ),
            const SizedBox(height: 8),
            cashier,
          ],
        );
      },
    );
  }

  InputDecoration _filterDecoration({required String label, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon == null ? null : Icon(icon, size: 19),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildCashierDropdown(List<String> cashiers) {
    final value = cashiers.contains(_selectedCashier)
        ? _selectedCashier
        : 'Semua';
    return SizedBox(
      height: 48,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: _filterDecoration(
          label: 'Kasir',
          icon: Icons.person_outline,
        ),
        items: [
          const DropdownMenuItem(value: 'Semua', child: Text('Semua Kasir')),
          ...cashiers.map(
            (cashier) => DropdownMenuItem(
              value: cashier,
              child: Text(cashier, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (value) => setState(() => _selectedCashier = value!),
      ),
    );
  }

  Widget _buildPeriodDropdown() {
    return SizedBox(
      height: 48,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedPeriod,
        isExpanded: true,
        decoration: _filterDecoration(
          label: 'Periode',
          icon: Icons.date_range_outlined,
        ),
        items: const [
          DropdownMenuItem(value: 'Semua', child: Text('Semua Waktu')),
          DropdownMenuItem(value: 'Hari Ini', child: Text('Hari Ini')),
          DropdownMenuItem(value: '7 Hari', child: Text('7 Hari')),
          DropdownMenuItem(value: '30 Hari', child: Text('30 Hari')),
        ],
        onChanged: (value) => setState(() => _selectedPeriod = value!),
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 48,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Cari invoice atau pelanggan...',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  Widget _buildStatusDropdown({required double width}) {
    return SizedBox(
      width: width,
      height: 48,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedStatus,
        isExpanded: true,
        decoration: _filterDecoration(
          label: 'Status',
          icon: Icons.filter_list_rounded,
        ),
        items: const [
          DropdownMenuItem(value: 'Semua', child: Text('Semua Status')),
          DropdownMenuItem(value: 'Lunas', child: Text('Lunas')),
          DropdownMenuItem(
            value: 'Belum Bayar',
            child: Text('Invoice Belum Bayar'),
          ),
          DropdownMenuItem(value: 'Batal', child: Text('Batal')),
        ],
        onChanged: (val) {
          if (val != null) setState(() => _selectedStatus = val);
        },
      ),
    );
  }

  Widget _buildOrderCards(
    List<PosOrder> orders, {
    required bool hasMore,
    required bool loadingMore,
  }) {
    if (orders.isEmpty) {
      return const PosEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Belum ada transaksi',
        message:
            'Transaksi dan invoice yang dibuat dari kasir akan tampil di halaman ini.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PosBloc>().add(RefreshOrders());
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: orders.length + (hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == orders.length) {
            return Center(
              child: OutlinedButton.icon(
                onPressed: loadingMore
                    ? null
                    : () => context.read<PosBloc>().add(LoadMoreOrders()),
                icon: loadingMore
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more),
                label: Text(
                  loadingMore ? 'Memuat transaksi...' : 'Muat lebih banyak',
                ),
              ),
            );
          }
          final order = orders[index];
          final displayStatus = _displayStatus(order);
          return InkWell(
            onTap: () => _showOrderDetailsDialog(context, order, true),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.04),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.invoice,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _badgeBackgroundColor(displayStatus),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          displayStatus,
                          style: TextStyle(
                            color: _badgeColor(displayStatus),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Aksi transaksi',
                        onSelected: (action) =>
                            _handleOrderAction(action, order, true),
                        itemBuilder: (_) => _orderActionItems(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    order.customer,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _buildInfoChip('Tanggal', _formatDate(order.date)),
                      _buildInfoChip(
                        'Total',
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(order.total),
                      ),
                      _buildInfoChip('Kasir', order.cashierName),
                    ],
                  ),
                  if (order.isInvoice &&
                      order.status.toLowerCase() != 'batal') ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.pending_actions_outlined,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Invoice tersimpan · menunggu pembayaran',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _showPayInvoiceSheet(order),
                        icon: const Icon(Icons.payments_outlined, size: 19),
                        label: const Text('Proses Pembayaran'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderTable(
    List<PosOrder> orders, {
    required bool hasMore,
    required bool loadingMore,
  }) {
    if (orders.isEmpty) {
      return const PosEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Belum ada transaksi',
        message:
            'Transaksi dan invoice yang dibuat dari kasir akan tampil di halaman ini.',
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<PosBloc>().add(RefreshOrders());
        await Future<void>.delayed(const Duration(milliseconds: 500));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.zero,
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll(
                      Colors.grey.shade100,
                    ),
                    columns: const [
                      DataColumn(label: Text('Invoice')),
                      DataColumn(label: Text('Tanggal')),
                      DataColumn(label: Text('Pelanggan')),
                      DataColumn(label: Text('Kasir')),
                      DataColumn(label: Text('Total'), numeric: true),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Aksi')),
                    ],
                    rows: orders.map((order) {
                      final status = _displayStatus(order);
                      return DataRow(
                        onSelectChanged: (_) =>
                            _showOrderDetailsDialog(context, order, false),
                        cells: [
                          DataCell(Text(order.invoice)),
                          DataCell(Text(_formatDate(order.date))),
                          DataCell(Text(order.customer)),
                          DataCell(Text(order.cashierName)),
                          DataCell(
                            Text(
                              NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(order.total),
                            ),
                          ),
                          DataCell(
                            Text(
                              status,
                              style: TextStyle(
                                color: _badgeColor(status),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DataCell(
                            order.isInvoice &&
                                    order.status.toLowerCase() != 'batal'
                                ? FilledButton.tonalIcon(
                                    onPressed: () =>
                                        _showPayInvoiceSheet(order),
                                    icon: const Icon(
                                      Icons.payments_outlined,
                                      size: 17,
                                    ),
                                    label: const Text('Bayar'),
                                  )
                                : PopupMenuButton<String>(
                                    tooltip: 'Aksi transaksi',
                                    onSelected: (action) => _handleOrderAction(
                                      action,
                                      order,
                                      false,
                                    ),
                                    itemBuilder: (_) => _orderActionItems(),
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
          if (hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: loadingMore
                      ? null
                      : () => context.read<PosBloc>().add(LoadMoreOrders()),
                  icon: loadingMore
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.expand_more),
                  label: Text(
                    loadingMore ? 'Memuat transaksi...' : 'Muat lebih banyak',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _displayStatus(PosOrder order) {
    if (order.status.toLowerCase() == 'batal') return 'Batal';
    if (order.paymentStatus.toLowerCase() == 'belum_bayar') {
      return 'Belum Bayar';
    }
    if (order.paymentStatus.toLowerCase() == 'lunas') return 'Lunas';
    return order.status;
  }

  String _formatDate(String value) {
    final date = PosOrder.parseDateValue(value);
    if (date.millisecondsSinceEpoch == 0) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day ${months[date.month - 1]} ${date.year}, $hour:$minute';
  }

  Future<void> _showPayInvoiceSheet(PosOrder order) async {
    if (order.id.isNotEmpty) {
      final posBloc = context.read<PosBloc>();
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: posBloc,
            child: PosPaymentPage(pendingOrder: order),
          ),
        ),
      );
      if (mounted) context.read<PosBloc>().add(RefreshOrders());
      return;
    }
    var method = 'tunai';
    final cashController = TextEditingController();
    var isSubmitting = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Proses Pembayaran Invoice',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                order.invoice,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total tagihan'),
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(order.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: const InputDecoration(
                  labelText: 'Metode pembayaran',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'tunai', child: Text('Tunai')),
                  DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                  DropdownMenuItem(value: 'debit', child: Text('Kartu Debit')),
                  DropdownMenuItem(
                    value: 'kartu_kredit',
                    child: Text('Kartu Kredit'),
                  ),
                  DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                  DropdownMenuItem(value: 'e_wallet', child: Text('E-Wallet')),
                ],
                onChanged: (value) =>
                    setSheetState(() => method = value ?? 'tunai'),
              ),
              if (method == 'tunai') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: cashController,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [RupiahInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Uang diterima',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final cash = method == 'tunai'
                            ? parseRupiah(cashController.text)
                            : order.total;
                        if (method == 'tunai' && cash < order.total) {
                          AppToast.error(
                            this.context,
                            'Uang diterima kurang dari total tagihan',
                          );
                          return;
                        }
                        setSheetState(() => isSubmitting = true);
                        final result = await sl<PosRepository>()
                            .payPendingOrder(
                              orderId: order.id,
                              method: method,
                              cashReceived: cash,
                            );
                        if (!mounted) return;
                        result.fold(
                          (failure) {
                            setSheetState(() => isSubmitting = false);
                            AppToast.error(this.context, failure.message);
                          },
                          (data) {
                            Navigator.pop(sheetContext);
                            this.context.read<PosBloc>().add(RefreshOrders());
                            AppToast.success(
                              this.context,
                              'Invoice ${order.invoice} berhasil dibayar',
                            );
                          },
                        );
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Bayar Sekarang'),
              ),
            ],
          ),
        ),
      ),
    );
    cashController.dispose();
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
  }

  Color _badgeColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
      case 'lunas':
        return Colors.green;
      case 'sebagian':
      case 'belum bayar':
      case 'baru':
        return Colors.orange;
      case 'batal':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Color _badgeBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
      case 'lunas':
        return const Color.fromRGBO(25, 135, 84, 0.15);
      case 'sebagian':
      case 'belum bayar':
      case 'baru':
        return const Color.fromRGBO(255, 159, 67, 0.15);
      case 'batal':
        return const Color.fromRGBO(220, 53, 69, 0.15);
      default:
        return const Color.fromRGBO(255, 159, 67, 0.15);
    }
  }

  void _showOrderDetailsDialog(
    BuildContext context,
    PosOrder order,
    bool isMobile,
  ) {
    final content = Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Invoice: ${order.invoice}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _badgeBackgroundColor(_displayStatus(order)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _displayStatus(order),
                  style: TextStyle(
                    color: _badgeColor(_displayStatus(order)),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Pelanggan: ${order.customer}',
            style: const TextStyle(fontSize: 15),
          ),
          Text(
            'Waktu: ${order.date}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Item Pembelian',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildReceiptItem('Metode pembayaran', '', order.paymentMethod),
          _buildReceiptItem('Kasir', '', order.cashierName),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'Rp ${order.total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _printReceipt(order),
                icon: const Icon(Icons.print_outlined),
                label: const Text('Print Nota'),
              ),
              OutlinedButton.icon(
                onPressed: () => _downloadInvoice(order),
                icon: const Icon(Icons.download_outlined),
                label: const Text('Download Invoice'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
        ],
      ),
    );

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => content,
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(width: 400, child: content),
        ),
      );
    }
  }

  List<PopupMenuEntry<String>> _orderActionItems() => const [
    PopupMenuItem(
      value: 'detail',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.visibility_outlined),
        title: Text('Lihat Detail'),
      ),
    ),
    PopupMenuItem(
      value: 'print',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.print_outlined),
        title: Text('Print Nota'),
      ),
    ),
    PopupMenuItem(
      value: 'download',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.download_outlined),
        title: Text('Download Invoice'),
      ),
    ),
  ];

  void _handleOrderAction(String action, PosOrder order, bool isMobile) {
    switch (action) {
      case 'print':
        _printReceipt(order);
        return;
      case 'download':
        _downloadInvoice(order);
        return;
      default:
        _showOrderDetailsDialog(context, order, isMobile);
    }
  }

  Future<Uint8List> _buildInvoicePdf(PosOrder order) async {
    final document = pw.Document(
      title: 'Invoice ${order.invoice}',
      author: 'Pantoo POS',
    );
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (_) => [
          pw.Text(
            'PANTOO POS',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Invoice ${order.invoice}'),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text('Tanggal: ${_formatDate(order.date)}'),
          pw.Text('Pelanggan: ${order.customer}'),
          pw.Text('Kasir: ${order.cashierName}'),
          pw.Text('Metode pembayaran: ${order.paymentMethod}'),
          if (order.note.trim().isNotEmpty) pw.Text('Catatan: ${order.note}'),
          pw.SizedBox(height: 18),
          if (order.items.isNotEmpty)
            pw.TableHelper.fromTextArray(
              headers: const ['Item', 'Qty', 'Harga', 'Subtotal'],
              data: order.items.map((item) {
                final name =
                    item['nama_inventaris']?.toString() ??
                    item['nama']?.toString() ??
                    '-';
                final qty = item['qty']?.toString() ?? '0';
                final price =
                    double.tryParse(
                      (item['harga_jual'] ?? item['harga_satuan'] ?? 0)
                          .toString(),
                    ) ??
                    0;
                final subtotal =
                    double.tryParse((item['subtotal'] ?? 0).toString()) ?? 0;
                return [
                  name,
                  qty,
                  currency.format(price),
                  currency.format(subtotal),
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          pw.SizedBox(height: 18),
          _pdfTotalRow('Subtotal', currency.format(order.subtotal)),
          if (order.discountAmount > 0)
            _pdfTotalRow('Diskon', '-${currency.format(order.discountAmount)}'),
          if (order.taxAmount > 0)
            _pdfTotalRow('Pajak', currency.format(order.taxAmount)),
          pw.Divider(),
          _pdfTotalRow('Total', currency.format(order.total), bold: true),
          pw.SizedBox(height: 28),
          pw.Center(child: pw.Text('Terima kasih atas kunjungan Anda')),
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _pdfTotalRow(String label, String value, {bool bold = false}) {
    final style = bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }

  Future<void> _printReceipt(PosOrder order) async {
    try {
      final bytes = await _buildInvoicePdf(order);
      await Printing.layoutPdf(
        name: 'Nota-${order.invoice}',
        onLayout: (_) async => bytes,
      );
    } catch (_) {
      if (mounted) AppToast.error(context, 'Gagal membuka layanan print');
    }
  }

  Future<void> _downloadInvoice(PosOrder order) async {
    try {
      final bytes = await _buildInvoicePdf(order);
      final directory =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final safeInvoice = order.invoice.replaceAll(
        RegExp(r'[^A-Za-z0-9_-]'),
        '_',
      );
      final file = File('${directory.path}/Invoice-$safeInvoice.pdf');
      await file.writeAsBytes(bytes, flush: true);
      if (mounted) {
        AppToast.success(context, 'Invoice tersimpan: ${file.path}');
      }
    } catch (_) {
      if (mounted) AppToast.error(context, 'Gagal mengunduh invoice');
    }
  }

  Widget _buildReceiptItem(String name, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text('$name ($qty)')),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
