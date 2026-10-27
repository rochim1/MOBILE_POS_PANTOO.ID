import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../injections.dart';
import '../../../core/utils/product_image_picker.dart';
import '../../../core/utils/rupiah_input_formatter.dart';
import '../../../domain/repositories/pos_inventory_repository.dart';
import '../../widgets/app_toast.dart';

class PosDirectPurchasePage extends StatefulWidget {
  final bool canCreate;
  const PosDirectPurchasePage({super.key, required this.canCreate});

  @override
  State<PosDirectPurchasePage> createState() => _PosDirectPurchasePageState();
}

class _PosDirectPurchasePageState extends State<PosDirectPurchasePage> {
  final _repository = sl<PosInventoryRepository>();
  final _supplier = TextEditingController();
  final _description = TextEditingController();
  final _amount = TextEditingController();
  final _receipt = TextEditingController();
  final _note = TextEditingController();
  Map<String, dynamic> _data = const {};
  bool _loading = true;
  bool _saving = false;
  String _bankId = '';
  String _expenseCode = '';
  String _category = 'lainnya';
  String _receiptHash = '';
  String _syncStatus = 'draft';
  late String _requestId;

  String _newRequestId() =>
      'mobile-direct-${DateTime.now().microsecondsSinceEpoch}';

  String get _draftKey {
    final prefs = sl<SharedPreferences>();
    return 'direct_purchase_draft:${prefs.getString('instansi_id') ?? 'tenant'}:${prefs.getString('user_id') ?? 'user'}';
  }

  @override
  void initState() {
    super.initState();
    _requestId = _newRequestId();
    _restoreDraft();
    _load();
  }

  void _restoreDraft() {
    final raw = sl<SharedPreferences>().getString(_draftKey);
    if (raw == null) return;
    try {
      final draft = jsonDecode(raw) as Map<String, dynamic>;
      _supplier.text = draft['supplier']?.toString() ?? '';
      _description.text = draft['description']?.toString() ?? '';
      final draftAmount = draft['amount']?.toString() ?? '';
      _amount.text = draftAmount.isEmpty
          ? ''
          : formatRupiahInput(parseRupiah(draftAmount));
      _receipt.text = draft['receipt']?.toString() ?? '';
      _note.text = draft['note']?.toString() ?? '';
      _bankId = draft['bankId']?.toString() ?? '';
      _expenseCode = draft['expenseCode']?.toString() ?? '';
      _category = draft['category']?.toString() ?? 'lainnya';
      _receiptHash = draft['receiptHash']?.toString() ?? '';
      _syncStatus = draft['syncStatus']?.toString() ?? 'draft';
      _requestId = draft['requestId']?.toString() ?? _requestId;
    } catch (_) {
      sl<SharedPreferences>().remove(_draftKey);
    }
  }

  Future<void> _saveDraft() => sl<SharedPreferences>().setString(
    _draftKey,
    jsonEncode({
      'supplier': _supplier.text,
      'description': _description.text,
      'amount': _amount.text,
      'receipt': _receipt.text,
      'note': _note.text,
      'bankId': _bankId,
      'expenseCode': _expenseCode,
      'category': _category,
      'receiptHash': _receiptHash,
      'syncStatus': _syncStatus,
      'requestId': _requestId,
    }),
  );

