import 'package:flutter/material.dart';

import '../../../../injections.dart';
import '../../../core/_core.dart';
import '../../../domain/repositories/pos_inventory_repository.dart';
import '../../widgets/app_toast.dart';
import 'pos_barcode_scanner_page.dart';

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
  final _reasonDetail = TextEditingController();
  PosInventoryLookups? _lookups;
  List<Map<String, dynamic>> _catalog = const [];
  final Map<String, Map<String, dynamic>> _selected = {};
  String _supplierId = '';
  String _sourceId = '';
  String _destinationId = '';
  String _scrapReason = 'rusak';
  String _incidentType = 'disposal';
  late DateTime _opnameDate;
  late DateTime _scrapDate;
  String _incidentLocation = 'gudang';
  bool _loading = true;

  bool get _editing => widget.existing != null;
  bool get _usesLocation => widget.type != PosInventoryDocumentType.purchase;

  @override
  void initState() {
    super.initState();
    _notes.text = widget.existing?['catatan']?.toString() ?? '';
    _reasonDetail.text = widget.existing?['alasan_detail']?.toString() ?? '';
    _supplierId = widget.existing?['supplier_id']?.toString() ?? '';
    _sourceId =
        (widget.existing?['lokasi'] as Map?)?['cabang_id']?.toString() ??
        (widget.existing?['dari'] as Map?)?['cabang_id']?.toString() ??
        _existingScrapLocationId() ??
        '';
    _destinationId =
        (widget.existing?['ke'] as Map?)?['cabang_id']?.toString() ?? '';
    _scrapReason = widget.existing?['alasan']?.toString() ?? 'rusak';
    if (!const {
      'rusak',
      'kadaluarsa',
      'hilang',
      'kehilangan',
      'lainnya',
      'usang',
      'cacat_produksi',
      'bencana',
      'kecelakaan',
      'mencair',
      'tumpah',
    }.contains(_scrapReason)) {
      _scrapReason = 'lainnya';
    }
    _incidentType = widget.existing?['jenis_insiden']?.toString() ?? 'disposal';
    _opnameDate =
        DateTime.tryParse(
          widget.existing?['tanggal_opname']?.toString() ?? '',
        ) ??
        DateTime.now();
    _scrapDate =
        DateTime.tryParse(
          widget.existing?['tanggal_scrap']?.toString() ?? '',
        ) ??
        DateTime.now();
    _incidentLocation =
        widget.existing?['lokasi_kejadian']?.toString() ?? 'gudang';
    _load();
  }

  String? _existingScrapLocationId() {
    if (widget.type != PosInventoryDocumentType.scrap) return null;
    final items = widget.existing?['items'] as List? ?? const [];
    if (items.isEmpty || items.first is! Map) return null;
    final value = (items.first as Map)['lokasi_cabang_id']?.toString();
    return value == null || value.isEmpty ? null : value;
  }

  @override
  void dispose() {
    _notes.dispose();
    _reasonDetail.dispose();
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
      if (restoreExisting && _editing) {
        _restoreExisting();
      } else if (widget.type == PosInventoryDocumentType.opname) {
        _selected
          ..clear()
          ..addEntries(
            rows.map((item) {
              final id = (item['inventaris_id'] ?? item['_id']).toString();
              final qty = (item['qty'] as num?)?.toDouble() ?? 0;
              final batches = (item['batches'] as List? ?? const [])
                  .whereType<Map>()
                  .where((batch) => batch['aktif'] != false)
                  .map(
                    (batch) => <String, dynamic>{
                      'no_batch': batch['no_batch']?.toString() ?? '',
                      'tanggal_kadaluarsa': batch['tanggal_kadaluarsa'],
                      'qty_system': (batch['qty'] as num?)?.toDouble() ?? 0,
                      'qty_fisik': (batch['qty'] as num?)?.toDouble() ?? 0,
                    },
                  )
                  .where((batch) => batch['no_batch'].toString().isNotEmpty)
                  .toList();
              return MapEntry(id, {
                ...item,
                'inventaris_id': id,
                'qty_system': qty,
                'input_qty': qty,
                'input_price': item['harga_beli'] ?? 0,
                'batch_counts': batches,
              });
            }),
          );
      } else if (restoreExisting) {
        _restoreExisting();
      }
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
        if (widget.type == PosInventoryDocumentType.scrap)
          'available_qty':
              old['saldo_lokasi_sebelum'] ?? old['stok_sebelum'] ?? old['qty'],
        'batch_counts': (old['batch_counts'] as List? ?? const [])
            .whereType<Map>()
            .map((batch) => Map<String, dynamic>.from(batch))
            .toList(),
      };
    }
  }

  Future<void> _chooseItem() async {
    final search = TextEditingController();
    var filtered = List<Map<String, dynamic>>.from(_catalog);
    var picked = await showDialog<Map<String, dynamic>>(
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
    if (widget.type == PosInventoryDocumentType.scrap) {
      picked = await _prepareScrapItem(picked);
      if (picked == null) return;
    }
    final selectedItem = picked;
    final id = (selectedItem['inventaris_id'] ?? selectedItem['_id'])
        .toString();
    setState(() {
      _selected[id] = {
        ...selectedItem,
        'inventaris_id': id,
        'input_qty': widget.type == PosInventoryDocumentType.opname
            ? (selectedItem['qty'] ?? 0)
            : 1.0,
        'input_price': selectedItem['harga_beli'] ?? 0,
        if (widget.type == PosInventoryDocumentType.scrap) ...{
          'tindakan': selectedItem['tindakan'] ?? 'kurangi_stok',
          'jumlah_hasil_recycle': selectedItem['jumlah_hasil_recycle'] ?? 0,
          'catatan_item': selectedItem['catatan_item'] ?? '',
        },
      };
    });
  }

  Future<Map<String, dynamic>?> _prepareScrapItem(
    Map<String, dynamic> item,
  ) async {
    final inventoryId =
        (item['inventaris_id'] ?? item['_id'])?.toString() ?? '';
    if (inventoryId.isEmpty) return null;
    setState(() => _loading = true);
    final result = await _repository.getLocationBalances(
      inventoryId: inventoryId,
      warehouseId: _sourceId,
    );
    if (mounted) setState(() => _loading = false);
    if (!mounted) return null;
    List<Map<String, dynamic>> balances = const [];
    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (items) => balances = items,
    );
    if (balances.isEmpty) {
      AppToast.error(context, 'Saldo lokasi barang tidak tersedia');
      return null;
    }
    Map<String, dynamic>? balance;
    if (balances.length == 1) {
      balance = balances.first;
    } else {
      balance = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Pilih sumber stok'),
          content: SizedBox(
            width: 520,
            height: 360,
            child: ListView.separated(
              itemCount: balances.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final candidate = balances[index];
                return ListTile(
                  title: Text(_balanceLocationLabel(candidate)),
                  subtitle: Text(
                    'Tersedia ${_numberText(candidate['qty'])} ${item['unit'] ?? ''}',
                  ),
                  onTap: () => Navigator.pop(dialogContext, candidate),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
          ],
        ),
      );
    }
    if (balance == null) return null;
    final batches = (balance['batches'] as List? ?? const [])
        .whereType<Map>()
        .where(
          (batch) =>
              batch['aktif'] != false &&
              ((batch['qty'] as num?)?.toDouble() ?? 0) > 0,
        )
        .map((batch) => Map<String, dynamic>.from(batch))
        .toList();
    return {
      ...item,
      'stock_balance_id': balance['_id'],
      'available_qty': balance['qty'],
      'selected_balance': balance,
      'batch_options': batches,
      'no_batch': item['no_batch'] ?? '',
    };
  }

  String _balanceLocationLabel(Map<String, dynamic> balance) {
    final parts =
        [
              balance['lokasi_cabang_nama'],
              balance['lokasi_gedung_nama'] ?? balance['lokasi_gedung_kode'],
              balance['lokasi_ruangan_nama'] ?? balance['lokasi_ruangan_kode'],
              balance['lokasi_rak_nama'],
            ]
            .map((value) => value?.toString().trim() ?? '')
            .where((value) => value.isNotEmpty)
            .toList();
    return parts.isEmpty ? 'Lokasi stok' : parts.join(' / ');
  }

  Future<void> _scanOpnameBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PosBarcodeScannerPage()),
    );
    if (!mounted || barcode == null || barcode.trim().isEmpty) return;
    final keyword = barcode.trim().toLowerCase();
    Map<String, dynamic>? found;
    for (final item in _catalog) {
      final candidates = [
        item['barcode'],
        item['sku'],
        item['kode_inventaris'],
      ].map((value) => value?.toString().trim().toLowerCase());
      if (candidates.contains(keyword)) {
        found = item;
        break;
      }
    }
    if (found == null) {
      AppToast.error(context, 'Barcode tidak ditemukan di lokasi opname ini');
      return;
    }
    final id = (found['inventaris_id'] ?? found['_id']).toString();
    final selected = _selected[id];
    if (selected == null) {
      AppToast.error(context, 'Barang tidak termasuk snapshot opname');
      return;
    }
    await _editPhysicalQuantity(selected);
  }

  Future<void> _scanScrapBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PosBarcodeScannerPage()),
    );
    if (!mounted || barcode == null || barcode.trim().isEmpty) return;
    final keyword = barcode.trim().toLowerCase();
    Map<String, dynamic>? found;
    for (final item in _catalog) {
      final candidates = [
        item['barcode'],
        item['sku'],
        item['kode_inventaris'],
      ].map((value) => value?.toString().trim().toLowerCase());
      if (candidates.contains(keyword)) {
        found = item;
        break;
      }
    }
    if (found == null) {
      AppToast.error(context, 'Barcode tidak ditemukan di lokasi sumber');
      return;
    }
    final id = (found['inventaris_id'] ?? found['_id']).toString();
    if (_selected.containsKey(id)) {
      AppToast.error(context, 'Barang sudah ada di daftar disposal');
      return;
    }
    final prepared = await _prepareScrapItem(found);
    if (prepared == null || !mounted) return;
    setState(() {
      _selected[id] = {
        ...prepared,
        'inventaris_id': id,
        'input_qty': 1.0,
        'input_price': prepared['harga_beli'] ?? 0,
        'tindakan': 'kurangi_stok',
        'jumlah_hasil_recycle': 0.0,
        'catatan_item': '',
      };
    });
  }

  Future<void> _editPhysicalQuantity(Map<String, dynamic> item) async {
    final batches = (item['batch_counts'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    if (batches.isNotEmpty) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              0,
              20,
              20 + MediaQuery.viewInsetsOf(sheetContext).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item['nama_inventaris']?.toString() ?? 'Hitung per batch',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Masukkan jumlah fisik untuk setiap batch.'),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: batches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final batch = batches[index];
                      return TextFormField(
                        initialValue: _numberText(batch['qty_fisik']),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: batch['no_batch']?.toString() ?? 'Batch',
                          helperText:
                              'Sistem ${_numberText(batch['qty_system'])}${(batch['tanggal_kadaluarsa']?.toString() ?? '').isEmpty ? '' : ' • Exp ${batch['tanggal_kadaluarsa']}'}',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) => batch['qty_fisik'] =
                            double.tryParse(value.replaceAll(',', '.')) ?? 0,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Terapkan'),
                ),
              ],
            ),
          ),
        ),
      );
      if (mounted) {
        setState(() {
          item['input_qty'] = batches.fold<double>(
            0,
            (sum, batch) =>
                sum + ((batch['qty_fisik'] as num?)?.toDouble() ?? 0),
          );
        });
      }
      return;
    }
    final controller = TextEditingController(
      text: _numberText(item['input_qty']),
    );
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(item['nama_inventaris']?.toString() ?? 'Jumlah fisik'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Jumlah fisik',
            suffixText: item['unit']?.toString(),
            helperText:
                'Stok sistem: ${_numberText(item['qty_system'] ?? item['qty'])}',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (raw) => Navigator.pop(
            dialogContext,
            double.tryParse(raw.replaceAll(',', '.')),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              double.tryParse(controller.text.replaceAll(',', '.')),
            ),
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(kThemeAnimationDuration);
    controller.dispose();
    if (value == null || value < 0 || !mounted) return;
    setState(() => item['input_qty'] = value);
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
    if (widget.type == PosInventoryDocumentType.opname &&
        _selected.values.any(
          (item) =>
              (item['batch_counts'] as List? ?? const []).whereType<Map>().any(
                (batch) => ((batch['qty_fisik'] as num?)?.toDouble() ?? -1) < 0,
              ),
        )) {
      AppToast.error(context, 'Jumlah fisik batch tidak boleh negatif');
      return;
    }
    if (widget.type == PosInventoryDocumentType.opname) {
      final withoutReason = _selected.values
          .cast<Map<String, dynamic>?>()
          .firstWhere((item) {
            final system =
                (item?['qty_system'] as num?)?.toDouble() ??
                (item?['qty'] as num?)?.toDouble() ??
                0;
            final physical = (item?['input_qty'] as num?)?.toDouble() ?? system;
            return (physical - system).abs() > 0.000001 &&
                (item?['catatan_item']?.toString().trim().length ?? 0) < 3;
          }, orElse: () => null);
      if (withoutReason != null) {
        AppToast.error(
          context,
          'Isi alasan selisih ${withoutReason['nama_inventaris']} minimal 3 karakter',
        );
        return;
      }
    }
    if (widget.type == PosInventoryDocumentType.transfer ||
        widget.type == PosInventoryDocumentType.scrap) {
      final excessive = _selected.values
          .cast<Map<String, dynamic>?>()
          .firstWhere((item) {
            final qty = (item?['input_qty'] as num? ?? 0).toDouble();
            dynamic rawAvailable;
            if (widget.type == PosInventoryDocumentType.scrap) {
              rawAvailable =
                  item?['available_qty'] ??
                  item?['saldo_lokasi_sebelum'] ??
                  item?['qty'];
            } else {
              rawAvailable = item?['qty'];
            }
            final available = rawAvailable is num
                ? rawAvailable.toDouble()
                : double.infinity;
            return qty > available;
          }, orElse: () => null);
      if (excessive != null) {
        AppToast.error(
          context,
          'Jumlah ${excessive['nama_inventaris']} melebihi stok lokasi (${_numberText(excessive['available_qty'] ?? excessive['qty'])} ${excessive['unit'] ?? ''})',
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
    if (widget.type == PosInventoryDocumentType.scrap) {
      if (_scrapReason == 'lainnya' && _reasonDetail.text.trim().length < 3) {
        AppToast.error(context, 'Isi detail alasan disposal');
        return;
      }
      for (final item in _selected.values) {
        final qty = (item['input_qty'] as num?)?.toDouble() ?? 0;
        final recycled =
            (item['jumlah_hasil_recycle'] as num?)?.toDouble() ?? 0;
        if (recycled < 0 || recycled > qty) {
          AppToast.error(
            context,
            'Jumlah hasil recycle ${item['nama_inventaris']} harus 0–${_numberText(qty)}',
          );
          return;
        }
        final batches = item['batch_options'] as List? ?? const [];
        if (batches.isNotEmpty &&
            (item['no_batch']?.toString().trim() ?? '').isEmpty) {
          AppToast.error(context, 'Pilih batch ${item['nama_inventaris']}');
          return;
        }
        if (batches.isNotEmpty) {
          final selectedBatch = batches
              .whereType<Map>()
              .cast<Map?>()
              .firstWhere(
                (batch) => batch?['no_batch']?.toString() == item['no_batch'],
                orElse: () => null,
              );
          final batchQty = (selectedBatch?['qty'] as num?)?.toDouble() ?? 0;
          if (qty - recycled > batchQty) {
            AppToast.error(
              context,
              'Jumlah hilang ${item['nama_inventaris']} melebihi saldo batch',
            );
            return;
          }
        }
      }
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
        'tanggal_opname': _dateValue(_opnameDate),
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
                if ((item['batch_counts'] as List? ?? const []).isNotEmpty)
                  'batch_counts': (item['batch_counts'] as List)
                      .whereType<Map>()
                      .map(
                        (batch) => {
                          'no_batch': batch['no_batch'],
                          'tanggal_kadaluarsa': batch['tanggal_kadaluarsa'],
                          'qty_system': batch['qty_system'],
                          'qty_fisik': batch['qty_fisik'],
                        },
                      )
                      .toList(),
                if ((item['catatan_item']?.toString() ?? '').isNotEmpty)
                  'catatan_item': item['catatan_item'],
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
        'tanggal_scrap': _dateValue(_scrapDate),
        'alasan': _scrapReason,
        'alasan_detail': _reasonDetail.text.trim(),
        'jenis_insiden': _incidentType,
        'lokasi_kejadian': _incidentLocation,
        'catatan': _notes.text.trim(),
        'items': _selected.values
            .map(
              (item) => {
                'inventaris_id': item['inventaris_id'],
                'stock_balance_id': item['stock_balance_id'] ?? item['_id'],
                'qty': item['input_qty'],
                'nilai_per_unit': item['input_price'],
                'no_batch': item['no_batch'],
                'catatan_item': item['catatan_item'],
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
  String _dateValue(DateTime value) => value.toIso8601String().split('T').first;
  String _numberText(dynamic value) {
    final number =
        (value as num?)?.toDouble() ??
        double.tryParse(value?.toString() ?? '') ??
        0;
    return number == number.roundToDouble()
        ? number.toInt().toString()
        : number.toString();
  }

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
                    if (widget.type == PosInventoryDocumentType.opname) ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _opnameDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _opnameDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal opname',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_dateValue(_opnameDate)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primary),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Semua saldo di lokasi dipotret otomatis. Masukkan hasil hitung fisik, lalu simpan sebagai draft sebelum diajukan dan diposting.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _scrapDate,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _scrapDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal kejadian',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(_dateValue(_scrapDate)),
                        ),
                      ),
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
                            value: 'kehilangan',
                            child: Text('Kehilangan'),
                          ),
                          DropdownMenuItem(
                            value: 'lainnya',
                            child: Text('Lainnya'),
                          ),
                          DropdownMenuItem(
                            value: 'usang',
                            child: Text('Usang'),
                          ),
                          DropdownMenuItem(
                            value: 'cacat_produksi',
                            child: Text('Cacat produksi'),
                          ),
                          DropdownMenuItem(
                            value: 'bencana',
                            child: Text('Bencana'),
                          ),
                          DropdownMenuItem(
                            value: 'kecelakaan',
                            child: Text('Kecelakaan operasional'),
                          ),
                          DropdownMenuItem(
                            value: 'mencair',
                            child: Text('Mencair / rusak suhu'),
                          ),
                          DropdownMenuItem(
                            value: 'tumpah',
                            child: Text('Tumpah / bocor'),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          _scrapReason = value ?? 'rusak';
                          _incidentType = switch (_scrapReason) {
                            'rusak' || 'cacat_produksi' => 'kerusakan',
                            'kadaluarsa' => 'kadaluarsa',
                            'hilang' || 'kehilangan' => 'kehilangan',
                            'kecelakaan' => 'kecelakaan',
                            'mencair' => 'mencair',
                            'tumpah' => 'tumpah',
                            _ => 'disposal',
                          };
                        }),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _incidentLocation,
                        decoration: const InputDecoration(
                          labelText: 'Lokasi kejadian',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'gudang',
                            child: Text('Gudang'),
                          ),
                          DropdownMenuItem(
                            value: 'cabang',
                            child: Text('Cabang / outlet'),
                          ),
                          DropdownMenuItem(
                            value: 'pengantaran',
                            child: Text('Pengantaran barang'),
                          ),
                          DropdownMenuItem(
                            value: 'ruang_operasional',
                            child: Text('Ruang operasional'),
                          ),
                          DropdownMenuItem(
                            value: 'lainnya',
                            child: Text('Lainnya'),
                          ),
                        ],
                        onChanged: (value) => setState(
                          () => _incidentLocation = value ?? 'gudang',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reasonDetail,
                        decoration: const InputDecoration(
                          labelText: 'Detail alasan / kronologi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Saldo belum berkurang saat draft dibuat. Stok dan jurnal kerugian baru diproses setelah dokumen disetujui.',
                        ),
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
                        if (widget.type == PosInventoryDocumentType.opname)
                          FilledButton.icon(
                            onPressed: _catalog.isEmpty
                                ? null
                                : _scanOpnameBarcode,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan'),
                          )
                        else if (widget.type == PosInventoryDocumentType.scrap)
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _catalog.isEmpty
                                    ? null
                                    : _scanScrapBarcode,
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Scan'),
                              ),
                              FilledButton.icon(
                                onPressed: _catalog.isEmpty
                                    ? null
                                    : _chooseItem,
                                icon: const Icon(Icons.add),
                                label: const Text('Tambah'),
                              ),
                            ],
                          )
                        else
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
                                  if (widget.type !=
                                      PosInventoryDocumentType.opname)
                                    IconButton(
                                      onPressed: () => setState(
                                        () => _selected.remove(entry.key),
                                      ),
                                      icon: const Icon(Icons.close),
                                    ),
                                ],
                              ),
                              if (widget.type ==
                                  PosInventoryDocumentType.opname) ...[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${item['kode_inventaris'] ?? '-'} • Sistem ${_numberText(item['qty_system'] ?? item['qty'])} ${item['unit'] ?? ''}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (widget.type ==
                                      PosInventoryDocumentType.opname &&
                                  (item['batch_counts'] as List? ?? const [])
                                      .isNotEmpty)
                                ...((item['batch_counts'] as List).whereType<Map>().map((
                                  batch,
                                ) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${batch['no_batch']}\nSistem ${_numberText(batch['qty_system'])}${(batch['tanggal_kadaluarsa']?.toString() ?? '').isEmpty ? '' : ' • Exp ${batch['tanggal_kadaluarsa']}'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 120,
                                          child: TextFormField(
                                            initialValue: _numberText(
                                              batch['qty_fisik'],
                                            ),
                                            keyboardType:
                                                const TextInputType.numberWithOptions(
                                                  decimal: true,
                                                ),
                                            decoration: const InputDecoration(
                                              labelText: 'Fisik',
                                              border: OutlineInputBorder(),
                                            ),
                                            onChanged: (value) {
                                              batch['qty_fisik'] =
                                                  double.tryParse(
                                                    value.replaceAll(',', '.'),
                                                  ) ??
                                                  0;
                                              item['input_qty'] =
                                                  (item['batch_counts'] as List)
                                                      .whereType<Map>()
                                                      .fold<double>(
                                                        0,
                                                        (sum, current) =>
                                                            sum +
                                                            ((current['qty_fisik']
                                                                        as num?)
                                                                    ?.toDouble() ??
                                                                0),
                                                      );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                })),
                              if (!(widget.type ==
                                      PosInventoryDocumentType.opname &&
                                  (item['batch_counts'] as List? ?? const [])
                                      .isNotEmpty))
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
                                                  PosInventoryDocumentType
                                                      .opname
                                              ? 'Jumlah fisik'
                                              : 'Jumlah (${item['unit'] ?? ''})',
                                          border: const OutlineInputBorder(),
                                        ),
                                        onChanged: (value) =>
                                            item['input_qty'] =
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
                              if (widget.type ==
                                  PosInventoryDocumentType.scrap) ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '${_balanceLocationLabel(Map<String, dynamic>.from(item['selected_balance'] as Map? ?? const {}))}\nSaldo tersedia ${_numberText(item['available_qty'] ?? item['qty'])} ${item['unit'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                if ((item['batch_options'] as List? ?? const [])
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue:
                                        (item['no_batch']?.toString() ?? '')
                                            .isEmpty
                                        ? null
                                        : item['no_batch'].toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Batch sumber *',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: (item['batch_options'] as List)
                                        .whereType<Map>()
                                        .map(
                                          (batch) => DropdownMenuItem<String>(
                                            value: batch['no_batch'].toString(),
                                            child: Text(
                                              '${batch['no_batch']} • ${_numberText(batch['qty'])} tersedia',
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) => setState(
                                      () => item['no_batch'] = value ?? '',
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  initialValue:
                                      item['tindakan']?.toString() ??
                                      'kurangi_stok',
                                  decoration: const InputDecoration(
                                    labelText: 'Tindakan stok',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'kurangi_stok',
                                      child: Text('Buang / kurangi stok'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'recycle',
                                      child: Text('Recycle sebagian'),
                                    ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => item['tindakan'] =
                                        value ?? 'kurangi_stok',
                                  ),
                                ),
                                if (item['tindakan'] == 'recycle') ...[
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    initialValue: _numberText(
                                      item['jumlah_hasil_recycle'],
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: InputDecoration(
                                      labelText: 'Jumlah berhasil direcycle',
                                      helperText:
                                          'Kerugian bersih = jumlah disposal dikurangi hasil recycle',
                                      suffixText: item['unit']?.toString(),
                                      border: const OutlineInputBorder(),
                                    ),
                                    onChanged: (value) =>
                                        item['jumlah_hasil_recycle'] =
                                            double.tryParse(
                                              value.replaceAll(',', '.'),
                                            ) ??
                                            0,
                                  ),
                                ],
                                const SizedBox(height: 10),
                                TextFormField(
                                  initialValue:
                                      item['catatan_item']?.toString() ?? '',
                                  decoration: const InputDecoration(
                                    labelText: 'Catatan barang',
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) =>
                                      item['catatan_item'] = value,
                                ),
                              ],
                              if (widget.type ==
                                  PosInventoryDocumentType.opname)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        initialValue:
                                            item['catatan_item']?.toString() ??
                                            '',
                                        decoration: const InputDecoration(
                                          labelText: 'Alasan selisih',
                                          hintText:
                                              'Wajib diisi jika stok fisik berbeda',
                                          border: OutlineInputBorder(),
                                        ),
                                        onChanged: (value) =>
                                            item['catatan_item'] = value,
                                      ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () =>
                                              _editPhysicalQuantity(item),
                                          icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 17,
                                          ),
                                          label: const Text(
                                            'Input hitung fisik',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (widget.type ==
                                  PosInventoryDocumentType.opname)
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Alasan minimal 3 karakter diperlukan saat terdapat selisih.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
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
