import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../../injections.dart';
import '../../../core/_core.dart';
import '../../../domain/models/pos_stock.dart';
import '../../../domain/repositories/pos_inventory_repository.dart';
import '../../../domain/repositories/pos_receipt_repository.dart';
import '../../bloc/pos/pos_bloc.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_keyboard_stable_dialog.dart';
import '../../widgets/pos_category_navigation.dart';
import '../../widgets/inventory_action_style.dart';
import '../../widgets/skeleton_loading.dart';
import 'pos_purchase_return_page.dart';
import 'pos_stock_page.dart';
import 'pos_inventory_editor_page.dart';
import 'pos_purchase_receiving_page.dart';
import 'pos_purchase_payable_page.dart';
import 'pos_purchase_workspace.dart';
import 'pos_warehouse_page.dart';
import 'utils/pos_inventory_action_policy.dart';
import 'utils/pos_purchase_progress.dart';
import 'utils/pos_purchase_order_document.dart';
import 'widgets/pos_setup_tour.dart';

enum _InventorySection {
  warehouse,
  stock,
  purchase,
  opname,
  transfer,
  scrap,
  purchaseReturn,
}

class PosInventoryPage extends StatefulWidget {
  final bool isGridView;
  final String initialSection;
  final GlobalKey? warehouseTourKey;
  final GlobalKey? stockTourKey;
  final PosSetupTourTargets? setupTourTargets;
  final PosWarehouseTourController? warehouseTourController;
  const PosInventoryPage({
    super.key,
    this.isGridView = true,
    this.initialSection = 'stock',
    this.warehouseTourKey,
    this.stockTourKey,
    this.setupTourTargets,
    this.warehouseTourController,
  });

  @override
  State<PosInventoryPage> createState() => _PosInventoryPageState();
}

class _PosInventoryPageState extends State<PosInventoryPage> {
  late _InventorySection _selected;
  bool _checkingRestock = false;

  Future<({double quantity, String? error})> _openPurchaseQuantity(
    String inventoryId,
  ) async {
    const pageSize = 100;
    var page = 1;
    var total = 0;
    var quantity = 0.0;
    do {
      final result = await sl<PosInventoryRepository>().getDocuments(
        type: PosInventoryDocumentType.purchase,
        openQuantityOnly: true,
        inventoryId: inventoryId,
        page: page,
        limit: pageSize,
      );
      PosInventoryDocumentPage? data;
      String? failureMessage;
      result.fold(
        (failure) => failureMessage = failure.message,
        (value) => data = value,
      );
      if (failureMessage != null) {
        return (quantity: quantity, error: failureMessage);
      }
      final current = data;
      if (current == null) break;
      total = current.totalCount;
      for (final purchase in current.items) {
        for (final item
            in (purchase['items'] as List? ?? const []).whereType<Map>()) {
          if (item['inventaris_id']?.toString() != inventoryId) continue;
          final remaining =
              PosPurchaseProgress.orderedBase(item) -
              PosPurchaseProgress.receivedBase(item);
          if (remaining > 0) quantity += remaining;
        }
      }
      if (current.items.isEmpty) break;
      page++;
    } while ((page - 1) * pageSize < total);
    return (quantity: quantity, error: null);
  }

  Future<void> _createPurchaseForStock(PosStock stock) async {
    if (_checkingRestock) return;
    setState(() => _checkingRestock = true);
    AppToast.info(context, 'Memeriksa PO terbuka untuk barang ini…');
    final open = await _openPurchaseQuantity(stock.id);
    if (!mounted) return;
    setState(() => _checkingRestock = false);
    if (open.error != null) {
      AppToast.error(
        context,
        'PO terbuka belum dapat diperiksa: ${open.error}',
      );
      return;
    }
    final threshold = stock.titikReorder > 0
        ? stock.titikReorder
        : stock.stokMinimum > 0
        ? stock.stokMinimum
        : 1.0;
    final target = stock.stokMaksimum > threshold
        ? stock.stokMaksimum
        : threshold * 2;
    final needed = (target - stock.stok - open.quantity)
        .clamp(0.0, double.infinity)
        .toDouble();
    if (open.quantity > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sudah ada PO terbuka'),
          content: Text(
            '${stock.namaInventaris} masih memiliki ${open.quantity} ${stock.baseUnit} '
            'dalam PO yang belum diterima. '
            '${needed > 0 ? 'Usulan tambahan: $needed ${stock.baseUnit}.' : 'Jumlah PO terbuka sudah memenuhi target stok.'} '
            'Periksa PO yang ada sebelum membuat pesanan baru.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Tetap Buat PO'),
            ),
          ],
        ),
      );
      if (!mounted || proceed != true) return;
    }
    final suggestedQuantity = needed > 0 ? needed : 1.0;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PosInventoryEditorPage(
          type: PosInventoryDocumentType.purchase,
          initialInventoryId: stock.id,
          initialQuantity: suggestedQuantity,
        ),
      ),
    );
    if (mounted && saved == true) {
      setState(() => _selected = _InventorySection.purchase);
    }
  }

  @override
  void initState() {
    super.initState();
    _selected = _sectionFromName(widget.initialSection);
  }

  @override
  void didUpdateWidget(covariant PosInventoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection) {
      _selected = _sectionFromName(widget.initialSection);
    }
  }

  _InventorySection _sectionFromName(String value) => switch (value) {
    'warehouse' => _InventorySection.warehouse,
    'purchase' => _InventorySection.purchase,
    'opname' => _InventorySection.opname,
    'transfer' => _InventorySection.transfer,
    'scrap' => _InventorySection.scrap,
    'purchaseReturn' => _InventorySection.purchaseReturn,
    _ => _InventorySection.stock,
  };

  @override
  Widget build(BuildContext context) {
    final permissions = Map<String, dynamic>.from(
      context.watch<PosBloc>().state.runtimeConfig['permissions'] as Map? ??
          const {},
    );
    final features = Map<String, dynamic>.from(
      context.watch<PosBloc>().state.runtimeConfig['features'] as Map? ??
          const {},
    );
    final trackStock = features['track_stock'] != false;
    final inventoryPolicy = Map<String, dynamic>.from(
      context.watch<PosBloc>().state.runtimeConfig['inventory_policy']
              as Map? ??
          const {},
    );
    final transferEnabled =
        inventoryPolicy['use_transfer_request'] == true ||
        inventoryPolicy['inventory_profile'] == 'centralized' ||
        inventoryPolicy['inventory_profile'] == 'advanced' ||
        inventoryPolicy['inventory_profile'] == 'custom';
    final sections = <_InventoryMenu>[
      if (permissions['view_warehouses'] == true)
        const _InventoryMenu(
          _InventorySection.warehouse,
          'Warehouse & Lokasi',
          Icons.warehouse_outlined,
        ),
      if (trackStock &&
          (permissions['view_stock'] == true ||
              permissions['adjust_stock'] == true))
        const _InventoryMenu(
          _InventorySection.stock,
          'Stok Inventori',
          Icons.inventory_2_outlined,
        ),
      if (trackStock && permissions['view_inventory_purchases'] == true)
        const _InventoryMenu(
          _InventorySection.purchase,
          'Pembelian & Penerimaan',
          Icons.receipt_long_outlined,
        ),
      if (trackStock && permissions['view_inventory_opnames'] == true)
        const _InventoryMenu(
          _InventorySection.opname,
          'Stok Opname',
          Icons.fact_check_outlined,
        ),
      if (trackStock &&
          transferEnabled &&
          permissions['view_inventory_transfers'] == true)
        const _InventoryMenu(
          _InventorySection.transfer,
          'Mutasi Stok',
          Icons.move_to_inbox_outlined,
        ),
      if (trackStock && permissions['view_inventory_scraps'] == true)
        const _InventoryMenu(
          _InventorySection.scrap,
          'Stok Terbuang',
          Icons.delete_sweep_outlined,
        ),
      if (trackStock && permissions['view_purchase_returns'] == true)
        const _InventoryMenu(
          _InventorySection.purchaseReturn,
          'Retur Pembelian',
          Icons.assignment_return_outlined,
        ),
    ];
    if (sections.isEmpty) {
      return const Center(
        child: Text('Akun ini belum memiliki akses inventori.'),
      );
    }
    if (!sections.any((item) => item.section == _selected)) {
      _selected = sections.first.section;
    }
    final content = _content(permissions);
    final categoryItems = sections
        .map(
          (item) => PosCategoryItem<_InventorySection>(
            value: item.section,
            icon: item.icon,
            label: item.label,
          ),
        )
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        if (wide) {
          return Row(
            children: [
              PosCategorySidebar<_InventorySection>(
                title: 'Kategori Inventori',
                items: categoryItems,
                selected: _selected,
                onSelected: (value) => setState(() => _selected = value),
                expandedWidth: 230,
                footer: 'Data inventori mengikuti akses gudang akun kasir.',
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
              child: PosCategoryDropdown<_InventorySection>(
                label: 'Kategori inventori',
                items: categoryItems,
                selected: _selected,
                onSelected: (value) => setState(() => _selected = value),
              ),
            ),
            Expanded(child: content),
          ],
        );
      },
    );
  }

  Widget _content(Map<String, dynamic> permissions) => switch (_selected) {
    _InventorySection.warehouse => PosWarehousePage(
      canCreate: permissions['create_warehouses'] == true,
      canUpdate: permissions['update_warehouses'] == true,
      canDelete: permissions['delete_warehouses'] == true,
      setupTourKey: widget.warehouseTourKey,
      setupTourTargets: widget.setupTourTargets,
      tourController: widget.warehouseTourController,
    ),
    _InventorySection.stock => PosStockPage(
      isGridView: widget.isGridView,
      onCreatePurchase:
          permissions['view_inventory_purchases'] == true &&
              permissions['create_inventory_purchases'] == true &&
              !_checkingRestock
          ? _createPurchaseForStock
          : null,
      onOpenStockOpname: permissions['view_inventory_opnames'] == true
          ? () => setState(() => _selected = _InventorySection.opname)
          : null,
      locationTourKey: widget.stockTourKey,
      contentTourKey: widget.setupTourTargets?.stockContent,
      adjustmentTourKey: widget.setupTourTargets?.stockAdjust,
    ),
    _InventorySection.purchase => PosPurchaseWorkspace(
      permissions: permissions,
      purchaseListBuilder: (onReceive, onPay) => _InventoryDocumentPage(
        key: const ValueKey(PosInventoryDocumentType.purchase),
        type: PosInventoryDocumentType.purchase,
        permissions: permissions,
        onReceivePurchase: onReceive,
        onPayPurchase: onPay,
      ),
    ),
    _InventorySection.opname => _InventoryDocumentPage(
      key: const ValueKey(PosInventoryDocumentType.opname),
      type: PosInventoryDocumentType.opname,
      permissions: permissions,
    ),
    _InventorySection.transfer => _InventoryDocumentPage(
      key: const ValueKey(PosInventoryDocumentType.transfer),
      type: PosInventoryDocumentType.transfer,
      permissions: permissions,
      canReceiveTransfer: permissions['receive_inventory_transfers'] == true,
    ),
    _InventorySection.scrap => _InventoryDocumentPage(
      key: const ValueKey(PosInventoryDocumentType.scrap),
      type: PosInventoryDocumentType.scrap,
      permissions: permissions,
    ),
    _InventorySection.purchaseReturn => const PosPurchaseReturnPage(),
  };
}

