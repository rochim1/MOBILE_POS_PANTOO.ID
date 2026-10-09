import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../../injections.dart';
import '../../../core/_core.dart';
import '../../../domain/repositories/pos_inventory_repository.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/inventory_action_style.dart';
import '../../widgets/skeleton_loading.dart';
import 'pos_barcode_scanner_page.dart';
import 'pos_purchase_payable_page.dart';
import 'utils/pos_purchase_progress.dart';

class PosPurchaseReceivingPage extends StatefulWidget {
  final Map<String, dynamic> purchase;
  final bool embedded;
  final bool canViewPayable;
  final bool canRecordPayment;
  final VoidCallback? onFinished;
  final ValueChanged<Map<String, dynamic>>? onPayRequested;
  const PosPurchaseReceivingPage({
    super.key,
    required this.purchase,
    this.embedded = false,
    this.canViewPayable = false,
    this.canRecordPayment = false,
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
  String get _pendingKey =>
      'inventory.receiving.pending:${widget.purchase['_id']}';
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
  late final List<Map<String, dynamic>> _items;

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
        final payload = Map<String, dynamic>.from(jsonDecode(saved) as Map);
        if (payload['purchase_id']?.toString() ==
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
    if (!mounted) return;
    result.fold((failure) => AppToast.error(context, failure.message), (data) {
      _lookups = data;
      final receivingWarehouses = data.warehouses
          .where((item) => item['is_receiving_location'] != false)
          .toList();
      final activeIsEligible = receivingWarehouses.any(
        (item) => item['_id']?.toString() == data.activeWarehouseId,
      );
      _warehouseId = activeIsEligible
          ? data.activeWarehouseId
          : receivingWarehouses.length == 1
          ? receivingWarehouses.first['_id']?.toString() ?? ''
          : '';
      if (receivingWarehouses.isEmpty) {
        AppToast.error(
          context,
          'Belum ada warehouse yang diaktifkan untuk penerimaan pembelian.',
        );
      }
    });
    historyResult.fold(
      (failure) => AppToast.error(
        context,
        'Riwayat penerimaan gagal dimuat: ${failure.message}',
      ),
      (data) => _history = data,
    );
    setState(() => _loading = false);
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
          title: const Text('Pilih baris PO'),
          children: poLines
              .map(
                (line) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, line),
                  child: Text(
                    '${line['nama_inventaris']} · sisa ${line['remaining']} ${line['unit'] ?? ''}',
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
    final remaining = (selectedItem['remaining'] as num).toDouble();
    final quantity = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(selectedItem['nama_inventaris']?.toString() ?? 'Barang PO'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Diterima sekarang (${selectedItem['unit'] ?? ''})',
              helperText: 'Sisa PO: ${selectedItem['remaining']}',
              border: const OutlineInputBorder(),
            ),
            validator: (raw) {
              final qty = double.tryParse((raw ?? '').replaceAll(',', '.'));
              return qty == null || !qty.isFinite || qty < 0 || qty > remaining
                  ? 'Isi jumlah 0 sampai $remaining'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
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
            child: const Text('Terapkan'),
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
          title: const Text('Ulangi penerimaan sebelumnya?'),
          content: const Text(
            'Permintaan terakhir belum dikonfirmasi. Data jumlah dan lokasi yang tersimpan akan dikirim ulang; perubahan form saat ini tidak ikut dikirim.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Periksa Riwayat'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ulangi Request'),
            ),
          ],
        ),
      );
      if (retry == true && mounted) await _sendReceiving(_pendingInput!);
      return;
    }
    final warehouse = _lookups?.warehouses
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (item) => item?['_id']?.toString() == _warehouseId,
          orElse: () => null,
        );
    final invalid = _items.cast<Map<String, dynamic>?>().firstWhere((item) {
      final qty = (item?['receive_qty'] as num? ?? 0).toDouble();
      return !qty.isFinite ||
          qty < 0 ||
          qty - (item?['remaining'] as num).toDouble() > 0.000001;
    }, orElse: () => null);
    if (invalid != null) {
      AppToast.error(
        context,
        'Jumlah ${invalid['nama_inventaris']} maksimal ${invalid['remaining']} ${invalid['unit'] ?? ''}',
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
        title: const Text('Konfirmasi penerimaan'),
        content: Text(
          '${selected.length} jenis barang akan menambah stok di '
          '${warehouse['nama_cabang'] ?? 'lokasi terpilih'}.\n\n'
          '${selected.map((item) => '${item['nama_inventaris']}: ${item['receive_qty']} ${item['unit'] ?? ''}').join('\n')}\n\n'
          'Pastikan jumlah, batch, dan lokasi sudah benar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Periksa Lagi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, Terima Barang'),
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
      final saved = await sl<SharedPreferences>().setString(
        _pendingKey,
        jsonEncode(input),
      );
      if (!saved) throw StateError('Penyimpanan request ditolak perangkat');
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

  Future<void> _sendReceiving(Map<String, dynamic> input) async {
    setState(() => _loading = true);
    final result = await _repository.receivePurchase(input);
    if (!mounted) return;
    var succeeded = false;
    dynamic receipt;
    result.fold(
      (failure) {
        AppToast.error(context, failure.message);
        setState(() => _loading = false);
      },
      (value) {
        succeeded = true;
        receipt = value;
      },
    );
    if (!succeeded) return;
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
    // A PO creates its payable at approval. A receipt is only a due-date
    // trigger for "saat penerimaan" terms; it is not a prerequisite to pay
    // immediate or credit terms, including after a partial receipt.
    if (!widget.canViewPayable) {
      _finish();
      return;
    }
    final openPayable = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Penerimaan selesai'),
        content: const Text(
          'Anda dapat melihat sisa hutang PO ini dan mencatat pembayaran sekarang atau nanti.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Nanti'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Lihat hutang'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (openPayable == true) {
      if (widget.embedded && widget.onPayRequested != null) {
        widget.onPayRequested!(widget.purchase);
        _finish();
        return;
      }
      await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PosPurchasePayablePage(
            purchase: widget.purchase,
            canRecordPayment: widget.canRecordPayment,
          ),
        ),
      );
    }
    if (!mounted) return;
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
        title: Text('Batalkan ${receipt['no_grn'] ?? 'penerimaan'}?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Alasan pembatalan *',
            hintText: 'Contoh: jumlah atau lokasi penerimaan keliru',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(dialogContext, value);
            },
            child: const Text('Batalkan Penerimaan'),
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
        title: Text('Riwayat penerimaan (${_history.length})'),
        subtitle: const Text('Penerimaan parsial yang sudah dicatat'),
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
          return ListTile(
            title: Text(receipt['no_grn']?.toString() ?? 'Penerimaan'),
            subtitle: Text(
              '${_shortDate(receipt['tanggal_terima'])}'
              '${(receipt['no_surat_jalan']?.toString() ?? '').isEmpty ? '' : ' · SJ ${receipt['no_surat_jalan']}'}\n$lines'
              '${receipt['journal_status'] == 'failed'
                  ? '\nJurnal asal gagal: ${receipt['journal_error'] ?? ''}'
                  : receipt['journal_status'] == 'pending'
                  ? '\nJurnal asal belum terkonfirmasi'
                  : ''}'
              '${receipt['cancel_journal_status'] == 'failed'
                  ? '\nJurnal pembatalan gagal: ${receipt['cancel_journal_error'] ?? ''}'
                  : cancelled && receipt['cancel_journal_status'] == 'pending'
                  ? '\nJurnal pembatalan belum terkonfirmasi'
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
                ? const Chip(label: Text('Dibatalkan'))
                : PopupMenuButton<String>(
                    enabled: !_loading,
                    tooltip: 'Aksi penerimaan',
                    onSelected: (action) => switch (action) {
                      'retry_journal' => _retryReceivingJournal(receipt),
                      'retry_cancel_journal' => _retryReceivingCancelJournal(
                        receipt,
                      ),
                      _ => _cancelReceiving(receipt),
                    },
                    itemBuilder: (_) => [
                      if ([
                        'failed',
                        'pending',
                      ].contains(receipt['journal_status']))
                        const PopupMenuItem(
                          value: 'retry_journal',
                          child: Text('Ulangi Jurnal'),
                        ),
                      if (cancelled &&
                          [
                            'failed',
                            'pending',
                          ].contains(receipt['cancel_journal_status']))
                        const PopupMenuItem(
                          value: 'retry_cancel_journal',
                          child: Text('Ulangi Jurnal Pembatalan'),
                        ),
                      if (!cancelled)
                        const PopupMenuItem(
                          value: 'cancel',
                          child: Text('Batalkan Penerimaan'),
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
          decoration: const InputDecoration(
            labelText: 'Tanggal penerimaan',
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
              onChanged: (value) => setState(() {
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
              decoration: const InputDecoration(
                labelText: 'Rak (opsional)',
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
        decoration: const InputDecoration(
          labelText: 'Nomor surat jalan (opsional)',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _notes,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Catatan penerimaan (opsional)',
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
                        child: Text(
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
                          const Text(
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
                            decoration: const InputDecoration(
                              labelText: 'Cabang penerimaan *',
                              prefixIcon: Icon(Icons.warehouse_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: (_lookups?.warehouses ?? const [])
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
                            title: const Text('Detail tambahan'),
                            subtitle: const Text(
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
                    child: const Text(
                      'Penerimaan parsial didukung. Isi hanya jumlah yang datang sekarang; sisanya tetap dapat diterima pada penerimaan berikutnya.',
                      style: TextStyle(height: 1.35),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Barang diterima',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Scan barcode barang PO',
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
                                  item['receive_qty'] = item['remaining'];
                                }
                              }),
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Terima Semua'),
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
                              'Dipesan ${item['qty_ordered'] ?? 0} · '
                              'Sudah diterima ${item['qty_received'] ?? 0} · '
                              'Sisa ${item['remaining']} ${item['unit'] ?? ''}',
                            ),
                            if ((item['conversion_factor'] as num? ?? 1) != 1)
                              Text(
                                'Konversi: 1 ${item['unit'] ?? ''} = ${item['conversion_factor']} ${item['base_unit'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            const SizedBox(height: 8),
                            TextFormField(
                              key: ValueKey(
                                '${item['_id']}-${item['receive_qty']}',
                              ),
                              initialValue: item['receive_qty'].toString(),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Diterima sekarang',
                                helperText:
                                    'Boleh kurang dari sisa untuk pengiriman parsial',
                                border: OutlineInputBorder(),
                              ),
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (raw) {
                                if ((raw ?? '').trim().isEmpty) return null;
                                final qty = double.tryParse(
                                  raw!.replaceAll(',', '.'),
                                );
                                final remaining = (item['remaining'] as num)
                                    .toDouble();
                                return qty == null ||
                                        !qty.isFinite ||
                                        qty < 0 ||
                                        qty > remaining
                                    ? 'Isi jumlah 0 sampai $remaining'
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
                                    ? 'Data pelacakan wajib'
                                    : 'Batch, kedaluwarsa & keterangan',
                              ),
                              subtitle: Text(
                                item['wajib_batch_number'] == true ||
                                        item['wajib_serial_number'] == true
                                    ? 'Lengkapi sebelum menyimpan'
                                    : 'Opsional untuk barang ini',
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
                                              ? 'Nomor batch *'
                                              : 'Nomor batch (opsional)',
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
                                                ? 'Tanggal kedaluwarsa *'
                                                : 'Tanggal kedaluwarsa (opsional)',
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
                                                ? 'Pilih tanggal'
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
                                        ? 'Serial number *'
                                        : 'Keterangan (opsional)',
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
                    onPressed: _loading || _items.isEmpty ? null : _save,
                    style: InventoryActionStyle.primary(),
                    icon: const Icon(Icons.inventory, size: 18),
                    label: const Text('Simpan Penerimaan'),
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
          title: Text('Terima ${widget.purchase['no_po'] ?? 'Pembelian'}'),
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
              tooltip: 'Kembali ke pembelian',
              onPressed: widget.onFinished,
              icon: const Icon(Icons.arrow_back),
            ),
            title: Text(
              'Terima ${widget.purchase['no_po'] ?? 'Pembelian'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Pembelian & Penerimaan'),
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
