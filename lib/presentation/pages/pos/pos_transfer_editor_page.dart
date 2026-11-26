import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'dart:async';
import '../../../core/utils/stock_quantity_input.dart';
import 'package:flutter/material.dart';
import '../../../core/network/graphql_client_provider.dart';
import '../../../data/graphql/pos_transfer_queries.dart';
import '../../../domain/models/pos_transfer.dart';
import '../../../domain/models/pos_transfer_choices.dart';
import '../../../domain/repositories/pos_transfer_repository.dart';
import '../../../../injections.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_content_skeletons.dart';
import '../../widgets/pos_keyboard_stable_dialog.dart';
import 'widgets/pos_transfer_location_fields.dart';
import 'widgets/pos_transfer_recovery_view.dart';

class PosTransferEditorPage extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final String? initialSourceId, initialDestinationId, initialInventoryId;
  final double? initialQuantity;
  final bool displayReplenishment;
  final PosTransferRepository? repository;
  final Map<String, dynamic>? inventoryPolicy;
  const PosTransferEditorPage({
    super.key,
    this.existing,
    this.initialSourceId,
    this.initialDestinationId,
    this.initialInventoryId,
    this.initialQuantity,
    this.displayReplenishment = false,
    this.repository,
    this.inventoryPolicy,
  });
  @override
  State<PosTransferEditorPage> createState() => _PosTransferEditorPageState();
}

class _PosTransferEditorPageState extends State<PosTransferEditorPage> {
  late final repo =
      widget.repository ?? PosTransferRepository(sl<GraphQLClientProvider>());
  final nonce = DateTime.now().microsecondsSinceEpoch.toString();
  Map<String, dynamic> draft = {};
  Map<String, dynamic>? recovery;
  List<Map<String, dynamic>> warehouses = [], banks = [], dimensions = [];
  bool loading = true,
      saving = false,
      loadingFinance = false,
      financeReady = false;
  String? error, financeError;
  int version = 0;
  final Set<Map<String, dynamic>> unitRequests = {};
  final Set<Map<String, dynamic>> unitLoading = {};
  TransferEditorMode mode = TransferEditorMode.between;
  TransferLocationChoices get choices =>
      TransferLocationChoices(policy: widget.inventoryPolicy);
  bool get english => posLocale(context).localeName.startsWith('en');
  String copy(String id, String en) => english ? en : id;
  List<Map<String, dynamic>> get items =>
      (draft['items'] as List).cast<Map<String, dynamic>>();
  List<Map<String, dynamic>> get costs =>
      (draft['biaya_transfer'] as List).cast<Map<String, dynamic>>();
  Map<String, dynamic>? warehouse(dynamic location) => warehouses
      .where(
        (w) =>
            w['_id']?.toString() ==
            (location as Map?)?['cabang_id']?.toString(),
      )
      .firstOrNull;
  String? get locationError {
    final source = warehouse(draft['dari']),
        destination = warehouse(draft['ke']);
    final pairError = transferOutletPairError(
      source,
      destination,
      english: english,
    );
    if (pairError != null) return pairError;
    if (source == null || destination == null) {
      return copy(
        'Pilih lokasi asal dan tujuan yang tersedia.',
        'Select an available source and destination.',
      );
    }
    if (!choices.allows(source, destination, mode)) {
      return copy(
        'Pasangan lokasi tidak tersedia untuk jenis perpindahan atau profil inventori ini. Pilih lokasi lain atau periksa pengaturan inventori.',
        'These locations are not available for this movement type or inventory profile. Choose another location or check inventory settings.',
      );
    }
    if (source['_id'] == destination['_id'] &&
        ['gedung_kode', 'ruangan_kode', 'rak_nama'].every(
          (key) =>
              '${draft['dari']?[key] ?? ''}' == '${draft['ke']?[key] ?? ''}',
        )) {
      return copy(
        'Untuk mutasi dalam lokasi yang sama, pilih gedung, ruangan, atau rak tujuan yang berbeda.',
        'Within the same location, choose a different destination building, room or rack.',
      );
    }
    return null;
  }

