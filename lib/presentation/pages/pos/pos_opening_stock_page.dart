import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/network/graphql_client_provider.dart';
import '../../../core/utils/rupiah_input_formatter.dart';
import '../../../domain/models/pos_stock.dart';
import '../../../domain/repositories/pos_opening_stock_repository.dart';
import '../../../domain/repositories/pos_stock_repository.dart';
import '../../../injections.dart';
import '../../bloc/pos/pos_bloc.dart';
import 'widgets/pos_transfer_location_fields.dart';

/// Opening stock is a document, not a manual edit of master stock or opname.
class PosOpeningStockPage extends StatefulWidget {
  final String? initialProductId;
  final String? initialLocationId;
  final Future<void> Function()? onComplete;
  final PosOpeningStockRepository? repository;
  const PosOpeningStockPage({
    super.key,
    this.initialProductId,
    this.initialLocationId,
    this.onComplete,
    this.repository,
  });
  @override
  State<PosOpeningStockPage> createState() => _PosOpeningStockPageState();
}

class _PosOpeningStockPageState extends State<PosOpeningStockPage> {
  late final PosOpeningStockRepository _repository;
  final _quantity = TextEditingController(text: '1');
  final _cost = TextEditingController(text: '0');
  final _date = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );
  final _acquired = TextEditingController();
  final _batch = TextEditingController();
  final _expiry = TextEditingController();
  final _serials = TextEditingController();
  List<PosStock> _products = [];
  List<Map<String, dynamic>> _locations = [];
  Map<String, dynamic>? _item;
  Map<String, dynamic> _locationPath = {};
  String? _productId, _locationId;
  String _unit = '', _scope = '';
  String? _error;
  bool _loading = true,
      _busy = false,
      _saved = false,
      _initialConsumed = false,
      _selecting = false;
  int _selectionVersion = 0;
  bool get _pending => _repository.draft.pending != null;
  List<Map<String, dynamic>> get _units =>
      [
        {'unit': _item?['base_unit'] ?? _item?['unit'] ?? 'unit', 'factor': 1},
        ...(_item?['unit_conversions'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e)),
      ].fold(
        <Map<String, dynamic>>[],
        (rows, row) =>
            rows.any((r) => r['unit'] == row['unit']) ? rows : [...rows, row],
      );

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        PosOpeningStockRepository(sl<GraphQLClientProvider>());
    _scope = _repository.provider.subscriptionScope;
    if ((context.read<PosBloc>().state.runtimeConfig['permissions']
            as Map?)?['initialize_stock'] ==
        true) {
      _load();
    } else {
      _loading = false;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final state = context.read<PosBloc>().state;
      final pending = _repository.draft.pending;
      final row = (pending?['items'] as List?)?.first as Map?;
      _productId =
          row?['inventaris_id']?.toString() ??
          (_initialConsumed ? null : widget.initialProductId);
      _locationId =
          row?['lokasi_cabang_id']?.toString() ??
          widget.initialLocationId ??
          state.checkoutStore?.branchId;
      if (_locationId?.isEmpty != false) {
        _locationId =
            (state.runtimeConfig['initial_setup'] as Map?)?['stock_location_id']
                ?.toString();
      }
      final repository = sl<PosStockRepository>();
      final locations = await repository.getStockLocations();
      _locations = locations.fold((f) => throw StateError(f.message), (r) => r);
      if (!_locations.any((r) => r['_id'] == _locationId)) _locationId = null;
      _locationPath = {
        'cabang_id': _locationId ?? '',
        for (final key in ['gedung_kode', 'ruangan_kode', 'rak_nama'])
          key: row?['lokasi_$key'] ?? '',
      };
      final products = await repository.getStockPage(
        limit: 100,
        locationId: _locationId,
      );
      _products = products.fold(
        (f) => throw StateError(f.message),
        (r) => r.items.where((p) => p.canRestockDirectly).toList(),
      );
      if (_productId != null) await _select(_productId!);
      if (row != null && pending != null) {
        _date.text = pending['tanggal'].toString();
        _quantity.text = row['qty'].toString();
        _cost.text = formatRupiahInput(
          num.tryParse(row['hpp'].toString()) ?? 0,
        );
        _unit =
            _item?['base_unit']?.toString() ??
            _item?['unit']?.toString() ??
            'unit';
        _batch.text = row['no_batch']?.toString() ?? '';
        _expiry.text = row['tanggal_kadaluarsa']?.toString() ?? '';
        _acquired.text = row['tanggal_perolehan']?.toString() ?? '';
        _serials.text = (row['serial_numbers'] as List? ?? const []).join('\n');
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _select(String id) async {
    final version = ++_selectionVersion;
    setState(() {
      _selecting = true;
      _item = null;
      _productId = id;
    });
    Map<String, dynamic> item;
    try {
      item = await _repository.detail(id);
    } finally {
      if (mounted && version == _selectionVersion) {
        setState(() => _selecting = false);
      }
    }
    if (!mounted || version != _selectionVersion) return;
    if (item['tracks_stock'] == false ||
        item['composition_type'] == 'bom' ||
        item['pos_product_type'] == 'package') {
      throw StateError('Pilih barang stok/komponen, bukan layanan atau paket.');
    }
    setState(() {
      _productId = id;
      _item = item;
      _cost.text = formatRupiahInput(
        num.tryParse((item['harga_beli'] ?? 0).toString()) ?? 0,
      );
      _unit =
          item['base_unit']?.toString() ?? item['unit']?.toString() ?? 'unit';
      _acquired.text = _date.text;
    });
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_scope != _repository.provider.subscriptionScope) {
      setState(() => _error = 'Operator berubah. Buka ulang saldo awal.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final pending = _repository.draft.pending;
      Map<String, dynamic> payload;
      if (pending != null) {
        payload = {...pending}..remove('request_id');
      } else {
        final qty = double.tryParse(_quantity.text.replaceAll(',', '.')) ?? 0;
        final cost = parseRupiah(_cost.text);
        if (_productId == null || _locationId == null || _item == null) {
          throw StateError('Pilih barang dan lokasi stok.');
        }
        if (!qty.isFinite || qty <= 0 || !cost.isFinite || cost < 0) {
          throw StateError(
            'Jumlah harus lebih dari nol dan biaya tidak boleh negatif.',
          );
        }
        final factor =
            (_units.firstWhere((r) => r['unit'] == _unit)['factor'] as num)
                .toDouble();
        payload = {
          'tanggal': _date.text.trim(),
          'keterangan': 'Saldo Awal Persediaan POS',
          'items': [
            {
              'inventaris_id': _productId,
              'lokasi_cabang_id': _locationId,
              for (final key in ['gedung_kode', 'ruangan_kode', 'rak_nama'])
                if (_locationPath[key]?.toString().isNotEmpty == true)
                  'lokasi_$key': _locationPath[key],
              'qty': qty * factor,
              'hpp': cost / factor,
              if (_item?['valuation_method'] == 'fifo')
                'tanggal_perolehan': _acquired.text.trim(),
              if (_batch.text.trim().isNotEmpty) 'no_batch': _batch.text.trim(),
              if (_expiry.text.trim().isNotEmpty)
                'tanggal_kadaluarsa': _expiry.text.trim(),
              if (_item?['wajib_serial_number'] == true)
                'serial_numbers': _serials.text
                    .split('\n')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
            },
          ],
        };
      }
      await _repository.submit(payload);
      if (!mounted) return;
      setState(() {
        _saved = true;
        _initialConsumed = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Stok awal tersimpan.')));
      if (widget.onComplete != null) {
        await widget.onComplete!();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _search(String value) async {
    if (_busy || _pending) return;
    final result = await sl<PosStockRepository>().getStockPage(
      search: value.trim(),
      limit: 100,
      locationId: _locationId,
    );
    if (!mounted) return;
    result.fold(
      (f) => setState(() => _error = f.message),
      (r) => setState(
        () => _products = r.items.where((p) => p.canRestockDirectly).toList(),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in [
      _quantity,
      _cost,
      _date,
      _acquired,
      _batch,
      _expiry,
      _serials,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool numeric = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: controller,
      enabled: !_busy && !_pending,
      maxLines: lines,
      inputFormatters: controller == _cost
          ? const [RupiahInputFormatter()]
          : null,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final permissions =
        context.watch<PosBloc>().state.runtimeConfig['permissions'] as Map? ??
        const {};
    if (permissions['initialize_stock'] != true) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Minta pengelola yang memiliki izin saldo awal untuk mengisi stok.',
          ),
        ),
      );
    }
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_saved) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.teal,
                size: 48,
              ),
              const Text(
                'Stok awal tersimpan. Gunakan Penerimaan untuk menambah stok berikutnya.',
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () {
                        setState(() {
                          _saved = false;
                          _item = null;
                          _productId = null;
                        });
                        _load();
                      },
                child: const Text('Isi stok awal barang lain'),
              ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Isi stok awal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Untuk barang yang sudah dimiliki sebelum memakai POS. Barang baru datang dicatat melalui Pembelian & Penerimaan. Stok paket/resep diisi pada komponennya.',
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_pending)
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Hasil sebelumnya belum pasti. Tekan Periksa & coba lagi untuk memakai permintaan yang sama, tanpa menggandakan stok.',
                  ),
                ),
              if (_item != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text('Barang: ${_item!['nama_inventaris']}'),
                ),
              if (!_pending)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TextField(
                    enabled: !_busy,
                    decoration: const InputDecoration(
                      labelText: 'Cari barang (nama / SKU)',
                      suffixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _search,
                  ),
                ),
              DropdownButtonFormField<String>(
                initialValue: _products.any((p) => p.id == _productId)
                    ? _productId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Barang stok',
                  border: OutlineInputBorder(),
                ),
                items: _products
                    .map(
                      (p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(
                          p.namaInventaris,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _busy || _pending
                    ? null
                    : (id) async {
                        if (id == null) return;
                        try {
                          await _select(id);
                        } catch (e) {
                          if (mounted) setState(() => _error = e.toString());
                        }
                      },
              ),
              const SizedBox(height: 14),
              PosTransferLocationFields(
                title: 'Stok Awal',
                warehouses: _locations,
                value: _locationPath,
                disabled: _busy || _pending,
                onChanged: (value) => setState(() {
                  _locationPath = value;
                  _locationId = value['cabang_id']?.toString();
                }),
              ),
              const SizedBox(height: 14),
              _field('Tanggal saldo awal (YYYY-MM-DD)', _date),
              if (_item != null) ...[
                DropdownButtonFormField<String>(
                  key: ValueKey('$_productId:$_unit'),
                  initialValue: _unit,
                  decoration: const InputDecoration(
                    labelText: 'Satuan jumlah dan biaya',
                    border: OutlineInputBorder(),
                  ),
                  items: _units
                      .map(
                        (r) => DropdownMenuItem(
                          value: r['unit'].toString(),
                          child: Text(r['unit'].toString()),
                        ),
                      )
                      .toList(),
                  onChanged: _busy || _pending
                      ? null
                      : (v) => setState(() {
                          final oldFactor =
                              (_units.firstWhere(
                                        (r) => r['unit'] == _unit,
                                      )['factor']
                                      as num)
                                  .toDouble();
                          final nextFactor =
                              (_units.firstWhere(
                                        (r) => r['unit'] == v,
                                      )['factor']
                                      as num)
                                  .toDouble();
                          _cost.text = formatRupiahInput(
                            parseRupiah(_cost.text) / oldFactor * nextFactor,
                          );
                          _unit = v!;
                        }),
                ),
                const SizedBox(height: 14),
                _field('Jumlah ($_unit)', _quantity, numeric: true),
                _field('Biaya per $_unit (Rp)', _cost, numeric: true),
                if (_item?['valuation_method'] == 'fifo')
                  _field('Tanggal perolehan (YYYY-MM-DD)', _acquired),
                _field(
                  _item?['wajib_batch_number'] == true
                      ? 'Nomor batch *'
                      : 'Nomor batch (opsional)',
                  _batch,
                ),
                _field(
                  'Kedaluwarsa (YYYY-MM-DD; wajib bila ada batch)',
                  _expiry,
                ),
                if (_item?['wajib_serial_number'] == true)
                  _field(
                    'Nomor seri (satu per baris, per unit dasar)',
                    _serials,
                    lines: 4,
                  ),
              ],
              FilledButton.icon(
                onPressed: _busy || _selecting || _item == null ? null : _save,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _busy
                      ? 'Menyimpan…'
                      : _pending
                      ? 'Periksa & coba lagi'
                      : 'Simpan stok awal & lanjutkan',
                ),
              ),
              TextButton(
                onPressed: _busy ? null : _load,
                child: const Text('Muat ulang barang/lokasi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
