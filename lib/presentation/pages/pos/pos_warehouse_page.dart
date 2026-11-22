import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/_core.dart';
import '../../../domain/repositories/pos_inventory_repository.dart';
import '../../../domain/repositories/pos_repository.dart';
import '../../../domain/models/pos_store.dart';
import '../../../injections.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_keyboard_stable_sheet.dart';
import '../../widgets/pos_ui.dart';
import '../../widgets/inventory_action_style.dart';
import 'widgets/pos_setup_tour.dart';

class PosWarehousePage extends StatefulWidget {
  final bool canCreate;
  final bool canUpdate;
  final bool canDelete;
  final GlobalKey? setupTourKey;
  final PosSetupTourTargets? setupTourTargets;
  final PosWarehouseTourController? tourController;

  const PosWarehousePage({
    super.key,
    required this.canCreate,
    required this.canUpdate,
    required this.canDelete,
    this.setupTourKey,
    this.setupTourTargets,
    this.tourController,
  });

  @override
  State<PosWarehousePage> createState() => _PosWarehousePageState();
}

class _PosWarehousePageState extends State<PosWarehousePage> {
  final _repository = sl<PosInventoryRepository>();
  final _search = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.tourController?.attach(_openGuidedCreate);
    _load();
  }

  @override
  void didUpdateWidget(covariant PosWarehousePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tourController != widget.tourController) {
      oldWidget.tourController?.detach(_openGuidedCreate);
      widget.tourController?.attach(_openGuidedCreate);
    }
  }

  @override
  void dispose() {
    widget.tourController?.detach(_openGuidedCreate);
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _openGuidedCreate() => _openForm(null, guided: true);

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final result = await _repository.getWarehouses(search: _search.text);
    if (!mounted) return;
    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (items) => setState(() => _items = items),
    );
    if (mounted) setState(() => _loading = false);
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    const controlHeight = 56.0;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.all(compact ? 12 : 16),
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final search = SizedBox(
                height: controlHeight,
                child: TextField(
                  controller: _search,
                  onChanged: _onSearch,
                  decoration: InputDecoration(
                    labelText: ('Cari warehouse').tr(context),
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              );
              final add = FilledButton.icon(
                key: widget.setupTourKey,
                onPressed: widget.canCreate ? () => _openForm(null) : null,
                style: InventoryActionStyle.primary(
                  controlHeight: controlHeight,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const PosText('Tambah Warehouse'),
              );
              if (constraints.maxWidth < 560) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [search, const SizedBox(height: 10), add],
                );
              }
              return Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 12),
                  add,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          if (_loading) const LinearProgressIndicator(),
          if (!_loading && _items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: PosEmptyState(
                icon: Icons.warehouse_outlined,
                title: 'Belum ada warehouse',
                message:
                    'Buat lokasi stok pertama agar outlet dan inventori dapat digunakan.',
              ),
            ),
          ..._items.map(_warehouseCard),
        ],
      ),
    );
  }

  Widget _warehouseCard(Map<String, dynamic> item) {
    final capabilities = <String>[
      if (item['is_sellable_location'] == true) 'Penjualan',
      if (item['is_receiving_location'] == true) 'Penerimaan',
      if (item['is_transfer_source'] == true) 'Sumber mutasi',
      if (item['is_transfer_destination'] == true) 'Tujuan mutasi',
    ].map((label) => label.tr(context)).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.warehouse_outlined),
        ),
        title: Text(
          item['nama_cabang']?.toString() ?? ('Warehouse').tr(context),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${item['branch_code'] ?? '-'} • ${_typeLabel(item['warehouse_type'])}\n'
          '${item['alamat_cabang'] ?? '-'}\n'
          '${capabilities.isEmpty ? ('Belum ada capability').tr(context) : capabilities.join(' • ')}',
        ),
        isThreeLine: true,
        trailing: widget.canUpdate || widget.canDelete
            ? PopupMenuButton<String>(
                onSelected: (value) =>
                    value == 'edit' ? _openForm(item) : _confirmDelete(item),
                itemBuilder: (_) => [
                  if (widget.canUpdate)
                    const PopupMenuItem(value: 'edit', child: PosText('Edit')),
                  if (widget.canDelete)
                    const PopupMenuItem(
                      value: 'delete',
                      child: PosText('Hapus'),
                    ),
                ],
              )
            : null,
      ),
    );
  }

  String _typeLabel(dynamic value) => switch (value?.toString()) {
    'central' => ('Gudang pusat').trCurrent(),
    'branch' => ('Gudang cabang').trCurrent(),
    'store' => ('Gudang toko').trCurrent(),
    'display' => ('Area display').trCurrent(),
    'in_transit' => ('Dalam perjalanan').trCurrent(),
    'quarantine' => ('Karantina').trCurrent(),
    _ => ('Warehouse lainnya').trCurrent(),
  };

  Future<void> _openForm(
    Map<String, dynamic>? existing, {
    bool guided = false,
  }) async {
    List<PosStore> outlets = const [];
    try {
      outlets = await sl<PosRepository>().getStores();
    } catch (_) {
      // Warehouse tetap dapat dikelola saat daftar outlet belum tersedia.
    }
    if (!mounted) return;
    final code = TextEditingController(
      text: existing?['branch_code']?.toString() ?? '',
    );
    final name = TextEditingController(
      text: existing?['nama_cabang']?.toString() ?? '',
    );
    final address = TextEditingController(
      text: existing?['alamat_cabang']?.toString() ?? '',
    );
    final phone = TextEditingController(
      text: existing?['no_telp']?.toString() ?? '',
    );
    var type = existing?['warehouse_type']?.toString() ?? 'store';
    var linkedOutletId = existing?['linked_toko_id']?.toString() ?? '';
    var sellable = existing?['is_sellable_location'] == true;
    var receiving =
        existing == null || existing['is_receiving_location'] == true;
    var transferSource =
        existing == null || existing['is_transfer_source'] == true;
    var transferDestination =
        existing == null || existing['is_transfer_destination'] == true;
    var saving = false;
    var guideScheduled = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => PosKeyboardStableSheet(
        heightFactor: .85,
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            if (guided && !guideScheduled) {
              guideScheduled = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await Future<void>.delayed(const Duration(milliseconds: 180));
                if (!sheetContext.mounted || widget.setupTourTargets == null) {
                  return;
                }
                final targets = widget.setupTourTargets!;
                await showInteractivePosSetupTour(
                  sheetContext,
                  fallbackTarget: targets.warehouseName,
                  stepTitle: 'Langkah 1 · Lokasi stok siap',
                  stageNumberOffset: 1,
                  totalStageCount: 5,
                  stages: [
                    PosSetupTourStage(
                      title: ('Nama dan alamat lokasi').tr(context),
                      description:
                          ('Isi identitas warehouse. Nama dan alamat wajib agar lokasi mudah dikenali.')
                              .tr(context),
                      target: targets.warehouseName,
                    ),
                    PosSetupTourStage(
                      title: ('Pilih tipe warehouse').tr(context),
                      description:
                          ('Pilih fungsi utama lokasi, misalnya gudang toko atau gudang pusat.')
                              .tr(context),
                      target: targets.warehouseType,
                    ),
                    PosSetupTourStage(
                      title: ('Aktifkan lokasi penjualan').tr(context),
                      description:
                          ('Aktifkan opsi ini agar warehouse dapat dihubungkan ke toko POS.')
                              .tr(context),
                      target: targets.warehouseSellable,
                    ),
                    PosSetupTourStage(
                      title: ('Simpan warehouse').tr(context),
                      description:
                          ('Setelah data wajib terisi, simpan. Status ringkasan akan diperbarui dari server.')
                              .tr(context),
                      target: targets.warehouseSave,
                    ),
                  ],
                );
              });
            }
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.viewInsetsOf(context).bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      existing == null
                          ? ('Tambah Warehouse').tr(context)
                          : ('Edit Warehouse').tr(context),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      key: widget.setupTourTargets?.warehouseName,
                      child: TextField(
                        controller: name,
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: ('Nama warehouse *').tr(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: code,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: ('Kode warehouse').tr(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: address,
                      maxLines: 2,
                      decoration: InputDecoration(
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: ('Alamat *').tr(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelText: ('Telepon').tr(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      key: widget.setupTourTargets?.warehouseType,
                      child: DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: ('Tipe warehouse').tr(context),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'central',
                            child: PosText('Gudang pusat'),
                          ),
                          DropdownMenuItem(
                            value: 'branch',
                            child: PosText('Gudang cabang'),
                          ),
                          DropdownMenuItem(
                            value: 'store',
                            child: PosText('Gudang toko'),
                          ),
                          DropdownMenuItem(
                            value: 'display',
                            child: PosText('Area display'),
                          ),
                          DropdownMenuItem(
                            value: 'quarantine',
                            child: PosText('Karantina'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: PosText('Lainnya'),
                          ),
                        ],
                        onChanged: (value) =>
                            setSheetState(() => type = value ?? 'store'),
                      ),
                    ),
                    if (type == 'store' || type == 'display') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: linkedOutletId.isEmpty
                            ? ''
                            : linkedOutletId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: ('Outlet POS terkait').tr(context),
                          helperText:
                              ('Wajib untuk pemindahan stok gudang toko ↔ display.')
                                  .tr(context),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: '',
                            child: PosText('Belum ditautkan'),
                          ),
                          for (final outlet in outlets)
                            DropdownMenuItem(
                              value: outlet.id,
                              child: Text(
                                outlet.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (linkedOutletId.isNotEmpty &&
                              !outlets.any(
                                (outlet) => outlet.id == linkedOutletId,
                              ))
                            DropdownMenuItem(
                              value: linkedOutletId,
                              child: Text(
                                posLocale(
                                  context,
                                ).posb3f4a442d275((linkedOutletId).toString()),
                              ),
                            ),
                        ],
                        onChanged: (value) =>
                            setSheetState(() => linkedOutletId = value ?? ''),
                      ),
                    ],
                    const SizedBox(height: 12),
                    PosText(
                      'Capability operasional',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Container(
                      key: widget.setupTourTargets?.warehouseSellable,
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const PosText('Lokasi penjualan'),
                        subtitle: const PosText(
                          'Stok dapat digunakan oleh kasir outlet',
                        ),
                        value: sellable,
                        onChanged: (value) =>
                            setSheetState(() => sellable = value),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const PosText('Penerimaan barang'),
                      value: receiving,
                      onChanged: (value) =>
                          setSheetState(() => receiving = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const PosText('Sumber mutasi stok'),
                      value: transferSource,
                      onChanged: (value) =>
                          setSheetState(() => transferSource = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const PosText('Tujuan mutasi stok'),
                      value: transferDestination,
                      onChanged: (value) =>
                          setSheetState(() => transferDestination = value),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      key: widget.setupTourTargets?.warehouseSave,
                      onPressed: saving
                          ? null
                          : () async {
                              if (name.text.trim().isEmpty ||
                                  address.text.trim().isEmpty) {
                                AppToast.error(
                                  sheetContext,
                                  'Nama dan alamat warehouse wajib diisi',
                                );
                                return;
                              }
                              setSheetState(() => saving = true);
                              final result = await _repository.saveWarehouse({
                                'branch_code': code.text.trim().toUpperCase(),
                                'nama_cabang': name.text.trim(),
                                'alamat_cabang': address.text.trim(),
                                'no_telp': phone.text.trim(),
                                'tipe_cabang': 'gudang',
                                'is_warehouse': true,
                                'warehouse_type': type,
                                'linked_toko_id': linkedOutletId.isEmpty
                                    ? null
                                    : linkedOutletId,
                                'is_sellable_location': sellable,
                                'is_receiving_location': receiving,
                                'is_transfer_source': transferSource,
                                'is_transfer_destination': transferDestination,
                              }, id: existing?['_id']?.toString());
                              if (!sheetContext.mounted) return;
                              result.fold(
                                (failure) {
                                  setSheetState(() => saving = false);
                                  AppToast.error(sheetContext, failure.message);
                                },
                                (_) {
                                  Navigator.pop(sheetContext);
                                  AppToast.success(
                                    this.context,
                                    'Warehouse berhasil disimpan',
                                  );
                                  _load();
                                },
                              );
                            },
                      child: Text(
                        saving
                            ? ('Menyimpan...').tr(context)
                            : ('Simpan').tr(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    // Tunggu route overlay benar-benar terlepas sebelum controller form dibuang.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    code.dispose();
    name.dispose();
    address.dispose();
    phone.dispose();
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const PosText('Hapus warehouse?'),
        content: Text(
          posLocale(context).posc9d3ba9c4543((item['nama_cabang']).toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const PosText('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const PosText('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _repository.deleteWarehouse(item['_id'].toString());
    if (!mounted) return;
    result.fold((failure) => AppToast.error(context, failure.message), (_) {
      AppToast.success(context, 'Warehouse berhasil dihapus');
      _load();
    });
  }
}
