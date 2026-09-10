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
  final List<Map<String, dynamic>> _additionalCosts = [];
  String _supplierId = '';
  String _sourceId = '';
  String _destinationId = '';
  String _buildingCode = '';
  String _roomCode = '';
  String _rackName = '';
  late DateTime _purchaseDate;
  DateTime? _deliveryDate;
  DateTime? _dueDate;
  String _deliveryAddress = '';
  String _paymentMethod = 'transfer';
  String _paymentTerms = 'tunai';
  String _creditType = 'net30';
  String _priority = 'normal';
  String _discountType = 'persen';
  String _ppnSource = 'none';
  String _costMode = 'expense';
  String _costAllocation = 'per_nilai';
  int _termDays = 0;
  int _installmentCount = 2;
  double _discountPercent = 0;
  double _discountFixed = 0;
  double _ppnPercent = 0;
  double _shippingCost = 0;
  bool _supplierIsPkp = false;
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
    final existingLocation = widget.existing?['lokasi'] as Map?;
    _buildingCode = existingLocation?['gedung_kode']?.toString() ?? '';
    _roomCode = existingLocation?['ruangan_kode']?.toString() ?? '';
    _rackName = existingLocation?['rak_nama']?.toString() ?? '';
    _purchaseDate =
        DateTime.tryParse(widget.existing?['tanggal_po']?.toString() ?? '') ??
        DateTime.now();
    _deliveryDate = DateTime.tryParse(
      widget.existing?['tanggal_pengiriman']?.toString() ?? '',
    );
    _dueDate = DateTime.tryParse(
      widget.existing?['due_date']?.toString() ?? '',
    );
    _deliveryAddress = widget.existing?['alamat_pengiriman']?.toString() ?? '';
    _paymentMethod =
        widget.existing?['metode_pembayaran']?.toString() ?? 'transfer';
    _paymentTerms =
        widget.existing?['syarat_pembayaran']?.toString() ?? 'tunai';
    _creditType = widget.existing?['tipe_kredit']?.toString() ?? 'net30';
    _priority = widget.existing?['prioritas']?.toString() ?? 'normal';
    _discountType = widget.existing?['diskon_type']?.toString() ?? 'persen';
    _ppnSource = widget.existing?['ppn_source']?.toString() ?? 'none';
    _costMode = widget.existing?['biaya_mode']?.toString() ?? 'expense';
    _costAllocation =
        widget.existing?['biaya_alokasi']?.toString() ?? 'per_nilai';
    _termDays = (widget.existing?['term_days'] as num?)?.toInt() ?? 0;
    _installmentCount =
        (widget.existing?['jumlah_termin'] as num?)?.toInt() ?? 2;
    _discountPercent =
        (widget.existing?['diskon_persen'] as num?)?.toDouble() ?? 0;
    _discountFixed =
        (widget.existing?['diskon_fixed'] as num?)?.toDouble() ?? 0;
    _ppnPercent = (widget.existing?['ppn_persen'] as num?)?.toDouble() ?? 0;
    _shippingCost =
        (widget.existing?['biaya_pengiriman'] as num?)?.toDouble() ?? 0;
    _supplierIsPkp = widget.existing?['supplier_is_pkp'] == true;
    _additionalCosts.addAll(
      (widget.existing?['biaya_tambahan'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (row) => {
              'jenis_biaya': row['jenis_biaya'] ?? 'lainnya',
              'deskripsi': row['deskripsi'] ?? '',
              'nominal': (row['nominal'] as num?)?.toDouble() ?? 0,
            },
          ),
    );
    _scrapReason = widget.existing?['alasan']?.toString() ?? 'rusak';
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
        String validOption(String current, List<Map<String, dynamic>> options) {
          if (options.any((option) => option['value'] == current)) {
            return current;
          }
          return options.isNotEmpty
              ? options.first['value']?.toString() ?? ''
              : '';
        }

        _scrapReason = validOption(_scrapReason, data.scrapReasons);
        _incidentType = validOption(_incidentType, data.scrapIncidentTypes);
        _incidentLocation = validOption(
          _incidentLocation,
          data.scrapOccurrenceLocations,
        );
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
        // Saat membuat opname, backend mengambil snapshot saldo lokasi. Item baru
        // ditampilkan ketika dokumen dibuka kembali untuk dihitung secara fisik.
        _selected.clear();
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
      final restored = <String, dynamic>{
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
      if (widget.type == PosInventoryDocumentType.opname) {
        _prepareOpnameUnits(restored, old);
      }
      _selected[id] = restored;
    }
  }

  void _prepareOpnameUnits(
    Map<String, dynamic> item,
    Map<String, dynamic> persisted,
  ) {
    final baseUnit = (item['base_unit'] ?? item['unit'] ?? 'unit').toString();
    final factors = <String, double>{baseUnit: 1};
    for (final raw in (item['unit_conversions'] as List? ?? const [])) {
      if (raw is! Map) continue;
      final unit = raw['unit']?.toString().trim() ?? '';
      final factor = (raw['factor'] as num?)?.toDouble() ?? 0;
      if (unit.isNotEmpty && factor > 0) factors[unit] = factor;
    }
    final saved = <String, double>{};
    for (final raw in (persisted['unit_breakdown'] as List? ?? const [])) {
      if (raw is! Map) continue;
      final unit = raw['unit']?.toString() ?? '';
      saved[unit] = (raw['input_qty'] as num?)?.toDouble() ?? 0;
    }
    item['base_unit'] = baseUnit;
    item['available_units'] = factors.entries
        .map(
          (entry) => <String, dynamic>{
            'unit': entry.key,
            'factor': entry.value,
            'input_qty': saved[entry.key] ?? 0,
          },
        )
        .toList();
    item['use_conversion'] = saved.isNotEmpty;
  }

  void _recalculateOpnameQuantity(Map<String, dynamic> item) {
    item['input_qty'] = (item['available_units'] as List? ?? const [])
        .whereType<Map>()
        .fold<double>(
          0,
          (sum, row) =>
              sum +
              ((row['input_qty'] as num?)?.toDouble() ?? 0) *
                  ((row['factor'] as num?)?.toDouble() ?? 1),
        );
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
    if (widget.type == PosInventoryDocumentType.purchase &&
        (_discountPercent < 0 ||
            _discountPercent > 100 ||
            _discountFixed < 0 ||
            _discountFixed > _purchaseSubtotal ||
            _ppnPercent < 0 ||
            _ppnPercent > 100 ||
            _shippingCost < 0 ||
            _additionalCosts.any(
              (row) => ((row['nominal'] as num?)?.toDouble() ?? 0) < 0,
            ))) {
      AppToast.error(
        context,
        'Diskon, pajak, atau biaya pembelian tidak valid',
      );
      return;
    }
    if (widget.type == PosInventoryDocumentType.purchase &&
        _paymentTerms == 'kredit' &&
        (_termDays < 0 ||
            (_creditType == 'termin' &&
                (_installmentCount < 2 || _installmentCount > 12)))) {
      AppToast.error(context, 'Jangka waktu kredit tidak valid');
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
    if (!(!_editing && widget.type == PosInventoryDocumentType.opname) &&
        (_selected.isEmpty ||
            _selected.values.any(
              (item) =>
                  (item['input_qty'] as num? ?? 0) < 0 ||
                  (widget.type != PosInventoryDocumentType.opname &&
                      (item['input_qty'] as num? ?? 0) <= 0),
            ))) {
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
        'tanggal_po': _dateValue(_purchaseDate),
        'tanggal_pengiriman': _deliveryDate == null
            ? ''
            : _dateValue(_deliveryDate!),
        'alamat_pengiriman': _deliveryAddress.trim(),
        'metode_pembayaran': _paymentMethod,
        'syarat_pembayaran': _paymentTerms,
        'tipe_kredit': _paymentTerms == 'kredit' ? _creditType : '',
        'payment_term_type': _paymentTerms == 'kredit'
            ? (_creditType == 'termin' ? 'termin' : 'net')
            : 'immediate',
        'term_days': _paymentTerms == 'kredit' ? _termDays : 0,
        'due_date': _dueDate == null ? '' : _dateValue(_dueDate!),
        'due_date_basis': widget.existing?['due_date_basis'] ?? 'invoice_date',
        'jumlah_termin': _creditType == 'termin' ? _installmentCount : 1,
        if (_creditType == 'termin')
          'jadwal_termin': _generatedInstallmentSchedule,
        'prioritas': _priority,
        'diskon_persen': _discountPercent,
        'diskon_type': _discountType,
        'diskon_fixed': _discountFixed,
        'ppn_persen': _ppnPercent,
        'ppn_source': _ppnSource,
        'supplier_is_pkp': _supplierIsPkp,
        'biaya_pengiriman': _shippingCost,
        'biaya_tambahan': _additionalCosts
            .where((row) => ((row['nominal'] as num?)?.toDouble() ?? 0) > 0)
            .map(
              (row) => {
                'jenis_biaya': row['jenis_biaya'],
                'deskripsi': row['deskripsi'],
                'nominal': row['nominal'],
              },
            )
            .toList(),
        'biaya_mode': _costMode,
        'biaya_alokasi': _costAllocation,
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
        'lokasi': _opnameLocationInput(source),
        'catatan': _notes.text.trim(),
        if (widget.existing?['biaya_transfer'] != null)
          'biaya_transfer': widget.existing?['biaya_transfer'],
        if (widget.existing?['biaya_mode'] != null)
          'biaya_mode': widget.existing?['biaya_mode'],
        if (widget.existing?['biaya_alokasi'] != null)
          'biaya_alokasi': widget.existing?['biaya_alokasi'],
        if (_editing)
          'items': _selected.values
              .map(
                (item) => {
                  'inventaris_id': item['inventaris_id'],
                  'qty_system': item['qty_system'] ?? item['qty'] ?? 0,
                  'qty_fisik': item['input_qty'],
                  'nama_inventaris': item['nama_inventaris'],
                  'kode_inventaris': item['kode_inventaris'],
                  'unit': item['base_unit'] ?? item['unit'],
                  if (item['use_conversion'] == true)
                    'unit_breakdown':
                        (item['available_units'] as List? ?? const [])
                            .whereType<Map>()
                            .where(
                              (row) =>
                                  ((row['input_qty'] as num?)?.toDouble() ??
                                      0) >
                                  0,
                            )
                            .map(
                              (row) => {
                                'unit': row['unit'],
                                'input_qty': row['input_qty'],
                                'factor': row['factor'],
                              },
                            )
                            .toList(),
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

  Map<String, dynamic> _opnameLocationInput(Map<String, dynamic> warehouse) {
    final building = _buildings.cast<Map?>().firstWhere(
      (row) => row?['kode_gedung']?.toString() == _buildingCode,
      orElse: () => null,
    );
    final room = _rooms.cast<Map?>().firstWhere(
      (row) => row?['kode_ruangan']?.toString() == _roomCode,
      orElse: () => null,
    );
    return {
      ..._locationInput(warehouse),
      'gedung_kode': _buildingCode,
      'gedung_nama': building?['nama_gedung']?.toString() ?? '',
      'ruangan_kode': _roomCode,
      'ruangan_nama': room?['nama_ruangan']?.toString() ?? '',
      'rak_nama': _rackName,
    };
  }

  List<Map<String, dynamic>> get _buildings =>
      (_warehouse(_sourceId)['gedung'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

  List<Map<String, dynamic>> get _rooms {
    final building = _buildings.cast<Map?>().firstWhere(
      (row) => row?['kode_gedung']?.toString() == _buildingCode,
      orElse: () => null,
    );
    return (building?['ruangan'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }

  List<String> get _racks {
    final room = _rooms.cast<Map?>().firstWhere(
      (row) => row?['kode_ruangan']?.toString() == _roomCode,
      orElse: () => null,
    );
    return (room?['rak'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => row['nama_rak']?.toString() ?? '')
        .where((value) => value.isNotEmpty)
        .toList();
  }

  double get _purchaseSubtotal => _selected.values.fold<double>(0, (sum, item) {
    final qty = (item['input_qty'] as num?)?.toDouble() ?? 0;
    final price = (item['input_price'] as num?)?.toDouble() ?? 0;
    final raw = qty * price;
    final discount = (item['diskon_item'] as num?)?.toDouble() ?? 0;
    return sum +
        (item['diskon_item_type'] == 'fixed'
            ? (raw - discount).clamp(0, double.infinity)
            : raw * (1 - discount.clamp(0, 100) / 100));
  });

  double get _purchaseDiscount => _discountType == 'fixed'
      ? _discountFixed
      : _purchaseSubtotal * _discountPercent / 100;

  double get _purchaseTax =>
      (_purchaseSubtotal - _purchaseDiscount).clamp(0, double.infinity) *
      _ppnPercent /
      100;

  double get _purchaseGrandTotal =>
      (_purchaseSubtotal - _purchaseDiscount).clamp(0, double.infinity) +
      _purchaseTax +
      _effectivePurchaseCost;

  double get _effectivePurchaseCost => _additionalCosts.isEmpty
      ? _shippingCost
      : _additionalCosts.fold<double>(
          0,
          (sum, row) => sum + ((row['nominal'] as num?)?.toDouble() ?? 0),
        );

  List<Map<String, dynamic>> get _generatedInstallmentSchedule {
    if (_creditType != 'termin') return const [];
    final count = _installmentCount.clamp(2, 12);
    final amount = count == 0 ? 0 : _purchaseGrandTotal / count;
    final start = _purchaseDate;
    return List.generate(
      count,
      (index) => {
        'no_termin': index + 1,
        'amount': index == count - 1
            ? _purchaseGrandTotal - (amount * (count - 1))
            : amount,
        'due_date': _dateValue(
          DateTime(start.year, start.month + index + 1, start.day),
        ),
      },
    );
  }

  List<String> _purchaseUnits(Map<String, dynamic> item) {
    final units = <String>{
      (item['base_unit'] ?? item['unit'] ?? 'unit').toString(),
      if ((item['unit']?.toString() ?? '').isNotEmpty) item['unit'].toString(),
    };
    for (final row in (item['unit_conversions'] as List? ?? const [])) {
      if (row is Map && (row['unit']?.toString() ?? '').isNotEmpty) {
        units.add(row['unit'].toString());
      }
    }
    return units.toList();
  }

  Widget _purchaseDateField({
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onChanged,
    bool optional = false,
  }) => InkWell(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: value ?? DateTime.now(),
        firstDate: DateTime.now().subtract(const Duration(days: 730)),
        lastDate: DateTime.now().add(const Duration(days: 1825)),
      );
      if (picked != null && mounted) onChanged(picked);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_outlined),
        border: const OutlineInputBorder(),
      ),
      child: Text(
        value == null
            ? (optional ? 'Belum ditentukan' : '-')
            : _dateValue(value),
      ),
    ),
  );

  Widget _buildPurchaseSetupCard() {
    Widget responsive(List<Widget> fields, {double breakpoint = 720}) =>
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= breakpoint
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: fields[i]),
                    ],
                  ],
                )
              : Column(
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      fields[i],
                    ],
                  ],
                ),
        );

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE1E5E9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi pembelian',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            responsive([
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _supplierId.isEmpty ? null : _supplierId,
                decoration: const InputDecoration(
                  labelText: 'Supplier *',
                  prefixIcon: Icon(Icons.local_shipping_outlined),
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
                onChanged: (value) => setState(() {
                  _supplierId = value ?? '';
                  final supplier = (_lookups?.suppliers ?? const [])
                      .cast<Map?>()
                      .firstWhere(
                        (row) => row?['_id']?.toString() == _supplierId,
                        orElse: () => null,
                      );
                  _supplierIsPkp = supplier?['is_pkp'] == true;
                  _ppnPercent = _supplierIsPkp
                      ? (supplier?['default_ppn_persen'] as num?)?.toDouble() ??
                            0
                      : 0;
                  _ppnSource = _supplierIsPkp ? 'supplier' : 'none';
                }),
              ),
              _purchaseDateField(
                label: 'Tanggal pembelian *',
                value: _purchaseDate,
                onChanged: (value) => setState(() => _purchaseDate = value),
              ),
              _purchaseDateField(
                label: 'Tanggal pengiriman',
                value: _deliveryDate,
                optional: true,
                onChanged: (value) => setState(() => _deliveryDate = value),
              ),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _deliveryAddress,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Alamat pengiriman',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _deliveryAddress = value,
            ),
            const SizedBox(height: 18),
            Text(
              'Pembayaran dan prioritas',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            responsive([
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Metode pembayaran',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                  DropdownMenuItem(value: 'tunai', child: Text('Tunai')),
                  DropdownMenuItem(value: 'giro', child: Text('Giro')),
                ],
                onChanged: (value) =>
                    setState(() => _paymentMethod = value ?? 'transfer'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _paymentTerms,
                decoration: const InputDecoration(
                  labelText: 'Syarat pembayaran',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'tunai', child: Text('Langsung')),
                  DropdownMenuItem(value: 'kredit', child: Text('Kredit')),
                ],
                onChanged: (value) =>
                    setState(() => _paymentTerms = value ?? 'tunai'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Prioritas',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'low', child: Text('Rendah')),
                  DropdownMenuItem(value: 'urgent', child: Text('Mendesak')),
                ],
                onChanged: (value) =>
                    setState(() => _priority = value ?? 'normal'),
              ),
            ]),
            if (_paymentTerms == 'kredit') ...[
              const SizedBox(height: 12),
              responsive([
                DropdownButtonFormField<String>(
                  initialValue: _creditType,
                  decoration: const InputDecoration(
                    labelText: 'Tipe kredit',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'net30', child: Text('Net 30')),
                    DropdownMenuItem(value: 'net45', child: Text('Net 45')),
                    DropdownMenuItem(value: 'net60', child: Text('Net 60')),
                    DropdownMenuItem(value: 'net90', child: Text('Net 90')),
                    DropdownMenuItem(value: 'termin', child: Text('Termin')),
                  ],
                  onChanged: (value) => setState(() {
                    _creditType = value ?? 'net30';
                    _termDays = switch (_creditType) {
                      'net45' => 45,
                      'net60' => 60,
                      'net90' => 90,
                      _ => 30,
                    };
                    if (_creditType != 'termin') {
                      _dueDate = _purchaseDate.add(Duration(days: _termDays));
                    }
                  }),
                ),
                TextFormField(
                  key: ValueKey('credit-detail-$_creditType'),
                  initialValue:
                      (_creditType == 'termin' ? _installmentCount : _termDays)
                          .toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _creditType == 'termin'
                        ? 'Jumlah termin (2–12)'
                        : 'Jatuh tempo (hari)',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    if (_creditType == 'termin') {
                      _installmentCount = (int.tryParse(value) ?? 2).clamp(
                        2,
                        12,
                      );
                    } else {
                      _termDays = int.tryParse(value) ?? 0;
                    }
                  },
                ),
                _purchaseDateField(
                  label: 'Tanggal jatuh tempo',
                  value: _dueDate,
                  optional: true,
                  onChanged: (value) => setState(() => _dueDate = value),
                ),
              ]),
            ],
            const SizedBox(height: 18),
            Text(
              'Diskon, pajak, dan biaya',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            responsive([
              DropdownButtonFormField<String>(
                initialValue: _discountType,
                decoration: const InputDecoration(
                  labelText: 'Jenis diskon',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'persen', child: Text('Persen')),
                  DropdownMenuItem(value: 'fixed', child: Text('Nominal')),
                ],
                onChanged: (value) =>
                    setState(() => _discountType = value ?? 'persen'),
              ),
              TextFormField(
                initialValue: _numberText(
                  _discountType == 'fixed' ? _discountFixed : _discountPercent,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _discountType == 'fixed'
                      ? 'Diskon nominal'
                      : 'Diskon (%)',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() {
                  final parsed =
                      double.tryParse(value.replaceAll(',', '.')) ?? 0;
                  if (_discountType == 'fixed') {
                    _discountFixed = parsed;
                  } else {
                    _discountPercent = parsed.clamp(0, 100);
                  }
                }),
              ),
              TextFormField(
                initialValue: _numberText(_ppnPercent),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'PPN (%)',
                  helperText: _supplierIsPkp ? 'Supplier PKP' : 'Manual',
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() {
                  _ppnPercent =
                      (double.tryParse(value.replaceAll(',', '.')) ?? 0).clamp(
                        0,
                        100,
                      );
                  _ppnSource = _ppnPercent > 0 ? 'manual' : 'none';
                }),
              ),
              TextFormField(
                initialValue: _numberText(_shippingCost),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Biaya pengiriman',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setState(
                  () => _shippingCost =
                      double.tryParse(value.replaceAll(',', '.')) ?? 0,
                ),
              ),
            ], breakpoint: 900),
            const SizedBox(height: 12),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Komponen biaya tambahan',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(
                    () => _additionalCosts.add({
                      'jenis_biaya': 'ongkir',
                      'deskripsi': '',
                      'nominal': 0.0,
                    }),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah biaya'),
                ),
              ],
            ),
            ..._additionalCosts.asMap().entries.map((entry) {
              final row = entry.value;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue:
                            row['jenis_biaya']?.toString() ?? 'lainnya',
                        decoration: const InputDecoration(
                          labelText: 'Jenis biaya',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'ongkir',
                            child: Text('Ongkos kirim'),
                          ),
                          DropdownMenuItem(
                            value: 'handling',
                            child: Text('Handling'),
                          ),
                          DropdownMenuItem(
                            value: 'asuransi',
                            child: Text('Asuransi'),
                          ),
                          DropdownMenuItem(
                            value: 'bea_cukai',
                            child: Text('Bea cukai'),
                          ),
                          DropdownMenuItem(
                            value: 'lainnya',
                            child: Text('Lainnya'),
                          ),
                        ],
                        onChanged: (value) =>
                            row['jenis_biaya'] = value ?? 'lainnya',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: row['deskripsi']?.toString() ?? '',
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => row['deskripsi'] = value,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _numberText(row['nominal']),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Nominal',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(
                          () => row['nominal'] =
                              double.tryParse(value.replaceAll(',', '.')) ?? 0,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Hapus biaya',
                      onPressed: () =>
                          setState(() => _additionalCosts.removeAt(entry.key)),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            }),
            if (_additionalCosts.isNotEmpty) ...[
              const SizedBox(height: 12),
              responsive([
                DropdownButtonFormField<String>(
                  initialValue: _costMode,
                  decoration: const InputDecoration(
                    labelText: 'Perlakuan biaya',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'expense',
                      child: Text('Beban langsung'),
                    ),
                    DropdownMenuItem(
                      value: 'landed_cost',
                      child: Text('Tambahkan ke nilai persediaan'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _costMode = value ?? 'expense'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _costAllocation,
                  decoration: const InputDecoration(
                    labelText: 'Alokasi biaya',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'per_nilai',
                      child: Text('Berdasarkan nilai'),
                    ),
                    DropdownMenuItem(
                      value: 'per_qty',
                      child: Text('Berdasarkan jumlah'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _costAllocation = value ?? 'per_nilai'),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnitConversion(Map<String, dynamic> item) {
    final units = (item['available_units'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    final hasBatches = (item['batch_counts'] as List? ?? const []).isNotEmpty;
    if (units.length < 2 || hasBatches) return const SizedBox.shrink();
    final enabled = item['use_conversion'] == true;
    final baseUnit = item['base_unit']?.toString() ?? 'unit';
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => setState(() {
              item['use_conversion'] = !enabled;
              if (!enabled) {
                for (final row in units) {
                  row['input_qty'] = 0.0;
                }
                final base = units.cast<Map?>().firstWhere(
                  (row) => row?['unit']?.toString() == baseUnit,
                  orElse: () => null,
                );
                if (base != null) base['input_qty'] = item['input_qty'] ?? 0;
                _recalculateOpnameQuantity(item);
              }
            }),
            icon: Icon(enabled ? Icons.close : Icons.swap_horiz),
            label: Text(enabled ? 'Tutup konversi' : 'Hitung dengan konversi'),
          ),
        ),
        if (enabled)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Konversi satuan fisik',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Isi jumlah per kemasan. Sistem menghitung total dalam $baseUnit.',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 10),
                ...units.map((row) {
                  final factor = (row['factor'] as num?)?.toDouble() ?? 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextFormField(
                      initialValue: _numberText(row['input_qty']),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Jumlah ${row['unit']}',
                        helperText: factor == 1
                            ? 'Satuan dasar'
                            : '1 ${row['unit']} = ${_numberText(factor)} $baseUnit',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) => setState(() {
                        row['input_qty'] =
                            double.tryParse(value.replaceAll(',', '.')) ?? 0;
                        _recalculateOpnameQuantity(item);
                      }),
                    ),
                  );
                }),
                Text(
                  'Total fisik: ${_numberText(item['input_qty'])} $baseUnit',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOpnameSetupCard() {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE1E5E9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editing ? 'Informasi & lokasi opname' : 'Buat opname baru',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              _editing
                  ? 'Perbarui informasi dokumen dan hasil penghitungan stok.'
                  : 'Pilih lokasi yang akan dihitung. Saldo akan dipotret otomatis.',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 680;
                final date = InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _opnameDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null && mounted) {
                      setState(() => _opnameDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Tanggal opname *',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(_dateValue(_opnameDate)),
                  ),
                );
                final location = DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _sourceId.isEmpty ? null : _sourceId,
                  decoration: const InputDecoration(
                    labelText: 'Cabang / lokasi stok *',
                    prefixIcon: Icon(Icons.warehouse_outlined),
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
                  onChanged: _editing
                      ? null
                      : (value) {
                          final id = value ?? '';
                          setState(() {
                            _sourceId = id;
                            _buildingCode = '';
                            _roomCode = '';
                            _rackName = '';
                            _selected.clear();
                          });
                          if (id.isNotEmpty) _loadLocationItems(id);
                        },
                );
                final fields = [date, location];
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: fields[0]),
                          const SizedBox(width: 12),
                          Expanded(child: fields[1]),
                        ],
                      )
                    : Column(
                        children: [
                          fields[0],
                          const SizedBox(height: 12),
                          fields[1],
                        ],
                      );
              },
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final fields = <Widget>[
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _buildingCode.isEmpty ? null : _buildingCode,
                    decoration: const InputDecoration(
                      labelText: 'Gedung (opsional)',
                      border: OutlineInputBorder(),
                    ),
                    items: _buildings
                        .map(
                          (row) => DropdownMenuItem(
                            value: row['kode_gedung'].toString(),
                            child: Text(
                              '${row['kode_gedung']} - ${row['nama_gedung']}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _editing
                        ? null
                        : (value) => setState(() {
                            _buildingCode = value ?? '';
                            _roomCode = '';
                            _rackName = '';
                          }),
                  ),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _roomCode.isEmpty ? null : _roomCode,
                    decoration: const InputDecoration(
                      labelText: 'Ruangan (opsional)',
                      border: OutlineInputBorder(),
                    ),
                    items: _rooms
                        .map(
                          (row) => DropdownMenuItem(
                            value: row['kode_ruangan'].toString(),
                            child: Text(
                              '${row['kode_ruangan']} - ${row['nama_ruangan']}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _editing || _buildingCode.isEmpty
                        ? null
                        : (value) => setState(() {
                            _roomCode = value ?? '';
                            _rackName = '';
                          }),
                  ),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _rackName.isEmpty ? null : _rackName,
                    decoration: const InputDecoration(
                      labelText: 'Rak (opsional)',
                      border: OutlineInputBorder(),
                    ),
                    items: _racks
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: _editing || _roomCode.isEmpty
                        ? null
                        : (value) => setState(() => _rackName = value ?? ''),
                  ),
                ];
                if (constraints.maxWidth >= 760) {
                  return Row(
                    children: [
                      for (var index = 0; index < fields.length; index++) ...[
                        if (index > 0) const SizedBox(width: 12),
                        Expanded(child: fields[index]),
                      ],
                    ],
                  );
                }
                return Column(
                  children: [
                    for (var index = 0; index < fields.length; index++) ...[
                      if (index > 0) const SizedBox(height: 12),
                      fields[index],
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Tujuan / catatan opname',
                hintText: 'Contoh: opname bulanan atau audit gudang',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEDF4F8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD2E1EA)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF3E6F8E)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Saat dibuat, sistem otomatis mengambil snapshot seluruh saldo di lokasi terpilih. Buka kembali draft untuk mengisi hasil hitung fisik, konversi satuan, dan alasan selisih.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      backgroundColor: const Color(0xFFF7F8FA),
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
                      _buildPurchaseSetupCard(),
                    if (_usesLocation &&
                        widget.type != PosInventoryDocumentType.opname)
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
                    if (widget.type == PosInventoryDocumentType.opname)
                      _buildOpnameSetupCard(),
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
                        items: (_lookups?.scrapReasons ?? const [])
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option['value']?.toString(),
                                child: Text(option['label']?.toString() ?? ''),
                              ),
                            )
                            .toList(),
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
                        items: (_lookups?.scrapOccurrenceLocations ?? const [])
                            .map(
                              (option) => DropdownMenuItem<String>(
                                value: option['value']?.toString(),
                                child: Text(option['label']?.toString() ?? ''),
                              ),
                            )
                            .toList(),
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
                          color: AppColors.warning.withValues(alpha: .09),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Saldo belum berkurang saat draft dibuat. Stok dan jurnal kerugian baru diproses setelah dokumen disetujui.',
                        ),
                      ),
                    ],
                    if (!(widget.type == PosInventoryDocumentType.opname &&
                        !_editing)) ...[
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
                          else if (widget.type ==
                              PosInventoryDocumentType.scrap)
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
                          child: Center(
                            child: Text('Belum ada barang dipilih'),
                          ),
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
                                                      value.replaceAll(
                                                        ',',
                                                        '.',
                                                      ),
                                                    ) ??
                                                    0;
                                                item['input_qty'] =
                                                    (item['batch_counts']
                                                            as List)
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
                                  if (widget.type ==
                                      PosInventoryDocumentType.opname)
                                    _buildUnitConversion(item),
                                if (!(widget.type ==
                                        PosInventoryDocumentType.opname &&
                                    (item['batch_counts'] as List? ?? const [])
                                        .isNotEmpty))
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          readOnly:
                                              widget.type ==
                                                  PosInventoryDocumentType
                                                      .opname &&
                                              item['use_conversion'] == true,
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
                                          onChanged: (value) => setState(
                                            () => item['input_qty'] =
                                                double.tryParse(
                                                  value.replaceAll(',', '.'),
                                                ) ??
                                                0,
                                          ),
                                        ),
                                      ),
                                      if (widget.type ==
                                          PosInventoryDocumentType
                                              .purchase) ...[
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
                                            onChanged: (value) => setState(
                                              () => item['input_price'] =
                                                  double.tryParse(value) ?? 0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                if (widget.type ==
                                    PosInventoryDocumentType.purchase) ...[
                                  const SizedBox(height: 10),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final fields = <Widget>[
                                        DropdownButtonFormField<String>(
                                          isExpanded: true,
                                          initialValue:
                                              item['unit']?.toString() ??
                                              _purchaseUnits(item).first,
                                          decoration: const InputDecoration(
                                            labelText: 'Satuan pembelian',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: _purchaseUnits(item)
                                              .map(
                                                (unit) => DropdownMenuItem(
                                                  value: unit,
                                                  child: Text(unit),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (value) => setState(
                                            () =>
                                                item['unit'] = value ?? 'unit',
                                          ),
                                        ),
                                        DropdownButtonFormField<String>(
                                          initialValue:
                                              item['diskon_item_type']
                                                  ?.toString() ??
                                              'persen',
                                          decoration: const InputDecoration(
                                            labelText: 'Jenis diskon item',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'persen',
                                              child: Text('Persen'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'fixed',
                                              child: Text('Nominal'),
                                            ),
                                          ],
                                          onChanged: (value) => setState(
                                            () => item['diskon_item_type'] =
                                                value ?? 'persen',
                                          ),
                                        ),
                                        TextFormField(
                                          initialValue: _numberText(
                                            item['diskon_item'],
                                          ),
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          decoration: const InputDecoration(
                                            labelText: 'Diskon item',
                                            border: OutlineInputBorder(),
                                          ),
                                          onChanged: (value) => setState(
                                            () => item['diskon_item'] =
                                                double.tryParse(
                                                  value.replaceAll(',', '.'),
                                                ) ??
                                                0,
                                          ),
                                        ),
                                      ];
                                      return constraints.maxWidth >= 720
                                          ? Row(
                                              children: [
                                                for (
                                                  var i = 0;
                                                  i < fields.length;
                                                  i++
                                                ) ...[
                                                  if (i > 0)
                                                    const SizedBox(width: 10),
                                                  Expanded(child: fields[i]),
                                                ],
                                              ],
                                            )
                                          : Column(
                                              children: [
                                                for (
                                                  var i = 0;
                                                  i < fields.length;
                                                  i++
                                                ) ...[
                                                  if (i > 0)
                                                    const SizedBox(height: 10),
                                                  fields[i],
                                                ],
                                              ],
                                            );
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    initialValue:
                                        item['catatan_item']?.toString() ?? '',
                                    decoration: const InputDecoration(
                                      labelText: 'Catatan item',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (value) =>
                                        item['catatan_item'] = value,
                                  ),
                                ],
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
                                  if ((item['batch_options'] as List? ??
                                          const [])
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
                                              value: batch['no_batch']
                                                  .toString(),
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
                                              item['catatan_item']
                                                  ?.toString() ??
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
                    ],
                    const SizedBox(height: 12),
                    if (widget.type == PosInventoryDocumentType.purchase)
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Color(0xFFE1E5E9)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _PurchaseSummaryRow(
                                label: 'Subtotal',
                                value: _purchaseSubtotal,
                              ),
                              _PurchaseSummaryRow(
                                label: 'Diskon',
                                value: -_purchaseDiscount,
                              ),
                              _PurchaseSummaryRow(
                                label: 'PPN ($_ppnPercent%)',
                                value: _purchaseTax,
                              ),
                              _PurchaseSummaryRow(
                                label: _additionalCosts.isEmpty
                                    ? 'Biaya pengiriman'
                                    : 'Biaya tambahan',
                                value: _effectivePurchaseCost,
                              ),
                              const Divider(height: 20),
                              _PurchaseSummaryRow(
                                label: 'Grand total',
                                value: _purchaseGrandTotal,
                                emphasized: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (widget.type == PosInventoryDocumentType.purchase)
                      const SizedBox(height: 12),
                    if (widget.type != PosInventoryDocumentType.opname)
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
                        _editing
                            ? 'Simpan Perubahan'
                            : widget.type == PosInventoryDocumentType.opname
                            ? 'Buat Opname'
                            : 'Simpan Draft',
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

class _PurchaseSummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasized;
  const _PurchaseSummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          '${value < 0 ? '-' : ''}Rp ${_currency(value.abs())}',
          style: TextStyle(
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            fontSize: emphasized ? 17 : 14,
          ),
        ),
      ],
    ),
  );

  static String _currency(double value) {
    final digits = value.round().toString();
    return digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  }
}

String _title(PosInventoryDocumentType type) => switch (type) {
  PosInventoryDocumentType.purchase => 'Faktur Pembelian',
  PosInventoryDocumentType.opname => 'Stok Opname',
  PosInventoryDocumentType.transfer => 'Mutasi Stok',
  PosInventoryDocumentType.scrap => 'Stok Terbuang',
};
