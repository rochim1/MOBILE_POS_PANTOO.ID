import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../injections.dart';
import '../../../core/_core.dart';
import '../../../core/error/failures.dart';
import '../../../domain/repositories/pos_inventory_repository.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/inventory_action_style.dart';
import '../../widgets/skeleton_loading.dart';
import '../../bloc/pos/pos_bloc.dart';
import 'pos_barcode_scanner_page.dart';
import 'utils/pos_purchase_progress.dart';

class PosPurchaseReceivingPage extends StatefulWidget {
  final Map<String, dynamic> purchase;
  final bool embedded;
  final bool canReceive;
  final bool canViewPayable;
  final bool canRecordPayment;
  final bool canOverrideReceivingTolerance;
  final double overReceiptTolerancePercent;
  final bool canCancelReceiving;
  final VoidCallback? onFinished;
  final ValueChanged<Map<String, dynamic>>? onPayRequested;
  const PosPurchaseReceivingPage({
    super.key,
    required this.purchase,
    this.embedded = false,
    this.canReceive = true,
    this.canViewPayable = false,
    this.canRecordPayment = false,
    this.canOverrideReceivingTolerance = false,
    this.overReceiptTolerancePercent = 0,
    this.canCancelReceiving = false,
    this.onFinished,
    this.onPayRequested,
  });

  @override
  State<PosPurchaseReceivingPage> createState() =>
      _PosPurchaseReceivingPageState();
}

class _PosPurchaseReceivingPageState extends State<PosPurchaseReceivingPage> {
  final _repository = sl<PosInventoryRepository>();
  final _receivingRequestId = const Uuid().v4();
  Map<String, dynamic>? _pendingInput;
  bool _pendingPayloadUnreadable = false;
  String get _pendingKey {
    final prefs = sl<SharedPreferences>();
    return 'inventory.receiving.pending:${prefs.getString('instansi_id') ?? 'tenant'}:${prefs.getString('user_id') ?? 'user'}:${widget.purchase['_id']}';
  }

  String _payloadHash(Map<String, dynamic> payload) =>
      sha256.convert(utf8.encode(jsonEncode(payload))).toString();

  double _receivableRemaining(Map<String, dynamic> item) {
    final contractual =
        (item['remaining'] as num?)?.toDouble() ??
        PosPurchaseProgress.remainingInOrderedUnit(item);
    if (!widget.canOverrideReceivingTolerance ||
        widget.overReceiptTolerancePercent <= 0) {
      return contractual;
    }
    final ordered = (item['qty_ordered'] as num?)?.toDouble() ?? 0;
    final received = (item['qty_received'] as num?)?.toDouble() ?? 0;
    return (ordered * (1 + widget.overReceiptTolerancePercent / 100) - received)
        .clamp(0, double.infinity)
        .toDouble();
  }

  Future<void> _persistPending(
    Map<String, dynamic> payload, {
    required String status,
    String error = '',
  }) async {
    final prefs = sl<SharedPreferences>();
    final tenantId = prefs.getString('instansi_id')?.trim() ?? '';
    final userId = prefs.getString('user_id')?.trim() ?? '';
    if (tenantId.isEmpty || userId.isEmpty) {
      throw StateError('Identitas instansi atau pengguna tidak tersedia');
    }
    final saved = await prefs.setString(
      _pendingKey,
      jsonEncode({
        'version': 1,
        'operation_kind': 'purchase_receiving_draft',
        'status': status,
        'instansi_id': tenantId,
        'user_id': userId,
        'purchase_id': widget.purchase['_id'],
        'client_request_id': payload['client_request_id'],
        'payload_hash': _payloadHash(payload),
        'saved_at': DateTime.now().toUtc().toIso8601String(),
        if (error.isNotEmpty) 'last_error': error,
        'payload': payload,
      }),
    );
    if (!saved) throw StateError('Penyimpanan request ditolak perangkat');
  }

  final _deliveryNote = TextEditingController();
  final _notes = TextEditingController();
  PosInventoryLookups? _lookups;
  String _warehouseId = '';
  String _buildingCode = '';
  String _roomCode = '';
  String _rackName = '';
  late DateTime _receivingDate;
  bool _loading = true;
  List<Map<String, dynamic>> _history = const [];
  List<Map<String, dynamic>> _landedCosts = const [];
  late final List<Map<String, dynamic>> _items;

  Map<String, dynamic> get _inventoryPolicy => Map<String, dynamic>.from(
    context.read<PosBloc>().state.runtimeConfig['inventory_policy'] as Map? ??
        const {},
  );

  List<Map<String, dynamic>> get _receivingWarehouses {
    final policy = _inventoryPolicy;
    final defaultId = policy['default_receiving_location_id']?.toString() ?? '';
    final purchaseLocationId =
        widget.purchase['receiving_location_id']?.toString() ?? '';
    return (_lookups?.warehouses ?? const <Map<String, dynamic>>[])
        .where((item) => item['is_receiving_location'] != false)
        .where(
          (item) =>
              purchaseLocationId.isEmpty ||
              item['_id']?.toString() == purchaseLocationId,
        )
        .where(
          (item) =>
              policy['inventory_profile'] != 'simple' ||
              (defaultId.isNotEmpty && item['_id']?.toString() == defaultId),
        )
        .toList();
  }