  Future<void> changeMode(TransferEditorMode next) async {
    if (mode == next || saving || recovery != null) return;
    if (items.isNotEmpty || '${draft['ke']?['cabang_id'] ?? ''}'.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(
            copy('Ganti jenis perpindahan?', 'Change movement type?'),
          ),
          content: Text(
            copy(
              'Lokasi tujuan dan daftar barang akan dikosongkan agar stok, batch, dan nomor seri tidak memakai alur lama. Catatan dan biaya tetap disimpan.',
              'The destination and items will be cleared to prevent using stock, batches or serials from the previous flow. Notes and costs are preserved.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const PosText('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(copy('Ganti jenis', 'Change type')),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() {
      mode = next;
      draft['ke'] = <String, dynamic>{};
      draft['items'] = <Map<String, dynamic>>[];
      if (!choices
          .sources(warehouses, mode)
          .any((w) => w['_id'] == draft['dari']?['cabang_id'])) {
        draft['dari'] = <String, dynamic>{};
      }
      version++;
    });
  }

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
      final pending = repo.pendingIntent(
        documentId: widget.existing?['_id']?.toString(),
      );
      if (pending != null) {
        setState(() {
          recovery = pending;
          loading = false;
        });
        return;
      }
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
        mode = widget.displayReplenishment
            ? TransferEditorMode.internal
            : choices.infer(warehouse(doc['dari']), warehouse(doc['ke']));
        version++;
        loading = false;
      });
      if (costs.isNotEmpty ||
          draft['branch_id'] != null ||
          draft['project_id'] != null) {
        unawaited(loadFinance());
      }
      if (widget.initialInventoryId != null && widget.existing == null) {
        unawaited(loadInitialItem());
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

  // Optional shortcut from the stock page. Its failure must not reload or
  // discard the editable transfer, and its result belongs to one form revision.
  Future<void> loadInitialItem() async {
    final requestedVersion = version;
    bool current() =>
        mounted && version == requestedVersion && !saving && recovery == null;
    try {
      final available = await repo.query(PosTransferQueries.items, {
        'id': draft['dari']['cabang_id'],
        'search': null,
      });
      if (!current()) return;
      final selected =
          transferMaps(available['GetInventarisAvailableInLocation'])
              .where(
                (r) =>
                    (r['inventaris_id'] ?? r['_id']).toString() ==
                    widget.initialInventoryId,
              )
              .firstOrNull;
      if (selected == null) {
        AppToast.warning(
          context,
          copy(
            'Barang awal tidak tersedia di lokasi asal. Pilih barang melalui Tambah barang.',
            'The initial item is unavailable at the source. Choose an item using Add item.',
          ),
        );
        return;
      }
      if (items.any(
        (r) => '${r['inventaris_id']}' == widget.initialInventoryId,
      ))
        return;
      setState(
        () => items.add({
          ...selected,
          'inventaris_id': selected['inventaris_id'] ?? selected['_id'],
          'qty': widget.initialQuantity ?? 1.0,
          'serial_numbers': <String>[],
        }),
      );
    } catch (_) {
      if (current())
        AppToast.warning(
          context,
          copy(
            'Barang awal belum dapat dimuat. Isian form tetap ada; pilih Tambah barang untuk mencoba lagi.',
            'The initial item could not be loaded. Your form is preserved; use Add item to try again.',
          ),
        );
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
    if (locationError != null) {
      AppToast.error(context, locationError!);
      return;
    }
    final invalid = validateTransferDraft(draft);
    if (invalid != null) {
      AppToast.error(context, invalid);
      return;
    }
    setState(() => saving = true);
    try {
      final payload = transferInput(draft);
      if (widget.existing == null) {
        await repo.execute(PosTransferQueries.create, {
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
        setState(
          () => recovery = repo.pendingIntent(
            documentId: widget.existing?['_id']?.toString(),
          ),
        );
        AppToast.error(
          context,
          '$e'.replaceFirst(RegExp(r'^(Exception|Bad state):\s*'), ''),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> recover() async {
    if (saving) return;
    setState(() => saving = true);
    try {
      await repo.recoverPending(
        documentId: widget.existing?['_id']?.toString(),
      );
      if (!mounted) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context, true);
      } else {
        setState(() => recovery = null);
        await load();
      }
    } catch (e) {
      if (mounted) AppToast.error(context, '$e');
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
      initialValue: number ? stockQuantityText(value) : value?.toString() ?? '',
      inputFormatters: number ? const [StockQuantityInputFormatter()] : null,
      maxLines: lines,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : lines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: (label).tr(context),
        hintText: number ? '0' : null,
        helperText: (hint)?.tr(context),
        border: const OutlineInputBorder(),
      ),
      onChanged: (v) => change(number && v.trim().isEmpty ? '0' : v),
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
      values[current] = current == 'landed_cost'
          ? transferRecoveryText(
              context,
              'Belum tersedia · pilih beban langsung',
              'Unavailable · select direct expense',
            )
          : current;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        key: ValueKey('$version:$label:$current'),
        initialValue: current.isEmpty && !optional ? null : current,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: (label).tr(context),
          border: const OutlineInputBorder(),
        ),
        items: values.entries
            .map(
              (r) => DropdownMenuItem(
                enabled: r.key != 'landed_cost',
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
          PosText(title, style: Theme.of(context).textTheme.titleMedium),
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
      title: ('Tambah barang transfer').tr(context),
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
      title: ('Pilih batch transfer').tr(context),
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
    if (saving ||
        recovery != null ||
        !items.contains(item) ||
        unitRequests.contains(item))
      return;
    final requestedVersion = version;
    bool current() =>
        mounted &&
        version == requestedVersion &&
        !saving &&
        recovery == null &&
        items.contains(item);
    setState(() {
      unitRequests.add(item);
      unitLoading.add(item);
    });
    FocusManager.instance.primaryFocus?.unfocus();
    try {
      final data = await repo.query(PosTransferQueries.units, {
        'id': item['inventaris_id'],
      });
      if (!current()) return;
      setState(() => unitLoading.remove(item));
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
          title: const PosText('Jumlah per satuan / kemasan'),
          content: ListView(
            children: [
              const PosText(
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
              child: const PosText('Batal'),
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
              child: const PosText('Gunakan jumlah'),
            ),
          ],
        ),
      );
      if (result == true && current()) {
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
      if (current())
        AppToast.error(context, 'Gagal memuat konversi satuan: $e');
    } finally {
      if (mounted)
        setState(() {
          unitRequests.remove(item);
          unitLoading.remove(item);
        });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existing == null
              ? ('Tambah Mutasi Stok').tr(context)
              : ('Ubah Mutasi Stok').tr(context),
        ),
      ),
      body: recovery != null
          ? PosTransferRecoveryView(
              intent: recovery!,
              busy: saving,
              onRecover: recover,
            )
          : loading
          ? const PosDocumentFormSkeleton()
          : error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PosText(error!),
                  TextButton(
                    onPressed: load,
                    child: const PosText('Coba lagi'),
                  ),
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
                      LayoutBuilder(
                        builder: (context, constraints) => ToggleButtons(
                          isSelected: [
                            mode == TransferEditorMode.between,
                            mode == TransferEditorMode.internal,
                          ],
                          onPressed: (index) =>
                              changeMode(TransferEditorMode.values[index]),
                          borderRadius: BorderRadius.circular(12),
                          constraints: BoxConstraints(
                            minHeight: 52,
                            maxWidth: (constraints.maxWidth - 3) / 2,
                            minWidth: (constraints.maxWidth - 3) / 2,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                copy(
                                  'Antar toko / gudang',
                                  'Between stores / warehouses',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                copy('Mutasi internal', 'Internal movement'),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          mode == TransferEditorMode.internal
                              ? copy(
                                  'Pindah rak dalam satu lokasi atau gudang toko ↔ display pada outlet yang sama. Persetujuan dan penerimaan mengikuti kebijakan inventori.',
                                  'Move between racks in one location, or store warehouse ↔ display within the same outlet. Approval and receipt follow inventory policy.',
                                )
                              : copy(
                                  'Kirim stok ke toko atau gudang lain. Pilihan lokasi mengikuti profil inventori; proses pengiriman dan penerimaan tetap berlaku.',
                                  'Send stock to another store or warehouse. Locations follow the inventory profile; shipping and receipt rules still apply.',
                                ),
                        ),
                      ),
                      if (choices.sources(warehouses, mode).isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            copy(
                              'Belum ada pasangan lokasi yang tersedia. Periksa lokasi aktif dan profil inventori di pengaturan; atau pilih tab lain.',
                              'No compatible locations are available. Check active locations and the inventory profile in settings, or choose the other tab.',
                            ),
                          ),
                        ),
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
                            posLocale(context).posb11d7ad2d4ac(
                              (draft['requires_approval'] == false
                                      ? ('tidak diperlukan').tr(context)
                                      : ('diperlukan').tr(context))
                                  .toString(),
                            ),
                          ),
                        text(
                          'Catatan transfer',
                          draft['catatan'],
                          (v) => draft['catatan'] = v,
                          lines: 2,
                        ),
                      ]),
                      section('Lokasi perpindahan', [
                        if (locationError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              locationError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        PosTransferLocationFields(
                          title: ('asal').tr(context),
                          warehouses: choices.sources(warehouses, mode),
                          value: Map<String, dynamic>.from(draft['dari']),
                          onChanged: (v) async {
                            if (items.isNotEmpty) {
                              final yes = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const PosText('Ganti lokasi asal?'),
                                  content: const PosText(
                                    'Daftar barang dikosongkan agar stok dan batch tidak memakai lokasi lama.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const PosText('Batal'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const PosText('Ganti lokasi'),
                                    ),
                                  ],
                                ),
                              );
                              if (yes != true || !mounted) return;
                            }
                            setState(() {
                              draft['dari'] = v;
                              draft['items'] = <Map<String, dynamic>>[];
                              version++;
                            });
                          },
                        ),
                        const Divider(),
                        PosTransferLocationFields(
                          title: ('tujuan').tr(context),
                          warehouses: choices.destinations(
                            warehouses,
                            warehouse(draft['dari']),
                            mode,
                          ),
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
                                        tooltip: ('Hapus barang').tr(context),
                                        onPressed: () => setState(
                                          () => items.removeAt(index),
                                        ),
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
                                    posLocale(context).pos19c47f48a246(
                                      (item['no_batch'] ??
                                              'Alokasi otomatis saat dikirim')
                                          .toString(),
                                      (item['tanggal_kadaluarsa'] ?? '')
                                          .toString(),
                                    ),
                                  ),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => chooseBatch(item),
                                        icon: const Icon(Icons.layers_outlined),
                                        label: const PosText('Pilih batch'),
                                      ),
                                      TextButton(
                                        onPressed: () => setState(
                                          () => item.addAll({
                                            'batch_id': null,
                                            'no_batch': '',
                                            'tanggal_kadaluarsa': '',
                                          }),
                                        ),
                                        child: const PosText(
                                          'Alokasi otomatis',
                                        ),
                                      ),
                                    ],
                                  ),
                                  text(
                                    'Nomor seri yang dikirim (satu per baris)',
                                    (item['serial_numbers'] as List? ?? [])
                                        .join('\n'),
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
                                    onPressed: unitRequests.contains(item)
                                        ? null
                                        : () => editUnits(item),
                                    icon: unitLoading.contains(item)
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.swap_horiz),
                                    label: const PosText(
                                      'Input satuan / kemasan',
                                    ),
                                  ),
                                  if (transferMaps(
                                    item['unit_breakdown'],
                                  ).isNotEmpty)
                                    Text(
                                      posLocale(context).pos2befc83ee9ee(
                                        (transferMaps(item['unit_breakdown'])
                                                .map(
                                                  (u) =>
                                                      '${u['input_qty']} ${u['unit']} × ${u['factor']}',
                                                )
                                                .join(' + '))
                                            .toString(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed: addItem,
                          icon: const Icon(Icons.add),
                          label: const PosText('Tambah barang'),
                        ),
                      ]),
                      Card(
                        child: ExpansionTile(
                          title: const PosText(
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
                                      child: Text(
                                        posLocale(context).posb4fb1c3b1411(
                                          (financeError).toString(),
                                        ),
                                      ),
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
                                              child: const PosText(
                                                'Hapus biaya',
                                              ),
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
                                    child: const PosText('Tambah biaya'),
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
                                    [('expense', 'Beban langsung')],
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
                        onPressed: saving || locationError != null
                            ? null
                            : save,
                        icon: saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          saving
                              ? ('Menyimpan...').tr(context)
                              : ('Simpan mutasi').tr(context),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
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
    title: PosText(widget.title),
    content: Column(
      children: [
        TextField(
          controller: search,
          decoration: InputDecoration(
            labelText: ('Cari nama, kode atau barcode').tr(context),
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
          TextButton(
            onPressed: load,
            child: Text(posLocale(context).posb4fb1c3b1411((error).toString())),
          ),
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
          const PosText(
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
                child: const PosText('Sebelumnya'),
              ),
              TextButton(
                onPressed: rows.length < 30 || loading
                    ? null
                    : () {
                        page++;
                        load();
                      },
                child: const PosText('Berikutnya'),
              ),
            ],
          ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const PosText('Batal'),
      ),
    ],
  );
}
