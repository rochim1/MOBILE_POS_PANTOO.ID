import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/_core.dart';
import '../../../../core/network/graphql_client_provider.dart';
import '../../../../domain/models/pos_order_detail.dart';
import '../../../../domain/repositories/pos_order_repository.dart';
import '../../../../domain/repositories/pos_product_management_repository.dart';
import '../../../../injections.dart';
import '../../bloc/pos/pos_bloc.dart';
import '../../bloc/pos_order_management/pos_order_management_bloc.dart';
import '../../bloc/pos_order_management/pos_order_management_event.dart';
import '../../bloc/pos_order_management/pos_order_management_state.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/skeleton_loading.dart';
import '../../widgets/pos_ui.dart';
import 'utils/pos_order_age.dart';

class PosKitchenDisplayPage extends StatelessWidget {
  const PosKitchenDisplayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = context.read<PosBloc>().state;
    final features = Map<String, dynamic>.from(
      pos.runtimeConfig['features'] as Map? ?? const {},
    );
    final permissions = Map<String, dynamic>.from(
      pos.runtimeConfig['permissions'] as Map? ?? const {},
    );
    if (features['use_kitchen_flow'] != true) {
      return const PosEmptyState(
        icon: Icons.soup_kitchen_outlined,
        title: 'Tampilan dapur belum aktif',
        message: 'Aktifkan Kitchen Flow pada Pengaturan POS terlebih dahulu.',
      );
    }
    if (permissions['view_tables'] != true) {
      return const PosEmptyState(
        icon: Icons.lock_outline,
        title: 'Akses tidak tersedia',
        message: 'Akun ini tidak memiliki izin melihat antrean pesanan.',
      );
    }
    if (pos.stores.isEmpty) {
      return const PosEmptyState(
        icon: Icons.store_outlined,
        title: 'Toko belum tersedia',
        message: 'Buat dan aktifkan toko sebelum membuka tampilan dapur.',
      );
    }
    final activeStoreId = pos.activeShift?['toko_id']?.toString();
    final initialStoreId = pos.stores.any((item) => item.id == activeStoreId)
        ? activeStoreId!
        : pos.stores.first.id;
    return BlocProvider(
      create: (_) => sl<PosOrderManagementBloc>(),
      child: _KitchenBoard(
        initialStoreId: initialStoreId,
        canUpdate: permissions['manage_orders'] == true,
      ),
    );
  }
}

class _KitchenBoard extends StatefulWidget {
  final String initialStoreId;
  final bool canUpdate;
  const _KitchenBoard({required this.initialStoreId, required this.canUpdate});

  @override
  State<_KitchenBoard> createState() => _KitchenBoardState();
}

class _KitchenBoardState extends State<_KitchenBoard> {
  late String _storeId;
  String _filter = '';
  Timer? _refreshTimer;
  Timer? _slaTimer;
  Timer? _clockTimer;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  Timer? _eventDebounce;
  WebSocketChannel? _channel;
  bool _realtimeConnected = false;
  bool _disposed = false;
  DateTime _now = DateTime.now();
  int _warningMinutes = 15;
  int _criticalMinutes = 25;
  List<Map<String, dynamic>> _stations = const [];
  String _stationId = '';
  ({String orderId, String target, bool acknowledged})? _pendingMove;

