import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../widgets/pos_keyboard_stable_sheet.dart';

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
import '../../widgets/skeleton_loading.dart';
import '../../../../domain/models/pos_table.dart';
import '../../../../domain/models/pos_order_detail.dart';
import '../../../../domain/models/pos_order.dart';
import '../../../../domain/repositories/pos_order_repository.dart';
import '../../../../core/network/graphql_client_provider.dart';
import 'utils/pos_order_age.dart';
import 'utils/pos_order_transition_policy.dart';
import '../../bloc/pos/pos_bloc.dart';
import 'pos_payment_page.dart';
import 'widgets/pos_active_order_mobile_filters.dart';
import 'widgets/pos_active_order_status_tabs.dart';

class PosTableOrderPage extends StatelessWidget {
  final ValueChanged<PosOrderDetail>? onEditOrder;
  final bool? _isGridView;
  bool get isGridView => _isGridView ?? true;

  const PosTableOrderPage({super.key, bool? isGridView, this.onEditOrder})
    : _isGridView = isGridView;

  @override
  Widget build(BuildContext context) {
    final config = context.read<PosBloc>().state.runtimeConfig;
    final canView = (config['permissions'] as Map?)?['view_tables'] == true;
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
    if (!canView || storeId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            !canView
                ? 'Anda tidak memiliki izin melihat pesanan aktif.'
                : allowOutOfShift
                ? 'Toko aktif belum tersedia untuk menampilkan meja.'
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
          create: (_) =>
              sl<PosOrderManagementBloc>()
                ..add(LoadActiveOrders(storeId: storeId)),
        ),
      ],
      child: _ActiveOrderListView(
        storeId: storeId,
        isGridView: isGridView,
        onEditOrder: onEditOrder,
      ),
    );
  }
}

class _ActiveOrderListView extends StatefulWidget {
  final ValueChanged<PosOrderDetail>? onEditOrder;
  final String storeId;
  final bool? _isGridView;
  bool get isGridView => _isGridView ?? true;

  const _ActiveOrderListView({
    required this.storeId,
    bool? isGridView,
    this.onEditOrder,
  }) : _isGridView = isGridView;

  @override
  State<_ActiveOrderListView> createState() => _ActiveOrderListViewState();
}

