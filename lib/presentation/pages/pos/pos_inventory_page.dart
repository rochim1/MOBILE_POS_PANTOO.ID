import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../injections.dart';
import '../../../core/_core.dart';
import '../../../domain/repositories/pos_inventory_repository.dart';
import '../../bloc/pos/pos_bloc.dart';
import '../../widgets/app_toast.dart';
import 'pos_purchase_return_page.dart';
import 'pos_stock_page.dart';
import 'pos_inventory_editor_page.dart';
import 'pos_purchase_receiving_page.dart';

enum _InventorySection {
  stock,
  purchase,
  opname,
  transfer,
  scrap,
  purchaseReturn,
}

class PosInventoryPage extends StatefulWidget {
  final bool isGridView;
  const PosInventoryPage({super.key, this.isGridView = true});

  @override
  State<PosInventoryPage> createState() => _PosInventoryPageState();
}

class _PosInventoryPageState extends State<PosInventoryPage> {
  _InventorySection _selected = _InventorySection.stock;

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
    final sections = <_InventoryMenu>[
      if (trackStock &&
          (permissions['view_stock'] == true ||
              permissions['adjust_stock'] == true))
        const _InventoryMenu(
          _InventorySection.stock,
          'Stok Inventori',
          Icons.inventory_2_outlined,
        ),
      if (permissions['view_inventory_purchases'] == true)
        const _InventoryMenu(
          _InventorySection.purchase,
          'Faktur Pembelian',
          Icons.receipt_long_outlined,
        ),
      if (permissions['view_inventory_opnames'] == true)
        const _InventoryMenu(
          _InventorySection.opname,
          'Stok Opname',
          Icons.fact_check_outlined,
        ),
      if (permissions['view_inventory_transfers'] == true)
        const _InventoryMenu(
          _InventorySection.transfer,
          'Terima Mutasi Stok',
          Icons.move_to_inbox_outlined,
        ),
      if (permissions['view_inventory_scraps'] == true)
        const _InventoryMenu(
          _InventorySection.scrap,
          'Stok Terbuang',
          Icons.delete_sweep_outlined,
        ),
      if (permissions['view_purchase_returns'] == true)
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        if (wide) {
          return Row(
            children: [
              SizedBox(
                width: 230,
                child: Material(
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(18, 18, 18, 10),
                        child: Text(
                          'Kategori Inventori',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          children: sections.map(_sideItem).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(child: content),
            ],
          );
        }
        return Column(
          children: [
            Container(
              height: 58,
              color: Colors.white,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                scrollDirection: Axis.horizontal,
                itemCount: sections.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final item = sections[index];
                  return ChoiceChip(
                    selected: item.section == _selected,
                    avatar: Icon(item.icon, size: 18),
                    label: Text(item.label),
                    onSelected: (_) => setState(() => _selected = item.section),
                  );
                },
              ),
            ),
            Expanded(child: content),
          ],
        );
      },
    );
  }

  Widget _sideItem(_InventoryMenu item) => Material(
    color: Colors.transparent,
    child: ListTile(
      dense: true,
      minLeadingWidth: 24,
      horizontalTitleGap: 10,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      selected: item.section == _selected,
      selectedColor: AppColors.primary,
      selectedTileColor: AppColors.primary.withValues(alpha: .09),
      leading: Icon(item.icon),
      title: Text(
        item.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      trailing: const Icon(Icons.chevron_right, size: 16),
      onTap: () => setState(() => _selected = item.section),
    ),
  );

  Widget _content(Map<String, dynamic> permissions) => switch (_selected) {
    _InventorySection.stock => PosStockPage(isGridView: widget.isGridView),
    _InventorySection.purchase => _InventoryDocumentPage(
      type: PosInventoryDocumentType.purchase,
      permissions: permissions,
    ),
    _InventorySection.opname => _InventoryDocumentPage(
      type: PosInventoryDocumentType.opname,
      permissions: permissions,
    ),
    _InventorySection.transfer => _InventoryDocumentPage(
      type: PosInventoryDocumentType.transfer,
      permissions: permissions,
      canReceiveTransfer: permissions['receive_inventory_transfers'] == true,
    ),
    _InventorySection.scrap => _InventoryDocumentPage(
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

class _InventoryDocumentPage extends StatefulWidget {
  final PosInventoryDocumentType type;
  final bool canReceiveTransfer;
  final Map<String, dynamic> permissions;
  const _InventoryDocumentPage({
    required this.type,
    required this.permissions,
    this.canReceiveTransfer = false,
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
  int _page = 1;
  int _total = 0;
  bool _loading = true;
  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    _load();
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
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PosInventoryEditorPage(type: widget.type, existing: existing),
      ),
    );
    if (changed == true) _load(page: 1);
  }

  Future<void> _runAction(Map<String, dynamic> item, String action) async {
    final requiresReason = const {
      'reject',
      'cancel',
      'delete',
    }.contains(action);
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_actionLabel(action)} ${_number(item)}?'),
        content: requiresReason
            ? TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alasan',
                  border: OutlineInputBorder(),
                ),
              )
            : const Text(
                'Pastikan rincian dokumen sudah benar sebelum melanjutkan.',
              ),
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
    controller.dispose();
    if (confirmed != true) return;
    if ((action == 'reject' || action == 'cancel') && reason.length < 3) {
      if (mounted) AppToast.error(context, 'Alasan minimal 3 karakter');
      return;
    }
    setState(() => _loading = true);
    final result = await _repository.runAction(
      type: widget.type,
      action: action,
      id: item['_id'].toString(),
      reason: reason,
    );
    if (!mounted) return;
    result.fold((failure) => AppToast.error(context, failure.message), (_) {
      AppToast.success(context, 'Status dokumen berhasil diperbarui');
      Navigator.maybePop(context);
      _load(page: 1);
    });
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _receive(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terima mutasi stok?'),
        content: Text(
          'Stok ${item['no_transfer'] ?? ''} akan dimasukkan ke lokasi tujuan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Terima'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _loading = true);
    final result = await _repository.receiveTransfer(item['_id'].toString());
    if (!mounted) return;
    result.fold((failure) => AppToast.error(context, failure.message), (_) {
      AppToast.success(context, 'Mutasi stok berhasil diterima');
      _load(page: 1);
    });
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.bgPrimary,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final search = TextField(
                  controller: _search,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    labelText: _searchLabel,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                );
                final status = DropdownButtonFormField<String>(
                  initialValue: _status,
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
                );
                final add = FilledButton.icon(
                  onPressed: _can('create') ? () => _openEditor() : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                );
                if (constraints.maxWidth >= 700) {
                  return Row(
                    children: [
                      Expanded(child: search),
                      const SizedBox(width: 10),
                      SizedBox(width: 180, child: status),
                      const SizedBox(width: 10),
                      SizedBox(height: 56, child: add),
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
                        const SizedBox(width: 8),
                        add,
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty && !_loading
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
    final status = item['status']?.toString() ?? '-';
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
              ],
            );
            final meta = <Widget>[
              _InventoryStatus(status),
              if (widget.type == PosInventoryDocumentType.purchase)
                Text(
                  _money(item['grand_total']),
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
            ];
            final leading = CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: .1),
              child: Icon(_emptyIcon, color: AppColors.primary),
            );
            return Padding(
              padding: const EdgeInsets.all(14),
              child: compact
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
                    ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showDetail(
    Map<String, dynamic> item,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final rows = (item['items'] as List? ?? const []).cast<Map>();
      return SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .68,
          maxChildSize: .92,
          builder: (_, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Text(
                _number(item),
                style: const TextStyle(
                  fontSize: 20,
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
                  _InventoryStatus(item['status']?.toString() ?? '-'),
                  const Spacer(),
                  Text(_date(_dateValue(item))),
                ],
              ),
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
                      row['qty_ordered'] ?? row['qty'] ?? row['qty_fisik'] ?? 0;
                  final system = row['qty_system'];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(row['nama_inventaris']?.toString() ?? '-'),
                    subtitle: system == null
                        ? null
                        : Text(
                            'Sistem: $system • Selisih: ${row['selisih'] ?? 0}',
                          ),
                    trailing: Text(
                      '$qty ${row['unit'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );
                }),
              if (_detailActions(item).isNotEmpty) ...[
                const Divider(height: 28),
                Wrap(spacing: 8, runSpacing: 8, children: _detailActions(item)),
              ],
              if (widget.type == PosInventoryDocumentType.transfer &&
                  item['status'] == 'in_transit' &&
                  widget.canReceiveTransfer) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _receive(item);
                  },
                  icon: const Icon(Icons.download_done),
                  label: const Text('Terima Mutasi Stok'),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );

  List<Widget> _detailActions(Map<String, dynamic> item) {
    final status = item['status']?.toString() ?? '';
    final actions = <String>[];
    if ((status == 'draft' || status == 'rejected') && _can('update')) {
      actions.add('edit');
    }
    if ((status == 'draft' || status == 'rejected') &&
        _can('submit') &&
        widget.type != PosInventoryDocumentType.scrap) {
      actions.add('submit');
    }
    if ((status == 'pending' || status == 'submitted') && _can('approve')) {
      actions.add('approve');
    }
    if ((status == 'pending' || status == 'submitted') && _can('reject')) {
      actions.add('reject');
    }
    if (widget.type == PosInventoryDocumentType.purchase &&
        (status == 'approved' || status == 'partially_received') &&
        _can('receive')) {
      actions.add('receive');
    }
    if (widget.type == PosInventoryDocumentType.opname &&
        status == 'approved' &&
        _can('post')) {
      actions.add('post');
    }
    if (widget.type == PosInventoryDocumentType.transfer &&
        status == 'approved' &&
        _can('post')) {
      actions.add('post');
    }
    if (widget.type == PosInventoryDocumentType.scrap &&
        status == 'draft' &&
        _can('approve')) {
      actions.add('approve');
    }
    if (widget.type == PosInventoryDocumentType.scrap &&
        status == 'approved' &&
        _can('process')) {
      actions.add('process');
    }
    if (const {'draft', 'submitted', 'approved', 'rejected'}.contains(status) &&
        _can('cancel') &&
        widget.type != PosInventoryDocumentType.purchase &&
        widget.type != PosInventoryDocumentType.scrap) {
      actions.add('cancel');
    }
    if ((status == 'draft' || status == 'rejected') && _can('delete')) {
      actions.add('delete');
    }
    return actions.map((action) {
      if (action == 'edit') {
        return OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _openEditor(item);
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Ubah'),
        );
      }
      if (action == 'receive') {
        return FilledButton.icon(
          onPressed: () async {
            Navigator.pop(context);
            final changed = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => PosPurchaseReceivingPage(purchase: item),
              ),
            );
            if (changed == true) _load(page: 1);
          },
          icon: const Icon(Icons.inventory),
          label: const Text('Terima Barang'),
        );
      }
      final destructive =
          action == 'delete' || action == 'reject' || action == 'cancel';
      return destructive
          ? OutlinedButton.icon(
              onPressed: () => _runAction(item, action),
              icon: Icon(_actionIcon(action)),
              label: Text(_actionLabel(action)),
            )
          : FilledButton.icon(
              onPressed: () => _runAction(item, action),
              icon: Icon(_actionIcon(action)),
              label: Text(_actionLabel(action)),
            );
    }).toList();
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
      ('pending', 'Menunggu'),
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