class _InventoryMenu {
  final _InventorySection section;
  final String label;
  final IconData icon;
  const _InventoryMenu(this.section, this.label, this.icon);
}

class _InventoryPurchaseSkeletonCard extends StatelessWidget {
  const _InventoryPurchaseSkeletonCard();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 16, borderRadius: 4)),
              SizedBox(width: 20),
              SkeletonBox(width: 64, height: 24, borderRadius: 8),
            ],
          ),
          SizedBox(height: 12),
          SkeletonBox(width: 170, height: 12, borderRadius: 4),
          SizedBox(height: 8),
          SkeletonBox(height: 12, borderRadius: 4),
          SizedBox(height: 12),
          SkeletonBox(width: 112, height: 34, borderRadius: 8),
        ],
      ),
    ),
  );
}

class _InventoryDocumentPage extends StatefulWidget {
  final PosInventoryDocumentType type;
  final bool canReceiveTransfer;
  final Map<String, dynamic> permissions;
  final ValueChanged<Map<String, dynamic>>? onReceivePurchase;
  final ValueChanged<Map<String, dynamic>>? onPayPurchase;
  const _InventoryDocumentPage({
    super.key,
    required this.type,
    required this.permissions,
    this.canReceiveTransfer = false,
    this.onReceivePurchase,
    this.onPayPurchase,
  });

  @override
  State<_InventoryDocumentPage> createState() => _InventoryDocumentPageState();
}

