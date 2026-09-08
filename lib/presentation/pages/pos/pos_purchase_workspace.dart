import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../injections.dart';
import '../../../domain/repositories/pos_inventory_repository.dart';
import '../../widgets/app_toast.dart';
import 'pos_purchase_receiving_page.dart';
import 'utils/pos_purchase_progress.dart';

class PosPurchaseWorkspace extends StatefulWidget {
  final Map<String, dynamic> permissions;
  final Widget Function(ValueChanged<Map<String, dynamic>> onReceive)
  purchaseListBuilder;

  const PosPurchaseWorkspace({
    super.key,
    required this.permissions,
    required this.purchaseListBuilder,
  });

  @override
  State<PosPurchaseWorkspace> createState() => _PosPurchaseWorkspaceState();
}

class _PosPurchaseWorkspaceState extends State<PosPurchaseWorkspace> {
  int _tab = 0;
  Map<String, dynamic>? _activeReceiving;

  @override
  Widget build(BuildContext context) {
    final receiving = _activeReceiving;
    if (receiving != null) {
      return PosPurchaseReceivingPage(
        purchase: receiving,
        embedded: true,
        onFinished: () => setState(() => _activeReceiving = null),
      );
    }
    return Column(
      children: [
        Material(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  icon: Icon(Icons.description_outlined),
                  label: Text('Purchase Order'),
                ),
                ButtonSegment(
                  value: 1,
                  icon: Icon(Icons.inventory_outlined),
                  label: Text('Penerimaan'),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (value) => setState(() => _tab = value.first),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _tab,
            children: [
              widget.purchaseListBuilder(
                (purchase) => setState(() => _activeReceiving = purchase),
              ),
              _ReceivingList(
                canReceive:
                    widget.permissions['receive_inventory_purchases'] == true,
                onReceive: (purchase) =>
                    setState(() => _activeReceiving = purchase),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReceivingList extends StatefulWidget {
  final bool canReceive;
  final ValueChanged<Map<String, dynamic>> onReceive;
  const _ReceivingList({required this.canReceive, required this.onReceive});

  @override
  State<_ReceivingList> createState() => _ReceivingListState();
}

class _ReceivingListState extends State<_ReceivingList> {
  final _repository = sl<PosInventoryRepository>();
  final _search = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _items = const [];
  List<Map<String, dynamic>> _receivablePurchases = const [];
  bool _loading = true;
  String _status = '';
  int _page = 1;
  int _total = 0;

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

  Future<void> _load({int? page}) async {
    final target = page ?? _page;
    setState(() => _loading = true);
    final result = await _repository.getGlobalPurchaseReceivings(
      search: _search.text,
      status: _status,
      page: target,
    );
    final purchasesResult = widget.canReceive
        ? await _repository.getDocuments(
            type: PosInventoryDocumentType.purchase,
            limit: 100,
          )
        : null;
    if (!mounted) return;
    result.fold((failure) => AppToast.error(context, failure.message), (data) {
      _items = data.items;
      _total = data.totalCount;
      _page = target;
    });
    purchasesResult?.fold(
      (failure) => AppToast.error(
        context,
        'Daftar PO yang dapat diterima gagal dimuat: ${failure.message}',
      ),
      (data) => _receivablePurchases = data.items.where((purchase) {
        final status = PosPurchaseProgress.effectiveStatus(purchase);
        return const {'approved', 'partially_received'}.contains(status) &&
            PosPurchaseProgress.hasRemaining(purchase);
      }).toList(),
    );
    setState(() => _loading = false);
  }

  Future<void> _receive(Map<String, dynamic> purchase) async {
    widget.onReceive(purchase);
  }

  String _number(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse('$value') ?? 0;
    return number == number.roundToDouble()
        ? number.toInt().toString()
        : number
              .toStringAsFixed(2)
              .replaceFirst(RegExp(r'0+$'), '')
              .replaceFirst(RegExp(r'\.$'), '');
  }

  void _searchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _load(page: 1));
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '-';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  Future<void> _detail(Map<String, dynamic> receipt) async {
    final rows = (receipt['items'] as List? ?? const []).whereType<Map>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .7,
        maxChildSize: .92,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              receipt['no_grn']?.toString() ?? 'Penerimaan',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(
              '${receipt['no_po'] ?? '-'} · ${receipt['supplier_name'] ?? '-'}',
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(receipt['status']?.toString() ?? '-')),
                Chip(label: Text(_date(receipt['tanggal_terima']))),
                if ((receipt['no_surat_jalan']?.toString() ?? '').isNotEmpty)
                  Chip(label: Text('SJ ${receipt['no_surat_jalan']}')),
              ],
            ),
            const Divider(height: 28),
            const Text(
              'Barang diterima',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            ...rows.map((raw) {
              final item = Map<String, dynamic>.from(raw);
              final allocations = (item['allocations'] as List? ?? const [])
                  .whereType<Map>();
              final locations = allocations
                  .map(
                    (allocation) =>
                        [
                              allocation['lokasi_cabang_nama'],
                              allocation['lokasi_gedung_nama'],
                              allocation['lokasi_ruangan_nama'],
                              allocation['lokasi_rak_nama'],
                            ]
                            .map((v) => v?.toString().trim() ?? '')
                            .where((v) => v.isNotEmpty)
                            .join(' / '),
                  )
                  .where((v) => v.isNotEmpty)
                  .join('\n');
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item['nama_inventaris']?.toString() ?? '-'),
                subtitle: Text(
                  [
                    if (locations.isNotEmpty) locations,
                    if ((item['no_batch']?.toString() ?? '').isNotEmpty)
                      'Batch ${item['no_batch']}',
                  ].join('\n'),
                ),
                trailing: Text(
                  '${item['qty_received'] ?? 0} ${item['unit'] ?? ''}',
                ),
              );
            }),
            if ((receipt['catatan']?.toString() ?? '').isNotEmpty) ...[
              const Divider(),
              Text('Catatan: ${receipt['catatan']}'),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () => _load(page: 1),
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: _searchChanged,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Cari GRN, PO, atau supplier',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            DropdownButton<String>(
              value: _status,
              items: const [
                DropdownMenuItem(value: '', child: Text('Semua')),
                DropdownMenuItem(value: 'completed', child: Text('Selesai')),
                DropdownMenuItem(value: 'cancelled', child: Text('Dibatalkan')),
              ],
              onChanged: (value) {
                setState(() => _status = value ?? '');
                _load(page: 1);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loading)
          const LinearProgressIndicator()
        else ...[
          if (_receivablePurchases.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Menunggu penerimaan',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8),
            ..._receivablePurchases.map((purchase) {
              final rows = (purchase['items'] as List? ?? const [])
                  .whereType<Map>();
              final remainingLines = rows
                  .where(
                    (row) =>
                        PosPurchaseProgress.remainingInOrderedUnit(row) >
                        .000001,
                  )
                  .length;
              final progress = PosPurchaseProgress.completionRatio(purchase);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              purchase['no_po']?.toString() ?? 'Purchase Order',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text('${(progress * 100).round()}% diterima'),
                        ],
                      ),
                      Text(
                        '${purchase['supplier_name'] ?? '-'} · $remainingLines jenis barang masih tersisa',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 10),
                      ...rows
                          .where(
                            (row) =>
                                PosPurchaseProgress.remainingInOrderedUnit(
                                  row,
                                ) >
                                .000001,
                          )
                          .map(
                            (row) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      row['nama_inventaris']?.toString() ?? '-',
                                    ),
                                  ),
                                  Text(
                                    'Sisa ${_number(PosPurchaseProgress.remainingInOrderedUnit(row))} ${row['unit'] ?? ''}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          onPressed: () => _receive(purchase),
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: Text(
                            progress > 0 ? 'Terima Sisa' : 'Terima Barang',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 18),
          ],
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Riwayat penerimaan',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (!_loading && _items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 36),
            child: Center(child: Text('Belum ada penerimaan barang')),
          )
        else if (!_loading)
          ..._items.map(
            (receipt) => Card(
              child: ListTile(
                onTap: () => _detail(receipt),
                leading: const CircleAvatar(
                  child: Icon(Icons.inventory_outlined),
                ),
                title: Text(receipt['no_grn']?.toString() ?? 'Penerimaan'),
                subtitle: Text(
                  '${receipt['no_po'] ?? '-'} · ${receipt['supplier_name'] ?? '-'}\n${_date(receipt['tanggal_terima'])}',
                ),
                isThreeLine: true,
                trailing: Chip(
                  label: Text(
                    receipt['status']?.toString() == 'cancelled'
                        ? 'Dibatalkan'
                        : 'Selesai',
                  ),
                ),
              ),
            ),
          ),
        if (_total > 20)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _page > 1 ? () => _load(page: _page - 1) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('Halaman $_page'),
              IconButton(
                onPressed: _page * 20 < _total
                    ? () => _load(page: _page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
    ),
  );
}
