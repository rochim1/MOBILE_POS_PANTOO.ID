import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/stock_quantity_input.dart';
import '../../../../injections.dart';
import '../../../core/network/graphql_client_provider.dart';
import '../../../data/graphql/pos_transfer_queries.dart';
import '../../../domain/models/pos_transfer.dart';
import '../../../domain/repositories/pos_transfer_repository.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_content_skeletons.dart';
import 'widgets/pos_transfer_location_fields.dart';
import 'widgets/pos_transfer_recovery_view.dart';

class PosTransferOperationPage extends StatefulWidget {
  final Map<String, dynamic> transfer;
  final String mode;
  final String? discrepancyId;
  final PosTransferRepository? repository;
  final bool canApproveLoss;
  const PosTransferOperationPage({
    super.key,
    required this.transfer,
    required this.mode,
    this.discrepancyId,
    this.repository,
    this.canApproveLoss = false,
  });
  @override
  State<PosTransferOperationPage> createState() =>
      _PosTransferOperationPageState();
}

class _PosTransferOperationPageState extends State<PosTransferOperationPage> {
  late final repo =
      widget.repository ?? PosTransferRepository(sl<GraphQLClientProvider>());
  Map<String, dynamic> doc = {}, quarantine = {};
  Map<String, dynamic>? recovery;
  List<Map<String, dynamic>> rows = [], warehouses = [];
  final selected = <String, Map<String, dynamic>>{};
  final reason = TextEditingController(),
      evidence = TextEditingController(),
      lossAccount = TextEditingController(text: '6200');
  bool loading = true, saving = false, approve = true;
  String? error;
  String kind = 'lost',
      receivedDate = transferToday(),
      postingDate = transferToday();
  int version = 0;
  bool get deciding => widget.mode == 'decide';
  Map<String, dynamic>? get report => transferMaps(
    doc['discrepancies'],
  ).where((r) => r['_id'].toString() == widget.discrepancyId).firstOrNull;
  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void dispose() {
    reason.dispose();
    evidence.dispose();
    lossAccount.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final pending = repo.pendingIntent(
        documentId: widget.transfer['_id'].toString(),
      );
      if (pending != null) {
        setState(() {
          recovery = pending;
          loading = false;
        });
        return;
      }
      if(widget.mode == 'recover') {
        throw StateError('Pemeriksaan transfer sudah selesai. Kembali dan muat ulang daftar.');
      }
      final current = await repo.detail(widget.transfer['_id'].toString());
      if (current['status'] != 'in_transit') {
        throw Exception(
          'Transfer tidak lagi dalam perjalanan. Kembali dan muat ulang.',
        );
      }
      final locations = await repo.warehouses();
      if (!mounted) return;
      setState(() {
        doc = current;
        warehouses = locations;
        rows = transferRemainingRows(doc);
        selected.clear();
        for (final row in rows) {
          selected[row['item_id'].toString()] = {
            'item_id': row['item_id'],
            'qty': 0.0,
            'serial_numbers': <String>[],
            'batch_allocations': transferMaps(
              row['batches'],
            ).map((b) => {...b, 'qty': 0.0}).toList(),
            'location': transferLocation(doc['ke'] as Map? ?? {}),
          };
        }
        version++;
        loading = false;
        if (deciding && report?['kind'] == 'lost' && !widget.canApproveLoss) {
          approve = false;
        }
      });
      if (deciding && report?['status'] != 'pending') {
        throw Exception('Laporan sudah diputuskan. Muat ulang daftar.');
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

  Future<void> save() async {
    if (saving || loading || error != null) return;
    try {
      Map<String, dynamic> variables;
      String query, root;
      if (deciding) {
        if (approve && report?['kind'] == 'lost' && !widget.canApproveLoss) {
          throw Exception(
            'Persetujuan kehilangan membutuhkan izin persetujuan scrap. Anda dapat menolak laporan.',
          );
        }
        if (reason.text.trim().isEmpty) {
          throw Exception('Catatan keputusan wajib diisi.');
        }
        if (approve &&
            report?['kind'] == 'damaged' &&
            '${quarantine['cabang_id'] ?? ''}'.isEmpty) {
          throw Exception('Pilih lokasi karantina untuk barang rusak.');
        }
        variables = {
          'id': doc['_id'],
          'discrepancy_id': widget.discrepancyId,
          'approve': approve,
          'note': reason.text.trim(),
          if (approve && report?['kind'] == 'damaged')
            'quarantine': transferLocation(quarantine),
          if (approve && report?['kind'] == 'lost')
            'loss_account_code': lossAccount.text.trim(),
        };
        query = PosTransferQueries.decide;
        root = 'DecideInventoryTransferDiscrepancy';
      } else {
        final movements = <Map<String, dynamic>>[];
        for (final row in rows) {
          final value = selected[row['item_id'].toString()]!;
          final qty = transferNumber(value['qty']);
          final serials = (value['serial_numbers'] as List).cast<String>();
          final batches = transferMaps(
            value['batch_allocations'],
          ).where((b) => transferNumber(b['qty']) != 0).toList();
          final invalid = validateTransferSelection(row, qty, serials, batches);
          if (invalid != null) throw Exception('${row['name']}: $invalid');
          if (qty <= 0) continue;
          if (widget.mode == 'receive' &&
              value['location']['cabang_id'] != doc['ke']['cabang_id']) {
            throw Exception(
              'Penempatan aktual harus berada di gudang tujuan transfer.',
            );
          }
          movements.add({
            'item_id': row['item_id'],
            'qty': qty,
            'serial_numbers': serials,
            'batch_allocations': batches
                .map(
                  (b) => {
                    for (final key in [
                      'batch_id',
                      'no_batch',
                      'tanggal_kadaluarsa',
                      'qty',
                    ])
                      if (b[key] != null) key: b[key],
                  },
                )
                .toList(),
            if (widget.mode == 'receive')
              'location': transferLocation(value['location'] as Map),
          });
        }
        if (movements.isEmpty) {
          throw Exception('Isi minimal satu jumlah yang diproses.');
        }
        if (widget.mode == 'receive') {
          final invalid = transferReceiptDatesError(
            doc,
            receivedDate,
            postingDate,
          );
          if (invalid != null) throw Exception(invalid);
          final payload = {
            'items': movements,
            'received_date': receivedDate,
            'posting_date': postingDate,
          };
          variables = {
            'id': doc['_id'],
            ...payload,
            'request_id': transferRequestId(
              'receive',
              doc['_id'].toString(),
              doc['updatedAt'],
              payload,
            ),
          };
          query = PosTransferQueries.receive;
          root = 'ReceiveInventoryTransfer';
        } else {
          if (reason.text.trim().isEmpty) {
            throw Exception('Alasan selisih wajib diisi.');
          }
          if (evidence.text.trim().isNotEmpty &&
              !RegExp(r'^https?://[^\s]+$').hasMatch(evidence.text.trim())) {
            throw Exception('Tautan bukti harus http/https yang valid.');
          }
          final payload = {
            'kind': kind,
            'reason': reason.text.trim(),
            'evidence_url': evidence.text.trim(),
            'items': movements,
          };
          variables = {
            'id': doc['_id'],
            'input': {
              ...payload,
              'request_id': transferRequestId(
                'report',
                doc['_id'].toString(),
                doc['updatedAt'],
                payload,
              ),
            },
          };
          query = PosTransferQueries.report;
          root = 'ReportInventoryTransferDiscrepancy';
        }
      }
      setState(() => saving = true);
      final result = await repo.execute(query, variables, root);
      if (mounted) {
        AppToast.success(
          context,
          result['status'] == 'posted'
              ? 'Transfer selesai. Periksa rincian jurnal bila ada biaya.'
              : deciding
              ? 'Keputusan tersimpan'
              : widget.mode == 'receive'
              ? 'Penerimaan tercatat; sisa tetap dalam perjalanan'
              : 'Laporan selisih diajukan; menunggu reviewer terpisah',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => recovery = repo.pendingIntent(
            documentId: widget.transfer['_id'].toString(),
          ),
        );
        AppToast.error(
          context,
          '$e\nJika hasil belum pasti, muat ulang dokumen sebelum mengulang.',
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
      await repo.recoverPending(documentId: widget.transfer['_id'].toString());
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

  Widget numberField(
    String label,
    dynamic value,
    ValueChanged<double> change, {
    String? key,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      key: ValueKey('$version:$key:$label'),
      initialValue: stockQuantityText(value),
      inputFormatters: const [StockQuantityInputFormatter()],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: (label).tr(context),
        hintText: '0',
        border: const OutlineInputBorder(),
      ),
      onChanged: (v) =>
          setState(() => change(v.trim().isEmpty ? 0 : transferNumber(v.replaceAll(',', '.')))),
    ),
  );
  Widget dateField(String label, String value, ValueChanged<String> change) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          key: ValueKey('$version:$label'),
          initialValue: value,
          decoration: InputDecoration(
            labelText: (label).tr(context),
            helperText: ('YYYY-MM-DD · mengikuti periode pembukuan').tr(
              context,
            ),
            border: const OutlineInputBorder(),
          ),
          onChanged: change,
        ),
      );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          recovery != null || widget.mode == 'recover'
              ? transferRecoveryText(context,'Periksa transfer sebelumnya','Check previous transfer')
              : deciding
              ? ('Keputusan selisih').tr(context)
              : widget.mode == 'receive'
              ? ('Terima Mutasi Stok').tr(context)
              : ('Laporkan selisih transfer').tr(context),
        ),
      ),
      body: recovery != null
          ? PosTransferRecoveryView(
              intent: recovery!,
              busy: saving,
              onRecover: recover,
            )
          : loading
          ? const PosDocumentFormSkeleton(fieldGroups: [3])
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
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '${doc['no_transfer']}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (deciding) ...[
                    Text(
                      '${report?['kind'] == 'damaged' ? ('Barang rusak').tr(context) : ('Barang hilang').tr(context)} • ${report?['reason']}',
                    ),
                    for (final item in transferMaps(report?['items']))
                      Text(
                        posLocale(context).pos256020cc43aa(
                          (item['qty']).toString(),
                          (item['serial_numbers'] ?? '').toString(),
                        ),
                      ),
                    SwitchListTile(
                      title: const PosText('Setujui laporan selisih'),
                      subtitle: const PosText(
                        'Menolak melepaskan barang agar dapat diproses ulang. Pelapor tidak boleh memutuskan laporannya sendiri.',
                      ),
                      value: approve,
                      onChanged:
                          report?['kind'] == 'lost' && !widget.canApproveLoss
                          ? null
                          : (v) => setState(() => approve = v),
                    ),
                    if (report?['kind'] == 'lost' && !widget.canApproveLoss)
                      const PosText(
                        'Izin persetujuan scrap tidak tersedia. Anda hanya dapat menolak; persetujuan dilakukan supervisor yang berwenang.',
                      ),
                    if (approve && report?['kind'] == 'damaged')
                      PosTransferLocationFields(
                        title: ('karantina').tr(context),
                        warehouses: warehouses
                            .where((w) => w['warehouse_type'] == 'quarantine')
                            .toList(),
                        value: quarantine,
                        onChanged: (v) => setState(() => quarantine = v),
                      ),
                    if (approve && report?['kind'] == 'lost')
                      TextField(
                        controller: lossAccount,
                        decoration: InputDecoration(
                          labelText: ('Kode akun beban kehilangan').tr(context),
                          helperText:
                              ('Backend memvalidasi izin scrap dan akun.').tr(
                                context,
                              ),
                          border: OutlineInputBorder(),
                        ),
                      ),
                  ] else ...[
                    if (widget.mode == 'receive') ...[
                      const PosText(
                        'Isi barang yang benar-benar tiba. Sisa dan selisih pending tidak diterima otomatis.',
                      ),
                      const SizedBox(height: 12),
                      dateField(
                        'Tanggal penerimaan fisik',
                        receivedDate,
                        (v) => receivedDate = v,
                      ),
                      dateField(
                        'Tanggal pembukuan',
                        postingDate,
                        (v) => postingDate = v,
                      ),
                    ] else
                      DropdownButtonFormField<String>(
                        initialValue: kind,
                        decoration: InputDecoration(
                          labelText: ('Jenis selisih').tr(context),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'lost',
                            child: PosText('Hilang / kurang permanen'),
                          ),
                          DropdownMenuItem(
                            value: 'damaged',
                            child: PosText('Rusak (perlu karantina)'),
                          ),
                        ],
                        onChanged: (v) => setState(() => kind = v ?? 'lost'),
                      ),
                    for (final row in rows)
                      Card(
                        key: ValueKey(row['item_id']),
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Builder(
                            builder: (_) {
                              final item = selected[row['item_id'].toString()]!;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    '${row['name']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    posLocale(context).posf7452c021e4b(
                                      (row['qty']).toString(),
                                      (row['unit']).toString(),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton(
                                    onPressed: () => setState(() {
                                      item.addAll({
                                        'qty': row['qty'],
                                        'serial_numbers': List<String>.from(
                                          row['serials'] as List,
                                        ),
                                        'batch_allocations': transferMaps(
                                          row['batches'],
                                        ),
                                      });
                                      version++;
                                    }),
                                    child: const PosText(
                                      'Isi seluruh sisa baris ini',
                                    ),
                                  ),
                                  numberField(
                                    'Jumlah diproses',
                                    item['qty'],
                                    (v) => item['qty'] = v,
                                    key: row['item_id'].toString(),
                                  ),
                                  for (final serial in row['serials'] as List)
                                    CheckboxListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        posLocale(
                                          context,
                                        ).pos2520218913bd((serial).toString()),
                                      ),
                                      value: (item['serial_numbers'] as List)
                                          .contains(serial),
                                      onChanged: (v) => setState(() {
                                        final list =
                                            item['serial_numbers'] as List;
                                        if (v == true) {
                                          list.add(serial);
                                        } else {
                                          list.remove(serial);
                                        }
                                      }),
                                    ),
                                  for (final batch in transferMaps(
                                    item['batch_allocations'],
                                  ))
                                    numberField(
                                      'Batch ${batch['no_batch']} · ${batch['tanggal_kadaluarsa'] ?? ''}',
                                      batch['qty'],
                                      (v) {
                                        batch['qty'] = v;
                                        final original =
                                            (item['batch_allocations'] as List)
                                                .cast<Map>()
                                                .firstWhere(
                                                  (b) =>
                                                      transferBatchKey(b) ==
                                                      transferBatchKey(batch),
                                                );
                                        original['qty'] = v;
                                      },
                                      key:
                                          '${row['item_id']}:${transferBatchKey(batch)}',
                                    ),
                                  if (widget.mode == 'receive')
                                    PosTransferLocationFields(
                                      title: posLocale(context).posadd23ff79c19(
                                        (row['name']).toString(),
                                      ),
                                      warehouses: warehouses
                                          .where(
                                            (w) =>
                                                w['_id'].toString() ==
                                                doc['ke']['cabang_id']
                                                    .toString(),
                                          )
                                          .toList(),
                                      value: Map<String, dynamic>.from(
                                        item['location'],
                                      ),
                                      onChanged: (v) =>
                                          setState(() => item['location'] = v),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    if (rows.isEmpty)
                      const PosText(
                        'Tidak ada sisa bebas. Periksa laporan selisih yang masih menunggu keputusan.',
                      ),
                  ],
                  if (widget.mode != 'receive') ...[
                    TextField(
                      controller: reason,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: deciding
                            ? ('Catatan keputusan (wajib)').tr(context)
                            : ('Alasan selisih (wajib)').tr(context),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!deciding)
                      TextField(
                        controller: evidence,
                        decoration: InputDecoration(
                          labelText: ('Tautan bukti (opsional)').tr(context),
                          border: OutlineInputBorder(),
                        ),
                      ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: saving ? null : save,
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      saving
                          ? ('Memproses...').tr(context)
                          : deciding
                          ? ('Simpan keputusan').tr(context)
                          : widget.mode == 'receive'
                          ? ('Terima jumlah ini').tr(context)
                          : ('Ajukan laporan selisih').tr(context),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    ),
  );
}
