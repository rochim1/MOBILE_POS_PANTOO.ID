import 'package:flutter/material.dart';

import '../../../../injections.dart';
import '../../../core/_core.dart';
import '../../../domain/repositories/pos_inventory_repository.dart';
import '../../widgets/app_toast.dart';

class PosPurchaseReceivingPage extends StatefulWidget {
  final Map<String, dynamic> purchase;
  const PosPurchaseReceivingPage({super.key, required this.purchase});

  @override
  State<PosPurchaseReceivingPage> createState() =>
      _PosPurchaseReceivingPageState();
}

class _PosPurchaseReceivingPageState extends State<PosPurchaseReceivingPage> {
  final _repository = sl<PosInventoryRepository>();
  final _deliveryNote = TextEditingController();
  PosInventoryLookups? _lookups;
  String _warehouseId = '';
  bool _loading = true;
  late final List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items = (widget.purchase['items'] as List? ?? const [])
        .map((raw) {
          final item = Map<String, dynamic>.from(raw as Map);
          final ordered = (item['qty_ordered'] as num? ?? 0).toDouble();
          final received = (item['qty_received'] as num? ?? 0).toDouble();
          item['remaining'] = (ordered - received).clamp(0, double.infinity);
          item['receive_qty'] = (ordered - received).clamp(0, double.infinity);
          return item;
        })
        .where((item) => (item['remaining'] as num) > 0)
        .toList();
    _load();
  }

  @override
  void dispose() {
    _deliveryNote.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _repository.getLookups();
    if (!mounted) return;
    result.fold((failure) => AppToast.error(context, failure.message), (data) {
      _lookups = data;
      _warehouseId = data.activeWarehouseId;
    });
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final warehouse = _lookups?.warehouses
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (item) => item?['_id']?.toString() == _warehouseId,
          orElse: () => null,
        );
    final invalid = _items.cast<Map<String, dynamic>?>().firstWhere((item) {
      final qty = (item?['receive_qty'] as num? ?? 0).toDouble();
      return qty < 0 || qty > (item?['remaining'] as num).toDouble();
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
    setState(() => _loading = true);
    final result = await _repository.receivePurchase({
      'purchase_id': widget.purchase['_id'],
      'tanggal_terima': DateTime.now().toIso8601String().split('T').first,
      'no_surat_jalan': _deliveryNote.text.trim(),
      'items': selected.map((item) {
        final qty = item['receive_qty'];
        return {
          'purchase_item_id': item['_id'],
          'inventaris_id': item['inventaris_id'],
          'nama_inventaris': item['nama_inventaris'],
          'qty_received': qty,
          'allocations': [
            {
              'lokasi_cabang_id': warehouse['_id'],
              'lokasi_cabang_nama': warehouse['nama_cabang'],
              'qty': qty,
            },
          ],
        };
      }).toList(),
    });
    if (!mounted) return;
    result.fold(
      (failure) {
        AppToast.error(context, failure.message);
        setState(() => _loading = false);
      },
      (_) {
        AppToast.success(context, 'Penerimaan pembelian berhasil dicatat');
        Navigator.pop(context, true);
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Terima ${widget.purchase['no_po'] ?? 'Pembelian'}'),
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
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _warehouseId.isEmpty ? null : _warehouseId,
                    decoration: const InputDecoration(
                      labelText: 'Lokasi penerimaan',
                      border: OutlineInputBorder(),
                    ),
                    items: (_lookups?.warehouses ?? const [])
                        .where((item) => item['is_receiving_location'] != false)
                        .map(
                          (item) => DropdownMenuItem(
                            value: item['_id'].toString(),
                            child: Text(item['nama_cabang'].toString()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _warehouseId = value ?? ''),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _deliveryNote,
                    decoration: const InputDecoration(
                      labelText: 'Nomor surat jalan (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Barang diterima',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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
                              'Belum diterima: ${item['remaining']} ${item['unit'] ?? ''}',
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: item['receive_qty'].toString(),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Jumlah diterima',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) => item['receive_qty'] =
                                  double.tryParse(value.replaceAll(',', '.')) ??
                                  0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loading || _items.isEmpty ? null : _save,
                    icon: const Icon(Icons.inventory),
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
          ),
  );
}