class _InventoryDocumentPageState extends State<_InventoryDocumentPage> {
  final _repository = sl<PosInventoryRepository>();
  final _search = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _items = const [];
  String _status = '';
  String _locationId = '';
  String _reason = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  List<Map<String, dynamic>> _warehouses = const [];
  int _page = 1;
  int _total = 0;
  bool _loading = true;
  String? _runningActionId;
  String? _runningActionLabel;
  Set<String> _pendingPurchaseApprovalIds = const {};
  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.type == PosInventoryDocumentType.purchase) {
      _loadPendingPurchaseApprovals();
    }
    if (widget.type == PosInventoryDocumentType.opname) _loadWarehouses();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({int? page}) async {
    setState(() => _loading = true);
    final targetPage = page ?? _page;
    final result = await _repository.getDocuments(
      type: widget.type,
      search: _search.text,
      status: _status,
      locationId: _locationId,
      dateFrom: _dateFilter(_dateFrom),
      dateTo: _dateFilter(_dateTo),
      reason: _reason,
      page: targetPage,
      limit: _limit,
    );
    if (!mounted) return;
    result.fold((failure) => AppToast.error(context, failure.message), (data) {
      setState(() {
        _items = data.items;
        _total = data.totalCount;
        _page = targetPage;
      });
    });
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadWarehouses() async {
    final result = await _repository.getWarehouses();
    if (!mounted) return;
    result.fold((_) {}, (items) => setState(() => _warehouses = items));
  }

  Future<void> _loadPendingPurchaseApprovals() async {
    final result = await _repository.getPendingPurchaseApprovalIds();
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _pendingPurchaseApprovalIds = const {}),
      (ids) => setState(() => _pendingPurchaseApprovalIds = ids),
    );
  }

  String _dateFilter(DateTime? value) =>
      value?.toIso8601String().split('T').first ?? '';

  Future<void> _showOpnameFilters() async {
    var locationId = _locationId;
    var dateFrom = _dateFrom;
    var dateTo = _dateTo;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Filter Stock Opname',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: locationId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Warehouse / Lokasi',
                    prefixIcon: Icon(Icons.warehouse_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Semua lokasi'),
                    ),
                    ..._warehouses.map(
                      (item) => DropdownMenuItem(
                        value: item['_id']?.toString() ?? '',
                        child: Text(
                          item['nama_cabang']?.toString() ?? '-',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => locationId = value ?? ''),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _OpnameDateFilter(
                        label: 'Dari tanggal',
                        value: dateFrom,
                        onChanged: (value) =>
                            setSheetState(() => dateFrom = value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OpnameDateFilter(
                        label: 'Sampai tanggal',
                        value: dateTo,
                        onChanged: (value) =>
                            setSheetState(() => dateTo = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          locationId = '';
                          dateFrom = null;
                          dateTo = null;
                        });
                      },
                      child: const Text('Reset'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, true),
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
    if (applied != true || !mounted) return;
    setState(() {
      _locationId = locationId;
      _dateFrom = dateFrom;
      _dateTo = dateTo;
    });
    _load(page: 1);
  }

  Future<void> _showScrapFilters() async {
    var reason = _reason;
    var dateFrom = _dateFrom;
    var dateTo = _dateTo;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Filter Stok Terbuang',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Alasan disposal',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Semua alasan')),
                    DropdownMenuItem(value: 'rusak', child: Text('Rusak')),
                    DropdownMenuItem(
                      value: 'kadaluarsa',
                      child: Text('Kadaluarsa'),
                    ),
                    DropdownMenuItem(value: 'hilang', child: Text('Hilang')),
                    DropdownMenuItem(
                      value: 'cacat_produksi',
                      child: Text('Cacat produksi'),
                    ),
                    DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => reason = value ?? ''),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _OpnameDateFilter(
                        label: 'Dari tanggal',
                        value: dateFrom,
                        onChanged: (value) =>
                            setSheetState(() => dateFrom = value),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OpnameDateFilter(
                        label: 'Sampai tanggal',
                        value: dateTo,
                        onChanged: (value) =>
                            setSheetState(() => dateTo = value),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => setSheetState(() {
                        reason = '';
                        dateFrom = null;
                        dateTo = null;
                      }),
                      child: const Text('Reset'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(sheetContext, true),
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
    if (applied != true || !mounted) return;
    setState(() {
      _reason = reason;
      _dateFrom = dateFrom;
      _dateTo = dateTo;
    });
    _load(page: 1);
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(page: 1));
  }

  String get _permissionPrefix => switch (widget.type) {
    PosInventoryDocumentType.purchase => 'inventory_purchases',
    PosInventoryDocumentType.opname => 'inventory_opnames',
    PosInventoryDocumentType.transfer => 'inventory_transfers',
    PosInventoryDocumentType.scrap => 'inventory_scraps',
  };
  bool _can(String action) =>
      widget.permissions['${action}_$_permissionPrefix'] == true;

  Future<void> _openEditor([Map<String, dynamic>? existing]) async {
    final bool? changed;
    if ((widget.type == PosInventoryDocumentType.opname ||
            widget.type == PosInventoryDocumentType.scrap) &&
        existing == null) {
      changed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final size = MediaQuery.sizeOf(dialogContext);
          final compact = size.width < 600;
          return PosKeyboardStableDialog(
            width: widget.type == PosInventoryDocumentType.scrap ? 960 : 760,
            height: size.height * .9,
            insetPadding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 32,
              vertical: compact ? 12 : 24,
            ),
            child: PosInventoryEditorPage(type: widget.type, inModal: true),
          );
        },
      );
    } else {
      changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PosInventoryEditorPage(type: widget.type, existing: existing),
        ),
      );
    }
    if (changed == true && mounted) _load(page: 1);
  }

  Future<void> _runAction(Map<String, dynamic> item, String action) async {
    if (_runningActionId != null) return;
    final requiresReason =
        const {'reject', 'cancel'}.contains(action) ||
        (action == 'delete' &&
            widget.type == PosInventoryDocumentType.purchase);
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_actionLabel(action)} ${_number(item)}?'),
        content: requiresReason
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_actionWarning(item, action)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: switch (action) {
                        'reject' => 'Alasan penolakan',
                        'cancel' => 'Alasan pembatalan',
                        _ => 'Alasan penghapusan',
                      },
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              )
            : Text(_actionWarning(item, action)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    final reason = controller.text.trim();
    await Future<void>.delayed(kThemeAnimationDuration);
    controller.dispose();
    if (confirmed != true) return;
    if (requiresReason && reason.length < 3) {
      if (mounted) AppToast.error(context, 'Alasan minimal 3 karakter');
      return;
    }
    if (!mounted || _runningActionId != null) return;
    setState(() {
      _loading = true;
      _runningActionId = item['_id'].toString();
      _runningActionLabel =
          action == 'submit' && widget.type == PosInventoryDocumentType.purchase
          ? 'Mengajukan PO ${_number(item)}...'
          : '${_actionLabel(action)} ${_number(item)}...';
    });
    try {
      final result = await _repository.runAction(
        type: widget.type,
        action: action,
        id: item['_id'].toString(),
        reason: reason,
      );
      if (!mounted) return;
      var succeeded = false;
      result.fold((failure) => AppToast.error(context, failure.message), (
        document,
      ) {
        succeeded = true;
        if (document is Map && document['cancel_journal_status'] == 'failed') {
          AppToast.error(
            context,
            'Stok sudah dikembalikan, tetapi jurnal pembatalan perlu diperiksa: ${document['cancel_journal_error'] ?? ''}',
          );
        } else if (document is Map && document['journal_status'] == 'failed') {
          AppToast.error(
            context,
            'Stok sudah diproses, tetapi jurnal perlu diperiksa: ${document['journal_error'] ?? ''}',
          );
        } else {
          AppToast.success(context, 'Status dokumen berhasil diperbarui');
        }
      });
      if (succeeded) {
        if (widget.type == PosInventoryDocumentType.purchase) {
          await _loadPendingPurchaseApprovals();
        }
        await _load(page: 1);
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(
          context,
          'Gagal memproses dokumen. Muat ulang untuk memeriksa statusnya.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _runningActionId = null;
          _runningActionLabel = null;
        });
      }
    }
  }

  String _actionWarning(Map<String, dynamic> item, String action) {
    final status = item['status']?.toString() ?? '';
    if (action == 'delete') {
      return widget.type == PosInventoryDocumentType.purchase
          ? 'Dokumen akan dihapus dan tidak dapat dipulihkan. Tuliskan alasan untuk jejak audit.'
          : 'Dokumen akan dihapus dan tidak dapat dipulihkan.';
    }
    if (action == 'cancel' &&
        widget.type == PosInventoryDocumentType.transfer &&
        (status == 'in_transit' || status == 'posted')) {
      return 'Pembatalan akan membalik perpindahan stok ke lokasi asal. Pastikan stok tujuan atau transit masih mencukupi.';
    }
    if (action == 'post' || action == 'process') {
      return 'Aksi ini mengubah saldo stok dan dapat membuat jurnal otomatis. Pastikan rincian barang sudah benar.';
    }
    if (action == 'approve') {
      return 'Dokumen akan disetujui untuk melanjutkan proses inventori.';
    }
    if (action == 'reject') {
      return 'Dokumen akan ditolak dan harus diperbaiki sebelum diproses kembali.';
    }
    return 'Pastikan rincian dokumen sudah benar sebelum melanjutkan.';
  }

  Future<void> _receive(Map<String, dynamic> item) async {
    if (_runningActionId != null) return;
    final remaining = (item['items'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .where(
          (row) =>
              ((row['qty'] as num?)?.toDouble() ?? 0) -
                  ((row['received_qty'] as num?)?.toDouble() ?? 0) >
              0.000001,
        )
        .toList();
    if (remaining.isEmpty) {
      AppToast.error(context, 'Tidak ada sisa barang untuk diterima');
      return;
    }
    final controllers = remaining.map((row) {
      final qty =
          ((row['qty'] as num?)?.toDouble() ?? 0) -
          ((row['received_qty'] as num?)?.toDouble() ?? 0);
      return TextEditingController(text: qty.toString());
    }).toList();
    List<Map<String, dynamic>>? receiptItems;
    String? validationError;
    try {
      receiptItems = await showDialog<List<Map<String, dynamic>>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return PosKeyboardStableFormDialog(
              width: 560,
              height: 580,
              title: const Text('Terima mutasi stok'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(dialogContext).bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Isi jumlah yang benar-benar tiba. Sisa tetap dalam perjalanan.',
                      ),
                      for (
                        var index = 0;
                        index < remaining.length;
                        index++
                      ) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: controllers[index],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText:
                                remaining[index]['nama_inventaris']
                                    ?.toString() ??
                                'Barang',
                            helperText:
                                'Sisa ${((remaining[index]['qty'] as num?)?.toDouble() ?? 0) - ((remaining[index]['received_qty'] as num?)?.toDouble() ?? 0)}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                      if (validationError != null) Text(validationError ?? ''),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    final rows = <Map<String, dynamic>>[];
                    for (var index = 0; index < remaining.length; index++) {
                      final max =
                          ((remaining[index]['qty'] as num?)?.toDouble() ?? 0) -
                          ((remaining[index]['received_qty'] as num?)
                                  ?.toDouble() ??
                              0);
                      final qty = double.tryParse(
                        controllers[index].text.trim(),
                      );
                      if (qty == null || qty < 0 || qty > max + 0.000001) {
                        setDialogState(
                          () => validationError = 'Jumlah diterima tidak valid',
                        );
                        return;
                      }
                      if (qty > 0) {
                        rows.add({
                          'item_id': remaining[index]['_id'],
                          'qty': qty,
                        });
                      }
                    }
                    if (rows.isEmpty) {
                      setDialogState(
                        () => validationError =
                            'Isi minimal satu jumlah diterima',
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, rows);
                  },
                  child: const Text('Terima jumlah ini'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      for (final controller in controllers) {
        controller.dispose();
      }
    }
    if (receiptItems == null) return;
    final transferId = item['_id'].toString();
    final snapshot =
        ((item['items'] as List?) ?? const [])
            .map((row) => Map<String, dynamic>.from(row as Map))
            .map(
              (row) => [
                row['_id'].toString(),
                (row['received_qty'] as num?)?.toDouble() ?? 0,
              ],
            )
            .toList()
          ..sort((a, b) => a[0].toString().compareTo(b[0].toString()));
    final requested =
        receiptItems
            .map(
              (row) => [
                row['item_id'].toString(),
                (row['qty'] as num).toDouble(),
              ],
            )
            .toList()
          ..sort((a, b) => a[0].toString().compareTo(b[0].toString()));
    final requestId =
        'transfer-receive-${sha256.convert(utf8.encode(jsonEncode([transferId, snapshot, requested])))}';
    if (!mounted || _runningActionId != null) return;
    setState(() {
      _loading = true;
      _runningActionId = transferId;
      _runningActionLabel = 'Mencatat penerimaan mutasi ${_number(item)}...';
    });
    try {
      final result = await _repository.receiveTransfer(
        transferId,
        receiptItems,
        requestId,
      );
      if (!mounted) return;
      var succeeded = false;
      result.fold((failure) => AppToast.error(context, failure.message), (
        document,
      ) {
        succeeded = true;
        if (document['journal_status'] == 'failed') {
          AppToast.error(
            context,
            'Stok diterima, tetapi jurnal biaya perlu dicoba ulang',
          );
        } else {
          AppToast.success(
            context,
            document['status'] == 'posted'
                ? 'Seluruh mutasi stok berhasil diterima'
                : 'Penerimaan sebagian berhasil dicatat',
          );
        }
      });
      if (succeeded) await _load(page: 1);
    } catch (_) {
      if (mounted) {
        AppToast.error(
          context,
          'Penerimaan mutasi gagal. Muat ulang untuk memeriksa statusnya.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _runningActionId = null;
          _runningActionLabel = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bgPrimary,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(
              MediaQuery.sizeOf(context).width < 600 ? 12 : 14,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 600;
                final controlHeight = compact ? 40.0 : 48.0;
                final search = SizedBox(
                  height: controlHeight,
                  child: TextField(
                    controller: _search,
                    onChanged: _onSearch,
                    decoration: InputDecoration(
                      labelText: _searchLabel,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
                final status = SizedBox(
                  height: controlHeight,
                  child: DropdownButtonFormField<String>(
                    initialValue: _status,
                    isDense: true,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: _statuses
                        .map(
                          (entry) => DropdownMenuItem(
                            value: entry.$1,
                            child: Text(
                              entry.$2,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => _status = value ?? '');
                      _load(page: 1);
                    },
                  ),
                );
                final add = FilledButton.icon(
                  onPressed: _can('create') ? () => _openEditor() : null,
                  style: InventoryActionStyle.primary(
                    controlHeight: controlHeight,
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah'),
                );
                final hasOpnameFilter =
                    _locationId.isNotEmpty ||
                    _dateFrom != null ||
                    _dateTo != null;
                final opnameFilter = IconButton.filledTonal(
                  onPressed: _showOpnameFilters,
                  tooltip: 'Filter lokasi dan tanggal',
                  style: InventoryActionStyle.filter(
                    controlHeight: controlHeight,
                  ),
                  icon: Badge(
                    isLabelVisible: hasOpnameFilter,
                    child: const Icon(Icons.tune_rounded),
                  ),
                );
                final hasScrapFilter =
                    _reason.isNotEmpty || _dateFrom != null || _dateTo != null;
                final scrapFilter = IconButton.filledTonal(
                  onPressed: _showScrapFilters,
                  tooltip: 'Filter alasan dan tanggal',
                  style: InventoryActionStyle.filter(
                    controlHeight: controlHeight,
                  ),
                  icon: Badge(
                    isLabelVisible: hasScrapFilter,
                    child: const Icon(Icons.tune_rounded),
                  ),
                );
                if (constraints.maxWidth >= 700) {
                  return Row(
                    children: [
                      Expanded(child: search),
                      const SizedBox(width: 10),
                      SizedBox(width: 180, child: status),
                      if (widget.type == PosInventoryDocumentType.opname) ...[
                        const SizedBox(width: 8),
                        opnameFilter,
                      ],
                      if (widget.type == PosInventoryDocumentType.scrap) ...[
                        const SizedBox(width: 8),
                        scrapFilter,
                      ],
                      const SizedBox(width: 10),
                      SizedBox(height: InventoryActionStyle.height, child: add),
                    ],
                  );
                }
                return Column(
                  children: [
                    search,
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: status),
                        if (widget.type == PosInventoryDocumentType.opname) ...[
                          const SizedBox(width: 8),
                          opnameFilter,
                        ],
                        if (widget.type == PosInventoryDocumentType.scrap) ...[
                          const SizedBox(width: 8),
                          scrapFilter,
                        ],
                        const SizedBox(width: 8),
                        add,
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          if (_runningActionLabel != null) ...[
            const LinearProgressIndicator(minHeight: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_runningActionLabel!)),
                ],
              ),
            ),
          ],
          Expanded(
            child: AbsorbPointer(
              absorbing: _runningActionId != null,
              child: RefreshIndicator(
                onRefresh: _load,
                child: _loading && _items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(14),
                        children: const [
                          _InventoryPurchaseSkeletonCard(),
                          SizedBox(height: 8),
                          _InventoryPurchaseSkeletonCard(),
                          SizedBox(height: 8),
                          _InventoryPurchaseSkeletonCard(),
                        ],
                      )
                    : _items.isEmpty && !_loading
                    ? ListView(
                        children: [
                          const SizedBox(height: 90),
                          Icon(_emptyIcon, size: 68, color: Colors.black26),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              _emptyText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Center(
                            child: Text(
                              'Tarik ke bawah untuk memuat ulang.',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) => _documentCard(_items[index]),
                      ),
              ),
            ),
          ),
          if (_total > _limit)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _page > 1 && !_loading
                        ? () => _load(page: _page - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Halaman $_page dari ${(_total / _limit).ceil()}'),
                  IconButton(
                    onPressed: _page * _limit < _total && !_loading
                        ? () => _load(page: _page + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _documentCard(Map<String, dynamic> item) {
    final itemCount = (item['items'] as List?)?.length ?? 0;
    final transferReceived = (item['items'] as List? ?? const [])
        .whereType<Map>()
        .fold<double>(
          0,
          (sum, row) => sum + ((row['received_qty'] as num?)?.toDouble() ?? 0),
        );
    final rawStatus = item['status']?.toString() ?? '-';
    final status = widget.type == PosInventoryDocumentType.purchase
        ? PosPurchaseProgress.effectiveStatus(item)
        : rawStatus;
    final payableStatus = item['payable_status']?.toString();
    final payableOutstanding = (item['payable_outstanding_amount'] as num?)
        ?.toDouble();
    final payableIsSettled =
        payableStatus == 'paid' ||
        (const {'open', 'partial'}.contains(payableStatus) &&
            payableOutstanding != null &&
            payableOutstanding <= 0.01);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showDetail(item),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Status + nominal/tombol membutuhkan ruang kanan yang cukup.
            // Gunakan layout bertumpuk lebih awal agar aman pada HP landscape,
            // split-screen, serta text scale yang lebih besar.
            final compact = constraints.maxWidth < 440;
            final info = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _number(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _subtitle(item),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 3),
                Text(
                  '$itemCount item • ${_date(_dateValue(item))}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                if (widget.type == PosInventoryDocumentType.transfer &&
                    rawStatus == 'in_transit' &&
                    transferReceived > 0)
                  Text(
                    '${_compactNumber(transferReceived)} dari ${_compactNumber((item['items'] as List? ?? const []).whereType<Map>().fold<double>(0, (sum, row) => sum + ((row['qty'] as num?)?.toDouble() ?? 0)))} sudah diterima',
                    style: const TextStyle(fontSize: 12, color: AppColors.info),
                  ),
                if (widget.type == PosInventoryDocumentType.purchase &&
                    rawStatus == 'completed' &&
                    status == 'partially_received')
                  const Text(
                    'Status lama tidak sesuai progres • masih bisa diterima',
                    style: TextStyle(fontSize: 12, color: AppColors.warning),
                  ),
              ],
            );
            final actionMenu = PopupMenuButton<String>(
              tooltip: 'Aksi dokumen',
              icon: const Icon(Icons.more_vert),
              onSelected: (action) => _handleCardAction(item, action),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'detail',
                  child: _ActionMenuItem(Icons.visibility_outlined, 'Detail'),
                ),
                const PopupMenuItem(
                  value: 'copy_number',
                  child: _ActionMenuItem(Icons.copy_outlined, 'Salin nomor'),
                ),
                ..._availableActions(item).map(
                  (action) => PopupMenuItem(
                    value: action,
                    child: _ActionMenuItem(
                      _actionIcon(action),
                      action == 'preview_po'
                          ? (PosPurchaseOrderDocument.isApproved(item)
                                ? 'Bagikan / Cetak PO'
                                : 'Pratinjau PO')
                          : _actionLabel(action),
                      destructive: const {
                        'reject',
                        'cancel',
                        'delete',
                      }.contains(action),
                    ),
                  ),
                ),
              ],
            );
            final meta = <Widget>[
              if (widget.type != PosInventoryDocumentType.purchase)
                _InventoryStatus(status),
              if (widget.type == PosInventoryDocumentType.purchase &&
                  widget.permissions['view_payables'] == true &&
                  payableIsSettled)
                const _PayablePaidBadge(),
              if (widget.type == PosInventoryDocumentType.purchase)
                Text(
                  _money(item['grand_total']),
                  maxLines: 1,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              if (widget.type == PosInventoryDocumentType.scrap)
                Text(
                  _money(item['total_nilai_scrap']),
                  maxLines: 1,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              if (widget.type == PosInventoryDocumentType.transfer &&
                  status == 'in_transit' &&
                  widget.canReceiveTransfer)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  onPressed: _loading ? null : () => _receive(item),
                  icon: const Icon(Icons.download_done, size: 16),
                  label: const Text('Terima'),
                ),
              actionMenu,
            ];
            final compactPurchaseMeta = Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _InventoryStatus(status),
                    if (widget.permissions['view_payables'] == true &&
                        payableIsSettled)
                      const _PayablePaidBadge(),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _money(item['grand_total']),
                      maxLines: 1,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 2),
                    actionMenu,
                  ],
                ),
              ],
            );
            final leading = CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: .1),
              child: Icon(_emptyIcon, color: AppColors.primary),
            );
            final content = widget.type == PosInventoryDocumentType.purchase
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      leading,
                      const SizedBox(width: 12),
                      Expanded(child: info),
                      const SizedBox(width: 8),
                      compactPurchaseMeta,
                    ],
                  )
                : compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          leading,
                          const SizedBox(width: 12),
                          Expanded(child: info),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 6,
                        children: meta,
                      ),
                    ],
                  )
                : Row(
                    children: [
                      leading,
                      const SizedBox(width: 12),
                      Expanded(child: info),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: meta
                            .expand(
                              (widget) => [
                                widget,
                                if (widget != meta.last)
                                  const SizedBox(height: 7),
                              ],
                            )
                            .toList(),
                      ),
                    ],
                  );
            return Padding(padding: const EdgeInsets.all(14), child: content);
          },
        ),
      ),
    );
  }

  Future<void> _showDetail(Map<String, dynamic> item) async {
    final selectedAction = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final rows = (item['items'] as List? ?? const []).cast<Map>();
        final totalQty = rows.fold<double>(0, (sum, row) {
          final value =
              row['qty_ordered'] ?? row['qty'] ?? row['qty_fisik'] ?? 0;
          return sum + ((value as num?)?.toDouble() ?? 0);
        });
        final totalSystem = rows.fold<double>(
          0,
          (sum, row) => sum + ((row['qty_system'] as num?)?.toDouble() ?? 0),
        );
        final totalPhysical = rows.fold<double>(
          0,
          (sum, row) => sum + ((row['qty_fisik'] as num?)?.toDouble() ?? 0),
        );
        final totalDifference = totalPhysical - totalSystem;
        final totalNetLoss = rows.fold<double>(0, (sum, row) {
          final qty = (row['qty'] as num?)?.toDouble() ?? 0;
          final recycled =
              (row['jumlah_hasil_recycle'] as num?)?.toDouble() ?? 0;
          return sum +
              ((row['jumlah_hilang'] as num?)?.toDouble() ?? qty - recycled);
        });
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: .68,
            maxChildSize: .92,
            builder: (_, controller) => ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              children: [
                Text(
                  _number(item),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _subtitle(item),
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _InventoryStatus(
                      widget.type == PosInventoryDocumentType.purchase
                          ? PosPurchaseProgress.effectiveStatus(item)
                          : item['status']?.toString() ?? '-',
                    ),
                    const Spacer(),
                    Text(_date(_dateValue(item))),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DetailMetric(
                      icon: Icons.inventory_2_outlined,
                      label: '${rows.length} jenis barang',
                    ),
                    _DetailMetric(
                      icon: Icons.numbers_outlined,
                      label: '${_compactNumber(totalQty)} total jumlah',
                    ),
                    if (widget.type == PosInventoryDocumentType.purchase)
                      _DetailMetric(
                        icon: Icons.payments_outlined,
                        label: _money(item['grand_total']),
                      ),
                    if (widget.type == PosInventoryDocumentType.purchase)
                      _DetailMetric(
                        icon: Icons.inventory_outlined,
                        label:
                            '${(PosPurchaseProgress.completionRatio(item) * 100).round()}% diterima',
                      ),
                    if (widget.type == PosInventoryDocumentType.transfer)
                      _DetailMetric(
                        icon: Icons.move_to_inbox_outlined,
                        label:
                            '${_compactNumber(rows.fold<double>(0, (sum, row) => sum + ((row['received_qty'] as num?)?.toDouble() ?? 0)))} diterima',
                      ),
                    if (widget.type == PosInventoryDocumentType.opname) ...[
                      _DetailMetric(
                        icon: Icons.approval_outlined,
                        label:
                            'Persetujuan ${item['approval_current_level'] ?? 0}/${item['approval_required_level'] ?? 1}',
                      ),
                      _DetailMetric(
                        icon: Icons.computer_outlined,
                        label: '${_compactNumber(totalSystem)} stok sistem',
                      ),
                      _DetailMetric(
                        icon: Icons.fact_check_outlined,
                        label: '${_compactNumber(totalPhysical)} hasil fisik',
                      ),
                      _DetailMetric(
                        icon: totalDifference == 0
                            ? Icons.check_circle_outline
                            : Icons.compare_arrows,
                        label:
                            '${totalDifference > 0 ? '+' : ''}${_compactNumber(totalDifference)} selisih',
                      ),
                    ],
                    if (widget.type == PosInventoryDocumentType.scrap) ...[
                      _DetailMetric(
                        icon: Icons.delete_sweep_outlined,
                        label:
                            '${_compactNumber(totalNetLoss)} kerugian bersih',
                      ),
                      _DetailMetric(
                        icon: Icons.payments_outlined,
                        label: _money(item['total_nilai_scrap']),
                      ),
                    ],
                  ],
                ),
                if (widget.type == PosInventoryDocumentType.opname &&
                    (item['alasan_penolakan']?.toString().trim() ?? '')
                        .isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.dangerBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.dangerBorder),
                    ),
                    child: Text(
                      'Alasan penolakan: ${item['alasan_penolakan']}',
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ),
                ],
                if ((item['catatan']?.toString().trim() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Catatan: ${item['catatan']}'),
                  ),
                ],
                if (widget.type == PosInventoryDocumentType.transfer &&
                    item['status'] == 'posted' &&
                    (item['total_biaya'] as num? ?? 0) > 0 &&
                    [
                      'failed',
                      'pending',
                      'unknown',
                    ].contains(item['journal_status'])) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Stok sudah diproses, tetapi jurnal biaya perlu diperiksa: ${item['journal_error'] ?? 'belum terkonfirmasi'}',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ],
                if (widget.type == PosInventoryDocumentType.transfer &&
                    item['status'] == 'cancelled' &&
                    (item['total_biaya'] as num? ?? 0) > 0 &&
                    [
                      'failed',
                      'pending',
                      'unknown',
                    ].contains(item['cancel_journal_status'])) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Stok sudah dikembalikan, tetapi jurnal pembatalan perlu diperiksa: ${item['cancel_journal_error'] ?? 'belum terkonfirmasi'}',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ],
                if (widget.type == PosInventoryDocumentType.opname &&
                    (item['approval_logs'] as List? ?? const [])
                        .isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Riwayat persetujuan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...(item['approval_logs'] as List).map((raw) {
                    final log = Map<String, dynamic>.from(raw as Map);
                    final action = (log['action']?.toString() ?? '-')
                        .replaceAll('_', ' ');
                    final note = log['note']?.toString().trim() ?? '';
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.check_circle_outline, size: 20),
                      title: Text(
                        action,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        [
                          if ((log['level'] as num? ?? 0) > 0)
                            'Level ${log['level']}',
                          if (note.isNotEmpty) note,
                        ].join(' • '),
                      ),
                      trailing: Text(_date(log['at'])),
                    );
                  }),
                ],
                const Divider(height: 28),
                const Text(
                  'Daftar barang',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Tidak ada rincian barang')),
                  )
                else
                  ...rows.map((row) {
                    final qty =
                        row['qty_ordered'] ??
                        row['qty'] ??
                        row['qty_fisik'] ??
                        0;
                    final system = row['qty_system'];
                    final isScrap =
                        widget.type == PosInventoryDocumentType.scrap;
                    final source =
                        [
                              row['lokasi_cabang_nama'],
                              row['lokasi_gedung_nama'] ??
                                  row['lokasi_gedung_kode'],
                              row['lokasi_ruangan_nama'] ??
                                  row['lokasi_ruangan_kode'],
                              row['lokasi_rak_nama'],
                            ]
                            .map((value) => value?.toString().trim() ?? '')
                            .where((value) => value.isNotEmpty)
                            .join(' / ');
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(row['nama_inventaris']?.toString() ?? '-'),
                      subtitle: widget.type == PosInventoryDocumentType.transfer
                          ? Text(
                              'Diterima ${_compactNumber(row['received_qty'] ?? 0)} • Sisa ${_compactNumber(((row['qty'] as num?)?.toDouble() ?? 0) - ((row['received_qty'] as num?)?.toDouble() ?? 0))}',
                            )
                          : isScrap
                          ? Text(
                              '${source.isEmpty ? 'Sumber stok tidak tercatat' : source}'
                              '${(row['no_batch']?.toString() ?? '').isEmpty ? '' : ' • Batch ${row['no_batch']}'}\n'
                              '${row['tindakan'] == 'recycle' ? 'Recycle ${_compactNumber(row['jumlah_hasil_recycle'])} • ' : ''}'
                              'Hilang ${_compactNumber(row['jumlah_hilang'] ?? row['qty'])}',
                            )
                          : system == null
                          ? null
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sistem: $system • Selisih: ${row['selisih'] ?? 0}',
                                ),
                                if ((row['batch_counts'] as List? ?? const [])
                                    .isNotEmpty)
                                  Text(
                                    '${(row['batch_counts'] as List).length} batch tercatat',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                if ((row['catatan_item']?.toString().trim() ??
                                        '')
                                    .isNotEmpty)
                                  Text(
                                    'Alasan selisih: ${row['catatan_item']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                      trailing: Text(
                        '$qty ${row['unit'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    );
                  }),
                if (_detailActions(item, (action) {
                  Navigator.pop(context, action);
                }).isNotEmpty) ...[
                  const Divider(height: 28),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _detailActions(item, (action) {
                      Navigator.pop(context, action);
                    }),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
    if (selectedAction != null && mounted) {
      await _executeItemAction(item, selectedAction);
    }
  }

  List<Widget> _detailActions(
    Map<String, dynamic> item,
    ValueChanged<String> onAction,
  ) {
    return _availableActions(item).map((action) {
      if (action == 'preview_po') {
        return OutlinedButton.icon(
          style: InventoryActionStyle.outlined(),
          onPressed: () => onAction(action),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: Text(
            PosPurchaseOrderDocument.isApproved(item)
                ? 'Bagikan / Cetak PO'
                : 'Pratinjau PO',
          ),
        );
      }
      if (action == 'edit') {
        return OutlinedButton.icon(
          style: InventoryActionStyle.outlined(),
          onPressed: () => onAction(action),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Ubah'),
        );
      }
      if (action == 'receive_purchase') {
        return OutlinedButton.icon(
          style: InventoryActionStyle.outlined(),
          onPressed: () => onAction(action),
          icon: const Icon(Icons.inventory),
          label: const Text('Terima Barang'),
        );
      }
      if (action == 'receive_transfer') {
        return OutlinedButton.icon(
          style: InventoryActionStyle.outlined(),
          onPressed: () => onAction(action),
          icon: const Icon(Icons.download_done),
          label: const Text('Terima Mutasi'),
        );
      }
      if (action == 'pay_purchase') {
        return OutlinedButton.icon(
          style: InventoryActionStyle.outlined(),
          onPressed: () => onAction(action),
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Bayar / Lihat Hutang'),
        );
      }
      return OutlinedButton.icon(
        style: InventoryActionStyle.outlined(),
        onPressed: () => onAction(action),
        icon: Icon(_actionIcon(action)),
        label: Text(_actionLabel(action)),
      );
    }).toList();
  }

  List<String> _availableActions(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? '';
    final approvalHistoryId = item['approval_history_id']?.toString() ?? '';
    final canApproveDocument =
        approvalHistoryId.isEmpty ||
        _pendingPurchaseApprovalIds.contains(item['_id']?.toString());
    final actions = PosInventoryActionPolicy.available(
      type: widget.type,
      status: status,
      can: _can,
      canReceiveTransfer: widget.canReceiveTransfer,
      canApproveDocument: canApproveDocument,
      purchaseHasRemaining:
          widget.type == PosInventoryDocumentType.purchase &&
          PosPurchaseProgress.hasRemaining(item),
      canViewPurchasePayments: widget.permissions['view_payables'] == true,
      purchaseHasPayable: item['payable_status'] != null,
    );
    if (widget.type == PosInventoryDocumentType.purchase) {
      actions.add('preview_po');
    }
    if (widget.type == PosInventoryDocumentType.scrap &&
        status == 'completed' &&
        ['failed', 'pending'].contains(item['journal_status']) &&
        _can('process')) {
      return [...actions, 'retry_journal'];
    }
    if (widget.type == PosInventoryDocumentType.transfer &&
        status == 'posted' &&
        (item['total_biaya'] as num? ?? 0) > 0 &&
        ['failed', 'pending', 'unknown'].contains(item['journal_status']) &&
        _can('post')) {
      return [...actions, 'retry_journal'];
    }
    if (widget.type == PosInventoryDocumentType.transfer &&
        status == 'cancelled' &&
        (item['total_biaya'] as num? ?? 0) > 0 &&
        [
          'failed',
          'pending',
          'unknown',
        ].contains(item['cancel_journal_status']) &&
        _can('cancel')) {
      return [...actions, 'retry_cancel_journal'];
    }
    return actions;
  }

  Future<void> _handleCardAction(
    Map<String, dynamic> item,
    String action,
  ) async {
    if (action == 'detail') {
      await _showDetail(item);
      return;
    }
    if (action == 'copy_number') {
      await Clipboard.setData(ClipboardData(text: _number(item)));
      if (mounted) AppToast.success(context, 'Nomor dokumen disalin');
      return;
    }
    await _executeItemAction(item, action);
  }

  Future<void> _executeItemAction(
    Map<String, dynamic> item,
    String action,
  ) async {
    if (action == 'retry_journal' &&
        widget.type == PosInventoryDocumentType.scrap) {
      if (_runningActionId != null) return;
      setState(() {
        _loading = true;
        _runningActionId = item['_id'].toString();
        _runningActionLabel = 'Mengulangi jurnal ${_number(item)}...';
      });
      try {
        final result = await _repository.retryScrapJournal(
          item['_id'].toString(),
        );
        if (!mounted) return;
        result.fold(
          (failure) => AppToast.error(context, failure.message),
          (document) =>
              document is Map &&
                  [
                    'posted',
                    'not_required',
                  ].contains(document['journal_status'])
              ? AppToast.success(context, 'Jurnal scrap berhasil diperbarui')
              : AppToast.error(
                  context,
                  'Jurnal belum selesai: ${document is Map ? document['journal_error'] ?? '' : ''}',
                ),
        );
        await _load(page: 1);
      } catch (_) {
        if (mounted) {
          AppToast.error(
            context,
            'Jurnal gagal diproses. Muat ulang untuk memeriksa statusnya.',
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _loading = false;
            _runningActionId = null;
            _runningActionLabel = null;
          });
        }
      }
      return;
    }
    if (action == 'edit') {
      await _openEditor(item);
      return;
    }
    if (action == 'preview_po') {
      await _previewPurchaseOrder(item);
      return;
    }
    if (action == 'receive_purchase') {
      if (widget.onReceivePurchase != null) {
        widget.onReceivePurchase!(item);
        return;
      }
      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PosPurchaseReceivingPage(
            purchase: item,
            canViewPayable: widget.permissions['view_payables'] == true,
            canRecordPayment:
                widget.permissions['record_payable_payment'] == true,
          ),
        ),
      );
      if (changed == true) _load(page: 1);
      return;
    }
    if (action == 'pay_purchase') {
      if (widget.onPayPurchase != null) {
        widget.onPayPurchase!(item);
        return;
      }
      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => PosPurchasePayablePage(
            purchase: item,
            canRecordPayment:
                widget.permissions['record_payable_payment'] == true,
          ),
        ),
      );
      if (changed == true) await _load(page: 1);
      return;
    }
    if (action == 'receive_transfer') {
      await _receive(item);
      return;
    }
    await _runAction(item, action);
  }

  Future<void> _previewPurchaseOrder(Map<String, dynamic> item) async {
    final id = item['_id']?.toString() ?? '';
    if (id.isEmpty) {
      AppToast.error(context, 'ID PO tidak tersedia');
      return;
    }
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      ),
    );
    Map<String, dynamic>? purchase;
    Uint8List? bytes;
    String? errorMessage;
    try {
      final result = await _repository.getPurchaseForPrint(id);
      if (!mounted) return;
      purchase = result.fold<Map<String, dynamic>>(
        (failure) => throw StateError(failure.message),
        (value) => value,
      );
      final buyerResult = await sl<PosReceiptRepository>()
          .getReceiptPrintData();
      if (!mounted) return;
      final company = buyerResult.fold<Map<String, String>>(
        (failure) => throw StateError(
          'Identitas pembeli tidak dapat dimuat: ${failure.message}',
        ),
        (data) => data.company,
      );
      if ((company['nama_resmi'] ?? '').trim().isEmpty &&
          (company['nama_instansi'] ?? '').trim().isEmpty) {
        throw StateError('Nama instansi belum tersedia untuk dokumen PO');
      }
      bytes = await PosPurchaseOrderDocument.build(
        purchase: purchase,
        company: company,
      );
    } catch (error) {
      errorMessage = error is StateError
          ? error.message
          : 'Gagal menyiapkan PO: $error';
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
    if (!mounted) return;
    if (errorMessage != null) {
      AppToast.error(context, errorMessage);
      return;
    }
    if (purchase == null || bytes == null) return;
    final official = PosPurchaseOrderDocument.isApproved(purchase);
    final number = (purchase['no_po']?.toString() ?? 'PO').replaceAll(
      RegExp(r'[^A-Za-z0-9._-]'),
      '_',
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(official ? 'Bagikan / Cetak PO' : 'Pratinjau PO'),
          ),
          body: PdfPreview(
            build: (_) async => bytes!,
            pdfFileName: '$number.pdf',
            allowPrinting: official,
            allowSharing: official,
            canChangePageFormat: false,
            canChangeOrientation: false,
          ),
        ),
      ),
    );
  }

  String get _searchLabel => switch (widget.type) {
    PosInventoryDocumentType.purchase => 'Cari nomor faktur / supplier',
    PosInventoryDocumentType.opname => 'Cari nomor opname',
    PosInventoryDocumentType.transfer => 'Cari nomor / lokasi mutasi',
    PosInventoryDocumentType.scrap => 'Cari nomor / barang terbuang',
  };
  IconData get _emptyIcon => switch (widget.type) {
    PosInventoryDocumentType.purchase => Icons.receipt_long_outlined,
    PosInventoryDocumentType.opname => Icons.fact_check_outlined,
    PosInventoryDocumentType.transfer => Icons.move_to_inbox_outlined,
    PosInventoryDocumentType.scrap => Icons.delete_sweep_outlined,
  };
  String get _emptyText => switch (widget.type) {
    PosInventoryDocumentType.purchase => 'Faktur pembelian tidak tersedia',
    PosInventoryDocumentType.opname => 'Stok opname tidak tersedia',
    PosInventoryDocumentType.transfer => 'Tidak ada mutasi yang perlu diterima',
    PosInventoryDocumentType.scrap => 'Catatan stok terbuang tidak tersedia',
  };
  List<(String, String)> get _statuses => switch (widget.type) {
    PosInventoryDocumentType.purchase => const [
      ('', 'Semua'),
      ('draft', 'Draft'),
      ('pending', 'Menunggu persetujuan'),
      ('approved', 'Disetujui'),
      ('partially_received', 'Diterima sebagian'),
      ('completed', 'Selesai'),
      ('rejected', 'Ditolak'),
    ],
    PosInventoryDocumentType.opname => const [
      ('', 'Semua'),
      ('draft', 'Draft'),
      ('submitted', 'Diajukan'),
      ('approved', 'Disetujui'),
      ('rejected', 'Ditolak'),
      ('posted', 'Diposting'),
      ('cancelled', 'Dibatalkan'),
    ],
    PosInventoryDocumentType.transfer => const [
      ('', 'Semua'),
      ('in_transit', 'Dalam perjalanan'),
      ('submitted', 'Diajukan'),
      ('approved', 'Disetujui'),
      ('posted', 'Selesai'),
      ('rejected', 'Ditolak'),
      ('cancelled', 'Dibatalkan'),
    ],
    PosInventoryDocumentType.scrap => const [
      ('', 'Semua'),
      ('draft', 'Draft'),
      ('approved', 'Disetujui'),
      ('completed', 'Diproses'),
      ('rejected', 'Ditolak'),
    ],
  };

  String _number(Map<String, dynamic> item) => switch (widget.type) {
    PosInventoryDocumentType.purchase => item['no_po']?.toString() ?? '-',
    PosInventoryDocumentType.opname => item['no_opname']?.toString() ?? '-',
    PosInventoryDocumentType.transfer => item['no_transfer']?.toString() ?? '-',
    PosInventoryDocumentType.scrap => item['no_scrap']?.toString() ?? '-',
  };
  dynamic _dateValue(Map<String, dynamic> item) => switch (widget.type) {
    PosInventoryDocumentType.purchase => item['tanggal_po'],
    PosInventoryDocumentType.opname => item['tanggal_opname'],
    PosInventoryDocumentType.transfer => item['tanggal_transfer'],
    PosInventoryDocumentType.scrap => item['tanggal_scrap'],
  };
  String _subtitle(Map<String, dynamic> item) => switch (widget.type) {
    PosInventoryDocumentType.purchase =>
      item['supplier_name']?.toString() ?? '-',
    PosInventoryDocumentType.opname => _location(item['lokasi']),
    PosInventoryDocumentType.transfer =>
      '${_location(item['dari'])} → ${_location(item['ke'])}',
    PosInventoryDocumentType.scrap =>
      '${item['alasan'] ?? '-'}${(item['lokasi_kejadian']?.toString() ?? '').isEmpty ? '' : ' • ${item['lokasi_kejadian']}'}',
  };
}

