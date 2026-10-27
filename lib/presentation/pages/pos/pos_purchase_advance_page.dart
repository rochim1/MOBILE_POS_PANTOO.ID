import 'package:flutter/material.dart';
import 'dart:async';
import '../../widgets/pos_keyboard_stable_dialog.dart';
import 'widgets/pos_paged_reference_picker.dart';
import 'package:crypto/crypto.dart';

import '../../../../injections.dart';
import '../../../core/utils/product_image_picker.dart';
import '../../../core/utils/rupiah_input_formatter.dart';
import '../../../domain/repositories/pos_inventory_repository.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/inventory_action_style.dart';

class PosPurchaseAdvancePage extends StatefulWidget {
  final bool canRequest;
  final PosInventoryRepository? repository;
  const PosPurchaseAdvancePage({
    super.key,
    required this.canRequest,
    this.repository,
  });

  @override
  State<PosPurchaseAdvancePage> createState() => _PosPurchaseAdvancePageState();
}

class _PosPurchaseAdvancePageState extends State<PosPurchaseAdvancePage> {
  late final _repository = widget.repository ?? sl<PosInventoryRepository>();
  int _page = 1, _total = 0, _loadVersion = 0;
  String _search = '';
  Timer? _searchTimer;
  bool _pickingPurchase = false;
  bool _loading = true;
  bool _submitting = false;
  List<Map<String, dynamic>> _requests = const [];

  String _requestId = _newRequestId();

  static String _newRequestId() =>
      'mobile-dp-${DateTime.now().microsecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _loadVersion++;
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({int? page}) async {
    final target = page ?? _page, version = ++_loadVersion;
    setState(() => _loading = true);
    final result = await _repository.getPurchaseAdvanceWorkspace(
      page: target,
      search: _search,
    );
    if (!mounted || version != _loadVersion) return;
    result.fold((failure) => AppToast.error(context, failure.message), (data) {
      final result = data['GetPurchaseAdvancePage'] as Map?;
      _requests = (result?['items'] as List? ?? [])
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
      _total = (result?['totalCount'] as num?)?.toInt() ?? 0;
      _page = target;
    });
    setState(() => _loading = false);
  }