class _ActiveOrderListViewState extends State<_ActiveOrderListView> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  Timer? _durationTicker;
  Timer? _refreshTimer;
  Timer? _slaTimer;
  Timer? _eventDebounce;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  WebSocketChannel? _channel;
  bool _realtimeConnected = false;
  int _warningMinutes = 15;
  int _criticalMinutes = 25;
  bool _usesKitchenFlow = false;
  DateTime _now = DateTime.now();
  String _status = '';
  String _fulfillment = '';
  String _sort = 'oldest';
  String _period = 'all';
  ({String orderId, String target, bool acknowledged})? _pendingMove;

  static const _fulfillmentItems = <DropdownMenuItem<String>>[
    DropdownMenuItem(value: '', child: Text('Semua tipe')),
    DropdownMenuItem(value: 'dine_in', child: Text('Meja')),
    DropdownMenuItem(value: 'free_table', child: Text('Tanpa meja')),
    DropdownMenuItem(value: 'take_away', child: Text('Bawa pulang')),
    DropdownMenuItem(value: 'delivery', child: Text('Pesan antar')),
    DropdownMenuItem(value: 'quick_service', child: Text('Layanan cepat')),
    DropdownMenuItem(value: 'reservation', child: Text('Reservasi')),
  ];
  static const _statusItems = <DropdownMenuItem<String>>[
    DropdownMenuItem(value: '', child: Text('Semua aktif')),
    DropdownMenuItem(value: 'Baru', child: Text('Baru')),
    DropdownMenuItem(value: 'Diproses', child: Text('Diproses')),
    DropdownMenuItem(value: 'Siap', child: Text('Siap')),
    DropdownMenuItem(value: 'Disajikan', child: Text('Diserahkan')),
  ];
  static const _sortItems = <DropdownMenuItem<String>>[
    DropdownMenuItem(
      value: 'newest',
      child: Text('Pesanan terbaru', overflow: TextOverflow.ellipsis),
    ),
    DropdownMenuItem(
      value: 'oldest',
      child: Text('Pesanan terlama', overflow: TextOverflow.ellipsis),
    ),
    DropdownMenuItem(
      value: 'longest',
      child: Text('Durasi terlama', overflow: TextOverflow.ellipsis),
    ),
    DropdownMenuItem(
      value: 'highest_total',
      child: Text('Total terbesar', overflow: TextOverflow.ellipsis),
    ),
  ];
  static const _periodItems = <DropdownMenuItem<String>>[
    DropdownMenuItem(value: 'all', child: Text('Semua tanggal')),
    DropdownMenuItem(value: 'today', child: Text('Hari ini')),
    DropdownMenuItem(value: 'week', child: Text('7 hari terakhir')),
  ];

  @override
  void initState() {
    super.initState();
    final runtime = context.read<PosBloc>().state.runtimeConfig;
    _usesKitchenFlow =
        (runtime['features'] as Map?)?['use_kitchen_flow'] == true;
    _warningMinutes = (runtime['sla_warning_minutes'] as num?)?.toInt() ?? 15;
    _criticalMinutes = (runtime['sla_critical_minutes'] as num?)?.toInt() ?? 25;
    _durationTicker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted && !_realtimeConnected) _reloadCurrentPage();
    });
    _loadSlaSettings();
    _slaTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) _loadSlaSettings();
    });
    _connectRealtime();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _durationTicker?.cancel();
    _refreshTimer?.cancel();
    _slaTimer?.cancel();
    _eventDebounce?.cancel();
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSlaSettings() async {
    final result = await sl<PosOrderRepository>().getSlaThresholds();
    if (!mounted) return;
    if (result == null) return;
    setState(() {
      _warningMinutes = result.$1;
      _criticalMinutes = result.$2;
    });
  }

  Future<void> _connectRealtime() async {
    if (!mounted || _channel != null) return;
    try {
      final token = await sl<FlutterSecureStorage>().read(key: 'auth_token');
      if (!mounted || token == null || token.isEmpty) return;
      final endpoint = Uri.parse(sl<GraphQLClientProvider>().endpointUrl);
      final channel = WebSocketChannel.connect(
        endpoint.replace(
          scheme: endpoint.scheme == 'https' ? 'wss' : 'ws',
          path: '/notifications',
          query: null,
          fragment: null,
        ),
      );
      _channel = channel;
      await channel.ready;
      if (!mounted) {
        channel.sink.close();
        return;
      }
      channel.sink.add(
        jsonEncode({'type': 'auth', 'token': token, 'client_type': 'mobile'}),
      );
      channel.stream.listen(
        _handleRealtimeMessage,
        onError: (_) => _handleRealtimeClosed(),
        onDone: _handleRealtimeClosed,
        cancelOnError: true,
      );
    } catch (_) {
      _handleRealtimeClosed();
    }
  }

  void _handleRealtimeMessage(dynamic raw) {
    if (!mounted) return;
    try {
      final message = jsonDecode(raw.toString()) as Map<String, dynamic>;
      if (message['type'] == 'auth_success') {
        if (!mounted) return;
        setState(() => _realtimeConnected = true);
        _pingTimer?.cancel();
        _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
          _channel?.sink.add(jsonEncode({'type': 'ping'}));
        });
        return;
      }
      if (message['type'] != 'pos_order_changed') return;
      final data = Map<String, dynamic>.from(
        message['data'] as Map? ?? const {},
      );
      final storeId = data['toko_id']?.toString() ?? '';
      if (storeId.isNotEmpty && storeId != widget.storeId) return;
      _eventDebounce?.cancel();
      _eventDebounce = Timer(
        const Duration(milliseconds: 250),
        _reloadCurrentPage,
      );
    } catch (_) {}
  }

  void _handleRealtimeClosed() {
    _channel = null;
    _pingTimer?.cancel();
    if (!mounted) return;
    setState(() => _realtimeConnected = false);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _connectRealtime);
  }

  void _reloadCurrentPage() {
    _reload(page: context.read<PosOrderManagementBloc>().state.page);
  }

  void _reload({int page = 0}) {
    context.read<PosOrderManagementBloc>().add(
      LoadActiveOrders(
        storeId: widget.storeId,
        search: _searchController.text,
        status: _status,
        fulfillment: _fulfillment,
        dateFrom: _period == 'all'
            ? ''
            : DateFormat('yyyy-MM-dd').format(
                _period == 'today'
                    ? _now
                    : _now.subtract(const Duration(days: 6)),
              ),
        dateTo: _period == 'all' ? '' : DateFormat('yyyy-MM-dd').format(_now),
        sort: _sort,
        page: page,
      ),
    );
  }

  Future<void> _refreshOrders() async {
    final bloc = context.read<PosOrderManagementBloc>();
    final completed = bloc.stream.firstWhere(
      (state) =>
          state.status == PosOrderManagementStatus.loaded ||
          state.status == PosOrderManagementStatus.failure,
    );
    _reloadCurrentPage();
    try {
      await completed.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      // The swipe indicator must never trap the operator during an outage.
    } on StateError {
      // The page was disposed while refresh was in progress.
    }
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
                  if (_pendingMove != null) {
                    setState(() => _pendingMove = null);
                  }
                  AppToast.error(context, state.errorMessage);
                } else if (state.status ==
                    PosOrderManagementStatus.actionSuccess) {
                  final pending = _pendingMove;
                  if (pending != null) {
                    setState(
                      () => _pendingMove = (
                        orderId: pending.orderId,
                        target: pending.target,
                        acknowledged: true,
                      ),
                    );
                  }
                  AppToast.success(context, state.successMessage);
                } else if (state.status == PosOrderManagementStatus.loaded) {
                  final pending = _pendingMove;
                  if (pending != null &&
                      (pending.acknowledged ||
                          state.orders.any(
                            (order) =>
                                order.id == pending.orderId &&
                                order.status == pending.target,
                          ))) {
                    setState(() => _pendingMove = null);
                  }
                }
              },
              builder: (context, state) {
                if (state.status == PosOrderManagementStatus.loading &&
                    state.orders.isEmpty) {
                  return MediaQuery.sizeOf(context).width < 1120
                      ? ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: 3,
                          itemBuilder: (_, index) => const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: PosOrderTicketSkeleton(),
                          ),
                        )
                      : const PosOrderBoardSkeleton();
                }
                if (state.orders.isEmpty && _pendingMove == null) {
                  return RefreshIndicator(
                    onRefresh: _refreshOrders,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 100),
                        const PosEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Tidak ada pesanan aktif',
                          message:
                              'Pesanan yang selesai tersedia di Riwayat Transaksi.',
                        ),
                        if (_searchController.text.isNotEmpty ||
                            _fulfillment.isNotEmpty ||
                            _status.isNotEmpty ||
                            _period != 'all')
                          Center(
                            child: TextButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _fulfillment = '';
                                  _status = '';
                                  _period = 'all';
                                });
                                _reload();
                              },
                              child: const Text('Atur ulang filter'),
                            ),
                          ),
                      ],
                    ),
                  );
                }
                final orders = state.orders;
                return RefreshIndicator(
                  onRefresh: _refreshOrders,
                  child: LayoutBuilder(
                    builder: (context, constraints) =>
                        constraints.maxWidth < 1120
                        ? _mobileOrderQueue(orders, state.statusCounts)
                        : widget.isGridView
                        ? _orderKanban(
                            orders
                                .where(
                                  (order) =>
                                      _status.isEmpty ||
                                      order.status == _status,
                                )
                                .toList(),
                          )
                        : _orderTable(
                            orders
                                .where(
                                  (order) =>
                                      _status.isEmpty ||
                                      order.status == _status,
                                )
                                .toList(),
                          ),
                  ),
                );
              },
            ),
          ),
          BlocBuilder<PosOrderManagementBloc, PosOrderManagementState>(
            builder: (context, state) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Halaman sebelumnya',
                    onPressed:
                        state.page <= 0 ||
                            state.status == PosOrderManagementStatus.loading
                        ? null
                        : () => _reload(page: state.page - 1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Halaman ${state.page + 1} · ${state.total} pesanan'),
                  IconButton(
                    tooltip: 'Halaman berikutnya',
                    onPressed:
                        (state.page + 1) * 30 >= state.total ||
                            state.status == PosOrderManagementStatus.loading
                        ? null
                        : () => _reload(page: state.page + 1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
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
            if (constraints.maxWidth < 900) {
              final activeLabels = <String>[
                if (_fulfillment.isNotEmpty)
                  switch (_fulfillment) {
                    'dine_in' => 'Meja',
                    'free_table' => 'Tanpa meja',
                    'take_away' => 'Bawa pulang',
                    'delivery' => 'Pesan antar',
                    'quick_service' => 'Layanan cepat',
                    'reservation' => 'Reservasi',
                    _ => _fulfillment,
                  },
                if (_status.isNotEmpty) _orderStatusLabel(_status),
                if (_period == 'today') 'Hari ini',
                if (_period == 'week') '7 hari terakhir',
                if (_sort != 'oldest')
                  switch (_sort) {
                    'oldest' => 'Pesanan terlama',
                    'longest' => 'Durasi terlama',
                    'highest_total' => 'Total terbesar',
                    _ => _sort,
                  },
              ];
              return PosActiveOrderMobileFilters(
                searchController: _searchController,
                onSearchChanged: _search,
                onOpenFilters: _showMobileFilters,
                activeLabels: activeLabels,
              );
            }
            const controlHeight = 48.0;
            final search = SizedBox(
              height: controlHeight,
              child: TextField(
                controller: _searchController,
                onChanged: _search,
                decoration: const InputDecoration(
                  hintText: 'Cari nomor order atau pelanggan…',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            );
            final controls = Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                SizedBox(
                  width: 180,
                  height: controlHeight,
                  child: DropdownButtonFormField<String>(
                    initialValue: _fulfillment,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Tipe Pemenuhan',
                      border: OutlineInputBorder(),
                    ),
                    items: _fulfillmentItems,
                    onChanged: (value) {
                      setState(() => _fulfillment = value ?? '');
                      _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 150,
                  height: controlHeight,
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: _statusItems,
                    onChanged: (value) {
                      setState(() => _status = value ?? '');
                      _reload();
                    },
                  ),
                ),
                SizedBox(
                  width: 170,
                  height: controlHeight,
                  child: DropdownButtonFormField<String>(
                    initialValue: _sort,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Urutkan',
                      border: OutlineInputBorder(),
                    ),
                    items: _sortItems,
                    onChanged: (value) {
                      setState(() => _sort = value ?? 'newest');
                      _reload();
                    },
                  ),
                ),
              ],
            );
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

  Future<void> _showMobileFilters() async {
    var fulfillment = _fulfillment;
    var status = _status;
    var sort = _sort;
    var period = _period;
    final selected =
        await showModalBottomSheet<
          ({String fulfillment, String status, String sort, String period})
        >(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          builder: (sheetContext) => StatefulBuilder(
            builder: (sheetContext, setSheetState) => ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Filter pesanan aktif',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      key: ValueKey('fulfillment-$fulfillment'),
                      initialValue: fulfillment,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tipe pemenuhan',
                        border: OutlineInputBorder(),
                      ),
                      items: _fulfillmentItems,
                      onChanged: (value) =>
                          setSheetState(() => fulfillment = value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('status-$status'),
                      initialValue: status,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: _statusItems,
                      onChanged: (value) =>
                          setSheetState(() => status = value ?? ''),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('period-$period'),
                      initialValue: period,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Tanggal pesanan',
                        border: OutlineInputBorder(),
                      ),
                      items: _periodItems,
                      onChanged: (value) =>
                          setSheetState(() => period = value ?? 'all'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey('sort-$sort'),
                      initialValue: sort,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Urutkan',
                        border: OutlineInputBorder(),
                      ),
                      items: _sortItems,
                      onChanged: (value) =>
                          setSheetState(() => sort = value ?? 'newest'),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => setSheetState(() {
                            fulfillment = '';
                            status = '';
                            sort = 'oldest';
                            period = 'all';
                          }),
                          child: const Text('Atur ulang'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => Navigator.pop(sheetContext, (
                            fulfillment: fulfillment,
                            status: status,
                            sort: sort,
                            period: period,
                          )),
                          child: const Text('Terapkan'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
    if (!mounted || selected == null) return;
    setState(() {
      _fulfillment = selected.fulfillment;
      _status = selected.status;
      _sort = selected.sort;
      _period = selected.period;
    });
    _reload();
  }

  Widget _mobileOrderQueue(
    List<PosOrderDetail> orders,
    Map<String, int> serverCounts,
  ) {
    const statuses = ['Baru', 'Diproses', 'Siap', 'Disajikan'];
    final counts = <String, int>{
      '': serverCounts.values.fold(0, (sum, count) => sum + count),
    };
    for (final status in statuses) {
      counts[status] = serverCounts[status] ?? 0;
    }
    final visible = _status.isEmpty
        ? orders
        : orders.where((order) => order.status == _status).toList();
    final pending = _pendingMove;
    final showPending =
        pending != null &&
        (_status.isEmpty || _status == pending.target) &&
        !visible.any(
          (order) =>
              order.id == pending.orderId && order.status == pending.target,
        );
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount:
          1 +
          visible.length +
          (showPending ? 1 : 0) +
          (visible.isEmpty && !showPending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) {
          return PosActiveOrderStatusTabs(
            selectedStatus: _status,
            counts: counts,
            onSelected: (status) {
              setState(() => _status = status);
              _reload();
            },
          );
        }
        if (showPending && index == 1) {
          return const Padding(
            key: ValueKey('pending-order-card-mobile'),
            padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: PosOrderTicketSkeleton(),
          );
        }
        if (visible.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const PosEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Tidak ada pesanan pada filter ini',
                  message: 'Coba status lain atau atur ulang filter.',
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _status = '';
                      _fulfillment = '';
                      _period = 'all';
                    });
                    _reload();
                  },
                  child: const Text('Atur ulang filter'),
                ),
              ],
            ),
          );
        }
        final orderIndex = index - 1 - (showPending ? 1 : 0);
        return Padding(
          key: ValueKey('active-order-${visible[orderIndex].id}'),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: _activeOrderCard(
            visible[orderIndex],
            orderIndex,
            showActions: true,
          ),
        );
      },
    );
  }

  Widget _orderKanban(List<PosOrderDetail> orders) {
    const statuses = ['Baru', 'Diproses', 'Siap', 'Disajikan'];
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: constraints.maxWidth < 1120 ? 1120 : constraints.maxWidth - 24,
          height: constraints.maxHeight - 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: statuses.map((status) {
              final columnOrders = orders
                  .where((order) => order.status == status)
                  .toList();
              final pending = _pendingMove;
              final showPending =
                  pending?.target == status &&
                  !columnOrders.any((order) => order.id == pending?.orderId);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: DragTarget<PosOrderDetail>(
                    onWillAcceptWithDetails: (details) =>
                        _canMoveTo(details.data, status),
                    onAcceptWithDetails: (details) =>
                        _moveOrder(details.data, status),
                    builder: (context, candidates, rejected) => Container(
                      decoration: BoxDecoration(
                        color: candidates.isNotEmpty
                            ? _orderStatusColor(status).withValues(alpha: .12)
                            : AppColors.bgSecondary,
                        border: Border.all(
                          color: candidates.isNotEmpty
                              ? _orderStatusColor(status)
                              : AppColors.border,
                          width: candidates.isNotEmpty ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: _orderStatusColor(
                                status,
                              ).withValues(alpha: .12),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(11),
                              ),
                            ),
                            child: Text(
                              '${_orderStatusLabel(status)} · ${columnOrders.length}/${context.read<PosOrderManagementBloc>().state.statusCounts[status] ?? 0}',
                              style: TextStyle(
                                color: _orderStatusColor(status),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Expanded(
                            child: columnOrders.isEmpty && !showPending
                                ? const Center(
                                    child: Text(
                                      'Tarik pesanan ke sini',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(8),
                                    itemCount:
                                        columnOrders.length +
                                        (showPending ? 1 : 0),
                                    itemBuilder: (_, index) {
                                      if (showPending && index == 0) {
                                        return Padding(
                                          key: const ValueKey(
                                            'pending-order-card',
                                          ),
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Semantics(
                                            label: 'Memindahkan pesanan',
                                            child:
                                                const PosOrderTicketSkeleton(),
                                          ),
                                        );
                                      }
                                      final order =
                                          columnOrders[index -
                                              (showPending ? 1 : 0)];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: _draggableOrderCard(
                                          order,
                                          orders.indexOf(order),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _draggableOrderCard(PosOrderDetail order, int index) {
    final canDrag =
        order.status == 'Baru' ||
        order.status == 'Diproses' ||
        order.status == 'Siap';
    if (!canDrag || _pendingMove != null) {
      return _activeOrderCard(order, index);
    }
    return Draggable<PosOrderDetail>(
      data: order,
      maxSimultaneousDrags: 1,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 280,
          child: Card(
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                order.orderNumber ?? 'Order',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: .35,
        child: _activeOrderCard(order, index),
      ),
      child: _activeOrderCard(order, index),
    );
  }

  bool _canMoveTo(PosOrderDetail order, String target) =>
      _pendingMove == null && nextPosOrderStatus(order.status) == target;

  void _moveOrder(PosOrderDetail order, String status) {
    if (_pendingMove != null || !_canMoveTo(order, status)) return;
    if (shouldPayBeforeOrderTransition(order, status)) {
      _openPayment(order);
      return;
    }
    final orderId = order.id;
    if (orderId == null || orderId.isEmpty) {
      AppToast.error(context, 'ID pesanan tidak tersedia');
      return;
    }
    setState(() {
      _pendingMove = (orderId: orderId, target: status, acknowledged: false);
      if (MediaQuery.sizeOf(context).width < 1120 &&
          _status.isNotEmpty &&
          status != 'Selesai') {
        _status = status;
      }
    });
    context.read<PosOrderManagementBloc>().add(
      UpdateOrderStatus(
        orderId: orderId,
        newStatus: status,
        tableId: order.tableId ?? '',
        storeId: widget.storeId,
        search: _searchController.text,
        statusFilter: _status,
      ),
    );
  }

  String _orderStatusLabel(String status) => switch (status) {
    'Baru' => 'Pesanan Baru',
    'Diproses' => _usesKitchenFlow ? 'Sedang Dibuat' : 'Sedang Diproses',
    'Siap' => _usesKitchenFlow ? 'Siap Disajikan' : 'Siap Diserahkan',
    'Disajikan' => 'Sudah Diserahkan',
    _ => status,
  };

  Color _orderStatusColor(String status) => switch (status) {
    'Diproses' => AppColors.warning,
    'Siap' => AppColors.success,
    'Disajikan' => AppColors.primary,
    _ => AppColors.info,
  };

  Widget _activeOrderCard(
    PosOrderDetail order,
    int index, {
    bool showActions = false,
  }) {
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
                '${_fulfillmentLabel(order)} · ${order.items.length} item',
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
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _ageChip(order),
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
              if (showActions) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      order.paymentStatus == 'lunas'
                          ? Icons.check_circle_outline
                          : Icons.payments_outlined,
                      size: 15,
                      color: order.paymentStatus == 'lunas'
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    Text(
                      order.paymentStatus == 'lunas' ? 'Lunas' : 'Belum lunas',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (order.note?.isNotEmpty == true ||
                        order.kitchenNote?.isNotEmpty == true ||
                        order.handoverNote?.isNotEmpty == true)
                      const Tooltip(
                        message: 'Ada catatan pesanan',
                        child: Icon(Icons.sticky_note_2_outlined, size: 16),
                      ),
                  ],
                ),
                if (nextPosOrderStatus(order.status) case final next?) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: _pendingMove == null
                          ? () => _moveOrder(order, next)
                          : null,
                      icon: Icon(
                        shouldPayBeforeOrderTransition(order, next)
                            ? Icons.payments_outlined
                            : Icons.arrow_forward,
                        size: 18,
                      ),
                      label: Text(
                        shouldPayBeforeOrderTransition(order, next)
                            ? order.webOrderPayBeforeProcessing &&
                                      next != 'Selesai'
                                  ? 'Bayar dahulu'
                                  : 'Bayar pesanan'
                            : _nextStatusLabel(next),
                      ),
                    ),
                  ),
                ],
              ],
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
                                '${entry.$2.customerName ?? 'Pelanggan umum'}\n${_fulfillmentLabel(entry.$2)}',
                              ),
                            ),
                            DataCell(Text(_orderDate(entry.$2.createdAt))),
                            DataCell(Text(_orderTime(entry.$2.createdAt))),
                            DataCell(_ageChip(entry.$2)),
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

  Widget _statusBadge(String? status) {
    final color = _orderStatusColor(status ?? '');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        border: Border.all(color: color.withValues(alpha: .4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status ?? 'Aktif',
        style: const TextStyle(
          color: AppColors.heading,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _ageChip(PosOrderDetail order) {
    final age = PosOrderAge.forOrder(
      order,
      _now,
      warningMinutes: _warningMinutes,
      criticalMinutes: _criticalMinutes,
    );
    if (age.minutes == null) return const SizedBox.shrink();
    final color = switch (age.tone) {
      PosOrderAgeTone.critical => AppColors.danger,
      PosOrderAgeTone.warning => AppColors.warning,
      PosOrderAgeTone.normal => AppColors.info,
    };
    final phase = switch (age.phase) {
      'Menunggu dapur' => 'Dapur',
      'Menunggu penyerahan' => 'Serah',
      _ => 'Proses',
    };
    return Tooltip(
      message: age.label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: .4)),
        ),
        child: Text(
          '$phase ${age.durationLabel}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.heading,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _fulfillmentLabel(PosOrderDetail order) => switch (order.orderType) {
    'dine_in' => 'Meja ${order.tableName ?? '-'}',
    'free_table' => 'Makan di tempat · Tanpa meja',
    'delivery' || 'online_delivery' => 'Pesan antar',
    'quick_service' => 'Layanan cepat',
    'reservation' => 'Reservasi',
    _ => 'Bawa pulang',
  };

  void _showActiveOrder(PosOrderDetail order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: SingleChildScrollView(
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
                if (order.note?.isNotEmpty == true)
                  _orderNote('Catatan umum', order.note!),
                if (order.customerProfileRequested &&
                    order.customerPhone?.isNotEmpty == true)
                  _orderNote(
                    'Permintaan profil pelanggan',
                    '${order.customerName ?? 'Pemesan'} · ${order.customerPhone}. Konfirmasi nomor, lalu pilih atau tambah pelanggan saat pembayaran.',
                  ),
                if (order.kitchenNote?.isNotEmpty == true)
                  _orderNote('Untuk dapur', order.kitchenNote!),
                if (order.handoverNote?.isNotEmpty == true)
                  _orderNote('Penyerahan', order.handoverNote!),
                if (order.internalNote?.isNotEmpty == true)
                  _orderNote('Internal kasir', order.internalNote!),
                if (order.orderType == 'reservation') ...[
                  const SizedBox(height: 8),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reservasi · ${_reservationStatusLabel(order.reservationStatus ?? 'pending')}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order.reservationStartAt ?? '-'} – ${order.reservationEndAt ?? '-'}',
                          ),
                          Text(
                            '${order.reservationGuestCount <= 0 ? 1 : order.reservationGuestCount} tamu${order.reservationDepositAmount > 0 ? ' · Deposit ${_currency(order.reservationDepositAmount)} (${order.reservationDepositPaid ? 'lunas' : 'belum dibayar'})' : ''}',
                          ),
                          if (_reservationNext(
                            order.reservationStatus,
                          ).isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(sheetContext);
                                    await _rescheduleReservation(order);
                                  },
                                  icon: const Icon(Icons.event_repeat_outlined),
                                  label: const Text('Jadwalkan ulang'),
                                ),
                                ..._reservationNext(
                                  order.reservationStatus,
                                ).map(
                                  (status) => OutlinedButton(
                                    onPressed: () async {
                                      Navigator.pop(sheetContext);
                                      await _updateReservationStatus(
                                        order,
                                        status,
                                      );
                                    },
                                    child: Text(
                                      _reservationStatusLabel(status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
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
                if (order.serviceOrder case final service?) ...[
                  const Divider(height: 24),
                  Text(
                    'Proses layanan',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${service['service_mode'] ?? 'Layanan'} · ${service['weight_kg'] ?? 0} kg · ${service['item_count'] ?? 0} item',
                  ),
                  if ((service['bag_tag']?.toString() ?? '').isNotEmpty)
                    Text('Tag: ${service['bag_tag']}'),
                  const SizedBox(height: 10),
                  if ((service['service_lines'] as List?)?.isNotEmpty == true)
                    ...(service['service_lines'] as List).whereType<Map>().map(
                      (rawLine) => _serviceLineCard(
                        sheetContext,
                        order,
                        Map<String, dynamic>.from(rawLine),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _serviceNext(service['status']?.toString())
                          .map(
                            (status) => OutlinedButton(
                              onPressed: () async {
                                Navigator.pop(sheetContext);
                                await _updateServiceStatus(order, status);
                              },
                              child: Text(_serviceStatusLabel(status)),
                            ),
                          )
                          .toList(),
                    ),
                ],
                if (order.status == 'Baru' &&
                    order.paymentStatus != 'lunas') ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      if (widget.onEditOrder case final openEditor?) {
                        openEditor(order);
                      } else {
                        _editOrder(order);
                      }
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Ubah Pesanan'),
                  ),
                ],
                if ((order.promoCode ?? '').isNotEmpty &&
                    order.paymentStatus != 'lunas' &&
                    order.status != 'Batal' &&
                    order.status != 'Selesai') ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _removeOrderPromo(order);
                    },
                    icon: const Icon(Icons.local_offer_outlined),
                    label: Text('Lepas voucher ${order.promoCode}'),
                  ),
                ],
                if (nextPosOrderStatus(order.status) case final next?) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _pendingMove == null
                        ? () {
                            Navigator.pop(sheetContext);
                            _moveOrder(order, next);
                          }
                        : null,
                    icon: Icon(
                      shouldPayBeforeOrderTransition(order, next)
                          ? Icons.payments_outlined
                          : Icons.arrow_forward,
                    ),
                    label: Text(
                      shouldPayBeforeOrderTransition(order, next)
                          ? order.webOrderPayBeforeProcessing &&
                                    next != 'Selesai'
                                ? 'Bayar dahulu'
                                : 'Bayar pesanan'
                          : next == 'Selesai' && order.orderType == 'dine_in'
                          ? 'Tutup pesanan & kosongkan meja'
                          : _nextStatusLabel(next),
                    ),
                  ),
                ],
                if (order.statusHistory.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    'Riwayat status',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  ...order.statusHistory.reversed.map(
                    (entry) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.history, size: 18),
                      title: Text(entry['status']?.toString() ?? '-'),
                      subtitle: Text(
                        [
                              entry['actor_name']?.toString(),
                              entry['note']?.toString(),
                            ]
                            .where((value) => value?.trim().isNotEmpty == true)
                            .join(' · '),
                      ),
                      trailing: Text(
                        _orderTime(entry['at']?.toString()),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _orderNote(String label, String value) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.bgSecondary,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    ),
    child: Text('$label: $value'),
  );

  List<String> _serviceNext(String? status) => switch (status) {
    'estimasi' => const ['diterima', 'batal'],
    'diterima' => const ['ditimbang', 'disortir', 'dikerjakan', 'batal'],
    'ditimbang' => const ['disortir', 'batal'],
    'disortir' => const ['dicuci', 'dikerjakan', 'batal'],
    'dicuci' => const ['dikeringkan', 'batal'],
    'dikeringkan' => const ['disetrika', 'qc', 'batal'],
    'disetrika' => const ['qc', 'batal'],
    'qc' => const ['dikemas', 'selesai', 'batal'],
    'dikemas' => const ['siap_diambil', 'selesai', 'batal'],
    'dikerjakan' => const ['selesai', 'batal'],
    'selesai' => const ['siap_diambil', 'diambil'],
    'siap_diambil' => const ['diambil'],
    _ => const [],
  };

  String _serviceStatusLabel(String value) =>
      const {
        'diterima': 'Diterima',
        'ditimbang': 'Ditimbang',
        'disortir': 'Disortir',
        'dicuci': 'Dicuci',
        'dikeringkan': 'Dikeringkan',
        'disetrika': 'Disetrika',
        'qc': 'Quality Control',
        'dikemas': 'Dikemas',
        'dikerjakan': 'Dikerjakan',
        'selesai': 'Selesai produksi',
        'siap_diambil': 'Siap diambil',
        'diambil': 'Sudah diambil',
        'batal': 'Batalkan',
      }[value] ??
      value;

  List<String> _serviceLineNext(String? status) => switch (status) {
    'diterima' => const ['inspeksi', 'antre_produksi', 'vendor', 'batal'],
    'inspeksi' => const [
      'menunggu_persetujuan',
      'antre_produksi',
      'vendor',
      'batal',
    ],
    'menunggu_persetujuan' => const ['antre_produksi', 'batal'],
    'antre_produksi' => const ['diproses', 'vendor', 'batal'],
    'vendor' => const ['qc', 'antre_produksi', 'batal'],
    'diproses' => const ['qc', 'batal'],
    'qc' => const ['perlu_cuci_ulang', 'dikemas', 'batal'],
    'perlu_cuci_ulang' => const ['antre_produksi', 'diproses', 'batal'],
    'dikemas' => const ['siap_diambil'],
    'siap_diambil' => const ['diserahkan'],
    _ => const [],
  };

  String _serviceLineStatusLabel(String value) =>
      const {
        'inspeksi': 'Inspeksi',
        'menunggu_persetujuan': 'Menunggu persetujuan',
        'antre_produksi': 'Antre produksi',
        'vendor': 'Ke vendor',
        'diproses': 'Mulai proses',
        'qc': 'Quality Control',
        'perlu_cuci_ulang': 'Proses ulang',
        'dikemas': 'Dikemas',
        'siap_diambil': 'Siap diambil',
        'diserahkan': 'Diserahkan',
        'batal': 'Batalkan item',
      }[value] ??
      _serviceStatusLabel(value);

  Widget _serviceLineCard(
    BuildContext sheetContext,
    PosOrderDetail order,
    Map<String, dynamic> line,
  ) {
    final pricingBasis = line['pricing_basis']?.toString() ?? 'per_item';
    final quantity = pricingBasis == 'per_kg'
        ? (line['weight_kg'] as num?)?.toDouble() ?? 0
        : (line['quantity'] as num?)?.toDouble() ?? 0;
    final unit =
        line['unit']?.toString() ?? (pricingBasis == 'per_kg' ? 'kg' : 'item');
    final status = line['status']?.toString() ?? 'diterima';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  line['name']?.toString() ?? 'Item layanan',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text('${_quantityText(quantity)} $unit'),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Status: ${_serviceLineStatusLabel(status)} · ${_currency((line['subtotal'] as num?) ?? 0)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if ((line['tag_code']?.toString() ?? '').isNotEmpty)
            Text('Tag: ${line['tag_code']}'),
          if ((line['condition_notes']?.toString() ?? '').isNotEmpty)
            Text('Kondisi: ${line['condition_notes']}'),
          if (_serviceLineNext(status).isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _serviceLineNext(status)
                  .map(
                    (next) => OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _updateServiceLineStatus(order, line, next);
                      },
                      child: Text(_serviceLineStatusLabel(next)),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _updateServiceStatus(PosOrderDetail order, String status) async {
    final result = await sl<PosOrderRepository>().updateServiceOrderStatus(
      order.id ?? '',
      status,
    );
    if (!mounted) return;
    result.fold((failure) => AppToast.error(context, failure.message), (_) {
      AppToast.success(context, 'Status layanan diperbarui');
      _reload();
    });
  }

  List<String> _reservationNext(String? status) =>
      switch (status ?? 'pending') {
        'pending' => const ['confirmed', 'cancelled'],
        'confirmed' => const ['checked_in', 'cancelled', 'no_show'],
        'checked_in' => const ['seated', 'cancelled'],
        'seated' => const ['completed'],
        _ => const [],
      };

  String _reservationStatusLabel(String status) => switch (status) {
    'pending' => 'Menunggu konfirmasi',
    'confirmed' => 'Konfirmasi',
    'checked_in' => 'Check-in',
    'seated' => 'Dudukkan tamu',
    'completed' => 'Selesai',
    'cancelled' => 'Batalkan',
    'no_show' => 'Tidak hadir',
    _ => status,
  };

  Future<void> _updateReservationStatus(
    PosOrderDetail order,
    String status,
  ) async {
    final result = await sl<PosOrderRepository>().updateReservationStatus(
      order.id ?? '',
      status,
    );
    if (!mounted) return;
    result.fold((failure) => AppToast.error(context, failure.message), (_) {
      AppToast.success(context, 'Status reservasi diperbarui');
      _reload();
    });
  }

  Future<void> _rescheduleReservation(PosOrderDetail order) async {
    var start =
        DateTime.tryParse(order.reservationStartAt ?? '') ?? DateTime.now();
    var end =
        DateTime.tryParse(order.reservationEndAt ?? '') ??
        start.add(const Duration(hours: 2));
    final guests = TextEditingController(
      text:
          '${order.reservationGuestCount <= 0 ? 1 : order.reservationGuestCount}',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Jadwalkan ulang reservasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mulai'),
                subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(start)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: start,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(start),
                  );
                  if (time != null) {
                    setDialogState(
                      () => start = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      ),
                    );
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Selesai'),
                subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(end)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: end,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (date == null || !context.mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(end),
                  );
                  if (time != null) {
                    setDialogState(
                      () => end = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      ),
                    );
                  }
                },
              ),
              TextField(
                controller: guests,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah tamu'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    final guestCount = int.tryParse(guests.text) ?? 0;
    guests.dispose();
    if (confirmed != true || guestCount < 1 || !end.isAfter(start)) {
      if (confirmed == true && mounted) {
        AppToast.warning(context, 'Rentang waktu atau jumlah tamu tidak valid');
      }
      return;
    }
    final result = await sl<PosOrderRepository>().rescheduleReservation(
      order.id ?? '',
      startAt: start,
      endAt: end,
      tableId: order.tableId,
      guestCount: guestCount,
    );
    if (!mounted) return;
    result.fold((failure) => AppToast.error(context, failure.message), (_) {
      AppToast.success(context, 'Jadwal reservasi diperbarui');
      _reload();
    });
  }

  Future<void> _updateServiceLineStatus(
    PosOrderDetail order,
    Map<String, dynamic> line,
    String status,
  ) async {
    final result = await sl<PosOrderRepository>().updateServiceLineStatus(
      order.id ?? '',
      line['line_id']?.toString() ?? '',
      status,
    );
    if (!mounted) return;
    result.fold((failure) => AppToast.error(context, failure.message), (_) {
      AppToast.success(context, 'Status item layanan diperbarui');
      _reload();
    });
  }

  Future<void> _editOrder(PosOrderDetail order) async {
    final products = context.read<PosBloc>().state.products;
    final quantities = <String, double>{
      for (final item in order.items)
        if ((item.productId ?? '').isNotEmpty)
          item.productId!: item.quantity ?? 0,
    };
    var search = '';
    var saving = false;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final needle = search.trim().toLowerCase();
          final filtered = products
              .where(
                (product) =>
                    needle.isEmpty ||
                    product.name.toLowerCase().contains(needle) ||
                    product.code.toLowerCase().contains(needle) ||
                    product.barcode.toLowerCase().contains(needle),
              )
              .toList();
          final totalItems = quantities.values.fold<double>(0, (a, b) => a + b);
          return PosKeyboardStableSheet(
            heightFactor: .88,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ubah Pesanan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${order.orderNumber ?? ''} · ${_quantityText(totalItems)} item',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: saving
                            ? null
                            : () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    onChanged: (value) => setSheetState(() => search = value),
                    decoration: const InputDecoration(
                      labelText: 'Cari menu',
                      hintText: 'Nama, kode, atau barcode',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('Menu tidak ditemukan'))
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            12,
                            0,
                            12,
                            MediaQuery.viewInsetsOf(context).bottom,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            final qty = quantities[product.id] ?? 0.0;
                            return ListTile(
                              title: Text(product.name),
                              subtitle: Text(
                                '${_currency(product.price)} · Stok ${product.stock.toStringAsFixed(0)}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Kurangi',
                                    onPressed: qty <= 0
                                        ? null
                                        : () => setSheetState(() {
                                            if (qty <= 1) {
                                              quantities.remove(product.id);
                                            } else {
                                              quantities[product.id] =
                                                  qty - 1.0;
                                            }
                                          }),
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      _quantityText(qty),
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Tambah',
                                    onPressed: () => setSheetState(
                                      () => quantities[product.id] = qty + 1.0,
                                    ),
                                    icon: const Icon(Icons.add_circle_outline),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: saving || quantities.isEmpty
                          ? null
                          : () async {
                              setSheetState(() => saving = true);
                              final originalByProduct = {
                                for (final item in order.items)
                                  if ((item.productId ?? '').isNotEmpty)
                                    item.productId!: item,
                              };
                              final productById = {
                                for (final product in products)
                                  product.id: product,
                              };
                              final payload = quantities.entries.map((entry) {
                                final product = productById[entry.key];
                                final original = originalByProduct[entry.key];
                                return <String, dynamic>{
                                  'produk_id': entry.key,
                                  'nama':
                                      product?.name ?? original?.productName,
                                  'kode':
                                      product?.code ?? original?.productCode,
                                  'qty': entry.value,
                                  'unit':
                                      product?.saleUnit ??
                                      original?.unit ??
                                      'unit',
                                  'harga_satuan':
                                      product?.price ?? original?.price ?? 0,
                                  if ((original?.notes ?? '').isNotEmpty)
                                    'catatan': original!.notes,
                                };
                              }).toList();
                              final result = await sl<PosOrderRepository>()
                                  .updateOrderItems(order.id ?? '', payload);
                              if (!sheetContext.mounted) return;
                              result.fold((failure) {
                                setSheetState(() => saving = false);
                                AppToast.error(sheetContext, failure.message);
                              }, (_) => Navigator.pop(sheetContext, true));
                            },
                      icon: saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(saving ? 'Menyimpan...' : 'Simpan Perubahan'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (saved == true && mounted) {
      AppToast.success(context, 'Pesanan berhasil diperbarui');
      _reload();
    }
  }

  Future<void> _removeOrderPromo(PosOrderDetail order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Lepas voucher dari pesanan?'),
        content: Text(
          'Voucher ${order.promoCode} akan dilepas. Total tagihan dihitung ulang oleh server dan perlu ditinjau sebelum pembayaran.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Lepas voucher'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || order.id == null) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final result = await sl<PosOrderRepository>().removeOrderPromo(order.id!);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    result.fold((failure) => AppToast.error(context, failure.message), (
      newTotal,
    ) {
      AppToast.success(
        context,
        'Voucher dilepas. Total baru ${_currency(newTotal)}. Tinjau sebelum bayar.',
      );
      _reload();
    });
  }

  String _nextStatusLabel(String status) => switch (status) {
    'Diproses' => 'Mulai proses',
    'Siap' => 'Tandai siap',
    'Disajikan' => 'Tandai sudah disajikan/diserahkan',
    'Selesai' => 'Selesaikan pesanan',
    _ => 'Perbarui status',
  };

  Future<void> _openPayment(PosOrderDetail order) async {
    final posBloc = context.read<PosBloc>();
    final pendingOrder = PosOrder(
      id: order.id ?? '',
      invoice: order.orderNumber ?? '-',
      date: order.createdAt ?? '-',
      customer: order.customerName ?? 'Pelanggan umum',
      customerId: order.customerId,
      cashierName: 'Kasir',
      paymentMethod: '-',
      orderType: 'dine_in',
      total: order.totalAmount ?? 0,
      subtotal: order.subtotal ?? order.totalAmount ?? 0,
      discountAmount: order.discountAmount ?? 0,
      taxAmount: order.taxAmount ?? 0,
      note: order.note ?? '',
      status: order.status ?? 'Siap',
      paymentStatus: order.paymentStatus,
      isInvoice: true,
      source: 'kasir',
      items: order.items
          .map(
            (item) => <String, dynamic>{
              '_id': item.id,
              'nama': item.productName ?? '-',
              'qty': item.quantity ?? 0,
              'harga_satuan': item.price ?? 0,
              'subtotal': (item.price ?? 0) * (item.quantity ?? 0),
              'catatan': item.notes ?? '',
            },
          )
          .toList(),
    );
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: posBloc,
          child: PosPaymentPage(
            pendingOrder: pendingOrder,
            requestedCustomerName: order.customerProfileRequested
                ? (order.customerName ?? '')
                : '',
            requestedCustomerPhone: order.customerProfileRequested
                ? (order.customerPhone ?? '')
                : '',
          ),
        ),
      ),
    );
    if (mounted) _reload();
  }

  String _currency(num value) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(value);

  String _quantityText(double value) => value == value.truncateToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');

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
                      return const PosSkeletonList(count: 4);
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
                  UpdateOrderStatus(
                    orderId: order.id!,
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
    'Baru' => 'Diproses',
    'Diproses' => 'Siap',
    'Siap' => 'Disajikan',
    _ => null,
  };

  String _nextOrderStatusLabel(String status) => switch (status) {
    'Diproses' => 'Mulai proses',
    'Siap' => 'Tandai siap',
    'Disajikan' => 'Tandai sudah disajikan',
    _ => 'Perbarui status',
  };
}