class _OpnameDateFilter extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  const _OpnameDateFilter({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: value ?? DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 730)),
        lastDate: DateTime.now(),
      );
      if (picked != null) onChanged(picked);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: value == null
            ? const Icon(Icons.calendar_today_outlined, size: 18)
            : IconButton(
                tooltip: 'Hapus tanggal',
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.close, size: 18),
              ),
      ),
      child: Text(
        value == null
            ? 'Semua'
            : DateFormat('dd MMM yyyy', 'id_ID').format(value!),
      ),
    ),
  );
}

class _InventoryStatus extends StatelessWidget {
  final String status;
  const _InventoryStatus(this.status);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _statusColor(status).withValues(alpha: .12),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      _statusLabel(status),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _statusColor(status),
      ),
    ),
  );
}

class _PayablePaidBadge extends StatelessWidget {
  const _PayablePaidBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF16824A).withValues(alpha: .12),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle_outline, size: 13, color: Color(0xFF16824A)),
        SizedBox(width: 4),
        Text(
          'Lunas',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF16824A),
          ),
        ),
      ],
    ),
  );
}

String _location(dynamic raw) {
  final value = raw is Map ? raw : const {};
  final label = [
    value['cabang_nama'],
    value['gedung_nama'],
    value['ruangan_nama'],
    value['rak_nama'],
  ].where((part) => (part?.toString() ?? '').isNotEmpty).join(' / ');
  return label.isEmpty ? 'Lokasi belum tercatat' : label;
}

