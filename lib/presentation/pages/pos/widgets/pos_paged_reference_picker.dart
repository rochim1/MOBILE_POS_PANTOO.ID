import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../domain/repositories/pos_inventory_repository.dart';

class PosPagedReferencePicker extends StatefulWidget {
  final Future<PosInventoryDocumentPage> Function(String, int) loader;
  final String Function(Map<String, dynamic>) label;
  final String placeholder;
  const PosPagedReferencePicker({
    super.key,
    required this.loader,
    required this.label,
    this.placeholder = 'Cari referensi',
  });
  @override
  State<PosPagedReferencePicker> createState() =>
      _PosPagedReferencePickerState();
}

class _PosPagedReferencePickerState extends State<PosPagedReferencePicker> {
  List<Map<String, dynamic>> items = [];
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
      setState(() {
        items = result.items;
        total = result.totalCount;
        page = target;
      });
    } catch (_) {
      if (mounted && current == version) {
        setState(() => error = 'Referensi gagal dimuat. Coba lagi.');
      }
    } finally {
      if (mounted && current == version) {
        setState(() => loading = false);
      }
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
        decoration: InputDecoration(
          labelText: widget.placeholder,
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) {
          version++;
          debounce?.cancel();
          setState(() {
            search = value;
            loading = true;
          });
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
            ? const Center(child: Text('Tidak ada referensi sesuai pencarian.'))
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final row = items[index];
                  return ListTile(
                    title: Text(
                      widget.label(row),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: loading ? null : () => Navigator.pop(context, row),
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
              'Halaman $page · $total pilihan',
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
    ],
  );
}
