import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../injections.dart';
import '../../../domain/repositories/pos_inventory_repository.dart';
import '../../widgets/app_toast.dart';

class PosPurchaseWorkspace extends StatefulWidget {
  final Map<String, dynamic> permissions;
  final Widget Function() purchaseListBuilder;

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

  @override
  Widget build(BuildContext context) => Column(
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
            widget.purchaseListBuilder(),
            _ReceivingList(
              canCancel:
                  widget.permissions['receive_inventory_purchases'] == true,
            ),
          ],
        ),
      ),
    ],
  );
}

class _ReceivingList extends StatefulWidget {
  final bool canCancel;
  const _ReceivingList({required this.canCancel});

  @override
  State<_ReceivingList> createState() => _ReceivingListState();
}

class _ReceivingListState extends State<_ReceivingList> {
  final _repository = sl<PosInventoryRepository>();
  final _search = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _items = const [];
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
    if (!mounted) return;
    result.fold((failure) => AppToast.error(context, failure.message), (data) {
      _items = data.items;
      _total = data.totalCount;
      _page = target;
    });
    setState(() => _loading = false);
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
        else if (_items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 72),
            child: Center(child: Text('Belum ada penerimaan barang')),
          )
        else
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