  void _finish() {
    if (widget.embedded) {
      widget.onFinished?.call();
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  void initState() {
    super.initState();
    final saved = sl<SharedPreferences>().getString(_pendingKey);
    if (saved != null) {
      try {
        final envelope = Map<String, dynamic>.from(jsonDecode(saved) as Map);
        final payload = envelope['payload'] is Map
            ? Map<String, dynamic>.from(envelope['payload'] as Map)
            : <String, dynamic>{};
        final prefs = sl<SharedPreferences>();
        if (envelope['version'] == 1 &&
            envelope['operation_kind'] == 'purchase_receiving_draft' &&
            const {
              'pending_confirmation',
              'retry_required',
            }.contains(envelope['status']) &&
            envelope['instansi_id'] == prefs.getString('instansi_id') &&
            envelope['user_id'] == prefs.getString('user_id') &&
            envelope['payload_hash'] == _payloadHash(payload) &&
            payload['purchase_id']?.toString() ==
                widget.purchase['_id']?.toString() &&
            (payload['client_request_id']?.toString() ?? '').isNotEmpty) {
          _pendingInput = payload;
        } else {
          _pendingPayloadUnreadable = true;
        }
      } catch (_) {
        _pendingPayloadUnreadable = true;
      }
    }
    _receivingDate = DateTime.now();
    _items = (widget.purchase['items'] as List? ?? const [])
        .map((raw) {
          final item = Map<String, dynamic>.from(raw as Map);
          item['remaining'] = PosPurchaseProgress.remainingInOrderedUnit(item);
          // Penerimaan mengubah stok dan jurnal. Jangan mengasumsikan seluruh
          // sisa PO benar-benar datang; kasir harus memilih jumlahnya.
          item['receive_qty'] = 0.0;
          item['no_batch'] = '';
          item['tanggal_kadaluarsa'] = '';
          item['keterangan'] = '';
          return item;
        })
        .where((item) => (item['remaining'] as num) > 0)
        .toList();
    _load();
  }

  @override
  void dispose() {
    _deliveryNote.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _repository.getLookups();
    final historyResult = await _repository.getPurchaseReceivings(
      widget.purchase['_id']?.toString() ?? '',
    );
    final costResult = await _repository.getLandedCostsForPurchase(
      widget.purchase['_id']?.toString() ?? '',
    );
    if (!mounted) return;
    result.fold((failure) => AppToast.error(context, failure.message), (data) {
      _lookups = data;
      final receivingWarehouses = _receivingWarehouses;
      // Alamat pengiriman PO belum menyimpan ID lokasi stok. Jika beberapa
      // gudang tersedia, jangan diam-diam memakai lokasi shift/default:
      // penerimaan bisa tercatat di gudang yang berbeda dari tujuan PO.
      _warehouseId = receivingWarehouses.length == 1
          ? receivingWarehouses.first['_id']?.toString() ?? ''
          : '';
      if (receivingWarehouses.isEmpty) {
        AppToast.error(
          context,
          widget.purchase['receiving_location_id'] != null
              ? 'Tujuan stok pada PO tidak tersedia untuk penerimaan. Periksa lokasi PO dan pengaturan inventori.'
              : _inventoryPolicy['inventory_profile'] == 'simple'
              ? 'Atur lokasi penerimaan default pada profil Inventory Simple sebelum menerima PO.'
              : 'Belum ada warehouse yang diaktifkan untuk penerimaan pembelian.',
        );
      }
    });
    var historyLoaded = false;
    historyResult.fold(
      (failure) => AppToast.error(
        context,
        'Riwayat penerimaan gagal dimuat: ${failure.message}',
      ),
      (data) {
        _history = data;
        historyLoaded = true;
      },
    );
    // A rejected request aimed at a non-default location cannot become valid
    // after the Simple profile narrows receiving to its configured location.
    // Check server history first so a committed request is never discarded.
    final pending = _pendingInput;
    final defaultId =
        _inventoryPolicy['default_receiving_location_id']?.toString() ?? '';
    if (historyLoaded &&
        pending != null &&
        _inventoryPolicy['inventory_profile'] == 'simple' &&
        defaultId.isNotEmpty &&
        !_history.any(
          (row) =>
              row['client_request_id']?.toString() ==
              pending['client_request_id']?.toString(),
        )) {
      final pendingItems = pending['items'] as List? ?? const [];
      final wrongLocation = pendingItems.whereType<Map>().any((item) {
        final allocations = item['allocations'] as List? ?? const [];
        return allocations.whereType<Map>().any(
          (allocation) =>
              allocation['lokasi_cabang_id']?.toString() != defaultId,
        );
      });
      if (wrongLocation) {
        await sl<SharedPreferences>().remove(_pendingKey);
        _pendingInput = null;
        if (!mounted) return;
        AppToast.error(
          context,
          'Request lama memakai lokasi yang ditolak profil Simple. Isi ulang jumlah penerimaan pada lokasi default.',
        );
      }
    }
    costResult.fold((_) {}, (data) => _landedCosts = data);
    setState(() => _loading = false);
  }

  Map<String, dynamic>? _costForReceipt(Map<String, dynamic> receipt) {
    final id = receipt['_id']?.toString();
    for (final cost in _landedCosts) {
      if (cost['receiving_id']?.toString() == id &&
          cost['client_request_id']?.toString() == 'mobile-lc:$id' &&
          cost['status'] != 'cancelled') {
        return cost;
      }
    }
    return null;
  }

  Future<void> _validateCost(Map<String, dynamic> cost) async {
    final id = cost['_id']?.toString() ?? '';
    if (id.isEmpty) return;
    setState(() => _loading = true);
    final result = await _repository.validateLandedCost(id);
    if (!mounted) return;
    result.fold(
      (failure) => AppToast.error(
        context,
        'Draft biaya tersimpan, tetapi belum diterapkan: ${failure.message}. Periksa di Inventory > Landed Cost.',
      ),
      (_) => AppToast.success(
        context,
        'Biaya aktual berhasil diterapkan ke nilai barang',
      ),
    );
    final costs = await _repository.getLandedCostsForPurchase(
      widget.purchase['_id']?.toString() ?? '',
    );
    if (!mounted) return;
    costs.fold((_) {}, (rows) => _landedCosts = rows);
    setState(() => _loading = false);
  }

  Future<void> _recordActualCost(Map<String, dynamic> receipt) async {
    final existing = _costForReceipt(receipt);
    if (existing != null) {
      if (existing['status'] == 'draft') await _validateCost(existing);
      return;
    }
    setState(() => _loading = true);
    final accountResult = await _repository.getCashAccountsForLandedCost();
    if (!mounted) return;
    List<Map<String, dynamic>> cashAccounts = [];
    String? accountError;
    accountResult.fold(
      (failure) => accountError = failure.message,
      (rows) => cashAccounts = rows,
    );
    setState(() => _loading = false);
    if (accountError != null || cashAccounts.isEmpty) {
      AppToast.error(
        context,
        accountError ??
            'Belum ada akun kas/bank aktif. Siapkan di Finance terlebih dahulu.',
      );
      return;
    }
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final referenceController = TextEditingController();
    var kind = 'freight';
    var paymentAccountCode =
        cashAccounts.any((row) => row['account_code'] == '1006')
        ? '1006'
        : cashAccounts.first['account_code'].toString();
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(posLocale(context).pose8182cdba6ee((receipt['no_grn'] ?? '').toString())),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PosText(
                  'Hanya untuk ongkir/biaya yang dibayar terpisah. Jika ongkir ada dalam invoice supplier yang sama dengan barang, catat lewat Vendor Bill di Finance web untuk satu GRN yang ditagih penuh; jangan catat di sini agar utang tidak ganda.',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: kind,
                  decoration:  InputDecoration(labelText: ('Jenis biaya').tr(context)),
                  items: const [
                    DropdownMenuItem(value: 'freight', child: PosText('Ongkir')),
                    DropdownMenuItem(
                      value: 'handling',
                      child: PosText('Handling'),
                    ),
                    DropdownMenuItem(
                      value: 'insurance',
                      child: PosText('Asuransi'),
                    ),
                    DropdownMenuItem(
                      value: 'customs',
                      child: PosText('Bea masuk'),
                    ),
                    DropdownMenuItem(value: 'lainnya', child: PosText('Lainnya')),
                  ],
                  onChanged: (value) => update(() => kind = value ?? 'freight'),
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration:  InputDecoration(
                    labelText: ('Nominal aktual (Rp)').tr(context),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: paymentAccountCode,
                  isExpanded: true,
                  decoration:  InputDecoration(
                    labelText: ('Kas / bank pembayaran').tr(context),
                  ),
                  items: cashAccounts
                      .map(
                        (account) => DropdownMenuItem<String>(
                          value: account['account_code']?.toString() ?? '',
                          child: Text(
                            '${account['account_code']} · ${account['account_name']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => update(
                    () => paymentAccountCode = value ?? paymentAccountCode,
                  ),
                ),
                TextField(
                  controller: referenceController,
                  decoration:  InputDecoration(
                    labelText: ('Referensi pembayaran (opsional)').tr(context),
                  ),
                  maxLength: 120,
                ),
                TextField(
                  controller: noteController,
                  decoration:  InputDecoration(
                    labelText: ('Catatan (opsional)').tr(context),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const PosText('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final amount = int.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) {
                  AppToast.error(
                    context,
                    'Nominal biaya harus Rupiah bulat positif',
                  );
                  return;
                }
                Navigator.pop(dialogContext, {
                  'kind': kind,
                  'amount': amount,
                  'note': noteController.text.trim(),
                  'payment_account_code': paymentAccountCode,
                  'payment_reference': referenceController.text.trim(),
                });
              },
              child: const PosText('Simpan & Terapkan'),
            ),
          ],
        ),
      ),
    );
    amountController.dispose();
    noteController.dispose();
    referenceController.dispose();
    if (values == null || !mounted) return;
    setState(() => _loading = true);
    final result = await _repository.createLandedCost({
      'client_request_id': 'mobile-lc:${receipt['_id']}',
      'po_id': widget.purchase['_id'],
      'receiving_id': receipt['_id'],
      'tanggal': DateTime.now().toIso8601String().split('T').first,
      'syarat_pembayaran': 'tunai',
      'payment_account_code': values['payment_account_code'],
      'payment_reference': values['payment_reference'],
      'catatan': values['note'],
      'biaya': [
        {
          'nama_biaya': values['kind'] == 'freight' ? 'Ongkir' : values['kind'],
          'tipe_biaya': values['kind'],
          'jumlah': values['amount'],
          'metode_alokasi': 'by_value',
        },
      ],
    });
    if (!mounted) return;
    dynamic created;
    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (value) => created = value,
    );
    setState(() => _loading = false);
    if (created is Map) await _validateCost(Map<String, dynamic>.from(created));
  }

