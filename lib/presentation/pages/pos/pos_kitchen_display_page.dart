import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/_core.dart';
import '../../../../core/network/graphql_client_provider.dart';
import '../../../../domain/models/pos_order_detail.dart';
import '../../../../injections.dart';
import '../../bloc/pos/pos_bloc.dart';
import '../../bloc/pos_order_management/pos_order_management_bloc.dart';
import '../../bloc/pos_order_management/pos_order_management_event.dart';
import '../../bloc/pos_order_management/pos_order_management_state.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/skeleton_loading.dart';
import '../../widgets/pos_ui.dart';

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
  Timer? _clockTimer;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  Timer? _eventDebounce;
  WebSocketChannel? _channel;
  bool _realtimeConnected = false;
  bool _disposed = false;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _storeId = widget.initialStoreId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
      _connectRealtime();
    });
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => mounted && !_realtimeConnected ? _reload() : null,
    );
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
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
      LoadActiveOrders(storeId: _storeId),
    );
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
                        onChanged: (value) {
                          if (value == null || value == _storeId) return;
                          setState(() => _storeId = value);
                          _reload();
                        },
                      ),
                    );
                    final refresh = IconButton.filledTonal(
                      tooltip: 'Muat ulang antrean',
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
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
                          const SizedBox(height: 10),
                          Row(children: [liveStatus, const Spacer(), refresh]),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        storeSelector,
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
            child:
                BlocConsumer<PosOrderManagementBloc, PosOrderManagementState>(
                  listener: (context, state) {
                    if (state.status == PosOrderManagementStatus.failure) {
                      AppToast.error(context, state.errorMessage);
                    }
                  },
                  builder: (context, state) {
                    if (state.status == PosOrderManagementStatus.loading &&
                        state.orders.isEmpty) {
                      return const PosOrderBoardSkeleton();
                    }
                    final orders = state.orders
                        .where(
                          (order) => [
                            'Baru',
                            'Diproses',
                            'Siap',
                          ].contains(order.status),
                        )
                        .toList();
                    if (orders.isEmpty) {
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
                                  'Pesanan baru akan tampil otomatis di sini.',
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
                        return Column(
                          children: [
                            _filterBar(orders),
                            if (widget.canUpdate) _compactDropTargets(),
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: () async => _reload(),
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: filtered.length,
                                  itemBuilder: (_, index) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _draggableTicket(filtered[index]),
                                  ),
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
      onSelectionChanged: (value) => setState(() => _filter = value.first),
    ),
  );

  Widget _wideBoard(List<PosOrderDetail> orders) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: ['Baru', 'Diproses', 'Siap'].map((status) {
      final rows = orders.where((order) => order.status == status).toList();
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
                    itemCount: rows.length,
                    itemBuilder: (_, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _draggableTicket(rows[index]),
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
    if (!widget.canUpdate || order.status == 'Siap') return _ticket(order);
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
      {'Baru': 'Diproses', 'Diproses': 'Siap'}[order.status] == targetStatus;

  Widget _ticket(PosOrderDetail order) {
    final status = order.status ?? 'Baru';
    final elapsed = _elapsed(order.createdAt);
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: elapsed.$2,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    elapsed.$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
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
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          style: const TextStyle(fontWeight: FontWeight.w600),
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: !widget.canUpdate
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Hanya lihat'),
                    )
                  : FilledButton.icon(
                      onPressed: () => status == 'Siap'
                          ? _confirmHandover(order)
                          : _advance(
                              order,
                              status == 'Baru' ? 'Diproses' : 'Siap',
                            ),
                      icon: Icon(
                        status == 'Baru'
                            ? Icons.play_arrow
                            : status == 'Diproses'
                            ? Icons.check
                            : Icons.room_service_outlined,
                      ),
                      label: Text(
                        status == 'Baru'
                            ? 'Mulai masak'
                            : status == 'Diproses'
                            ? 'Tandai siap'
                            : _handoverLabel(order),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _advance(PosOrderDetail order, String nextStatus, {String note = ''}) {
    context.read<PosOrderManagementBloc>().add(
      UpdateItemStatus(
        orderId: order.id ?? '',
        itemId: '',
        newStatus: nextStatus,
        tableId: order.tableId ?? '',
        storeId: _storeId,
        note: note,
      ),
    );
  }

  Future<void> _confirmHandover(PosOrderDetail order) async {
    final controller = TextEditingController(text: order.handoverNote ?? '');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_handoverLabel(order)),
        content: TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Catatan penyerahan (opsional)',
            hintText: 'Contoh: diterima pelanggan atau diserahkan ke kurir',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
    final note = controller.text.trim();
    controller.dispose();
    if (confirmed == true && mounted) {
      _advance(order, 'Disajikan', note: note);
    }
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
  String _handoverLabel(PosOrderDetail order) => switch (order.orderType) {
    'dine_in' || 'free_table' => 'Tandai sudah disajikan',
    'delivery' || 'online_delivery' => 'Tandai sudah dikirim',
    _ => 'Tandai sudah diserahkan',
  };
  (String, Color) _elapsed(String? raw) {
    final created = DateTime.tryParse(raw ?? '')?.toLocal();
    if (created == null) return ('-', Colors.blueGrey);
    final minutes = _now.difference(created).inMinutes.clamp(0, 9999);
    final label = minutes < 60
        ? '$minutes mnt'
        : '${minutes ~/ 60}j ${minutes % 60}m';
    return (
      label,
      minutes >= 30
          ? AppColors.danger
          : minutes >= 15
          ? AppColors.warning
          : AppColors.info,
    );
  }
}
