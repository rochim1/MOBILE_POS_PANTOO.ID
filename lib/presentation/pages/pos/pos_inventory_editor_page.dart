import 'package:flutter/material.dart';

import '../../../../injections.dart';
import '../../../core/_core.dart';
import '../../../domain/repositories/pos_inventory_repository.dart';
import '../../widgets/app_toast.dart';

class PosInventoryEditorPage extends StatefulWidget {
  final PosInventoryDocumentType type;
  final Map<String, dynamic>? existing;
  const PosInventoryEditorPage({super.key, required this.type, this.existing});

  @override
  State<PosInventoryEditorPage> createState() => _PosInventoryEditorPageState();
}

class _PosInventoryEditorPageState extends State<PosInventoryEditorPage> {
  final _repository = sl<PosInventoryRepository>();
  final _notes = TextEditingController();
  PosInventoryLookups? _lookups;
  List<Map<String, dynamic>> _catalog = const [];
  final Map<String, Map<String, dynamic>> _selected = {};
  String _supplierId = '';
  String _sourceId = '';
  String _destinationId = '';
  String _scrapReason = 'rusak';
  String _incidentType = 'disposal';
  bool _loading = true;

  bool get _editing => widget.existing != null;
  bool get _usesLocation => widget.type != PosInventoryDocumentType.purchase;