String _location(dynamic raw) {
  final value = raw is Map ? raw : const {};
  return [
    value['cabang_nama'],
    value['gedung_nama'],
    value['ruangan_nama'],
    value['rak_nama'],
  ].where((part) => (part?.toString() ?? '').isNotEmpty).join(' / ');
}

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
  'pending' || 'submitted' => 'Menunggu',
  'approved' => 'Disetujui',
  'partially_received' => 'Diterima sebagian',
  'in_transit' => 'Dalam perjalanan',
  'completed' || 'posted' => 'Selesai',
  'rejected' => 'Ditolak',
  'cancelled' => 'Dibatalkan',
  _ => value,
};
Color _statusColor(String value) => switch (value) {
  'approved' => Colors.blue,
  'completed' || 'posted' => Colors.green,
  'rejected' || 'cancelled' => Colors.red,
  'pending' || 'submitted' || 'in_transit' => Colors.orange,
  _ => Colors.blueGrey,
};

String _actionLabel(String action) => switch (action) {
  'submit' => 'Ajukan',
  'approve' => 'Setujui',
  'reject' => 'Tolak',
  'post' => 'Proses Stok',
  'process' => 'Proses',
  'cancel' => 'Batalkan',
  'delete' => 'Hapus',
  _ => action,
};
IconData _actionIcon(String action) => switch (action) {
  'submit' => Icons.send_outlined,
  'approve' => Icons.check_circle_outline,
  'reject' => Icons.cancel_outlined,
  'post' || 'process' => Icons.play_circle_outline,
  'cancel' => Icons.block,
  'delete' => Icons.delete_outline,
  _ => Icons.more_horiz,
};