String _compactNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);

String _money(dynamic value) => NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
).format((value as num?) ?? num.tryParse(value?.toString() ?? '') ?? 0);
String _date(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  return parsed == null
      ? (value?.toString() ?? '-')
      : DateFormat('dd MMM yyyy', 'id_ID').format(parsed.toLocal());
}

String _statusLabel(String value) => switch (value) {
  'draft' => 'Draft',
  'pending' => 'Menunggu persetujuan',
  'submitted' => 'Diajukan',
  'approved' => 'Disetujui',
  'partially_received' => 'Diterima sebagian',
  'in_transit' => 'Dalam perjalanan',
  'completed' || 'posted' => 'Selesai',
  'rejected' => 'Ditolak',
  'cancelled' => 'Dibatalkan',
  _ => value,
};
Color _statusColor(String value) => switch (value) {
  'approved' => AppColors.info,
  'completed' || 'posted' => AppColors.success,
  'rejected' || 'cancelled' => AppColors.danger,
  'pending' || 'submitted' || 'in_transit' => AppColors.warning,
  _ => AppColors.neutral,
};

String _actionLabel(String action) => switch (action) {
  'edit' => 'Ubah',
  'submit' => 'Ajukan',
  'approve' => 'Setujui',
  'reject' => 'Tolak',
  'post' => 'Proses Stok',
  'process' => 'Proses',
  'cancel' => 'Batalkan',
  'delete' => 'Hapus',
  'receive_purchase' => 'Terima Barang',
  'pay_purchase' => 'Pembayaran / Riwayat',
  'preview_po' => 'Dokumen PO',
  'receive_transfer' => 'Terima Mutasi',
  'retry_journal' => 'Ulangi Jurnal',
  'retry_cancel_journal' => 'Ulangi Jurnal Batal',
  _ => action,
};
IconData _actionIcon(String action) => switch (action) {
  'edit' => Icons.edit_outlined,
  'submit' => Icons.send_outlined,
  'approve' => Icons.check_circle_outline,
  'reject' => Icons.cancel_outlined,
  'post' || 'process' => Icons.play_circle_outline,
  'cancel' => Icons.block,
  'delete' => Icons.delete_outline,
  'receive_purchase' => Icons.inventory_2_outlined,
  'pay_purchase' => Icons.payments_outlined,
  'preview_po' => Icons.picture_as_pdf_outlined,
  'receive_transfer' => Icons.download_done,
  'retry_journal' => Icons.refresh,
  'retry_cancel_journal' => Icons.restart_alt,
  _ => Icons.more_horiz,
};

class _ActionMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destructive;

  const _ActionMenuItem(this.icon, this.label, {this.destructive = false});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: destructive ? AppColors.danger : null),
      const SizedBox(width: 10),
      Text(
        label,
        style: TextStyle(color: destructive ? AppColors.danger : null),
      ),
    ],
  );
}

class _DetailMetric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailMetric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}
