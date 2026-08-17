import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injections.dart';
import '../../../core/_core.dart';
import '../../../domain/repositories/purchase_return_repository.dart';
import '../../widgets/app_toast.dart';
import '../../bloc/pos/pos_bloc.dart';

class PosPurchaseReturnPage extends StatefulWidget {
  const PosPurchaseReturnPage({super.key});

  @override
  State<PosPurchaseReturnPage> createState() => _PosPurchaseReturnPageState();
}

class _PosPurchaseReturnPageState extends State<PosPurchaseReturnPage> {
  final _repository = sl<PurchaseReturnRepository>();
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _items = const [];
  bool _loading = true;
  String _status = '';
  int _page = 1;
  int _total = 0;
  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({int? page}) async {
    setState(() => _loading = true);
    final nextPage = page ?? _page;
    final result = await _repository.getAll(
      search: _searchController.text,
      status: _status,
      page: nextPage,
      limit: _limit,
    );
    if (!mounted) return;
    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (data) => setState(() {
        _items = data.items;
        _total = data.totalCount;
        _page = nextPage;
      }),
    );
    if (mounted) setState(() => _loading = false);
  }

  void _search(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(page: 1));
  }

  Future<void> _openCreate() async {
    final permissions = Map<String, dynamic>.from(
      context.read<PosBloc>().state.runtimeConfig['permissions'] as Map? ??
          const {},
    );
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _CreatePurchaseReturnPage(
          canSubmit: permissions['submit_purchase_returns'] == true,
        ),
      ),
    );
    if (created == true) _load(page: 1);
  }

  Future<void> _openDetail(String id) async {
    final permissions = Map<String, dynamic>.from(
      context.read<PosBloc>().state.runtimeConfig['permissions'] as Map? ??
          const {},
    );
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _PurchaseReturnDetailPage(id: id, permissions: permissions),
      ),
    );
    // Detail dapat berubah lewat aksi atau refresh server. Muat ulang daftar
    // setiap kembali, termasuk ketika pengguna memakai tombol Back sistem.
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final permissions = Map<String, dynamic>.from(
      context.watch<PosBloc>().state.runtimeConfig['permissions'] as Map? ??
          const {},
    );
    final canCreate = permissions['create_purchase_returns'] == true;
    return ColoredBox(
      color: AppColors.bgPrimary,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final search = TextField(
                  controller: _searchController,
                  onChanged: _search,
                  decoration: const InputDecoration(
                    labelText: 'Cari nomor retur / supplier',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                );
                final status = DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Semua')),
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(
                      value: 'pending_approval',
                      child: Text('Menunggu'),
                    ),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('Disetujui'),
                    ),
                    DropdownMenuItem(value: 'rejected', child: Text('Ditolak')),
                    DropdownMenuItem(
                      value: 'processed',
                      child: Text('Diproses'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _status = value ?? '');
                    _load(page: 1);
                  },
                );
                final button = FilledButton.icon(
                  onPressed: canCreate ? _openCreate : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Retur ke Supplier'),
                );
                if (constraints.maxWidth >= 720) {
                  return Row(
                    children: [
                      Expanded(child: search),
                      const SizedBox(width: 12),
                      SizedBox(width: 190, child: status),
                      const SizedBox(width: 12),
                      SizedBox(height: 56, child: button),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    search,
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: status),
                        const SizedBox(width: 10),
                        button,
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
                      children: const [
                        SizedBox(height: 100),
                        Icon(
                          Icons.assignment_return_outlined,
                          size: 64,
                          color: Colors.black26,
                        ),
                        SizedBox(height: 12),
                        Center(child: Text('Belum ada retur ke supplier')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return Card(
                          child: ListTile(
                            onTap: () => _openDetail(item['_id'].toString()),
                            leading: CircleAvatar(
                              backgroundColor: _statusColor(
                                item['approval_status'].toString(),
                              ).withValues(alpha: .12),
                              child: Icon(
                                Icons.assignment_return_outlined,
                                color: _statusColor(
                                  item['approval_status'].toString(),
                                ),
                              ),
                            ),
                            title: Text(
                              item['no_return']?.toString() ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${item['supplier_name'] ?? '-'} • ${item['no_po'] ?? '-'}\n'
                              '${_date(item['tanggal_return'])} • ${item['lokasi_cabang_nama'] ?? '-'}',
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _money(item['grand_total_return']),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _StatusChip(
                                      item['approval_status']?.toString() ?? '',
                                    ),
                                  ],
                                ),
                                PopupMenuButton<String>(
                                  tooltip: 'Aksi retur',
                                  onSelected: (action) async {
                                    if (action == 'detail') {
                                      await _openDetail(item['_id'].toString());
                                      return;
                                    }
                                    final number =
                                        item['no_return']?.toString() ?? '';
                                    await Clipboard.setData(
                                      ClipboardData(text: number),
                                    );
                                    if (context.mounted) {
                                      AppToast.success(
                                        context,
                                        'Nomor retur disalin',
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'detail',
                                      child: ListTile(
                                        dense: true,
                                        leading: Icon(
                                          Icons.visibility_outlined,
                                        ),
                                        title: Text('Detail & aksi'),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'copy',
                                      child: ListTile(
                                        dense: true,
                                        leading: Icon(Icons.copy_outlined),
                                        title: Text('Salin nomor'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          if (_total > _limit)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _page > 1 ? () => _load(page: _page - 1) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Halaman $_page dari ${(_total / _limit).ceil()}'),
                  IconButton(
                    onPressed: _page * _limit < _total
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
}

class _CreatePurchaseReturnPage extends StatefulWidget {
  final bool canSubmit;
  const _CreatePurchaseReturnPage({required this.canSubmit});
  @override
  State<_CreatePurchaseReturnPage> createState() =>
      _CreatePurchaseReturnPageState();
}

class _CreatePurchaseReturnPageState extends State<_CreatePurchaseReturnPage> {
  final _repository = sl<PurchaseReturnRepository>();
  final _search = TextEditingController();
  final _notes = TextEditingController();
  List<Map<String, dynamic>> _purchases = const [];
  List<Map<String, dynamic>> _groups = const [];
  Map<String, dynamic>? _purchase;
  Map<String, dynamic>? _group;
  String _reason = 'barang_rusak';
  String _method = 'credit_note';
  bool _loading = false;
  late bool _submitApproval;

  @override
  void initState() {
    super.initState();
    _submitApproval = widget.canSubmit;
  }

  List<Map<String, dynamic>> get _availableItems =>
      (_group?['items'] as List? ?? const []).cast<Map<String, dynamic>>();

  @override
  void dispose() {
    _search.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _findPurchases() async {
    if (_search.text.trim().length < 2) {
      AppToast.error(context, 'Masukkan minimal 2 karakter');
      return;
    }
    setState(() => _loading = true);
    final result = await _repository.searchPurchases(_search.text);
    if (!mounted) return;
    result.fold(
      (f) => AppToast.error(context, f.message),
      (rows) => setState(() => _purchases = rows),
    );
    setState(() => _loading = false);
  }

  Future<void> _selectPurchase(Map<String, dynamic> purchase) async {
    setState(() {
      _purchase = purchase;
      _groups = const [];
      _group = null;
      _loading = true;
    });
    final result = await _repository.getAvailability(
      purchase['_id'].toString(),
    );
    if (!mounted) return;
    result.fold((f) => AppToast.error(context, f.message), (rows) {
      for (final group in rows) {
        group['items'] = (group['items'] as List? ?? const []).map((raw) {
          final item = Map<String, dynamic>.from(raw as Map);
          item['selected'] = false;
          item['qty_return'] = 0.0;
          return item;
        }).toList();
      }
      setState(() {
        _groups = rows;
        _group = rows.isNotEmpty ? rows.first : null;
      });
    });
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_purchase == null || _group == null) {
      AppToast.error(context, 'Pilih pembelian dan lokasi retur');
      return;
    }
    final selectedItems = _availableItems
        .where((item) => item['selected'] == true)
        .toList();
    final invalidItem = selectedItems.cast<Map<String, dynamic>?>().firstWhere((
      item,
    ) {
      final qty = (item?['qty_return'] as num?)?.toDouble() ?? 0;
      final max = (item?['available_qty'] as num?)?.toDouble() ?? 0;
      return qty <= 0 || qty > max;
    }, orElse: () => null);
    if (invalidItem != null) {
      AppToast.error(
        context,
        'Jumlah ${invalidItem['nama_inventaris']} harus lebih dari 0 dan maksimal ${invalidItem['available_qty']} ${invalidItem['unit']}',
      );
      return;
    }
    final selected = selectedItems
        .where(
          (item) =>
              item['selected'] == true && (item['qty_return'] as num? ?? 0) > 0,
        )
        .toList();
    if (selected.isEmpty) {
      AppToast.error(
        context,
        'Pilih minimal satu barang dan masukkan jumlah retur',
      );
      return;
    }
    final location = Map<String, dynamic>.from(_group!['lokasi'] as Map);
    setState(() => _loading = true);
    final input = {
      'purchase_id': _purchase!['_id'],
      'tanggal_return': DateTime.now().toIso8601String(),
      'lokasi': {
        'cabang_id': location['cabang_id'],
        'cabang_nama': location['cabang_nama'],
        'gedung_kode': location['gedung_kode'],
        'gedung_nama': location['gedung_nama'],
        'ruangan_kode': location['ruangan_kode'],
        'ruangan_nama': location['ruangan_nama'],
        'rak_nama': location['rak_nama'],
      },
      'return_reason': _reason,
      'return_method': _method,
      'catatan': _notes.text.trim(),
      'items': selected.map((item) {
        final qty = (item['qty_return'] as num).toDouble();
        return {
          'purchase_item_id': item['purchase_item_id'],
          'nama_inventaris': item['nama_inventaris'],
          'qty_return': qty,
          'no_batch': item['no_batch'],
          'alasan': _reason,
        };
      }).toList(),
    };
    final created = await _repository.createReturn(input);
    if (!mounted) return;
    await created.fold((f) async => AppToast.error(context, f.message), (
      data,
    ) async {
      if (_submitApproval) {
        final submitted = await _repository.submit(data['_id'].toString());
        if (!mounted) return;
        var submitSucceeded = false;
        submitted.fold(
          (f) {
            AppToast.error(
              context,
              'Draft tersimpan, tetapi gagal dikirim: ${f.message}',
            );
          },
          (_) {
            submitSucceeded = true;
            AppToast.success(
              context,
              'Retur dibuat dan dikirim untuk persetujuan',
            );
          },
        );
        if (!submitSucceeded) {
          if (mounted) setState(() => _loading = false);
          return;
        }
      } else {
        AppToast.success(context, 'Draft retur berhasil disimpan');
      }
      if (mounted) Navigator.pop(context, true);
    });
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retur ke Supplier'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('1. Cari pembelian', style: _sectionStyle),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onSubmitted: (_) => _findPurchases(),
                      decoration: const InputDecoration(
                        labelText: 'Nomor PO / supplier',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _findPurchases,
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
              if (_purchases.isNotEmpty) ...[
                const SizedBox(height: 8),
                ..._purchases.map(
                  (po) => ListTile(
                    selected:
                        po['_id'].toString() == _purchase?['_id']?.toString(),
                    leading: Icon(
                      po['_id'].toString() == _purchase?['_id']?.toString()
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: AppColors.primary,
                    ),
                    title: Text('${po['no_po']} — ${po['supplier_name']}'),
                    subtitle: Text(_money(po['grand_total'])),
                    onTap: () => _selectPurchase(po),
                  ),
                ),
              ],
              if (_purchase != null) ...[
                const Divider(height: 28),
                const Text('2. Lokasi dan barang', style: _sectionStyle),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _group?['lokasi']?['label']?.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Lokasi stok',
                    border: OutlineInputBorder(),
                  ),
                  items: _groups
                      .map(
                        (group) => DropdownMenuItem(
                          value: group['lokasi']?['label']?.toString(),
                          child: Text(
                            group['lokasi']?['label']?.toString() ?? '-',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(
                    () => _group = _groups.firstWhere(
                      (group) => group['lokasi']?['label']?.toString() == value,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_availableItems.isEmpty)
                  const Text('Tidak ada barang yang masih dapat diretur.'),
                ..._availableItems.map(
                  (item) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: item['selected'] == true,
                            title: Text(
                              item['nama_inventaris']?.toString() ?? '-',
                            ),
                            subtitle: Text(
                              'Tersedia: ${item['available_qty']} ${item['unit']} • ${_money(item['harga_beli'])}',
                            ),
                            onChanged: (value) => setState(
                              () => item['selected'] = value == true,
                            ),
                          ),
                          if (item['selected'] == true)
                            TextFormField(
                              initialValue: (item['qty_return'] as num? ?? 0)
                                  .toString(),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: 'Jumlah retur (${item['unit']})',
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                final qty =
                                    double.tryParse(
                                      value.replaceAll(',', '.'),
                                    ) ??
                                    0;
                                item['qty_return'] = qty;
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 28),
                const Text('3. Alasan dan penyelesaian', style: _sectionStyle),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _reason,
                  decoration: const InputDecoration(
                    labelText: 'Alasan retur',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'barang_rusak',
                      child: Text('Barang rusak'),
                    ),
                    DropdownMenuItem(
                      value: 'kualitas_tidak_sesuai',
                      child: Text('Kualitas tidak sesuai'),
                    ),
                    DropdownMenuItem(
                      value: 'salah_kirim',
                      child: Text('Salah kirim'),
                    ),
                    DropdownMenuItem(
                      value: 'kelebihan_qty',
                      child: Text('Kelebihan jumlah'),
                    ),
                    DropdownMenuItem(
                      value: 'kadaluarsa',
                      child: Text('Kedaluwarsa'),
                    ),
                    DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
                  ],
                  onChanged: (value) =>
                      setState(() => _reason = value ?? _reason),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  decoration: const InputDecoration(
                    labelText: 'Penyelesaian',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'credit_note',
                      child: Text('Kurangi utang / kredit supplier'),
                    ),
                    DropdownMenuItem(
                      value: 'refund',
                      child: Text('Refund uang'),
                    ),
                    DropdownMenuItem(
                      value: 'replacement',
                      child: Text('Penggantian barang'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _method = value ?? _method),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (widget.canSubmit)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _submitApproval,
                    title: const Text('Langsung kirim untuk persetujuan'),
                    onChanged: (value) =>
                        setState(() => _submitApproval = value),
                  )
                else
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.info_outline),
                    title: Text('Retur akan disimpan sebagai draft'),
                    subtitle: Text(
                      'Akun ini tidak memiliki izin mengirim persetujuan.',
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: const Icon(Icons.save),
                  label: Text(
                    _submitApproval ? 'Simpan & Kirim' : 'Simpan Draft',
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x55FFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _PurchaseReturnDetailPage extends StatefulWidget {
  final String id;
  final Map<String, dynamic> permissions;
  const _PurchaseReturnDetailPage({
    required this.id,
    required this.permissions,
  });
  @override
  State<_PurchaseReturnDetailPage> createState() =>
      _PurchaseReturnDetailPageState();
}

class _PurchaseReturnDetailPageState extends State<_PurchaseReturnDetailPage> {
  final _repository = sl<PurchaseReturnRepository>();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _repository.getOne(widget.id);
    if (!mounted) return;
    result.fold(
      (f) => AppToast.error(context, f.message),
      (data) => setState(() => _data = data),
    );
    setState(() => _loading = false);
  }

  Future<void> _action(String action) async {
    String value = '';
    if (action == 'reject') {
      final controller = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tolak retur'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Alasan penolakan',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tolak'),
            ),
          ],
        ),
      );
      value = controller.text.trim();
      controller.dispose();
      if (confirmed != true || value.length < 3) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            action == 'process'
                ? 'Proses retur?'
                : action == 'approve'
                ? 'Setujui retur?'
                : 'Kirim untuk persetujuan?',
          ),
          content: Text(
            action == 'process'
                ? 'Stok dan konsekuensi finansial akan diproses oleh server.'
                : 'Pastikan data retur sudah benar.',
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
      if (confirmed != true) return;
    }
    setState(() => _loading = true);
    final result = switch (action) {
      'submit' => await _repository.submit(widget.id),
      'approve' => await _repository.approve(widget.id),
      'reject' => await _repository.reject(widget.id, value),
      'process' => await _repository.process(widget.id),
      _ => await _repository.retryJournal(widget.id),
    };
    if (!mounted) return;
    result.fold(
      (f) {
        AppToast.error(context, f.message);
        setState(() => _loading = false);
      },
      (_) {
        _changed = true;
        AppToast.success(context, 'Status retur berhasil diperbarui');
        _load();
      },
    );
  }

  Future<void> _editMetadata() async {
    final data = _data;
    if (data == null) return;
    var reason = data['return_reason']?.toString() ?? 'barang_rusak';
    var method = data['return_method']?.toString() ?? 'credit_note';
    final notes = TextEditingController(
      text: data['catatan']?.toString() ?? '',
    );
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ubah retur pembelian'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  decoration: const InputDecoration(labelText: 'Alasan'),
                  items: const [
                    DropdownMenuItem(
                      value: 'barang_rusak',
                      child: Text('Barang rusak'),
                    ),
                    DropdownMenuItem(
                      value: 'kualitas_tidak_sesuai',
                      child: Text('Kualitas tidak sesuai'),
                    ),
                    DropdownMenuItem(
                      value: 'salah_kirim',
                      child: Text('Salah kirim'),
                    ),
                    DropdownMenuItem(
                      value: 'kelebihan_qty',
                      child: Text('Kelebihan jumlah'),
                    ),
                    DropdownMenuItem(
                      value: 'kadaluarsa',
                      child: Text('Kedaluwarsa'),
                    ),
                    DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => reason = value ?? reason),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  decoration: const InputDecoration(labelText: 'Penyelesaian'),
                  items: const [
                    DropdownMenuItem(
                      value: 'credit_note',
                      child: Text('Kurangi utang / kredit'),
                    ),
                    DropdownMenuItem(
                      value: 'refund',
                      child: Text('Refund uang'),
                    ),
                    DropdownMenuItem(
                      value: 'replacement',
                      child: Text('Penggantian barang'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => method = value ?? method),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notes,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Catatan'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    final noteValue = notes.text.trim();
    notes.dispose();
    if (confirmed != true) return;
    setState(() => _loading = true);
    final result = await _repository.update(widget.id, {
      'return_reason': reason,
      'return_method': method,
      'catatan': noteValue,
    });
    if (!mounted) return;
    result.fold(
      (failure) {
        AppToast.error(context, failure.message);
        setState(() => _loading = false);
      },
      (_) {
        _changed = true;
        AppToast.success(context, 'Retur berhasil diperbarui');
        _load();
      },
    );
  }

  Future<void> _deleteReturn() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus retur pembelian?'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Alasan penghapusan'),
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
    final reason = controller.text.trim();
    controller.dispose();
    if (confirmed != true) return;
    setState(() => _loading = true);
    final result = await _repository.delete(widget.id, reason);
    if (!mounted) return;
    result.fold(
      (failure) {
        AppToast.error(context, failure.message);
        setState(() => _loading = false);
      },
      (_) {
        AppToast.success(context, 'Retur berhasil dihapus');
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {},
      child: Scaffold(
        appBar: AppBar(
          title: Text(data?['no_return']?.toString() ?? 'Detail Retur'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
        ),
        body: _loading && data == null
            ? const Center(child: CircularProgressIndicator())
            : data == null
            ? const Center(child: Text('Data tidak ditemukan'))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    data['supplier_name']?.toString() ?? '-',
                                    style: _sectionStyle,
                                  ),
                                ),
                                _StatusChip(
                                  data['approval_status']?.toString() ?? '',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('PO: ${data['no_po'] ?? '-'}'),
                            Text('Tanggal: ${_date(data['tanggal_return'])}'),
                            Text(
                              'Lokasi: ${data['lokasi']?['label'] ?? data['lokasi_cabang_nama'] ?? '-'}',
                            ),
                            Text(
                              'Alasan: ${data['return_reason_label'] ?? data['return_reason'] ?? '-'}',
                            ),
                            Text(
                              'Penyelesaian: ${data['return_method_label'] ?? data['return_method'] ?? '-'}',
                            ),
                            if ((data['catatan']?.toString() ?? '').isNotEmpty)
                              Text('Catatan: ${data['catatan']}'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Barang diretur', style: _sectionStyle),
                    ...(data['items'] as List? ?? const []).map((raw) {
                      final item = raw as Map;
                      return Card(
                        child: ListTile(
                          title: Text(
                            item['nama_inventaris']?.toString() ?? '-',
                          ),
                          subtitle: Text(
                            '${item['qty_return']} ${item['unit']} • ${_money(item['harga_beli'])}',
                          ),
                          trailing: Text(
                            _money(item['subtotal']),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'Total: ${_money(data['grand_total_return'])}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if ((data['rejected_reason']?.toString() ?? '').isNotEmpty)
                      _Notice(
                        'Ditolak: ${data['rejected_reason']}',
                        Colors.red,
                      ),
                    if ((data['journal_error']?.toString() ?? '').isNotEmpty)
                      _Notice(
                        'Jurnal gagal: ${data['journal_error']}',
                        Colors.orange,
                      ),
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, runSpacing: 8, children: _actions(data)),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  List<Widget> _actions(Map<String, dynamic> data) {
    final status = data['approval_status']?.toString();
    bool can(String key) => widget.permissions[key] == true;
    return [
      if ((status == 'draft' || status == 'rejected') &&
          can('update_purchase_returns'))
        OutlinedButton.icon(
          onPressed: _loading ? null : _editMetadata,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Ubah'),
        ),
      if ((status == 'draft' || status == 'rejected') &&
          can('submit_purchase_returns'))
        FilledButton.icon(
          onPressed: _loading ? null : () => _action('submit'),
          icon: const Icon(Icons.send),
          label: const Text('Kirim Persetujuan'),
        ),
      if (status == 'pending_approval' && can('approve_purchase_returns'))
        FilledButton.icon(
          onPressed: _loading ? null : () => _action('approve'),
          icon: const Icon(Icons.check),
          label: const Text('Setujui'),
        ),
      if (status == 'pending_approval' && can('reject_purchase_returns'))
        OutlinedButton.icon(
          onPressed: _loading ? null : () => _action('reject'),
          icon: const Icon(Icons.close),
          label: const Text('Tolak'),
        ),
      if (status == 'approved' && can('process_purchase_returns'))
        FilledButton.icon(
          onPressed: _loading ? null : () => _action('process'),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Proses Retur'),
        ),
      if (data['journal_status'] == 'failed' && can('process_purchase_returns'))
        OutlinedButton.icon(
          onPressed: _loading ? null : () => _action('retry'),
          icon: const Icon(Icons.refresh),
          label: const Text('Coba Jurnal Lagi'),
        ),
      if ((status == 'draft' || status == 'rejected') &&
          can('delete_purchase_returns'))
        OutlinedButton.icon(
          onPressed: _loading ? null : _deleteReturn,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Hapus'),
        ),
    ];
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _statusColor(status).withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      _statusLabel(status),
      style: TextStyle(
        color: _statusColor(status),
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class _Notice extends StatelessWidget {
  final String text;
  final Color color;
  const _Notice(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(text, style: TextStyle(color: color)),
  );
}

const _sectionStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
String _money(dynamic value) => NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
).format((value as num?) ?? num.tryParse(value?.toString() ?? '') ?? 0);
String _date(dynamic value) {
  final raw = value?.toString() ?? '';
  final date = DateTime.tryParse(raw);
  return date == null
      ? raw
      : DateFormat('dd MMM yyyy', 'id_ID').format(date.toLocal());
}

Color _statusColor(String status) => switch (status) {
  'draft' => Colors.blueGrey,
  'pending_approval' => Colors.orange,
  'approved' => Colors.blue,
  'rejected' => Colors.red,
  'processed' => Colors.green,
  _ => Colors.grey,
};
String _statusLabel(String status) => switch (status) {
  'draft' => 'Draft',
  'pending_approval' => 'Menunggu',
  'approved' => 'Disetujui',
  'rejected' => 'Ditolak',
  'processed' => 'Diproses',
  _ => status,
};