  Future<Map<String, dynamic>?> _pickPurchase() async {
    if (_pickingPurchase) return null;
    setState(() => _pickingPurchase = true);
    try {
      return await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => PosKeyboardStableFormDialog(
          width: 520,
          height: 600,
          title: const Text('Pilih PO dengan sisa kesepakatan DP'),
          content: PosPagedReferencePicker(
            placeholder: 'Cari nomor PO atau pemasok',
            loader: (search, page) async {
              final result = await _repository.getEligibleAdvancePurchases(
                search: search,
                page: page,
              );
              return result.fold(
                (failure) => throw Exception(failure.message),
                (data) => data,
              );
            },
            label: (row) => '${row['no_po']} · ${row['supplier_name']}',
          ),
          actions: const [],
        ),
      );
    } finally {
      if (mounted) setState(() => _pickingPurchase = false);
    }
  }

  String _money(dynamic value) => 'Rp${(value as num? ?? 0).round()}'
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');

  String _status(String value) => switch (value) {
    'requested' => 'Menunggu persetujuan',
    'approved' => 'Disetujui',
    'rejected' => 'Ditolak',
    'partially_paid' => 'Dibayar sebagian',
    'paid' => 'Sudah dibayar Finance',
    'settled' => 'Sudah dialokasikan/diselesaikan',
    _ => value,
  };

  Future<void> _openRequestForm() async {
    var purchase = await _pickPurchase();
    if (purchase == null || !mounted) return;
    String purchaseId = purchase['_id'].toString();
    final amount = TextEditingController();
    final purpose = TextEditingController();
    PickedProductImage? proforma;
    final accepted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final remaining =
              (purchase!['advance_available_amount'] as num?)?.toDouble() ?? 0;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Ajukan pembayaran DP',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Permintaan ini tidak mengeluarkan uang. Finance tetap harus menyetujui dan membayar secara terpisah.',
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${purchase!['no_po']} · ${purchase!['supplier_name']}',
                    ),
                    subtitle: const Text('Purchase Order terpilih'),
                    trailing: IconButton(
                      tooltip: 'Ganti PO',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () async {
                        final selected = await _pickPurchase();
                        if (selected != null && sheetContext.mounted) {
                          setSheetState(() {
                            purchase = selected;
                            purchaseId = selected['_id'].toString();
                            amount.clear();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amount,
                    inputFormatters: const [RupiahInputFormatter()],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Nominal DP',
                      helperText: 'Maksimum tersisa ${_money(remaining)}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: purpose,
                    maxLength: 500,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Tujuan / keterangan',
                      hintText: 'Contoh: DP sesuai proforma supplier',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  OutlinedButton.icon(
                    style: InventoryActionStyle.outlined(),
                    onPressed: () async {
                      final picked = await pickProductImage();
                      if (picked != null) {
                        setSheetState(() => proforma = picked);
                      }
                    },
                    icon: const Icon(Icons.attach_file, size: 18),
                    label: Text(
                      proforma == null
                          ? 'Lampirkan proforma (opsional)'
                          : 'Proforma: ${proforma!.name}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    style: InventoryActionStyle.primary(),
                    onPressed: () {
                      final parsed = int.tryParse(
                        amount.text.replaceAll(RegExp(r'[^0-9]'), ''),
                      );
                      if (parsed == null || parsed <= 0 || parsed > remaining) {
                        AppToast.error(
                          context,
                          'Nominal harus lebih dari nol dan tidak melebihi ${_money(remaining)}.',
                        );
                        return;
                      }
                      if (purpose.text.trim().isEmpty) {
                        AppToast.error(
                          context,
                          'Tujuan permintaan DP wajib diisi.',
                        );
                        return;
                      }
                      Navigator.pop(sheetContext, true);
                    },
                    child: const Text('Kirim permintaan'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (accepted != true || !mounted) {
      amount.dispose();
      purpose.dispose();
      return;
    }
    setState(() => _submitting = true);
    String? proformaUrl;
    if (proforma != null) {
      final upload = await _repository.uploadPurchaseAdvanceProforma(
        proforma!.bytes,
        proforma!.name,
      );
      final failed = upload.fold(
        (failure) {
          AppToast.error(context, failure.message);
          return true;
        },
        (url) {
          proformaUrl = url;
          return false;
        },
      );
      if (failed || !mounted) {
        amount.dispose();
        purpose.dispose();
        if (mounted) setState(() => _submitting = false);
        return;
      }
    }
    final input = {
      'purchase_id': purchaseId,
      'amount': int.parse(amount.text.replaceAll(RegExp(r'[^0-9]'), '')),
      'purpose': purpose.text.trim(),
      'request_id': _requestId,
      if (proformaUrl != null) 'proforma_url': proformaUrl,
      if (proforma != null)
        'proforma_hash': sha256.convert(proforma!.bytes).toString(),
    };
    amount.dispose();
    purpose.dispose();
    final result = await _repository.requestPurchaseAdvance(input);
    if (!mounted) return;
    await result.fold(
      (failure) async => AppToast.error(context, failure.message),
      (_) async {
        _requestId = _newRequestId();
        AppToast.success(
          context,
          'Permintaan DP terkirim. Menunggu approval dan pembayaran Finance.',
        );
        await _load();
      },
    );
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permintaan uang muka supplier',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Status pembayaran hanya dicatat oleh Finance.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            if (widget.canRequest)
              FilledButton.icon(
                style: InventoryActionStyle.primary(),
                onPressed: _submitting || _pickingPurchase
                    ? null
                    : _openRequestForm,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajukan DP'),
              ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Cari PO atau pemasok',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _search = value;
            _loadVersion++;
            _searchTimer?.cancel();
            setState(() => _loading = true);
            _searchTimer = Timer(
              const Duration(milliseconds: 300),
              () => _load(page: 1),
            );
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Halaman sebelumnya',
              onPressed: !_loading && _page > 1
                  ? () => _load(page: _page - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Flexible(
              child: Text(
                'Halaman $_page · $_total permintaan',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'Halaman berikutnya',
              onPressed: !_loading && _page * 20 < _total
                  ? () => _load(page: _page + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_requests.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('Belum ada permintaan DP.'),
            ),
          )
        else
          ..._requests.map(
            (row) => Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            row['no_po']?.toString() ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          _money(row['amount']),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(row['supplier_name']?.toString() ?? '-'),
                    const Divider(height: 22),
                    Text(_status(row['status']?.toString() ?? '-')),
                    if ((row['purpose']?.toString() ?? '').isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        row['purpose'].toString(),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                    if ((row['proforma_url']?.toString() ?? '').isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Proforma terlampir · hanya bukti pendukung, bukan Vendor Bill',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    if ((row['rejection_reason']?.toString() ?? '').isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Alasan penolakan: ${row['rejection_reason']}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    if ((row['paid_amount'] as num? ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Dibayar ${_money(row['paid_amount'])} · Dialokasikan ${_money(row['allocated_amount'])} · Saldo ${_money(row['balance'])}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
