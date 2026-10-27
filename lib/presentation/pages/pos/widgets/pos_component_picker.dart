import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../domain/models/pos_product.dart';
import '../../../../domain/repositories/pos_product_management_repository.dart';

class PosComponentPicker extends StatefulWidget {
  final Set<String> selected;
  final Future<PosComponentPage> Function(String, int) loader;
  final void Function(List<PosProduct>) onRecords;
  const PosComponentPicker({
    super.key,
    required this.selected,
    required this.loader,
    required this.onRecords,
  });
  @override
  State<PosComponentPicker> createState() => _PosComponentPickerState();
}

class _PosComponentPickerState extends State<PosComponentPicker> {
  late final Set<String> selected = Set.from(widget.selected);
  List<PosProduct> items = [];
  int page = 1, total = 0, version = 0;
  String search = '', error = '';
  bool loading = true;
  Timer? debounce;
  @override
  void initState() {
    super.initState();
    load(1);
  }

  Future<void> load(int target) async {
    final current = ++version;
    setState(() {
      loading = true;
      error = '';
    });
    try {
      final result = await widget.loader(search, target);
      if (!mounted || current != version) return;
      widget.onRecords(result.items);
      setState(() {
        items = result.items;
        total = result.total;
        page = target;
      });
    } catch (_) {
      if (mounted && current == version) {
        setState(() => error = 'Komponen gagal dimuat. Coba lagi.');
      }
    } finally {
      if (mounted && current == version) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    version++;
    debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextField(
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Cari bahan atau komponen',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          search = value;
          version++;
          debounce?.cancel();
          debounce = Timer(const Duration(milliseconds: 300), () => load(1));
        },
      ),
      if (loading) const LinearProgressIndicator(),
      if (error.isNotEmpty)
        Row(
          children: [
            Expanded(child: Text(error)),
            TextButton(
              onPressed: () => load(page),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      Expanded(
        child: items.isEmpty && !loading
            ? const Center(child: Text('Komponen stok tidak ditemukan.'))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final item = items[index];
                  return CheckboxListTile(
                    value: selected.contains(item.id),
                    title: Text(item.name),
                    subtitle: Text('${item.code} · ${item.saleUnit}'),
                    onChanged: (value) => setState(() {
                      if (value == true) {
                        selected.add(item.id);
                      } else {
                        selected.remove(item.id);
                      }
                    }),
                  );
                },
              ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Halaman sebelumnya',
            onPressed: !loading && page > 1 ? () => load(page - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Flexible(
            child: Text(
              'Halaman $page · $total komponen',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Halaman berikutnya',
            onPressed: !loading && page * 20 < total
                ? () => load(page + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, selected),
            child: Text('Terapkan (${selected.length})'),
          ),
        ],
      ),
    ],
  );
}