  @override
  void initState() {
    super.initState();
    final runtime = context.read<PosBloc>().state.runtimeConfig;
    _warningMinutes = (runtime['sla_warning_minutes'] as num?)?.toInt() ?? 15;
    _criticalMinutes = (runtime['sla_critical_minutes'] as num?)?.toInt() ?? 25;
    _storeId = widget.initialStoreId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
      _loadStations();
      _loadSlaSettings();
      _connectRealtime();
    });
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => mounted && !_realtimeConnected ? _reload() : null,
    );
    _slaTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) _loadSlaSettings();
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    _slaTimer?.cancel();
    _clockTimer?.cancel();
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _eventDebounce?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _connectRealtime() async {
    if (_disposed || _channel != null) return;
    final token = await sl<FlutterSecureStorage>().read(key: 'auth_token');
    if (_disposed || token == null || token.isEmpty) return;
    try {
      final endpoint = Uri.parse(sl<GraphQLClientProvider>().endpointUrl);
      final uri = endpoint.replace(
        scheme: endpoint.scheme == 'https' ? 'wss' : 'ws',
        path: '/notifications',
        query: null,
        fragment: null,
      );
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      await channel.ready;
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
    try {
      final message = jsonDecode(raw.toString()) as Map<String, dynamic>;
      if (message['type'] == 'auth_success') {
        if (mounted) setState(() => _realtimeConnected = true);
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
      final eventStoreId = data['toko_id']?.toString() ?? '';
      if (eventStoreId.isNotEmpty && eventStoreId != _storeId) return;
      _eventDebounce?.cancel();
      _eventDebounce = Timer(const Duration(milliseconds: 250), _reload);
    } catch (_) {}
  }

  void _handleRealtimeClosed() {
    _channel = null;
    _pingTimer?.cancel();
    if (mounted && _realtimeConnected) {
      setState(() => _realtimeConnected = false);
    } else {
      _realtimeConnected = false;
    }
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _connectRealtime);
  }

  void _reload() {
    context.read<PosOrderManagementBloc>().add(
      LoadKitchenTickets(storeId: _storeId, stationId: _stationId),
    );
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

  Future<void> _loadStations() async {
    final rows = await sl<PosProductManagementRepository>()
        .getProductionStations(storeId: _storeId);
    if (!mounted) return;
    setState(() {
      _stations = rows;
      if (_stationId.isNotEmpty &&
          !rows.any((row) => row['_id']?.toString() == _stationId)) {
        _stationId = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stores = context.read<PosBloc>().state.stores;
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Material(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 620;
                    final storeSelector = SizedBox(
                      width: compact ? constraints.maxWidth : 300,
                      height: compact ? 40 : 48,
                      child: DropdownButtonFormField<String>(
                        initialValue: _storeId,
                        isDense: true,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Dapur toko',
                          prefixIcon: Icon(Icons.store_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: stores
                            .map(
                              (store) => DropdownMenuItem(
                                value: store.id,
                                child: Text(
                                  store.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _pendingMove != null
                            ? null
                            : (value) {
                                if (value == null || value == _storeId) return;
                                setState(() {
                                  _storeId = value;
                                  _stationId = '';
                                });
                                _loadStations();
                                _reload();
                              },
                      ),
                    );
                    final refresh = IconButton.filledTonal(
                      tooltip: 'Muat ulang antrean',
                      onPressed: _reload,
                      style: compact
                          ? IconButton.styleFrom(
                              fixedSize: const Size.square(40),
                              iconSize: 19,
                            )
                          : null,
                      icon: const Icon(Icons.refresh),
                    );
                    final stationSelector = SizedBox(
                      width: compact ? constraints.maxWidth : 220,
                      height: compact ? 40 : 48,
                      child: DropdownButtonFormField<String>(
                        initialValue: _stationId,
                        isDense: true,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Stasiun',
                          prefixIcon: Icon(Icons.soup_kitchen_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: Text('Semua stasiun'),
                          ),
                          ..._stations.map(
                            (row) => DropdownMenuItem(
                              value: row['_id']?.toString() ?? '',
                              child: Text(row['name']?.toString() ?? 'Stasiun'),
                            ),
                          ),
                        ],
                        onChanged: _pendingMove != null
                            ? null
                            : (value) {
                                setState(() => _stationId = value ?? '');
                                _reload();
                              },
                      ),
                    );
                    final liveStatus = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _realtimeConnected ? Icons.circle : Icons.wifi_off,
                          color: _realtimeConnected
                              ? AppColors.success
                              : AppColors.warning,
                          size: _realtimeConnected ? 10 : 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _realtimeConnected
                              ? 'Real-time'
                              : 'Fallback 60 detik',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          storeSelector,
                          const SizedBox(height: 6),
                          stationSelector,
                          const SizedBox(height: 6),
                          Row(children: [liveStatus, const Spacer(), refresh]),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        storeSelector,
                        const SizedBox(width: 10),
                        stationSelector,
                        const Spacer(),
                        liveStatus,
                        const SizedBox(width: 10),
                        refresh,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocConsumer<PosOrderManagementBloc, PosOrderManagementState>(
              listener: (context, state) {
                if (state.status == PosOrderManagementStatus.failure) {
                  if (_pendingMove?.acknowledged == true) {
                    setState(() => _pendingMove = null);
                  }
                  AppToast.error(context, state.errorMessage);
                } else if (state.status == PosOrderManagementStatus.loaded &&
                    _pendingMove?.acknowledged == true) {
                  setState(() => _pendingMove = null);
                }
              },
              builder: (context, state) {
                if (state.status == PosOrderManagementStatus.loading &&
                    state.orders.isEmpty &&
                    _pendingMove == null) {
                  return const PosOrderBoardSkeleton();
                }
                final orders = state.orders
                    .where(
                      (order) =>
                          ['Baru', 'Diproses', 'Siap'].contains(order.status),
                    )
                    .toList();
                if (orders.isEmpty && _pendingMove == null) {
                  return RefreshIndicator(
                    onRefresh: () async => _reload(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 90),
                        PosEmptyState(
                          icon: Icons.soup_kitchen_outlined,
                          title: 'Tidak ada antrean dapur',
                          message:
                              'Pesanan dengan produk “Kirim ke dapur” akan tampil di sini. Produk langsung jadi tidak masuk antrean.',
                        ),
                      ],
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 850) {
                      return _wideBoard(orders);
                    }
                    final filtered = _filter.isEmpty
                        ? orders
                        : orders
                              .where((order) => order.status == _filter)
                              .toList();
                    final pending = _pendingMove;
                    final showPending =
                        pending != null &&
                        (_filter.isEmpty || _filter == pending.target) &&
                        !filtered.any(
                          (order) =>
                              order.id == pending.orderId &&
                              order.status == pending.target,
                        );
                    return Column(
                      children: [
                        _filterBar(orders),
                        if (widget.canUpdate) _compactDropTargets(),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async => _reload(),
                            child: ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount:
                                  filtered.length + (showPending ? 1 : 0),
                              itemBuilder: (_, index) {
                                if (showPending && index == 0) {
                                  return _pendingTicket();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _draggableTicket(
                                    filtered[index - (showPending ? 1 : 0)],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar(List<PosOrderDetail> orders) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
    child: SegmentedButton<String>(
      segments: [
        ButtonSegment(value: '', label: Text('Semua (${orders.length})')),
        ButtonSegment(
          value: 'Baru',
          label: Text('Baru (${_count(orders, 'Baru')})'),
        ),
        ButtonSegment(
          value: 'Diproses',
          label: Text('Dibuat (${_count(orders, 'Diproses')})'),
        ),
        ButtonSegment(
          value: 'Siap',
          label: Text('Siap (${_count(orders, 'Siap')})'),
        ),
      ],
      selected: {_filter},
      onSelectionChanged: _pendingMove != null
          ? null
          : (value) => setState(() => _filter = value.first),
    ),
  );

  Widget _wideBoard(List<PosOrderDetail> orders) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: ['Baru', 'Diproses', 'Siap'].map((status) {
      final rows = orders.where((order) => order.status == status).toList();
      final pending = _pendingMove;
      final showPending =
          pending?.target == status &&
          !rows.any((order) => order.id == pending?.orderId);
      return Expanded(
        child: DragTarget<PosOrderDetail>(
          onWillAcceptWithDetails: (details) => _canDrop(details.data, status),
          onAcceptWithDetails: (details) => _advance(details.data, status),
          builder: (context, candidates, rejected) => AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: candidates.isNotEmpty
                ? _statusColor(status).withValues(alpha: .08)
                : Colors.transparent,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  color: _statusColor(status).withValues(alpha: .12),
                  child: Text(
                    '${_statusLabel(status)} · ${rows.length}',
                    style: TextStyle(
                      color: _statusColor(status),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: rows.length + (showPending ? 1 : 0),
                    itemBuilder: (_, index) => showPending && index == 0
                        ? _pendingTicket()
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _draggableTicket(
                              rows[index - (showPending ? 1 : 0)],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );

  Widget _compactDropTargets() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    child: Row(
      children: ['Diproses', 'Siap'].map((status) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: DragTarget<PosOrderDetail>(
              onWillAcceptWithDetails: (details) =>
                  _canDrop(details.data, status),
              onAcceptWithDetails: (details) => _advance(details.data, status),
              builder: (context, candidates, rejected) => Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: candidates.isNotEmpty
                      ? _statusColor(status).withValues(alpha: .18)
                      : Colors.white,
                  border: Border.all(color: _statusColor(status)),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Tarik ke ${_statusLabel(status)}',
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );

  Widget _draggableTicket(PosOrderDetail order) {
    if (!widget.canUpdate || order.status == 'Siap' || _pendingMove != null) {
      return _ticket(order);
    }
    return Draggable<PosOrderDetail>(
      data: order,
      maxSimultaneousDrags: 1,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 300,
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
      childWhenDragging: Opacity(opacity: .35, child: _ticket(order)),
      child: _ticket(order),
    );
  }

  bool _canDrop(PosOrderDetail order, String targetStatus) =>
      _pendingMove == null &&
      {'Baru': 'Diproses', 'Diproses': 'Siap'}[order.status] == targetStatus;

  Widget _pendingTicket() => Padding(
    key: const ValueKey('pending-kitchen-ticket'),
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(
      label: 'Memindahkan pesanan dapur',
      child: const PosOrderTicketSkeleton(),
    ),
  );

  Widget _ticket(PosOrderDetail order) {
    final status = order.status ?? 'Baru';
    final age = PosOrderAge.forOrder(
      order,
      _now,
      warningMinutes: _warningMinutes,
      criticalMinutes: _criticalMinutes,
      stationId: _stationId,
    );
    final ageColor = switch (age.tone) {
      PosOrderAgeTone.critical => AppColors.danger,
      PosOrderAgeTone.warning => AppColors.warning,
      PosOrderAgeTone.normal => AppColors.info,
    };
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: _statusColor(status), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: _statusColor(status).withValues(alpha: .1),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber ?? 'Order',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _fulfillment(order),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: age.label,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: ageColor.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: ageColor.withValues(alpha: .45),
                      ),
                    ),
                    child: Text(
                      age.durationLabel,
                      style: const TextStyle(
                        color: AppColors.heading,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 4),
            child: Text(
              order.customerName?.trim().isNotEmpty == true
                  ? order.customerName!
                  : 'Walk-in',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          ...order.items
              .where(
                (item) =>
                    item.preparationMode == 'station' &&
                    (_stationId.isEmpty ||
                        item.productionStationId == _stationId),
              )
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 34,
                        child: Text(
                          '${item.quantity ?? 0}×',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName ?? 'Produk',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (item.notes?.trim().isNotEmpty == true)
                              Text(
                                item.notes!,
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.canUpdate && item.id?.isNotEmpty == true)
                        IconButton.filledTonal(
                          tooltip: switch (item.productionStatus) {
                            'queued' => 'Mulai proses',
                            'preparing' => 'Tandai siap',
                            'ready' => 'Tandai sudah disajikan',
                            _ => 'Status selesai',
                          },
                          onPressed:
                              _pendingMove == null &&
                                  const {
                                    'queued',
                                    'preparing',
                                    'ready',
                                  }.contains(item.productionStatus)
                              ? () => _advanceItem(order, item)
                              : null,
                          icon: Icon(switch (item.productionStatus) {
                            'queued' => Icons.play_arrow,
                            'preparing' => Icons.check,
                            'ready' => Icons.room_service_outlined,
                            _ => Icons.done_all,
                          }),
                        ),
                    ],
                  ),
                ),
              ),
          if (order.note?.trim().isNotEmpty == true)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 2),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.warningBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Catatan: ${order.note}'),
            ),
          if (order.kitchenNote?.trim().isNotEmpty == true)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 2),
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.infoBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Untuk dapur: ${order.kitchenNote}'),
            ),
          if (!widget.canUpdate)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined),
                  SizedBox(width: 8),
                  Text('Hanya lihat'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _advanceItem(PosOrderDetail order, PosOrderItem item) async {
    if (_pendingMove != null) return;
    final orderId = order.id?.trim() ?? '';
    final itemId = item.id?.trim() ?? '';
    if (orderId.isEmpty || itemId.isEmpty) {
      AppToast.warning(
        context,
        'Item dapur belum memiliki ID yang valid. Muat ulang pesanan.',
      );
      _reload();
      return;
    }
    final nextStatus = switch (item.productionStatus) {
      'queued' => 'preparing',
      'preparing' => 'ready',
      'ready' => 'served',
      _ => item.productionStatus,
    };
    final result = await sl<PosOrderRepository>().updateOrderItemStatus(
      orderId,
      itemId,
      nextStatus,
      expectedRevision: item.revision,
    );
    if (!mounted) return;
    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (_) => _reload(),
    );
  }

  Future<void> _advance(
    PosOrderDetail order,
    String targetStatus, {
    String note = '',
  }) async {
    if (!_canDrop(order, targetStatus)) return;
    final orderId = order.id?.trim() ?? '';
    if (orderId.isEmpty) {
      AppToast.warning(context, 'ID pesanan tidak valid. Muat ulang pesanan.');
      _reload();
      return;
    }
    setState(() {
      _pendingMove = (
        orderId: orderId,
        target: targetStatus,
        acknowledged: false,
      );
      _filter = targetStatus;
    });
    try {
      final target =
          const {
            'Baru': 'queued',
            'Diproses': 'preparing',
            'Siap': 'ready',
            'Disajikan': 'served',
          }[targetStatus] ??
          targetStatus;
      final items = order.items
          .where(
            (item) =>
                item.preparationMode == 'station' &&
                (_stationId.isEmpty ||
                    item.productionStationId == _stationId) &&
                item.id?.isNotEmpty == true &&
                item.productionStatus != target,
          )
          .toList();
      // Orders with only ready-stock/instant products do not have kitchen items.
      // Their board movement is an order workflow transition, never an item
      // production update.
      if (items.isEmpty) {
        final result = await sl<PosOrderRepository>().updateOrderStatus(
          orderId,
          targetStatus,
          note: note,
        );
        if (!mounted) return;
        result.fold((failure) {
          setState(() => _pendingMove = null);
          AppToast.error(context, failure.message);
        }, (_) => _acknowledgeMove());
        return;
      }
      for (final item in items) {
        final result = await sl<PosOrderRepository>().updateOrderItemStatus(
          orderId,
          item.id!,
          target,
          note: note,
          expectedRevision: item.revision,
        );
        if (!mounted) return;
        if (result.isLeft()) {
          setState(() => _pendingMove = null);
          result.fold(
            (failure) => AppToast.error(context, failure.message),
            (_) {},
          );
          _reload();
          return;
        }
      }
      if (mounted) _acknowledgeMove();
    } catch (_) {
      if (!mounted) return;
      setState(() => _pendingMove = null);
      AppToast.error(context, 'Gagal memindahkan pesanan. Coba lagi.');
      _reload();
    }
  }

  void _acknowledgeMove() {
    final pending = _pendingMove;
    if (pending == null) return;
    setState(
      () => _pendingMove = (
        orderId: pending.orderId,
        target: pending.target,
        acknowledged: true,
      ),
    );
    _reload();
  }

  int _count(List<PosOrderDetail> orders, String status) =>
      orders.where((order) => order.status == status).length;
  String _statusLabel(String status) => switch (status) {
    'Baru' => 'Pesanan Baru',
    'Diproses' => 'Sedang Dibuat',
    'Siap' => 'Siap Disajikan',
    _ => status,
  };
  Color _statusColor(String status) => switch (status) {
    'Diproses' => AppColors.warning,
    'Siap' => AppColors.success,
    _ => AppColors.info,
  };
  String _fulfillment(PosOrderDetail order) => switch (order.orderType) {
    'dine_in' => order.tableName ?? 'Makan di tempat',
    'free_table' => 'Makan di tempat · tanpa meja',
    'delivery' || 'online_delivery' => 'Pesan antar',
    'quick_service' => 'Layanan cepat',
    'reservation' => 'Reservasi',
    _ => 'Bawa pulang',
  };
}
