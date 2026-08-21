import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/_core.dart';
import '../../../domain/repositories/pos_inventory_repository.dart';
import '../../../injections.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_ui.dart';

class PosWarehousePage extends StatefulWidget {
  final bool canCreate;
  final bool canUpdate;
  final bool canDelete;

  const PosWarehousePage({
    super.key,
    required this.canCreate,
    required this.canUpdate,
    required this.canDelete,
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
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final search = TextField(
              controller: _search,
              onChanged: _onSearch,
              decoration: const InputDecoration(
                labelText: 'Cari warehouse',
                prefixIcon: Icon(Icons.search),
              ),
            );
            final add = FilledButton.icon(
              onPressed: widget.canCreate ? () => _openForm() : null,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Warehouse'),
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

  Widget _warehouseCard(Map<String, dynamic> item) {
    final capabilities = <String>[
      if (item['is_sellable_location'] == true) 'Penjualan',
      if (item['is_receiving_location'] == true) 'Penerimaan',
      if (item['is_transfer_source'] == true) 'Sumber mutasi',
      if (item['is_transfer_destination'] == true) 'Tujuan mutasi',
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.warehouse_outlined),
        ),
        title: Text(
          item['nama_cabang']?.toString() ?? 'Warehouse',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${item['branch_code'] ?? '-'} • ${_typeLabel(item['warehouse_type'])}\n'
          '${item['alamat_cabang'] ?? '-'}\n'
          '${capabilities.isEmpty ? 'Belum ada capability' : capabilities.join(' • ')}',
        ),
        isThreeLine: true,
        trailing: widget.canUpdate || widget.canDelete
            ? PopupMenuButton<String>(
                onSelected: (value) =>
                    value == 'edit' ? _openForm(item) : _confirmDelete(item),
                itemBuilder: (_) => [
                  if (widget.canUpdate)
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (widget.canDelete)
                    const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              )
            : null,
      ),
    );
  }

  String _typeLabel(dynamic value) => switch (value?.toString()) {
    'central' => 'Gudang pusat',
    'branch' => 'Gudang cabang',
    'store' => 'Gudang toko',
    'display' => 'Area display',
    'in_transit' => 'Dalam perjalanan',
    'quarantine' => 'Karantina',
    _ => 'Warehouse lainnya',
  };

  Future<void> _openForm([Map<String, dynamic>? existing]) async {
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
    var sellable = existing?['is_sellable_location'] == true;
    var receiving =
        existing == null || existing['is_receiving_location'] == true;
    var transferSource =
        existing == null || existing['is_transfer_source'] == true;
    var transferDestination =
        existing == null || existing['is_transfer_destination'] == true;
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
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
                  existing == null ? 'Tambah Warehouse' : 'Edit Warehouse',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nama warehouse *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Kode warehouse',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: address,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Alamat *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telepon'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(
                    labelText: 'Tipe warehouse',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'central',
                      child: Text('Gudang pusat'),
                    ),
                    DropdownMenuItem(
                      value: 'branch',
                      child: Text('Gudang cabang'),
                    ),
                    DropdownMenuItem(
                      value: 'store',
                      child: Text('Gudang toko'),
                    ),
                    DropdownMenuItem(
                      value: 'display',
                      child: Text('Area display'),
                    ),
                    DropdownMenuItem(
                      value: 'quarantine',
                      child: Text('Karantina'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Lainnya')),
                  ],
                  onChanged: (value) => type = value ?? 'store',
                ),
                const SizedBox(height: 12),
                Text(
                  'Capability operasional',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Lokasi penjualan'),
                  subtitle: const Text(
                    'Stok dapat digunakan oleh kasir outlet',
                  ),
                  value: sellable,
                  onChanged: (value) => setSheetState(() => sellable = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Penerimaan barang'),
                  value: receiving,
                  onChanged: (value) => setSheetState(() => receiving = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sumber mutasi stok'),
                  value: transferSource,
                  onChanged: (value) =>
                      setSheetState(() => transferSource = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tujuan mutasi stok'),
                  value: transferDestination,
                  onChanged: (value) =>
                      setSheetState(() => transferDestination = value),
                ),
                const SizedBox(height: 12),
                FilledButton(
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
                  child: Text(saving ? 'Menyimpan...' : 'Simpan'),
                ),
              ],
            ),
          ),
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
        title: const Text('Hapus warehouse?'),
        content: Text(
          '${item['nama_cabang']} hanya dapat dihapus jika belum dipakai outlet dan belum memiliki saldo inventaris.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
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
