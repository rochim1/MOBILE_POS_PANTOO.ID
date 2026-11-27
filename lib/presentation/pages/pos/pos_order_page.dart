import '../../widgets/pos_record_skeletons.dart';
import '../../widgets/pos_content_skeletons.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
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
import '../../../../domain/repositories/pos_receipt_repository.dart';
import '../../../../domain/models/pos_receipt_template.dart';
import '../../../../injections.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_keyboard_stable_sheet.dart';
import 'pos_payment_page.dart';
import '../../widgets/pos_ui.dart';
import '../../widgets/pos_category_navigation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:printing/printing.dart';
import '../../../../core/network/graphql_client_provider.dart';
import 'utils/pos_invoice_source.dart';
import 'utils/pos_customer_invoice_document.dart';
import 'utils/pos_business_print_branding.dart';
import '../../../../core/receipt/pos_receipt_document_builder.dart';
import '../../../../core/receipt/pos_receipt_print_service.dart';

enum _OrderCategory { all, cashier, online, invoice }

class PosOrderPage extends StatefulWidget {
  final bool isGridView;

  const PosOrderPage({super.key, this.isGridView = true});

  @override
  State<PosOrderPage> createState() => _PosOrderPageState();
}

class _PosOrderPageState extends State<PosOrderPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _filtersExpanded = false;
  bool _printingInvoice = false;
  String _searchQuery = '';
  String _selectedStatus = 'Semua';
  String _selectedCashier = 'Semua';
  String _selectedPeriod = 'Semua';
  _OrderCategory _selectedCategory = _OrderCategory.all;
  Set<String>? _selectedOrderKeys;
  Set<String> get _selection => _selectedOrderKeys ??= <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PosBloc>().add(RefreshOrders());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      final matchesCategory = switch (_selectedCategory) {
        _OrderCategory.all => true,
        _OrderCategory.cashier => !order.isInvoice && !_isOnline(order),
        _OrderCategory.online => _isOnline(order),
        _OrderCategory.invoice => order.isInvoice,
      };

      return matchesText &&
          matchesStatus &&
          matchesCashier &&
          matchesPeriod &&
          matchesCategory;
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

        final categories = _categoryItems(state.orders);
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final content = Column(
              children: [
                if (!compact || _filtersExpanded)
                  _buildTransactionFilters(
                    cashiers,
                    compact: compact,
                    maxPanelHeight: (constraints.maxHeight * .45 - 48)
                        .clamp(0.0, 240.0)
                        .toDouble(),
                  ),
                const Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child:
                        state.ordersRefreshing ||
                            (state.status == PosStatus.loading &&
                                state.orders.isEmpty)
                        ? widget.isGridView
                              ? const PosRecordListSkeleton(
                                  kind: PosRecordSkeletonKind.transaction,
                                  padding: EdgeInsets.zero,
                                )
                              : const PosDataTableSkeleton(
                                  columns: 7,
                                  minWidth: 1000,
                                )
                        : widget.isGridView
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
                ),
              ],
            );
            if (!compact) {
              return Row(
                children: [
                  PosCategorySidebar<_OrderCategory>(
                    title: ('Kategori Order').tr(context),
                    items: categories,
                    selected: _selectedCategory,
                    onSelected: (value) =>
                        setState(() => _selectedCategory = value),
                    expandedWidth: 230,
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: content),
                ],
              );
            }
            return Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: PosCategoryDropdown<_OrderCategory>(
                          label: ('Kategori order').tr(context),
                          items: categories,
                          selected: _selectedCategory,
                          onSelected: (value) =>
                              setState(() => _selectedCategory = value),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildFilterToggle(),
                    ],
                  ),
                ),
                Expanded(child: content),
              ],
            );
          },
        );
      },
    );
  }

  List<PosCategoryItem<_OrderCategory>> _categoryItems(List<PosOrder> orders) {
    final cashier = orders.where((item) => !item.isInvoice && !_isOnline(item));
    final online = orders.where(_isOnline);
    final invoices = orders.where((item) => item.isInvoice);
    return [
      PosCategoryItem(
        value: _OrderCategory.all,
        icon: Icons.list_alt_outlined,
        label: posLocale(context).pos5ab6295dbc59((orders.length).toString()),
      ),
      PosCategoryItem(
        value: _OrderCategory.cashier,
        icon: Icons.point_of_sale_outlined,
        label: posLocale(context).posf9195de99c01((cashier.length).toString()),
      ),
      PosCategoryItem(
        value: _OrderCategory.online,
        icon: Icons.language_outlined,
        label: posLocale(context).pos46179ba2b7f3((online.length).toString()),
      ),
      PosCategoryItem(
        value: _OrderCategory.invoice,
        icon: Icons.request_quote_outlined,
        label: posLocale(context).pos1d39c9ee7007((invoices.length).toString()),
      ),
    ];
  }

  bool _isOnline(PosOrder order) {
    final source = (order.source ?? '').toLowerCase();
    return source.contains('online') ||
        source.contains('marketplace') ||
        source.contains('ecommerce');
  }

  Widget _buildFilterToggle() {
    final count = [
      _searchQuery.isNotEmpty,
      _selectedStatus != 'Semua',
      _selectedCashier != 'Semua',
      _selectedPeriod != 'Semua',
    ].where((active) => active).length;
    return Semantics(
      expanded: _filtersExpanded,
      child: IconButton.outlined(
        key: const Key('transaction_filter_toggle'),
        tooltip: ('Filter').tr(context),
        isSelected: _filtersExpanded,
        style: IconButton.styleFrom(
          minimumSize: const Size.square(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          if (_filtersExpanded) FocusScope.of(context).unfocus();
          setState(() => _filtersExpanded = !_filtersExpanded);
        },
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text('$count'),
          child: const Icon(Icons.filter_list_rounded),
        ),
      ),
    );
  }

  Widget _buildTransactionFilters(
    List<String> cashiers, {
    required bool compact,
    required double maxPanelHeight,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: !compact
          ? _buildFilterPanel(cashiers)
          : ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxPanelHeight),
              child: SingleChildScrollView(child: _buildFilterPanel(cashiers)),
            ),
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
      labelText: (label).tr(context),
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
      height: 56,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: _filterDecoration(
          label: ('Kasir').tr(context),
          icon: Icons.person_outline,
        ),
        items: [
          const DropdownMenuItem(value: 'Semua', child: PosText('Semua Kasir')),
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
      height: 56,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedPeriod,
        isExpanded: true,
        decoration: _filterDecoration(
          label: ('Periode').tr(context),
          icon: Icons.date_range_outlined,
        ),
        items: const [
          DropdownMenuItem(value: 'Semua', child: PosText('Semua Waktu')),
          DropdownMenuItem(value: 'Hari Ini', child: PosText('Hari Ini')),
          DropdownMenuItem(value: '7 Hari', child: PosText('7 Hari')),
          DropdownMenuItem(value: '30 Hari', child: PosText('30 Hari')),
        ],
        onChanged: (value) => setState(() => _selectedPeriod = value!),
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 56,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: ('Transaksi').tr(context),
          hintText: ('Cari invoice atau pelanggan...').tr(context),
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
      height: 56,
      child: DropdownButtonFormField<String>(
        initialValue: _selectedStatus,
        isExpanded: true,
        decoration: _filterDecoration(
          label: ('Status').tr(context),
          icon: Icons.filter_list_rounded,
        ),
        items: const [
          DropdownMenuItem(value: 'Semua', child: PosText('Semua Status')),
          DropdownMenuItem(value: 'Lunas', child: PosText('Lunas')),
          DropdownMenuItem(
            value: 'Belum Bayar',
            child: PosText('Invoice Belum Bayar'),
          ),
          DropdownMenuItem(value: 'Batal', child: PosText('Batal')),
        ],
        onChanged: (val) {
          if (val != null) setState(() => _selectedStatus = val);
        },
      ),
    );
  }

  Future<void> _refreshOrders() async {
    final bloc = context.read<PosBloc>();
    final completed = bloc.stream
        .skipWhile((state) => !state.ordersRefreshing)
        .firstWhere((state) => !state.ordersRefreshing);
    bloc.add(RefreshOrders());
    await completed;
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
        await _refreshOrders();
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
                  loadingMore
                      ? ('Memuat transaksi...').tr(context)
                      : ('Muat lebih banyak').tr(context),
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
                        child: PosText(
                          displayStatus,
                          style: TextStyle(
                            color: _badgeColor(displayStatus),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: ('Aksi transaksi').tr(context),
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
                      _buildInfoChip(
                        ('Tanggal').tr(context),
                        _formatDate(order.date),
                      ),
                      _buildInfoChip(
                        ('Total').tr(context),
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(order.total),
                      ),
                      _buildInfoChip(('Kasir').tr(context), order.cashierName),
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
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: PosText(
                            'Invoice tersimpan · menunggu pembayaran',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
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
                        label: const PosText('Proses Pembayaran'),
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
    final selectedOrders = orders
        .where((order) => _selection.contains(_selectionKey(order)))
        .toList();
    return RefreshIndicator(
      onRefresh: () async {
        await _refreshOrders();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (selectedOrders.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: .18),
                ),
              ),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        posLocale(
                          context,
                        ).posac37abdf6133((selectedOrders.length).toString()),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => setState(_selection.clear),
                    child: const PosText('Batalkan'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: selectedOrders.length == 1
                        ? () => _printReceipt(selectedOrders.single)
                        : null,
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const PosText('Print Struk'),
                  ),
                ],
              ),
            ),
          ],
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
                      DataColumn(label: PosText('Jenis')),
                      DataColumn(label: PosText('Nama')),
                      DataColumn(label: PosText('No Transaksi')),
                      DataColumn(label: PosText('Tanggal')),
                      DataColumn(label: PosText('Kasir')),
                      DataColumn(label: PosText('Status')),
                      DataColumn(label: PosText('Tagihan'), numeric: true),
                      DataColumn(label: PosText('Aksi')),
                    ],
                    rows: orders.map((order) {
                      final status = _displayStatus(order);
                      final key = _selectionKey(order);
                      return DataRow(
                        selected: _selection.contains(key),
                        onSelectChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selection.add(key);
                            } else {
                              _selection.remove(key);
                            }
                          });
                        },
                        cells: [
                          DataCell(PosText(_orderKind(order))),
                          DataCell(Text(order.customer)),
                          DataCell(Text(order.invoice)),
                          DataCell(Text(_formatDate(order.date))),
                          DataCell(Text(order.cashierName)),
                          DataCell(
                            PosText(
                              status,
                              style: TextStyle(
                                color: _badgeColor(status),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
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
                            order.isInvoice &&
                                    order.status.toLowerCase() != 'batal'
                                ? FilledButton.tonalIcon(
                                    onPressed: () =>
                                        _showPayInvoiceSheet(order),
                                    icon: const Icon(
                                      Icons.payments_outlined,
                                      size: 17,
                                    ),
                                    label: const PosText('Bayar'),
                                  )
                                : PopupMenuButton<String>(
                                    tooltip: ('Aksi transaksi').tr(context),
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
                    loadingMore
                        ? ('Memuat transaksi...').tr(context)
                        : ('Muat lebih banyak').tr(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _selectionKey(PosOrder order) =>
      order.id.isNotEmpty ? order.id : order.invoice;

  String _orderKind(PosOrder order) {
    if (order.isInvoice) return 'Faktur';
    if (_isOnline(order)) return 'Online';
    return 'Kasir';
  }

  String _displayStatus(PosOrder order) {
    if (order.status.toLowerCase() == 'batal') return 'Batal';
    if (order.paymentStatus.toLowerCase() == 'belum_bayar') {
      return 'Belum Bayar';
    }
    if (order.paymentStatus.toLowerCase() == 'lunas') return 'Lunas';
    if (order.paymentStatus == 'partial') return 'Sebagian dibayar';
    if (order.paymentStatus == 'credited') return 'Dikreditkan';
    if (order.paymentStatus == 'cancelled') return 'Invoice dibatalkan';
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
    const englishMonths = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthNames = posLocale(context).localeName == 'en'
        ? englishMonths
        : months;
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day ${monthNames[date.month - 1]} ${date.year}, $hour:$minute';
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
      builder: (sheetContext) => PosKeyboardStableSheet(
        heightFactor: .72,
        child: StatefulBuilder(
          builder: (context, setSheetState) => Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
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
                  const PosText(
                    'Proses Pembayaran Invoice',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                        const PosText('Total tagihan'),
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
                    decoration: InputDecoration(
                      labelText: ('Metode pembayaran').tr(context),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'tunai', child: PosText('Tunai')),
                      DropdownMenuItem(value: 'qris', child: PosText('QRIS')),
                      DropdownMenuItem(
                        value: 'debit',
                        child: PosText('Kartu Debit'),
                      ),
                      DropdownMenuItem(
                        value: 'kartu_kredit',
                        child: PosText('Kartu Kredit'),
                      ),
                      DropdownMenuItem(
                        value: 'transfer',
                        child: PosText('Transfer'),
                      ),
                      DropdownMenuItem(
                        value: 'e_wallet',
                        child: PosText('E-Wallet'),
                      ),
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
                      decoration: InputDecoration(
                        labelText: ('Uang diterima').tr(context),
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
                                this.context.read<PosBloc>().add(
                                  RefreshOrders(),
                                );
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
                        : const PosText('Bayar Sekarang'),
                  ),
                ],
              ),
            ),
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
        return AppColors.success;
      case 'sebagian':
      case 'belum bayar':
      case 'baru':
        return AppColors.warning;
      case 'batal':
        return AppColors.danger;
      default:
        return AppColors.warning;
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
    final content = SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    posLocale(
                      context,
                    ).posee94ad7e244c((order.invoice).toString()),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _badgeBackgroundColor(_displayStatus(order)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: PosText(
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
              posLocale(context).pose8576d8afa6c((order.customer).toString()),
              style: const TextStyle(fontSize: 15),
            ),
            Text(
              posLocale(
                context,
              ).posee16580f1d1c((_formatDate(order.date)).toString()),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const PosText(
              'Item Pembelian',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...order.items.map((item) {
              final name =
                  item['nama_inventaris']?.toString() ??
                  item['nama']?.toString() ??
                  '-';
              final qty = item['qty']?.toString() ?? '0';
              final unit = item['unit']?.toString() ?? 'unit';
              final components =
                  (item['component_consumptions'] as List? ?? const [])
                      .whereType<Map>()
                      .toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReceiptItem(
                      name,
                      '$qty $unit',
                      posLocale(context).pos70272f418def(
                        (formatRupiahAmount(
                          num.tryParse((item['subtotal'] ?? 0).toString()) ?? 0,
                        )).toString(),
                      ),
                    ),
                    if (components.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4, left: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const PosText(
                              'Komposisi dikonsumsi',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            ...components.map(
                              (component) => Text(
                                posLocale(context).pos04f490437f3e(
                                  (component['nama_inventaris'] ?? '-')
                                      .toString(),
                                  (component['qty_consumed_base'] ?? 0)
                                      .toString(),
                                  (component['unit'] ?? 'unit').toString(),
                                  (formatRupiahAmount(
                                    num.tryParse(
                                          (component['harga_pokok_total'] ?? 0)
                                              .toString(),
                                        ) ??
                                        0,
                                  )).toString(),
                                ),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            }),
            _buildReceiptItem(
              ('Metode pembayaran').tr(context),
              '',
              order.paymentMethod,
            ),
            _buildReceiptItem(('Kasir').tr(context), '', order.cashierName),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const PosText(
                  'Total Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  posLocale(context).pos70272f418def(
                    (formatRupiahAmount(order.total)).toString(),
                  ),
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
                  label: const PosText('Print Struk'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _printInvoice(order),
                  icon: const Icon(Icons.description_outlined),
                  label: const PosText('Print Invoice'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _printInvoice(order, share: true),
                  icon: const Icon(Icons.share_outlined),
                  label: Text(
                    posLocale(context).localeName.startsWith('en')
                        ? 'Share Invoice PDF'
                        : 'Bagikan Invoice PDF',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const PosText('Tutup'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SafeArea(
          child: PosKeyboardStableSheet(heightFactor: .85, child: content),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400,
              maxHeight: MediaQuery.sizeOf(context).height * .85,
            ),
            child: content,
          ),
        ),
      );
    }
  }

  List<PopupMenuEntry<String>> _orderActionItems() => [
    PopupMenuItem(
      value: 'detail',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.visibility_outlined),
        title: PosText('Lihat Detail'),
      ),
    ),
    PopupMenuItem(
      value: 'print',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.print_outlined),
        title: PosText('Print Struk'),
      ),
    ),
    PopupMenuItem(
      value: 'invoice',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.description_outlined),
        title: PosText('Print Invoice'),
      ),
    ),
    PopupMenuItem(
      value: 'share_invoice',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.share_outlined),
        title: Text(
          posLocale(context).localeName.startsWith('en')
              ? 'Share Invoice PDF'
              : 'Bagikan Invoice PDF',
        ),
      ),
    ),
  ];

  void _handleOrderAction(String action, PosOrder order, bool isMobile) {
    switch (action) {
      case 'print':
        _printReceipt(order);
        return;
      case 'invoice':
        _printInvoice(order);
        return;
      case 'share_invoice':
        _printInvoice(order, share: true);
        return;
      default:
        _showOrderDetailsDialog(context, order, isMobile);
    }
  }

  Future<Uint8List> _buildReceiptPdf(
    PosOrder order,
    PosReceiptTemplate template,
    Map<String, String> company,
  ) async {
    return PosReceiptDocumentBuilder.build(
      data: PosReceiptDocumentData(
        invoice: order.invoice,
        dateLabel: _formatDate(order.date),
        cashierName: order.cashierName,
        customerName: order.customer,
        paymentMethod: order.paymentMethod,
        orderType: order.orderType,
        subtotal: order.subtotal,
        discount: order.discountAmount,
        tax: order.taxAmount,
        total: order.total,
        note: order.note,
        items: order.items,
      ),
      template: template,
      company: company,
    );
  }

  Future<Uint8List> _buildInvoicePdf(PosOrder order) async {
    final language = posLocale(context).localeName;
    final provider = sl<GraphQLClientProvider>();
    final scope = provider.subscriptionScope;
    final client = provider.client;
    final invoice = await PosInvoiceSource.load(order, (
      query,
      variables,
    ) async {
      final result = await client
          .query(
            QueryOptions(
              document: gql(query),
              variables: variables,
              fetchPolicy: FetchPolicy.networkOnly,
            ),
          )
          .timeout(const Duration(seconds: 20));
      if (result.hasException) {
        throw StateError(
          'Saldo invoice belum dapat dimuat. Coba lagi saat terhubung.',
        );
      }
      return result.data ?? {};
    });
    final companyResult = await sl<PosReceiptRepository>()
        .getReceiptPrintData();
    final company = companyResult.fold<Map<String, String>>(
      (failure) => throw StateError(failure.message),
      (data) => data.company,
    );
    final logo = await PosBusinessPrintBranding.loadCompanyLogo(
      company['logo'] ?? '',
    );
    if (scope != provider.subscriptionScope ||
        !identical(client, provider.client)) {
      throw StateError('Sesi kasir berubah. Buka invoice kembali.');
    }
    final bytes = await PosCustomerInvoiceDocument.build(
      invoice: invoice,
      company: company,
      logoBytes: logo,
      language: language,
    );
    if (scope != provider.subscriptionScope ||
        !identical(client, provider.client)) {
      throw StateError('Sesi kasir berubah. Buka invoice kembali.');
    }
    return bytes;
  }

  Future<void> _printReceipt(PosOrder order) async {
    try {
      final templateResult = await sl<PosReceiptRepository>()
          .getReceiptPrintData();
      final printData = templateResult.fold(
        (_) => const PosReceiptPrintData(
          template: PosReceiptTemplate(),
          company: {},
        ),
        (value) => value,
      );
      final bytes = await _buildReceiptPdf(
        order,
        printData.template,
        printData.company,
      );
      await PosReceiptPrintService(sl()).printPdf(
        bytes: bytes,
        name: 'Struk-${order.invoice}',
        format: PosReceiptDocumentBuilder.pageFormatFor(
          printData.template,
          order.items.length,
        ),
      );
    } catch (error) {
      if (mounted) {
        AppToast.error(
          context,
          error.toString().contains('PRINTER_NOT_CONFIGURED')
              ? 'Pilih printer Bluetooth di Pengaturan Printer terlebih dahulu.'
              : 'Printer Bluetooth tidak merespons. Periksa koneksi printer.',
        );
      }
    }
  }

  Future<void> _printInvoice(PosOrder order, {bool share = false}) async {
    if (_printingInvoice) return;
    setState(() => _printingInvoice = true);
    try {
      final bytes = await _buildInvoicePdf(order);
      if (!mounted) return;
      if (share) {
        await Printing.sharePdf(
          bytes: bytes,
          filename:
              'Invoice-${order.invoice.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '-')}.pdf',
        );
        return;
      }
      await PosReceiptPrintService(sl()).printDocumentPdf(
        bytes: bytes,
        name:
            'Invoice-${order.invoice.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '-')}.pdf',
      );
    } catch (error) {
      if (mounted) {
        AppToast.error(
          context,
          error is StateError
              ? error.message.toString()
              : 'Gagal membuka layanan print invoice',
        );
      }
    } finally {
      if (mounted) setState(() => _printingInvoice = false);
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
