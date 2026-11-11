import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../domain/repositories/pos_repository.dart';

class PosCatalogCategoryPicker extends StatefulWidget {
  final Future<PosCatalogCategoryPage> Function(String search, int page) load;
  const PosCatalogCategoryPicker({super.key, required this.load});
  @override
  State<PosCatalogCategoryPicker> createState() =>
      _PosCatalogCategoryPickerState();
}

class _PosCatalogCategoryPickerState extends State<PosCatalogCategoryPicker> {
  final _search = TextEditingController();
  Timer? _debounce;
  int _version = 0, _page = 1, _total = 0;
  bool _loading = true;
  String _error = '';
  List<String> _items = const [];
  static const special = [
    'Semua Kategori',
    'Favorit',
    'Produk Paket',
    'Produk Layanan',
    'Promo',
    'Deposit',
  ];
  @override
  void initState() {
    super.initState();
    _load(1);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load(int page) async {
    final version = ++_version;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final result = await widget.load(_search.text, page);
      if (!mounted || version != _version) return;
      setState(() {
        _items = result.items;
        _total = result.total;
        _page = page;
      });
    } catch (_) {
      if (mounted && version == _version) {
        setState(
          () =>
              _error = 'Kategori gagal dimuat. Periksa koneksi lalu coba lagi.',
        );
      }
    } finally {
      if (mounted && version == _version) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: SizedBox(
      width: 420,
      height: 540,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: PosText(
                    'Pilih kategori',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: ('Tutup').tr(context),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            TextField(
              controller: _search,
              decoration:  InputDecoration(
                labelText: ('Cari kategori').tr(context),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) {
                ++_version;
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 300),
                  () => _load(1),
                );
              },
            ),
            if (_loading) const LinearProgressIndicator(),
            if (_error.isNotEmpty)
              TextButton(onPressed: () => _load(_page), child: PosText(_error)),
            Expanded(
              child: ListView(
                children: [
                  if (_search.text.isEmpty)
                    ...special.map(
                      (name) => ListTile(
                        dense: true,
                        title: Text(name),
                        onTap: () => Navigator.pop(context, name),
                      ),
                    ),
                  ..._items
                      .where((name) => !special.contains(name))
                      .map(
                        (name) => ListTile(
                          dense: true,
                          title: Text(name),
                          onTap: () => Navigator.pop(context, name),
                        ),
                      ),
                  if (!_loading &&
                      _items.isEmpty &&
                      _search.text.isNotEmpty &&
                      _error.isEmpty)
                    const ListTile(title: PosText('Kategori tidak ditemukan')),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  tooltip: ('Kategori sebelumnya').tr(context),
                  onPressed: _page <= 1 || _loading
                      ? null
                      : () => _load(_page - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    posLocale(context).pos6a42159c5abb((_page).toString(), (_total).toString()),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  tooltip: ('Kategori berikutnya').tr(context),
                  onPressed: _page * 20 >= _total || _loading
                      ? null
                      : () => _load(_page + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