  Map<String, dynamic>? get _selectedWarehouse =>
      _lookups?.warehouses.cast<Map<String, dynamic>?>().firstWhere(
        (row) => row?['_id']?.toString() == _warehouseId,
        orElse: () => null,
      );

  List<Map<String, dynamic>> get _buildings =>
      (_selectedWarehouse?['gedung'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

  Map<String, dynamic>? get _selectedBuilding =>
      _buildings.cast<Map<String, dynamic>?>().firstWhere(
        (row) => row?['kode_gedung']?.toString() == _buildingCode,
        orElse: () => null,
      );

  List<Map<String, dynamic>> get _rooms =>
      (_selectedBuilding?['ruangan'] as List? ?? const [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

  Map<String, dynamic>? get _selectedRoom =>
      _rooms.cast<Map<String, dynamic>?>().firstWhere(
        (row) => row?['kode_ruangan']?.toString() == _roomCode,
        orElse: () => null,
      );

  List<String> get _racks => (_selectedRoom?['rak'] as List? ?? const [])
      .whereType<Map>()
      .map((row) => row['nama_rak']?.toString() ?? '')
      .where((value) => value.isNotEmpty)
      .toList();

  Future<void> _scanReceivingBarcode() async {
    if (_warehouseId.isEmpty) {
      AppToast.error(context, 'Pilih cabang penerimaan sebelum scan.');
      return;
    }
    final scanned = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PosBarcodeScannerPage()),
    );
    if (!mounted || scanned == null || scanned.trim().isEmpty) return;
    final code = scanned.trim().toLowerCase();
    final result = await _repository.findPurchaseInventoryByCode(
      scanned.trim(),
    );
    if (!mounted) return;
    final matches = result.fold<List<Map<String, dynamic>>>(
      (failure) {
        AppToast.error(context, failure.message);
        return const [];
      },
      (items) => items
          .where(
            (item) => [
              item['barcode'],
              item['sku'],
              item['kode_inventaris'],
            ].any((value) => value?.toString().trim().toLowerCase() == code),
          )
          .toList(),
    );
    if (matches.isEmpty) {
      AppToast.error(context, 'Kode produk tidak ditemukan.');
      return;
    }
    if (matches.length != 1) {
      AppToast.error(
        context,
        'Kode cocok dengan beberapa produk. Pilih manual.',
      );
      return;
    }
    final inventoryId = matches.single['_id']?.toString() ?? '';
    final poLines = _items
        .where((item) => item['inventaris_id']?.toString() == inventoryId)
        .toList();
    if (poLines.isEmpty) {
      AppToast.error(context, 'Produk ini tidak ada pada sisa PO.');
      return;
    }
    Map<String, dynamic>? item;
    if (poLines.length == 1) {
      item = poLines.single;
    } else {
      item = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const PosText('Pilih baris PO'),
          children: poLines
              .map(
                (line) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, line),
                  child: Text(
                    posLocale(dialogContext).pos2f893bcc6344((line['nama_inventaris']).toString(), (line['remaining']).toString(), (line['unit'] ?? '').toString()),
                  ),
                ),
              )
              .toList(),
        ),
      );
    }
    if (!mounted || item == null) return;
    final selectedItem = item;
    final controller = TextEditingController(
      text: (selectedItem['receive_qty'] ?? 0).toString(),
    );
    final formKey = GlobalKey<FormState>();
    final remaining = _receivableRemaining(selectedItem);
    final quantity = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(selectedItem['nama_inventaris']?.toString() ?? ('Barang PO').tr(dialogContext)),
        content: Form(
          key: formKey,
          child: TextFormField(
errorBuilder: posValidationError,
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: posLocale(dialogContext).pos4c2897c3151f((selectedItem['unit'] ?? '').toString()),
              helperText: posLocale(dialogContext).pos9475d97d7968((selectedItem['remaining']).toString()),
              border: const OutlineInputBorder(),
            ),
            validator: (raw) {
              final qty = double.tryParse((raw ?? '').replaceAll(',', '.'));
              return qty == null || !qty.isFinite || qty < 0 || qty > remaining
                  ? posLocale(dialogContext).posd06dba4cee38((remaining).toString())
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const PosText('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(
                  dialogContext,
                  double.parse(controller.text.replaceAll(',', '.')),
                );
              }
            },
            child: const PosText('Terapkan'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(kThemeAnimationDuration);
    controller.dispose();
    if (!mounted || quantity == null) return;
    if (!quantity.isFinite || quantity < 0 || quantity > remaining) {
      AppToast.error(
        context,
        'Jumlah harus 0 sampai $remaining ${selectedItem['unit'] ?? ''}.',
      );
      return;
    }
    setState(() => selectedItem['receive_qty'] = quantity);
    AppToast.success(
      context,
      'Jumlah diterima diperbarui. Periksa batch dan lokasi sebelum simpan.',
    );
  }

  Future<void> _save() async {
    if (!widget.canReceive) return;
    if (_pendingPayloadUnreadable) {
      AppToast.error(
        context,
        'Request penerimaan sebelumnya tidak dapat dibaca. Periksa riwayat GRN dan hubungi admin sebelum menerima ulang.',
      );
      return;
    }
    if (_pendingInput != null) {
      final retry = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const PosText('Ulangi penerimaan sebelumnya?'),
          content: const PosText(
            'Permintaan terakhir belum dikonfirmasi. Data jumlah dan lokasi yang tersimpan akan dikirim ulang; perubahan form saat ini tidak ikut dikirim.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const PosText('Periksa Riwayat'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const PosText('Ulangi Request'),
            ),
          ],
        ),
      );
      if (retry == true && mounted) await _retryPendingReceiving();
      return;
    }
    final warehouse = _receivingWarehouses
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (item) => item?['_id']?.toString() == _warehouseId,
          orElse: () => null,
        );
    final invalid = _items.cast<Map<String, dynamic>?>().firstWhere((item) {
      final qty = (item?['receive_qty'] as num? ?? 0).toDouble();
      return !qty.isFinite ||
          qty < 0 ||
          qty - _receivableRemaining(item!) > 0.000001;
    }, orElse: () => null);
    if (invalid != null) {
      AppToast.error(
        context,
        'Jumlah ${invalid['nama_inventaris']} maksimal ${_receivableRemaining(invalid)} ${invalid['unit'] ?? ''}',
      );
      return;
    }
    final selected = _items
        .where((item) => (item['receive_qty'] as num? ?? 0) > 0)
        .toList();
    if (warehouse == null || selected.isEmpty) {
      AppToast.error(context, 'Pilih lokasi dan isi jumlah penerimaan');
      return;
    }
    for (final item in selected) {
      final batch = item['no_batch']?.toString().trim() ?? '';
      final expiry = item['tanggal_kadaluarsa']?.toString().trim() ?? '';
      final serial = item['keterangan']?.toString().trim() ?? '';
      final itemName = item['nama_inventaris']?.toString() ?? 'barang';
      if (item['wajib_batch_number'] == true &&
          (batch.isEmpty || expiry.isEmpty)) {
        AppToast.error(
          context,
          'Nomor batch dan tanggal kedaluwarsa $itemName wajib diisi',
        );
        return;
      }
      if (batch.isEmpty != expiry.isEmpty) {
        AppToast.error(
          context,
          'Nomor batch dan tanggal kedaluwarsa $itemName harus diisi bersamaan',
        );
        return;
      }
      final expiryDate = DateTime.tryParse(expiry);
      if (expiry.isNotEmpty && expiryDate == null) {
        AppToast.error(context, 'Tanggal kedaluwarsa $itemName tidak valid');
        return;
      }
      if (expiryDate != null &&
          expiryDate.isBefore(
            DateTime(
              _receivingDate.year,
              _receivingDate.month,
              _receivingDate.day,
            ),
          )) {
        AppToast.error(
          context,
          'Tanggal kedaluwarsa $itemName tidak boleh sebelum tanggal penerimaan',
        );
        return;
      }
      if (item['wajib_serial_number'] == true && serial.isEmpty) {
        AppToast.error(context, 'Serial number $itemName wajib diisi');
        return;
      }
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const PosText('Konfirmasi penerimaan'),
        content: Text(
          posLocale(dialogContext).posb77962af8721((selected.length).toString(), (warehouse['nama_cabang'] ?? 'lokasi terpilih').toString(), (selected.map((item) => '${item['nama_inventaris']}: ${item['receive_qty']} ${item['unit'] ?? ''}').join('\n')).toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const PosText('Periksa Lagi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const PosText('Ya, Terima Barang'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final input = <String, dynamic>{
      'client_request_id': _receivingRequestId,
      'purchase_id': widget.purchase['_id'],
      'tanggal_terima': _receivingDate.toIso8601String().split('T').first,
      'no_surat_jalan': _deliveryNote.text.trim(),
      'catatan': _notes.text.trim(),
      'items': selected.map((item) {
        final qty = item['receive_qty'];
        return {
          'purchase_item_id': item['_id'],
          'inventaris_id': item['inventaris_id'],
          if ((item['kategori']?.toString() ?? '').isNotEmpty)
            'kategori': item['kategori'],
          'nama_inventaris': item['nama_inventaris'],
          'qty_received': qty,
          if ((item['no_batch']?.toString() ?? '').isNotEmpty)
            'no_batch': item['no_batch'],
          if ((item['tanggal_kadaluarsa']?.toString() ?? '').isNotEmpty)
            'tanggal_kadaluarsa': item['tanggal_kadaluarsa'],
          'keterangan': (item['keterangan']?.toString() ?? '').trim().isEmpty
              ? 'Penerimaan dari supplier'
              : item['keterangan'],
          'allocations': [
            {
              'lokasi_cabang_id': warehouse['_id'],
              'lokasi_cabang_nama': warehouse['nama_cabang'],
              'lokasi_gedung_kode': _buildingCode,
              'lokasi_gedung_nama': _selectedBuilding?['nama_gedung'] ?? '',
              'lokasi_ruangan_kode': _roomCode,
              'lokasi_ruangan_nama': _selectedRoom?['nama_ruangan'] ?? '',
              'lokasi_rak_nama': _rackName,
              'qty': qty,
            },
          ],
        };
      }).toList(),
    };
    try {
      await _persistPending(input, status: 'pending_confirmation');
      _pendingInput = input;
    } catch (error) {
      if (mounted) {
        AppToast.error(
          context,
          'Request belum dikirim karena gagal disimpan di perangkat: $error',
        );
      }
      return;
    }
    await _sendReceiving(input);
  }

  Future<void> _retryPendingReceiving() async {
    final input = _pendingInput;
    if (input == null) return;
    setState(() => _loading = true);
    final historyResult = await _repository.getPurchaseReceivings(
      widget.purchase['_id']?.toString() ?? '',
    );
    if (!mounted) return;
    var historyFailed = false;
    final history = historyResult.fold<List<Map<String, dynamic>>>((failure) {
      historyFailed = true;
      AppToast.error(
        context,
        'Riwayat GRN belum dapat diperbarui: ${failure.message}',
      );
      return const [];
    }, (rows) => rows);
    if (historyFailed) {
      setState(() => _loading = false);
      return;
    }
    if (history.any(
      (row) =>
          row['client_request_id']?.toString() ==
          input['client_request_id']?.toString(),
    )) {
      await sl<SharedPreferences>().remove(_pendingKey);
      if (!mounted) return;
      _pendingInput = null;
      setState(() {
        _history = history;
        _loading = false;
      });
      AppToast.success(
        context,
        'Penerimaan sebelumnya sudah tercatat; request tidak dikirim ulang.',
      );
      return;
    }
    final purchaseResult = await _repository.getPurchaseForPrint(
      widget.purchase['_id']?.toString() ?? '',
    );
    if (!mounted) return;
    final current = purchaseResult.fold<Map<String, dynamic>?>((failure) {
      AppToast.error(context, 'PO belum dapat diperbarui: ${failure.message}');
      return null;
    }, (value) => value);
    if (current == null) {
      setState(() => _loading = false);
      return;
    }
    if (!const {
      'approved',
      'partially_received',
      'completed',
    }.contains(current['status'])) {
      setState(() => _loading = false);
      AppToast.error(
        context,
        'PO sudah tidak dapat menerima barang. Periksa status terbaru sebelum membuat request baru.',
      );
      return;
    }
    final currentItems = {
      for (final raw
          in (current['items'] as List? ?? const []).whereType<Map>())
        raw['_id']?.toString() ?? '': Map<String, dynamic>.from(raw),
    };
    final stale = (input['items'] as List? ?? const []).whereType<Map>().any((
      row,
    ) {
      final currentRow =
          currentItems[row['purchase_item_id']?.toString() ?? ''];
      final requested = (row['qty_received'] as num?)?.toDouble() ?? 0;
      return currentRow == null ||
          requested - _receivableRemaining(currentRow) > 0.000001;
    });
    if (stale) {
      setState(() {
        _history = history;
        _loading = false;
      });
      AppToast.error(
        context,
        'Sisa PO berubah sejak request disimpan. Request lama tidak dikirim; periksa riwayat lalu buat penerimaan baru.',
      );
      return;
    }
    setState(() => _history = history);
    await _sendReceiving(input);
  }

  Future<void> _sendReceiving(Map<String, dynamic> input) async {
    if (!widget.canReceive) return;
    setState(() => _loading = true);
    final result = await _repository.receivePurchase(input);
    if (!mounted) return;
    var succeeded = false;
    var rejectedByPolicy = false;
    dynamic receipt;
    String failureMessage = '';
    result.fold(
      (failure) {
        failureMessage = failure.message;
        rejectedByPolicy =
            failure is InventoryRequestRejectedFailure ||
            failure.message.contains(
              'Profil Inventory Simple hanya menerima stok pada lokasi default',
            ) ||
            failure.message.contains(
              'Lokasi penerimaan berbeda dari tujuan stok yang tercatat pada PO',
            );
        AppToast.error(context, failure.message);
        setState(() => _loading = false);
      },
      (value) {
        succeeded = true;
        receipt = value;
      },
    );
    if (!succeeded) {
      if (rejectedByPolicy) {
        await sl<SharedPreferences>().remove(_pendingKey);
        _pendingInput = null;
        return;
      }
      try {
        await _persistPending(
          input,
          status: 'retry_required',
          error: failureMessage,
        );
      } catch (_) {
        // Draft awal sudah tersimpan. Jangan menghapusnya bila pembaruan
        // metadata retry gagal ditulis perangkat.
      }
      return;
    }
    await sl<SharedPreferences>().remove(_pendingKey);
    _pendingInput = null;
    if (!mounted) return;
    if (receipt is Map && receipt['journal_status'] == 'failed') {
      AppToast.error(
        context,
        'Stok sudah diterima, tetapi jurnal perlu diperiksa: ${receipt['journal_error'] ?? ''}',
      );
    } else {
      AppToast.success(context, 'Penerimaan pembelian berhasil dicatat');
    }
    // Receiving posts stock and GRNI only. Supplier invoices and payments are
    // verified separately by Finance; never imply that a receipt creates AP.
    if (receipt is Map && receipt['status'] == 'active') {
      final recordCost = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const PosText('Ada ongkir atau biaya aktual?'),
          content: const PosText(
            'Jika dibayar terpisah, catat sekarang agar biaya masuk nilai barang. Estimasi di PO tidak otomatis dibebankan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const PosText('Nanti'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const PosText('Catat biaya'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (recordCost == true) {
        await _recordActualCost(Map<String, dynamic>.from(receipt));
      }
      if (!mounted) return;
    }
    _finish();
  }

  String _shortDate(dynamic value) {
    final raw = value?.toString() ?? '';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw.isEmpty ? '-' : raw;
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  Future<void> _cancelReceiving(Map<String, dynamic> receipt) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(posLocale(dialogContext).pos345a2afe9fe7((receipt['no_grn'] ?? 'penerimaan').toString())),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration:  InputDecoration(
            labelText: ('Alasan pembatalan *').tr(dialogContext),
            hintText: ('Contoh: jumlah atau lokasi penerimaan keliru').tr(dialogContext),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const PosText('Kembali'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const PosText('Batalkan Penerimaan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (reason == null || !mounted) return;
    setState(() => _loading = true);
    final result = await _repository.cancelPurchaseReceiving(
      receivingId: receipt['_id']?.toString() ?? '',
      reason: reason,
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        AppToast.error(context, failure.message);
        setState(() => _loading = false);
      },
      (cancelled) {
        if (cancelled is Map &&
            cancelled['cancel_journal_status'] == 'failed') {
          AppToast.error(
            context,
            'Stok dikembalikan, tetapi jurnal pembatalan gagal: ${cancelled['cancel_journal_error'] ?? ''}',
          );
        } else {
          AppToast.success(context, 'Penerimaan berhasil dibatalkan');
        }
        // Snapshot PO yang dibawa halaman ini sudah berubah. Kembali ke daftar
        // agar PO dan sisa kuantitas dimuat ulang dari server.
        _finish();
      },
    );
  }

  Future<void> _retryReceivingJournal(Map<String, dynamic> receipt) async {
    setState(() => _loading = true);
    final result = await _repository.retryReceivingJournal(
      receipt['_id'].toString(),
    );
    if (!mounted) return;
    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (updated) =>
          updated is Map &&
              ['posted', 'not_required'].contains(updated['journal_status'])
          ? AppToast.success(context, 'Jurnal penerimaan berhasil diperbarui')
          : AppToast.error(
              context,
              'Jurnal belum selesai: ${updated is Map ? updated['journal_error'] ?? '' : ''}',
            ),
    );
    await _load();
  }

  Future<void> _retryReceivingCancelJournal(
    Map<String, dynamic> receipt,
  ) async {
    setState(() => _loading = true);
    final result = await _repository.retryReceivingCancelJournal(
      receipt['_id'].toString(),
    );
    if (!mounted) return;
    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (updated) =>
          updated is Map &&
              [
                'posted',
                'not_required',
              ].contains(updated['cancel_journal_status'])
          ? AppToast.success(context, 'Jurnal pembatalan berhasil diperbarui')
          : AppToast.error(
              context,
              'Jurnal pembatalan belum selesai: ${updated is Map ? updated['cancel_journal_error'] ?? '' : ''}',
            ),
    );
    await _load();
  }

  Widget _buildHistory() {
    if (_history.isEmpty) return const SizedBox.shrink();
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.history),
        title: Text(posLocale(context).pos78bff8e79d25((_history.length).toString())),
        subtitle: const PosText('Penerimaan parsial yang sudah dicatat'),
        children: _history.map((receipt) {
          final lines = (receipt['items'] as List? ?? const [])
              .whereType<Map>()
              .map((item) {
                final batch = item['no_batch']?.toString() ?? '';
                return '${item['nama_inventaris'] ?? '-'} · ${item['qty_received'] ?? 0} ${item['unit'] ?? ''}'
                    '${batch.isEmpty ? '' : ' · Batch $batch'}';
              })
              .join('\n');
          final cancelled = receipt['status']?.toString() == 'cancelled';
          final actualCost = _costForReceipt(
            Map<String, dynamic>.from(receipt),
          );
          return ListTile(
            title: Text(receipt['no_grn']?.toString() ?? ('Penerimaan').tr(context)),
            subtitle: Text(
              '${_shortDate(receipt['tanggal_terima'])}'
              '${(receipt['no_surat_jalan']?.toString() ?? '').isEmpty ? '' : (' · SJ ${receipt['no_surat_jalan']}').tr(context)}\n$lines'
              '${receipt['journal_status'] == 'failed'
                  ? ('\nJurnal asal gagal: ${receipt['journal_error'] ?? ''}').tr(context)
                  : receipt['journal_status'] == 'pending'
                  ? ('\nJurnal asal belum terkonfirmasi').tr(context)
                  : ''}'
              '${actualCost == null ? '' : ('\nBiaya aktual: ${actualCost['status'] == 'validated' ? 'diterapkan'.tr(context) : 'draft menunggu validasi'.tr(context)}').tr(context)}'
              '${receipt['cancel_journal_status'] == 'failed'
                  ? ('\nJurnal pembatalan gagal: ${receipt['cancel_journal_error'] ?? ''}').tr(context)
                  : cancelled && receipt['cancel_journal_status'] == 'pending'
                  ? ('\nJurnal pembatalan belum terkonfirmasi').tr(context)
                  : ''}',
            ),
            isThreeLine: true,
            trailing:
                cancelled &&
                    ![
                      'failed',
                      'pending',
                    ].contains(receipt['journal_status']) &&
                    ![
                      'failed',
                      'pending',
                    ].contains(receipt['cancel_journal_status'])
                ? const Chip(label: PosText('Dibatalkan'))
                : PopupMenuButton<String>(
                    enabled: !_loading,
                    tooltip: ('Aksi penerimaan').tr(context),
                    onSelected: (action) => switch (action) {
                      'cost' => _recordActualCost(
                        Map<String, dynamic>.from(receipt),
                      ),
                      'retry_journal' => _retryReceivingJournal(receipt),
                      'retry_cancel_journal' => _retryReceivingCancelJournal(
                        receipt,
                      ),
                      _ => _cancelReceiving(receipt),
                    },
                    itemBuilder: (_) => [
                      if (!cancelled && actualCost?['status'] != 'validated')
                        PopupMenuItem(
                          value: 'cost',
                          child: Text(
                            actualCost == null
                                ? ('Catat ongkir/biaya aktual').tr(context)
                                : ('Terapkan draft biaya').tr(context),
                          ),
                        ),
                      if ([
                        'failed',
                        'pending',
                      ].contains(receipt['journal_status']))
                        const PopupMenuItem(
                          value: 'retry_journal',
                          child: PosText('Ulangi Jurnal'),
                        ),
                      if (cancelled &&
                          [
                            'failed',
                            'pending',
                          ].contains(receipt['cancel_journal_status']))
                        const PopupMenuItem(
                          value: 'retry_cancel_journal',
                          child: PosText('Ulangi Jurnal Pembatalan'),
                        ),
                      if (!cancelled && widget.canCancelReceiving)
                        const PopupMenuItem(
                          value: 'cancel',
                          child: PosText('Batalkan Penerimaan'),
                        ),
                    ],
                  ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAdvancedReceivingFields() => Column(
    children: [
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _receivingDate,
            firstDate: DateTime.now().subtract(const Duration(days: 365)),
            lastDate: DateTime.now(),
          );
          if (picked != null && mounted) {
            setState(() => _receivingDate = picked);
          }
        },
        child: InputDecorator(
          decoration:  InputDecoration(
            labelText: ('Tanggal penerimaan').tr(context),
            prefixIcon: Icon(Icons.calendar_today_outlined),
            border: OutlineInputBorder(),
          ),
          child: Text(_receivingDate.toIso8601String().split('T').first),
        ),
      ),
      const SizedBox(height: 10),
      LayoutBuilder(
        builder: (context, constraints) {
          final fields = <Widget>[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _buildingCode.isEmpty ? null : _buildingCode,
              decoration:  InputDecoration(
                labelText: ('Gedung (opsional)').tr(context),
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
              onChanged: (value) => setState(() {
                _buildingCode = value ?? '';
                _roomCode = '';
                _rackName = '';
              }),
            ),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _roomCode.isEmpty ? null : _roomCode,
              decoration:  InputDecoration(
                labelText: ('Ruangan (opsional)').tr(context),
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
              onChanged: _buildingCode.isEmpty
                  ? null
                  : (value) => setState(() {
                      _roomCode = value ?? '';
                      _rackName = '';
                    }),
            ),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _rackName.isEmpty ? null : _rackName,
              decoration:  InputDecoration(
                labelText: ('Rak (opsional)').tr(context),
                border: OutlineInputBorder(),
              ),
              items: _racks
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: _roomCode.isEmpty
                  ? null
                  : (value) => setState(() => _rackName = value ?? ''),
            ),
          ];
          return constraints.maxWidth >= 720
              ? Row(
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(child: fields[i]),
                    ],
                  ],
                )
              : Column(
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      fields[i],
                    ],
                  ],
                );
        },
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _deliveryNote,
        decoration:  InputDecoration(
          labelText: ('Nomor surat jalan (opsional)').tr(context),
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _notes,
        maxLines: 2,
        decoration:  InputDecoration(
          labelText: ('Catatan penerimaan (opsional)').tr(context),
          border: OutlineInputBorder(),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final body = _loading && _lookups == null
        ? const _ReceivingFormSkeleton()
        : Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_pendingPayloadUnreadable)
                    const Card(
                      color: Color(0xFFFFEBEE),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: PosText(
                          'Request penerimaan sebelumnya di perangkat tidak dapat dibaca. Penerimaan baru diblokir untuk mencegah stok ganda. Periksa riwayat GRN dan hubungi admin inventori.',
                        ),
                      ),
                    ),
                  Card(
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
                          const PosText(
                            'Informasi penerimaan',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: _warehouseId.isEmpty
                                ? null
                                : _warehouseId,
                            decoration:  InputDecoration(
                              labelText: ('Cabang penerimaan *').tr(context),
                              prefixIcon: Icon(Icons.warehouse_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: _receivingWarehouses
                                .where(
                                  (item) =>
                                      item['is_receiving_location'] != false,
                                )
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item['_id'].toString(),
                                    child: Text(item['nama_cabang'].toString()),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(() {
                              _warehouseId = value ?? '';
                              _buildingCode = '';
                              _roomCode = '';
                              _rackName = '';
                            }),
                          ),
                          const SizedBox(height: 12),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: const EdgeInsets.only(bottom: 4),
                            leading: const Icon(Icons.tune),
                            title: const PosText('Detail tambahan'),
                            subtitle: const PosText(
                              'Tanggal, surat jalan, gedung, ruangan, rak, dan catatan',
                            ),
                            children: [_buildAdvancedReceivingFields()],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildHistory(),
                  if (_history.isNotEmpty) const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const PosText(
                      'Penerimaan parsial didukung. Isi hanya jumlah yang datang sekarang; sisanya tetap dapat diterima pada penerimaan berikutnya.',
                      style: TextStyle(height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: PosText(
                          'Barang diterima',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: ('Scan barcode barang PO').tr(context),
                        onPressed: _items.isEmpty
                            ? null
                            : _scanReceivingBarcode,
                        icon: const Icon(Icons.qr_code_scanner),
                      ),
                      TextButton.icon(
                        onPressed: _items.isEmpty
                            ? null
                            : () => setState(() {
                                for (final item in _items) {
                                  item['receive_qty'] = _receivableRemaining(
                                    item,
                                  );
                                }
                              }),
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const PosText('Terima Semua'),
                      ),
                    ],
                  ),
                  ..._items.map(
                    (item) => Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['nama_inventaris']?.toString() ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              posLocale(context).posfc674fc6d98d((item['qty_ordered'] ?? 0).toString(), (item['qty_received'] ?? 0).toString(), (item['remaining']).toString(), (item['unit'] ?? '').toString()),
                            ),
                            if (_receivableRemaining(item) >
                                (item['remaining'] as num).toDouble())
                              Text(
                                posLocale(context).poscd4516ba1708((widget.overReceiptTolerancePercent.toStringAsFixed(2)).toString(), (_receivableRemaining(item)).toString(), (item['unit'] ?? '').toString()),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.warning,
                                ),
                              ),
                            if ((item['conversion_factor'] as num? ?? 1) != 1)
                              Text(
                                posLocale(context).posa006c9daadf0((item['unit'] ?? '').toString(), (item['conversion_factor']).toString(), (item['base_unit'] ?? '').toString()),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            const SizedBox(height: 8),
                            TextFormField(
errorBuilder: posValidationError,
                              key: ValueKey(
                                '${item['_id']}-${item['receive_qty']}',
                              ),
                              initialValue: item['receive_qty'].toString(),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration:  InputDecoration(
                                labelText: ('Diterima sekarang').tr(context),
                                helperText:
                                    ('Boleh kurang dari sisa untuk pengiriman parsial').tr(context),
                                border: OutlineInputBorder(),
                              ),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (raw) {
                                if ((raw ?? '').trim().isEmpty) return null;
                                final qty = double.tryParse(
                                  raw!.replaceAll(',', '.'),
                                );
                                final remaining = _receivableRemaining(item);
                                return qty == null ||
                                        !qty.isFinite ||
                                        qty < 0 ||
                                        qty > remaining
                                    ? posLocale(context).posd06dba4cee38((remaining).toString())
                                    : null;
                              },
                              onChanged: (value) {
                                final raw = value.trim();
                                final parsed = raw.isEmpty
                                    ? 0.0
                                    : double.tryParse(raw.replaceAll(',', '.'));
                                item['receive_qty'] =
                                    parsed != null && parsed.isFinite
                                    ? parsed
                                    : double.nan;
                              },
                            ),
                            ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              initiallyExpanded:
                                  item['wajib_batch_number'] == true ||
                                  item['wajib_serial_number'] == true,
                              leading: const Icon(Icons.qr_code_2),
                              title: Text(
                                item['wajib_batch_number'] == true ||
                                        item['wajib_serial_number'] == true
                                    ? ('Data pelacakan wajib').tr(context)
                                    : ('Batch, kedaluwarsa & keterangan').tr(context),
                              ),
                              subtitle: Text(
                                item['wajib_batch_number'] == true ||
                                        item['wajib_serial_number'] == true
                                    ? ('Lengkapi sebelum menyimpan').tr(context)
                                    : ('Opsional untuk barang ini').tr(context),
                              ),
                              children: [
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final fields = <Widget>[
                                      TextFormField(
                                        initialValue: item['no_batch']
                                            ?.toString(),
                                        decoration: InputDecoration(
                                          labelText:
                                              item['wajib_batch_number'] == true
                                              ? ('Nomor batch *').tr(context)
                                              : ('Nomor batch (opsional)').tr(context),
                                          border: const OutlineInputBorder(),
                                        ),
                                        onChanged: (value) =>
                                            item['no_batch'] = value.trim(),
                                      ),
                                      InkWell(
                                        onTap: () async {
                                          final current = DateTime.tryParse(
                                            item['tanggal_kadaluarsa']
                                                    ?.toString() ??
                                                '',
                                          );
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate:
                                                current ??
                                                _receivingDate.add(
                                                  const Duration(days: 30),
                                                ),
                                            firstDate: DateTime(
                                              _receivingDate.year,
                                              _receivingDate.month,
                                              _receivingDate.day,
                                            ),
                                            lastDate: DateTime(2200),
                                          );
                                          if (picked != null && mounted) {
                                            setState(() {
                                              item['tanggal_kadaluarsa'] =
                                                  picked
                                                      .toIso8601String()
                                                      .split('T')
                                                      .first;
                                            });
                                          }
                                        },
                                        child: InputDecorator(
                                          decoration: InputDecoration(
                                            labelText:
                                                item['wajib_batch_number'] ==
                                                    true
                                                ? ('Tanggal kedaluwarsa *').tr(context)
                                                : ('Tanggal kedaluwarsa (opsional)').tr(context),
                                            border: const OutlineInputBorder(),
                                            suffixIcon: const Icon(
                                              Icons.calendar_today_outlined,
                                            ),
                                          ),
                                          child: Text(
                                            (item['tanggal_kadaluarsa']
                                                            ?.toString() ??
                                                        '')
                                                    .isEmpty
                                                ? ('Pilih tanggal').tr(context)
                                                : _shortDate(
                                                    item['tanggal_kadaluarsa'],
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ];
                                    return constraints.maxWidth >= 620
                                        ? Row(
                                            children: [
                                              Expanded(child: fields[0]),
                                              const SizedBox(width: 10),
                                              Expanded(child: fields[1]),
                                            ],
                                          )
                                        : Column(
                                            children: [
                                              fields[0],
                                              const SizedBox(height: 10),
                                              fields[1],
                                            ],
                                          );
                                  },
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  initialValue: item['keterangan']?.toString(),
                                  decoration: InputDecoration(
                                    labelText:
                                        item['wajib_serial_number'] == true
                                        ? ('Serial number *').tr(context)
                                        : ('Keterangan (opsional)').tr(context),
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (value) =>
                                      item['keterangan'] = value,
                                ),
                                const SizedBox(height: 4),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: !widget.canReceive || _loading || _items.isEmpty
                        ? null
                        : _save,
                    style: InventoryActionStyle.primary(),
                    icon: const Icon(Icons.inventory, size: 18),
                    label: const PosText('Simpan Penerimaan'),
                  ),
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
          );
    if (!widget.embedded) {
      return Scaffold(
        appBar: AppBar(
          title: Text(posLocale(context).posfd9cce7e760d((widget.purchase['no_po'] ?? 'Pembelian').toString())),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: body,
      );
    }
    return Column(
      children: [
        Material(
          color: Colors.white,
          child: ListTile(
            leading: IconButton(
              tooltip: ('Kembali ke pembelian').tr(context),
              onPressed: widget.onFinished,
              icon: const Icon(Icons.arrow_back),
            ),
            title: Text(
              posLocale(context).posfd9cce7e760d((widget.purchase['no_po'] ?? 'Pembelian').toString()),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const PosText('Pembelian & Penerimaan'),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: body),
      ],
    );
  }
}

class _ReceivingFormSkeleton extends StatelessWidget {
  const _ReceivingFormSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: const [
      SkeletonBox(height: 88, borderRadius: 14),
      SizedBox(height: 12),
      SkeletonBox(height: 52, borderRadius: 10),
      SizedBox(height: 10),
      SkeletonBox(height: 52, borderRadius: 10),
      SizedBox(height: 10),
      SkeletonBox(height: 52, borderRadius: 10),
      SizedBox(height: 18),
      SkeletonBox(height: 20, width: 170, borderRadius: 5),
      SizedBox(height: 10),
      _ReceivingItemSkeletonCard(),
      SizedBox(height: 10),
      _ReceivingItemSkeletonCard(),
      SizedBox(height: 18),
      SkeletonBox(height: 48, borderRadius: 10),
    ],
  );
}

class _ReceivingItemSkeletonCard extends StatelessWidget {
  const _ReceivingItemSkeletonCard();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(width: 190, height: 16, borderRadius: 4),
          SizedBox(height: 9),
          SkeletonBox(width: 125, height: 12, borderRadius: 4),
          SizedBox(height: 14),
          SkeletonBox(height: 44, borderRadius: 8),
        ],
      ),
    ),
  );
}