  Future<void> _pickAndUploadReceipt() async {
    final picked = await pickProductImage();
    if (picked == null || !mounted) return;
    setState(() => _syncStatus = 'uploading');
    await _saveDraft();
    final result = await _repository.uploadDirectPurchaseReceipt(
      picked.bytes,
      picked.name,
    );
    if (!mounted) return;
    await result.fold(
      (failure) async {
        setState(() => _syncStatus = 'upload_failed');
        await _saveDraft();
        if (mounted) AppToast.error(context, failure.message);
      },
      (url) async {
        _receipt.text = url;
        _receiptHash = sha256.convert(picked.bytes).toString();
        setState(() => _syncStatus = 'uploaded');
        await _saveDraft();
      },
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _repository.getDirectPurchaseWorkspace();
    if (!mounted) return;
    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (value) => setState(() {
        _data = value;
        final policy = value['GetDirectPurchasePolicy'] as Map?;
        final categories = (policy?['allowed_categories'] as List? ?? const [])
            .map((item) => item.toString())
            .toList();
        if (categories.isNotEmpty && !categories.contains(_category)) {
          _category = categories.first;
        }
      }),
    );
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    final amount =
        int.tryParse(_amount.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (_supplier.text.trim().isEmpty ||
        _description.text.trim().isEmpty ||
        amount <= 0 ||
        _bankId.isEmpty ||
        _expenseCode.isEmpty) {
      AppToast.error(
        context,
        'Lengkapi supplier, deskripsi, nominal, sumber dana, dan akun beban.',
      );
      return;
    }
    await _saveDraft();
    setState(() => _saving = true);
    setState(() => _syncStatus = 'submitting');
    await _saveDraft();
    final result = await _repository.createDirectPurchase({
      'supplier_name': _supplier.text.trim(),
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'bank_account_id': _bankId,
      'receipt_url': _receipt.text.trim().isEmpty ? null : _receipt.text.trim(),
      'receipt_hash': _receiptHash.isEmpty ? null : _receiptHash,
      'note': _note.text.trim(),
      'request_id': _requestId,
      'items': [
        {
          'kind': 'expense',
          'description': _description.text.trim(),
          'category': _category,
          'quantity': 1,
          'unit_price': amount,
          'debit_account_code': _expenseCode,
        },
      ],
    });
    if (!mounted) return;
    result.fold(
      (failure) async {
        setState(() => _syncStatus = 'retry_required');
        await _saveDraft();
        if (mounted) {
          AppToast.error(
            context,
            '${failure.message} Draft tetap tersimpan dan belum mengubah stok/kas.',
          );
        }
      },
      (_) async {
        await sl<SharedPreferences>().remove(_draftKey);
        _supplier.clear();
        _description.clear();
        _amount.clear();
        _receipt.clear();
        _receiptHash = '';
        _note.clear();
        setState(() {
          _bankId = '';
          _expenseCode = '';
          _syncStatus = 'draft';
          _requestId = _newRequestId();
        });
        if (mounted) {
          AppToast.success(
            context,
            'Permintaan tersimpan. Menunggu approval; kas belum berkurang.',
          );
        }
        await _load();
      },
    );
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final policy = Map<String, dynamic>.from(
      (_data['GetDirectPurchasePolicy'] as Map?) ?? const {},
    );
    final rows = (_data['GetDirectPurchases'] as List? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final options = Map<String, dynamic>.from(
      (_data['GetDirectPurchaseOptions'] as Map?) ?? const {},
    );
    final banks = (options['banks'] as List? ?? const []).cast<Map>();
    final accounts = (options['accounts'] as List? ?? const [])
        .cast<Map>()
        .where((account) => account['type'] == 'expense')
        .toList();
    final categories = (policy['allowed_categories'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();
    final categoryValue = categories.contains(_category)
        ? _category
        : (categories.isEmpty ? null : categories.first);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Pembelian Langsung',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Untuk pembelian kecil yang langsung dibayar. Pengiriman PO, Vendor Bill, dan utang tidak dibuat.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (policy['enabled'] != true)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Fitur belum diaktifkan oleh Finance tenant.'),
              ),
            ),
          if (policy['enabled'] == true && widget.canCreate)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _supplier,
                      decoration: const InputDecoration(labelText: 'Supplier'),
                    ),
                    TextField(
                      controller: _description,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi pembelian',
                      ),
                    ),
                    TextField(
                      controller: _amount,
                      inputFormatters: const [RupiahInputFormatter()],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            'Nominal (maks. Rp${policy['amount_limit'] ?? 0})',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _bankId.isEmpty ? null : _bankId,
                      decoration: const InputDecoration(
                        labelText: 'Sumber dana',
                      ),
                      items: banks
                          .map(
                            (b) => DropdownMenuItem(
                              value: b['_id'].toString(),
                              child: Text(
                                '${b['name']} ••••${b['account_number_last4'] ?? ''}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _bankId = v ?? ''),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _expenseCode.isEmpty ? null : _expenseCode,
                      decoration: const InputDecoration(
                        labelText: 'Akun beban',
                      ),
                      items: accounts
                          .map(
                            (a) => DropdownMenuItem(
                              value: a['code'].toString(),
                              child: Text('${a['code']} — ${a['name']}'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _expenseCode = v ?? ''),
                    ),
                    if (categories.isNotEmpty)
                      DropdownButtonFormField<String>(
                        initialValue: categoryValue,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                        ),
                        items: categories
                            .map(
                              (v) => DropdownMenuItem(value: v, child: Text(v)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _category = v ?? _category),
                      ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.receipt_long_outlined),
                      title: Text(
                        _receipt.text.isEmpty
                            ? 'Tambahkan foto nota'
                            : 'Bukti nota sudah diunggah',
                      ),
                      subtitle: Text('Status sinkronisasi: $_syncStatus'),
                      trailing: OutlinedButton(
                        onPressed: _saving || _syncStatus == 'uploading'
                            ? null
                            : _pickAndUploadReceipt,
                        child: Text(
                          _receipt.text.isEmpty ? 'Pilih foto' : 'Ganti',
                        ),
                      ),
                    ),
                    TextField(
                      controller: _note,
                      decoration: const InputDecoration(labelText: 'Catatan'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () async {
                                    await _saveDraft();
                                    if (!mounted) return;
                                    AppToast.success(
                                      this.context,
                                      'Draft disimpan lokal; belum mengubah stok/kas.',
                                    );
                                  },
                            child: const Text('Simpan draft'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(
                            onPressed: _saving ? null : _submit,
                            child: Text(_saving ? 'Mengirim…' : 'Ajukan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text('Riwayat', style: Theme.of(context).textTheme.titleMedium),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Belum ada Pembelian Langsung.'),
            ),
          ...rows.map(
            (row) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${row['number']} · ${row['supplier_name']}'),
              subtitle: Text('${row['date']} · ${row['status']}'),
              trailing: Text('Rp${row['total_amount'] ?? 0}'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _supplier.dispose();
    _description.dispose();
    _amount.dispose();
    _receipt.dispose();
    _note.dispose();
    super.dispose();
  }
}
