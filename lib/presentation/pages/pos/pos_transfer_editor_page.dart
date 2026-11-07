import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/graphql_client_provider.dart';
import '../../../data/graphql/pos_transfer_queries.dart';
import '../../../domain/models/pos_transfer.dart';
import '../../../domain/repositories/pos_transfer_repository.dart';
import '../../../../injections.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/skeleton_loading.dart';
import '../../widgets/pos_keyboard_stable_dialog.dart';
import 'widgets/pos_transfer_location_fields.dart';

class PosTransferEditorPage extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final String? initialSourceId, initialDestinationId, initialInventoryId;
  final double? initialQuantity;
  final bool displayReplenishment;
  final PosTransferRepository? repository;
  const PosTransferEditorPage({
    super.key,
    this.existing,
    this.initialSourceId,
    this.initialDestinationId,
    this.initialInventoryId,
    this.initialQuantity,
    this.displayReplenishment = false,
    this.repository,
  });
  @override
  State<PosTransferEditorPage> createState() => _PosTransferEditorPageState();
}

class _PosTransferEditorPageState extends State<PosTransferEditorPage> {
  late final repo =
      widget.repository ?? PosTransferRepository(sl<GraphQLClientProvider>());
  final nonce = DateTime.now().microsecondsSinceEpoch.toString();
  Map<String, dynamic> draft = {};
  List<Map<String, dynamic>> warehouses = [], banks = [], dimensions = [];
  bool loading = true,
      saving = false,
      loadingFinance = false,
      financeReady = false;
  String? error, financeError;
  int version = 0;
  List<Map<String, dynamic>> get items =>
      (draft['items'] as List).cast<Map<String, dynamic>>();
  List<Map<String, dynamic>> get costs =>
      (draft['biaya_transfer'] as List).cast<Map<String, dynamic>>();
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final list = await repo.warehouses();
      final doc = widget.existing == null
          ? <String, dynamic>{
              'tanggal_transfer': transferToday(),
              'catatan': widget.displayReplenishment ? 'Isi rak display' : '',
              'dari': {'cabang_id': widget.initialSourceId ?? ''},
              'ke': {'cabang_id': widget.initialDestinationId ?? ''},
              'items': <Map<String, dynamic>>[],
              'biaya_transfer': <Map<String, dynamic>>[],
              'biaya_mode': 'expense',
              'biaya_alokasi': 'per_nilai',
            }
          : await repo.detail(widget.existing!['_id'].toString());
      if (widget.existing != null &&
          !['draft', 'rejected'].contains(doc['status'])) {
        throw Exception(
          'Status transfer berubah. Muat ulang daftar sebelum mengedit.',
        );
      }
      doc['items'] = transferMaps(doc['items']);
      doc['biaya_transfer'] = transferMaps(doc['biaya_transfer']);
      for (final cost in doc['biaya_transfer'] as List) {
        cost['_row_key'] = Object();
      }
      for (final side in ['dari', 'ke']) {
        doc[side] = transferLocation(doc[side] as Map? ?? {});
        final loc = doc[side] as Map;
        loc['cabang_nama'] ??=
            list
                .where((r) => r['_id'].toString() == loc['cabang_id'])
                .firstOrNull?['nama_cabang'] ??
            '';
      }
      if (!mounted) return;
      setState(() {
        warehouses = list;
        draft = doc;
        version++;
        loading = false;
      });
      if (costs.isNotEmpty ||
          draft['branch_id'] != null ||
          draft['project_id'] != null) {
        unawaited(loadFinance());
      }
      if (widget.initialInventoryId != null && widget.existing == null) {
        final available = await repo.query(PosTransferQueries.items, {
          'id': doc['dari']['cabang_id'],
          'search': null,
        });
        final selected =
            transferMaps(available['GetInventarisAvailableInLocation'])
                .where(
                  (r) =>
                      (r['inventaris_id'] ?? r['_id']).toString() ==
                      widget.initialInventoryId,
                )
                .firstOrNull;
        if (selected != null && mounted) {
          setState(
            () => items.add({
              ...selected,
              'inventaris_id': selected['inventaris_id'] ?? selected['_id'],
              'qty': widget.initialQuantity ?? 1.0,
              'serial_numbers': <String>[],
            }),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  Future<void> loadFinance() async {
    if (loadingFinance || financeReady) return;
    setState(() {
      loadingFinance = true;
      financeError = null;
    });
    try {
      final data = await repo.query(PosTransferQueries.paymentRefs);
      if (mounted) {
        setState(() {
          banks = transferMaps(data['GetInventoryTransferPaymentAccounts']);
          dimensions = transferMaps(data['GetFinanceDimensionOptions']);
          financeReady = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => financeError = e.toString());
    } finally {
      if (mounted) setState(() => loadingFinance = false);
    }
  }

  Future<void> save() async {
    if (saving || loading || error != null) return;
    final invalid = validateTransferDraft(draft);
    if (invalid != null) {
      AppToast.error(context, invalid);
      return;
    }
    setState(() => saving = true);
    try {
      final payload = transferInput(draft);
      if (widget.existing == null) {
        await repo.mutate(PosTransferQueries.create, {
          'input': payload,
          'request_id': transferRequestId('create', nonce, null, payload),
        }, 'CreateInventoryTransfer');
      } else {
        await repo.mutate(PosTransferQueries.update, {
          'id': draft['_id'],
          'input': payload,
        }, 'UpdateInventoryTransfer');
      }
      if (mounted) {
        AppToast.success(context, 'Mutasi stok berhasil disimpan');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          '$e\nJika koneksi terputus, periksa daftar sebelum membuat transfer baru.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget text(
    String label,
    dynamic value,
    ValueChanged<String> change, {
    bool number = false,
    int lines = 1,
    String? hint,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      initialValue: value?.toString() ?? '',
      maxLines: lines,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : lines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        helperText: hint,
        border: const OutlineInputBorder(),
      ),
      onChanged: change,
    ),
  );
  Widget select(
    String label,
    dynamic value,
    List<(String, String)> options,
    ValueChanged<String?> change, {
    bool optional = true,
  }) {
    final current = value?.toString() ?? '';
    final values = <String, String>{
      if (optional) '': 'Tidak dipilih',
      for (final r in options) r.$1: r.$2,
    };
    if (current.isNotEmpty && !values.containsKey(current)) {
      values[current] = current;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        key: ValueKey('$version:$label:$current'),
        initialValue: current.isEmpty && !optional ? null : current,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: values.entries
            .map(
              (r) => DropdownMenuItem(
                value: r.key,
                child: Text(r.value, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: saving ? null : change,
      ),
    );
  }

  Widget section(String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    ),
  );
  Future<void> addItem() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final from = draft['dari'] as Map;
    if ('${from['cabang_id'] ?? ''}'.isEmpty) {
      AppToast.warning(context, 'Pilih lokasi asal dahulu');
      return;
    }
    final picked = await showTransferReferencePicker(
      context,
      title: 'Tambah barang transfer',
      loader: (search, page) async {
        final data = await repo.query(PosTransferQueries.itemsPage, {
          'id': from['cabang_id'],
          'building': from['gedung_kode'],
          'room': from['ruangan_kode'],
          'rack': from['rak_nama'],
          'search': search,
          'page': page,
        });
        return transferMaps(data['GetInventoryTransferProductPage']['items']);
      },
      label: (r) => '${r['nama_inventaris']} · ${r['qty']} ${r['unit'] ?? ''}',
    );
    if (picked != null && mounted) {
      setState(
        () => items.add({
          ...picked,
          '_row_key': DateTime.now().microsecondsSinceEpoch.toString(),
          'inventaris_id': picked['inventaris_id'] ?? picked['_id'],
          'qty': 1.0,
          'serial_numbers': <String>[],
          'catatan_item': '',
        }),
      );
    }
  }

  Future<void> chooseBatch(Map<String, dynamic> item) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showTransferReferencePicker(
      context,
      title: 'Pilih batch transfer',
      loader: (search, page) async {
        final data = await repo.query(PosTransferQueries.batches, {
          'id': item['inventaris_id'],
          'location': draft['dari']['cabang_id'],
          'search': search,
          'page': page,
        });
        return transferMaps(data['SearchInventoryBatchOptions']['items']);
      },
      label: (r) =>
          '${r['no_batch']} · ${r['tanggal_kadaluarsa'] ?? 'Tanpa kedaluwarsa'} · ${r['qty']}',
    );
    if (picked != null && mounted) {
      setState(
        () => item.addAll({
          'batch_id': picked['_id'],
          'no_batch': picked['no_batch'],
          'tanggal_kadaluarsa': picked['tanggal_kadaluarsa'],
        }),
      );
    }
  }

  Future<void> editUnits(Map<String, dynamic> item) async {
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final data = await repo.query(PosTransferQueries.units, {
        'id': item['inventaris_id'],
      });
      final master = data['GetOneInventarisUmum'] as Map;
      final saved = transferMaps(item['unit_breakdown']);
      final options = <String, double>{
        '${master['base_unit'] ?? master['unit'] ?? item['unit'] ?? 'unit'}': 1,
        for (final u in transferMaps(master['unit_conversions']))
          '${u['unit']}': transferNumber(u['factor']),
      };
      final rows = [
        for (final u in options.entries)
          {
            'unit': u.key,
            'factor': u.value,
            'input_qty':
                saved
                    .where((s) => s['unit'] == u.key)
                    .firstOrNull?['input_qty'] ??
                0,
          },
      ];
      if (!mounted) return;
      final result = await showDialog<bool>(
        context: context,
        builder: (c) => PosKeyboardStableFormDialog(
          width: 560,
          height: 550,
          title: const Text('Jumlah per satuan / kemasan'),
          content: ListView(
            children: [
              const Text(
                'Total dihitung ke satuan dasar. Faktor berasal dari master barang.',
              ),
              for (final u in rows)
                text(
                  '${u['unit']} (× ${u['factor']})',
                  u['input_qty'],
                  (v) =>
                      u['input_qty'] = transferNumber(v.replaceAll(',', '.')),
                  number: true,
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final invalid = rows.any(
                  (u) =>
                      !transferNumber(u['input_qty']).isFinite ||
                      transferNumber(u['input_qty']) < 0 ||
                      !transferNumber(u['factor']).isFinite ||
                      transferNumber(u['factor']) <= 0,
                );
                if (invalid) {
                  AppToast.error(c, 'Jumlah satuan harus nol atau positif.');
                  return;
                }
                final total = rows.fold<double>(
                  0,
                  (n, u) =>
                      n +
                      transferNumber(u['factor']) *
                          transferNumber(u['input_qty']),
                );
                if (total <= 0) {
                  AppToast.error(c, 'Isi minimal satu satuan.');
                  return;
                }
                Navigator.pop(c, true);
              },
              child: const Text('Gunakan jumlah'),
            ),
          ],
        ),
      );
      if (result == true && mounted) {
        setState(() {
          item['unit_breakdown'] = rows
              .where((u) => transferNumber(u['input_qty']) > 0)
              .toList();
          item['qty'] = rows.fold<double>(
            0,
            (n, u) =>
                n +
                transferNumber(u['factor']) * transferNumber(u['input_qty']),
          );
          version++;
        });
      }
    } catch (e) {
      if (mounted) AppToast.error(context, 'Gagal memuat konversi satuan: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.existing == null ? 'Tambah Mutasi Stok' : 'Ubah Mutasi Stok',
      ),
    ),
    body: loading
        ? const PosPageSkeleton()
        : error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error!),
                TextButton(onPressed: load, child: const Text('Coba lagi')),
              ],
            ),
          )
        : AbsorbPointer(
            absorbing: saving,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    section('Informasi transfer', [
                      text(
                        'Tanggal transfer (YYYY-MM-DD)',
                        draft['tanggal_transfer'],
                        (v) => draft['tanggal_transfer'] = v,
                      ),
                      if (draft['submitted_at'] == null)
                        select(
                          'Persetujuan',
                          draft['requires_approval']?.toString(),
                          [
                            ('', 'Ikuti kebijakan instansi'),
                            ('true', 'Perlu persetujuan'),
                            ('false', 'Tanpa persetujuan (sesuai izin)'),
                          ],
                          (v) => setState(() {
                            if (v == null || v.isEmpty) {
                              draft.remove('requires_approval');
                            } else {
                              draft['requires_approval'] = v == 'true';
                            }
                          }),
                        ),
                      if (draft['submitted_at'] != null)
                        Text(
                          'Persetujuan ${draft['requires_approval'] == false ? 'tidak diperlukan' : 'diperlukan'} • aturan terkunci setelah diajukan',
                        ),
                      text(
                        'Catatan transfer',
                        draft['catatan'],
                        (v) => draft['catatan'] = v,
                        lines: 2,
                      ),
                    ]),
                    section('Lokasi perpindahan', [
                      PosTransferLocationFields(
                        title: 'asal',
                        warehouses: warehouses
                            .where((w) => w['is_transfer_source'] != false)
                            .toList(),
                        value: Map<String, dynamic>.from(draft['dari']),
                        onChanged: (v) async {
                          if (items.isNotEmpty) {
                            final yes = await showDialog<bool>(
                              context: context,
                              builder: (c) => AlertDialog(
                                title: const Text('Ganti lokasi asal?'),
                                content: const Text(
                                  'Daftar barang dikosongkan agar stok dan batch tidak memakai lokasi lama.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Batal'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Ganti lokasi'),
                                  ),
                                ],
                              ),
                            );
                            if (yes != true || !mounted) return;
                          }
                          setState(() {
                            draft['dari'] = v;
                            draft['items'] = <Map<String, dynamic>>[];
                          });
                        },
                      ),
                      const Divider(),
                      PosTransferLocationFields(
                        title: 'tujuan',
                        warehouses: warehouses
                            .where((w) => w['is_transfer_destination'] != false)
                            .toList(),
                        value: Map<String, dynamic>.from(draft['ke']),
                        onChanged: (v) => setState(() => draft['ke'] = v),
                      ),
                    ]),
                    section('Daftar barang', [
                      for (final (index, item) in items.indexed)
                        Card(
                          key: ValueKey(
                            '$version:${item['_row_key'] ?? item['_id'] ?? index}',
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item['nama_inventaris']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Hapus barang',
                                      onPressed: () =>
                                          setState(() => items.removeAt(index)),
                                      icon: const Icon(Icons.close),
                                    ),
                                  ],
                                ),
                                text(
                                  'Jumlah ${item['unit'] ?? 'unit'}',
                                  item['qty'],
                                  (v) {
                                    item['qty'] = transferNumber(
                                      v.replaceAll(',', '.'),
                                    );
                                    item['unit_breakdown'] =
                                        <Map<String, dynamic>>[];
                                  },
                                  number: true,
                                ),
                                Text(
                                  'Batch: ${item['no_batch'] ?? 'Alokasi otomatis saat dikirim'} · ${item['tanggal_kadaluarsa'] ?? ''}',
                                ),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => chooseBatch(item),
                                      icon: const Icon(Icons.layers_outlined),
                                      label: const Text('Pilih batch'),
                                    ),
                                    TextButton(
                                      onPressed: () => setState(
                                        () => item.addAll({
                                          'batch_id': null,
                                          'no_batch': '',
                                          'tanggal_kadaluarsa': '',
                                        }),
                                      ),
                                      child: const Text('Alokasi otomatis'),
                                    ),
                                  ],
                                ),
                                text(
                                  'Nomor seri yang dikirim (satu per baris)',
                                  (item['serial_numbers'] as List? ?? []).join(
                                    '\n',
                                  ),
                                  (v) => item['serial_numbers'] = v
                                      .split(RegExp(r'[\n,;]+'))
                                      .map((s) => s.trim())
                                      .where((s) => s.isNotEmpty)
                                      .toList(),
                                  lines: 3,
                                ),
                                text(
                                  'Catatan barang',
                                  item['catatan_item'],
                                  (v) => item['catatan_item'] = v,
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => editUnits(item),
                                  icon: const Icon(Icons.swap_horiz),
                                  label: const Text('Input satuan / kemasan'),
                                ),
                                if (transferMaps(
                                  item['unit_breakdown'],
                                ).isNotEmpty)
                                  Text(
                                    'Konversi tersimpan: ${transferMaps(item['unit_breakdown']).map((u) => '${u['input_qty']} ${u['unit']} × ${u['factor']}').join(' + ')}',
                                  ),
                              ],
                            ),
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah barang'),
                      ),
                    ]),
                    Card(
                      child: ExpansionTile(
                        title: const Text(
                          'Biaya, rekening & dimensi (opsional)',
                        ),
                        initiallyExpanded: costs.isNotEmpty,
                        onExpansionChanged: (v) {
                          if (v) loadFinance();
                        },
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (loadingFinance)
                                  const LinearProgressIndicator(),
                                if (financeError != null)
                                  TextButton(
                                    onPressed: loadFinance,
                                    child: Text('$financeError · Coba lagi'),
                                  ),
                                select(
                                  'Cabang penanggung jawab',
                                  draft['branch_id'],
                                  dimensions
                                      .where((r) => r['kind'] == 'branch')
                                      .map(
                                        (r) => (
                                          r['_id'].toString(),
                                          '${r['code']} · ${r['name']}',
                                        ),
                                      )
                                      .toList(),
                                  (v) => setState(() {
                                    draft['branch_id'] = v?.isEmpty == true
                                        ? null
                                        : v;
                                    draft['payment_branch_id'] =
                                        draft['branch_id'];
                                  }),
                                ),
                                select(
                                  'Proyek',
                                  draft['project_id'],
                                  dimensions
                                      .where((r) => r['kind'] == 'project')
                                      .map(
                                        (r) => (
                                          r['_id'].toString(),
                                          '${r['code']} · ${r['name']}',
                                        ),
                                      )
                                      .toList(),
                                  (v) => setState(
                                    () => draft['project_id'] =
                                        v?.isEmpty == true ? null : v,
                                  ),
                                ),
                                for (final (index, cost) in costs.indexed)
                                  Card(
                                    key: ValueKey(cost['_row_key']),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        children: [
                                          text(
                                            'Jenis biaya',
                                            cost['jenis_biaya'],
                                            (v) => cost['jenis_biaya'] = v,
                                          ),
                                          text(
                                            'Deskripsi biaya',
                                            cost['deskripsi'],
                                            (v) => cost['deskripsi'] = v,
                                          ),
                                          text(
                                            'Nominal biaya (Rp)',
                                            cost['nominal'],
                                            (v) => cost['nominal'] =
                                                transferNumber(v),
                                            number: true,
                                          ),
                                          text(
                                            'Kode akun beban (opsional)',
                                            cost['akun_beban'],
                                            (v) => cost['akun_beban'] = v,
                                          ),
                                          TextButton(
                                            onPressed: () => setState(
                                              () => costs.removeAt(index),
                                            ),
                                            child: const Text('Hapus biaya'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                OutlinedButton(
                                  onPressed: () {
                                    loadFinance();
                                    setState(
                                      () => costs.add({
                                        '_row_key': Object(),
                                        'jenis_biaya': 'ongkir',
                                        'nominal': 0.0,
                                        'deskripsi': '',
                                      }),
                                    );
                                  },
                                  child: const Text('Tambah biaya'),
                                ),
                                select(
                                  'Rekening pembayaran biaya',
                                  draft['payment_bank_account_id'],
                                  banks
                                      .map(
                                        (r) => (
                                          r['_id'].toString(),
                                          r['label'].toString(),
                                        ),
                                      )
                                      .toList(),
                                  (v) => setState(
                                    () => draft['payment_bank_account_id'] =
                                        v?.isEmpty == true ? null : v,
                                  ),
                                ),
                                select(
                                  'Cabang pembayar',
                                  draft['payment_branch_id'],
                                  dimensions
                                      .where((r) => r['kind'] == 'branch')
                                      .map(
                                        (r) => (
                                          r['_id'].toString(),
                                          '${r['code']} · ${r['name']}',
                                        ),
                                      )
                                      .toList(),
                                  (v) => setState(
                                    () => draft['payment_branch_id'] =
                                        v?.isEmpty == true ? null : v,
                                  ),
                                ),
                                select(
                                  'Perlakuan biaya',
                                  draft['biaya_mode'] ?? 'expense',
                                  [
                                    ('expense', 'Beban langsung'),
                                    (
                                      'landed_cost',
                                      'Tambahkan ke nilai persediaan',
                                    ),
                                  ],
                                  (v) =>
                                      setState(() => draft['biaya_mode'] = v),
                                  optional: false,
                                ),
                                select(
                                  'Alokasi biaya',
                                  draft['biaya_alokasi'] ?? 'per_nilai',
                                  [
                                    ('per_nilai', 'Berdasarkan nilai'),
                                    ('per_qty', 'Berdasarkan jumlah'),
                                  ],
                                  (v) => setState(
                                    () => draft['biaya_alokasi'] = v,
                                  ),
                                  optional: false,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: saving ? null : save,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(saving ? 'Menyimpan...' : 'Simpan mutasi'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
  );
}

Future<Map<String, dynamic>?> showTransferReferencePicker(
  BuildContext context, {
  required String title,
  required Future<List<Map<String, dynamic>>> Function(String, int) loader,
  required String Function(Map<String, dynamic>) label,
  bool paginated = true,
}) => showDialog<Map<String, dynamic>>(
  context: context,
  builder: (_) => _TransferReferencePicker(
    title: title,
    loader: loader,
    label: label,
    paginated: paginated,
  ),
);

class _TransferReferencePicker extends StatefulWidget {
  final String title;
  final Future<List<Map<String, dynamic>>> Function(String, int) loader;
  final String Function(Map<String, dynamic>) label;
  final bool paginated;
  const _TransferReferencePicker({
    required this.title,
    required this.loader,
    required this.label,
    required this.paginated,
  });
  @override
  State<_TransferReferencePicker> createState() =>
      _TransferReferencePickerState();
}

class _TransferReferencePickerState extends State<_TransferReferencePicker> {
  final search = TextEditingController();
  Timer? timer;
  int generation = 0, page = 1;
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> rows = [];
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    timer?.cancel();
    search.dispose();
    super.dispose();
  }

  Future<void> load() async {
    final current = ++generation;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final next = await widget.loader(search.text, page);
      if (mounted && generation == current) setState(() => rows = next);
    } catch (e) {
      if (mounted && generation == current) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted && generation == current) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => PosKeyboardStableFormDialog(
    width: 660,
    height: 650,
    title: Text(widget.title),
    content: Column(
      children: [
        TextField(
          controller: search,
          decoration: const InputDecoration(
            labelText: 'Cari nama, kode atau barcode',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (_) {
            timer?.cancel();
            timer = Timer(const Duration(milliseconds: 350), () {
              page = 1;
              load();
            });
          },
        ),
        if (loading) const LinearProgressIndicator(),
        if (error != null)
          TextButton(onPressed: load, child: Text('$error · Coba lagi')),
        Expanded(
          child: ListView(
            children: [
              for (final row in rows)
                ListTile(
                  title: Text(widget.label(row)),
                  onTap: () => Navigator.pop(context, row),
                ),
            ],
          ),
        ),
        if (!widget.paginated)
          const Text(
            'Maksimal 100 hasil. Ketik nama/kode untuk mempersempit pencarian.',
          ),
        if (widget.paginated)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
              onPressed: page <= 1 || loading
                    ? null
                    : () {
                        page--;
                        load();
                      },
                child: const Text('Sebelumnya'),
              ),
              TextButton(
                onPressed: rows.length < 30 || loading
                    ? null
                    : () {
                        page++;
                        load();
                      },
                child: const Text('Berikutnya'),
              ),
            ],
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
    ],
  );
}