  @override
  void initState() {
    super.initState();
    _notes.text = widget.existing?['catatan']?.toString() ?? '';
    _supplierId = widget.existing?['supplier_id']?.toString() ?? '';
    _sourceId =
        (widget.existing?['lokasi'] as Map?)?['cabang_id']?.toString() ??
        (widget.existing?['dari'] as Map?)?['cabang_id']?.toString() ??
        '';
    _destinationId =
        (widget.existing?['ke'] as Map?)?['cabang_id']?.toString() ?? '';
    _scrapReason = widget.existing?['alasan']?.toString() ?? 'rusak';
    _incidentType = widget.existing?['jenis_insiden']?.toString() ?? 'disposal';
    _load();
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _repository.getLookups();
    if (!mounted) return;
    await result.fold(
      (failure) async {
        AppToast.error(context, failure.message);
      },
      (data) async {
        _lookups = data;
        if (_sourceId.isEmpty) _sourceId = data.activeWarehouseId;
        if (widget.type == PosInventoryDocumentType.purchase) {
          _catalog = data.inventoryItems;
          _restoreExisting();
        } else if (_sourceId.isNotEmpty) {
          await _loadLocationItems(_sourceId, restoreExisting: true);
        }
      },
    );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadLocationItems(
    String warehouseId, {
    bool restoreExisting = false,
  }) async {
    setState(() => _loading = true);
    final result = await _repository.getLocationItems(warehouseId);
    if (!mounted) return;
    result.fold((failure) => AppToast.error(context, failure.message), (rows) {
      _catalog = rows;
      if (restoreExisting) _restoreExisting();
    });
    if (mounted) setState(() => _loading = false);
  }

  void _restoreExisting() {
    final oldItems = widget.existing?['items'] as List? ?? const [];
    for (final raw in oldItems) {
      final old = Map<String, dynamic>.from(raw as Map);
      final id = old['inventaris_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final catalogItem = _catalog.cast<Map<String, dynamic>?>().firstWhere(
        (item) => (item?['inventaris_id'] ?? item?['_id'])?.toString() == id,
        orElse: () => null,
      );
      _selected[id] = {
        ...?catalogItem,
        ...old,
        'inventaris_id': id,
        'input_qty': old['qty_ordered'] ?? old['qty_fisik'] ?? old['qty'] ?? 1,
        'input_price': old['harga_beli'] ?? old['nilai_per_unit'] ?? 0,
      };
    }
  }

  Future<void> _chooseItem() async {
    final search = TextEditingController();
    var filtered = List<Map<String, dynamic>>.from(_catalog);
    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pilih barang'),
          content: SizedBox(
            width: 520,
            height: 430,
            child: Column(
              children: [
                TextField(
                  controller: search,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Cari nama / kode barang',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setDialogState(() {
                    final keyword = value.toLowerCase();
                    filtered = _catalog.where((item) {
                      return '${item['nama_inventaris']} ${item['kode_inventaris']}'
                          .toLowerCase()
                          .contains(keyword);
                    }).toList();
                  }),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, index) {
                      final item = filtered[index];
                      final id =
                          (item['inventaris_id'] ?? item['_id'])?.toString() ??
                          '';
                      return ListTile(
                        enabled: !_selected.containsKey(id),
                        title: Text(item['nama_inventaris']?.toString() ?? '-'),
                        subtitle: Text(
                          '${item['kode_inventaris'] ?? '-'} • Stok ${item['qty'] ?? item['stok'] ?? '-'} ${item['unit'] ?? ''}',
                        ),
                        onTap: () => Navigator.pop(dialogContext, item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
    search.dispose();
    if (picked == null) return;
    final id = (picked['inventaris_id'] ?? picked['_id']).toString();
    setState(() {
      _selected[id] = {
        ...picked,
        'inventaris_id': id,
        'input_qty': widget.type == PosInventoryDocumentType.opname
            ? (picked['qty'] ?? 0)
            : 1.0,
        'input_price': picked['harga_beli'] ?? 0,
      };
    });
  }

  Future<void> _save() async {
    if (widget.type == PosInventoryDocumentType.purchase &&
        _supplierId.isEmpty) {
      AppToast.error(context, 'Pilih supplier');
      return;
    }
    if (_usesLocation && _sourceId.isEmpty) {
      AppToast.error(context, 'Pilih lokasi sumber');
      return;
    }
    if (widget.type == PosInventoryDocumentType.transfer &&
        (_destinationId.isEmpty || _destinationId == _sourceId)) {
      AppToast.error(context, 'Pilih lokasi tujuan yang berbeda');
      return;
    }
    if (_selected.isEmpty ||
        _selected.values.any(
          (item) =>
              (item['input_qty'] as num? ?? 0) < 0 ||
              (widget.type != PosInventoryDocumentType.opname &&
                  (item['input_qty'] as num? ?? 0) <= 0),
        )) {
      AppToast.error(context, 'Tambahkan barang dan isi jumlah yang valid');
      return;
    }
    if (widget.type == PosInventoryDocumentType.transfer ||
        widget.type == PosInventoryDocumentType.scrap) {
      final excessive = _selected.values
          .cast<Map<String, dynamic>?>()
          .firstWhere((item) {
            final qty = (item?['input_qty'] as num? ?? 0).toDouble();
            final available = (item?['qty'] as num? ?? double.infinity)
                .toDouble();
            return qty > available;
          }, orElse: () => null);
      if (excessive != null) {
        AppToast.error(
          context,
          'Jumlah ${excessive['nama_inventaris']} melebihi stok lokasi (${excessive['qty']} ${excessive['unit'] ?? ''})',
        );
        return;
      }
    }
    if (widget.type == PosInventoryDocumentType.scrap &&
        _selected.values.any(
          (item) =>
              (item['stock_balance_id'] ?? item['_id'])?.toString().isEmpty !=
              false,
        )) {
      AppToast.error(context, 'Saldo lokasi barang terbuang tidak valid');
      return;
    }
    final source = _warehouse(_sourceId);
    final destination = _warehouse(_destinationId);
    final input = switch (widget.type) {
      PosInventoryDocumentType.purchase => {
        'supplier_id': _supplierId,
        'tanggal_po': widget.existing?['tanggal_po'] ?? _today,
        'tanggal_pengiriman': widget.existing?['tanggal_pengiriman'],
        'alamat_pengiriman': widget.existing?['alamat_pengiriman'],
        'metode_pembayaran':
            widget.existing?['metode_pembayaran'] ?? 'transfer',
        'syarat_pembayaran': widget.existing?['syarat_pembayaran'],
        'prioritas': widget.existing?['prioritas'],
        'diskon_persen': widget.existing?['diskon_persen'],
        'ppn_persen': widget.existing?['ppn_persen'],
        'biaya_pengiriman': widget.existing?['biaya_pengiriman'],
        'catatan': _notes.text.trim(),
        'items': _selected.values
            .map(
              (item) => {
                'inventaris_id': item['inventaris_id'],
                'nama_inventaris': item['nama_inventaris'],
                'qty_ordered': item['input_qty'],
                'harga_beli': item['input_price'],
                'unit': item['unit'],
                'diskon_item': item['diskon_item'],
                'diskon_item_type': item['diskon_item_type'],
                'catatan_item': item['catatan_item'],
              },
            )
            .toList(),
      },
      PosInventoryDocumentType.opname => {
        'tanggal_opname': _today,
        'lokasi': _locationInput(source),
        'catatan': _notes.text.trim(),
        if (widget.existing?['biaya_transfer'] != null)
          'biaya_transfer': widget.existing?['biaya_transfer'],
        if (widget.existing?['biaya_mode'] != null)
          'biaya_mode': widget.existing?['biaya_mode'],
        if (widget.existing?['biaya_alokasi'] != null)
          'biaya_alokasi': widget.existing?['biaya_alokasi'],
        'items': _selected.values
            .map(
              (item) => {
                'inventaris_id': item['inventaris_id'],
                'qty_system': item['qty_system'] ?? item['qty'] ?? 0,
                'qty_fisik': item['input_qty'],
                'nama_inventaris': item['nama_inventaris'],
                'kode_inventaris': item['kode_inventaris'],
                'unit': item['unit'],
              },
            )
            .toList(),
      },
      PosInventoryDocumentType.transfer => {
        'tanggal_transfer': _today,
        'dari': _locationInput(source),
        'ke': _locationInput(destination),
        'catatan': _notes.text.trim(),
        'items': _selected.values
            .map(
              (item) => {
                'inventaris_id': item['inventaris_id'],
                'nama_inventaris': item['nama_inventaris'],
                'kode_inventaris': item['kode_inventaris'],
                'unit': item['unit'],
                'qty': item['input_qty'],
              },
            )
            .toList(),
      },
      PosInventoryDocumentType.scrap => {
        'tanggal_scrap': _today,
        'alasan': _scrapReason,
        'jenis_insiden': _incidentType,
        'lokasi_kejadian': 'cabang',
        'catatan': _notes.text.trim(),
        'items': _selected.values
            .map(
              (item) => {
                'inventaris_id': item['inventaris_id'],
                'stock_balance_id': item['stock_balance_id'] ?? item['_id'],
                'qty': item['input_qty'],
                'nilai_per_unit': item['input_price'],
                'no_batch': item['no_batch'],
                'tindakan': item['tindakan'] ?? 'kurangi_stok',
                'jumlah_hasil_recycle': item['jumlah_hasil_recycle'],
              },
            )
            .toList(),
      },
    };
    setState(() => _loading = true);
    final result = await _repository.saveDocument(
      type: widget.type,
      input: input,
      id: widget.existing?['_id']?.toString(),
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        AppToast.error(context, failure.message);
        setState(() => _loading = false);
      },
      (_) {
        AppToast.success(
          context,
          _editing ? 'Dokumen berhasil diperbarui' : 'Draft berhasil dibuat',
        );
        Navigator.pop(context, true);
      },
    );
  }

  Map<String, dynamic> _warehouse(String id) =>
      _lookups?.warehouses.cast<Map<String, dynamic>?>().firstWhere(
        (item) => item?['_id']?.toString() == id,
        orElse: () => null,
      ) ??
      {};
  Map<String, dynamic> _locationInput(Map<String, dynamic> warehouse) => {
    'cabang_id': warehouse['_id'],
    'cabang_nama': warehouse['nama_cabang'],
  };
  String get _today => DateTime.now().toIso8601String().split('T').first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_editing ? 'Ubah' : 'Tambah'} ${_title(widget.type)}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading && _lookups == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (widget.type == PosInventoryDocumentType.purchase)
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _supplierId.isEmpty ? null : _supplierId,
                        decoration: const InputDecoration(
                          labelText: 'Supplier',
                          border: OutlineInputBorder(),
                        ),
                        items: (_lookups?.suppliers ?? const [])
                            .map(
                              (item) => DropdownMenuItem(
                                value: item['_id'].toString(),
                                child: Text(item['nama_supplier'].toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _supplierId = value ?? ''),
                      ),
                    if (_usesLocation)
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _sourceId.isEmpty ? null : _sourceId,
                        decoration: const InputDecoration(
                          labelText: 'Lokasi sumber',
                          border: OutlineInputBorder(),
                        ),
                        items: (_lookups?.warehouses ?? const [])
                            .map(
                              (item) => DropdownMenuItem(
                                value: item['_id'].toString(),
                                child: Text(item['nama_cabang'].toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          final id = value ?? '';
                          setState(() {
                            _sourceId = id;
                            _selected.clear();
                          });
                          if (id.isNotEmpty) _loadLocationItems(id);
                        },
                      ),
                    if (widget.type == PosInventoryDocumentType.transfer) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _destinationId.isEmpty
                            ? null
                            : _destinationId,
                        decoration: const InputDecoration(
                          labelText: 'Lokasi tujuan',
                          border: OutlineInputBorder(),
                        ),
                        items: (_lookups?.warehouses ?? const [])
                            .where(
                              (item) => item['_id'].toString() != _sourceId,
                            )
                            .map(
                              (item) => DropdownMenuItem(
                                value: item['_id'].toString(),
                                child: Text(item['nama_cabang'].toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _destinationId = value ?? ''),
                      ),
                    ],
                    if (widget.type == PosInventoryDocumentType.scrap) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _scrapReason,
                        decoration: const InputDecoration(
                          labelText: 'Alasan barang terbuang',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'rusak',
                            child: Text('Rusak'),
                          ),
                          DropdownMenuItem(
                            value: 'kadaluarsa',
                            child: Text('Kedaluwarsa'),
                          ),
                          DropdownMenuItem(
                            value: 'hilang',
                            child: Text('Hilang'),
                          ),
                          DropdownMenuItem(
                            value: 'lainnya',
                            child: Text('Lainnya'),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _scrapReason = value ?? 'rusak'),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Daftar barang',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _catalog.isEmpty ? null : _chooseItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah barang'),
                        ),
                      ],
                    ),
                    if (_selected.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: Text('Belum ada barang dipilih')),
                      ),
                    ..._selected.entries.map((entry) {
                      final item = entry.value;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['nama_inventaris']?.toString() ??
                                          '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => setState(
                                      () => _selected.remove(entry.key),
                                    ),
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: item['input_qty']
                                          .toString(),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: InputDecoration(
                                        labelText:
                                            widget.type ==
                                                PosInventoryDocumentType.opname
                                            ? 'Jumlah fisik'
                                            : 'Jumlah (${item['unit'] ?? ''})',
                                        border: const OutlineInputBorder(),
                                      ),
                                      onChanged: (value) => item['input_qty'] =
                                          double.tryParse(
                                            value.replaceAll(',', '.'),
                                          ) ??
                                          0,
                                    ),
                                  ),
                                  if (widget.type ==
                                      PosInventoryDocumentType.purchase) ...[
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: item['input_price']
                                            .toString(),
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Harga beli',
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) =>
                                            item['input_price'] =
                                                double.tryParse(value) ?? 0,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notes,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Catatan',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _loading ? null : _save,
                      icon: const Icon(Icons.save),
                      label: Text(
                        _editing ? 'Simpan Perubahan' : 'Simpan Draft',
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
                if (_loading)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x44FFFFFF),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
    );
  }
}

String _title(PosInventoryDocumentType type) => switch (type) {
  PosInventoryDocumentType.purchase => 'Faktur Pembelian',
  PosInventoryDocumentType.opname => 'Stok Opname',
  PosInventoryDocumentType.transfer => 'Mutasi Stok',
  PosInventoryDocumentType.scrap => 'Stok Terbuang',
};
