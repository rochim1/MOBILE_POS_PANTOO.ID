import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:mobile_pos_pantoo/l10n/inventory_terminology.dart';
import 'package:flutter/material.dart';
import '../../../../domain/models/pos_transfer.dart';
import '../utils/pos_inventory_detail_format.dart';

class PosTransferDetails extends StatelessWidget {
  final Map<String, dynamic> document;
  final bool canReceive, canDecide;
  final String? actorId;
  final ValueChanged<String> onAction;
  const PosTransferDetails({
    super.key,
    required this.document,
    required this.canReceive,
    required this.canDecide,
    required this.onAction,
    this.actorId,
  });
  String place(dynamic value) {
    final loc = value as Map? ?? {};
    return ['cabang_nama', 'gedung_kode', 'ruangan_kode', 'rak_nama']
        .map((k) => loc[k]?.toString() ?? '')
        .where((v) => v.isNotEmpty)
        .join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    final routing =
        (document['routing_snapshot'] ?? document['routing_preview']) as Map?;
    final rows = transferRemainingRows(document);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 28),
        PosText(
          'Alur & rincian transfer',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          routing == null
              ? ('Alur historis belum tercatat; periksa status dan penerimaan.')
                    .tr(context)
              : '${document['routing_snapshot'] != null ? ('Aturan saat dikirim').tr(context) : ('Rencana saat ini').tr(context)}: ${routing['mode'] == 'direct' ? ('Langsung selesai saat dikirim').tr(context) : ('Kirim → Transit → Terima di tujuan').tr(context)}',
        ),
        if (routing?['reason'] != null)
          Text(
            inventoryTransferReasonText('${routing!['reason']}').tr(context),
          ),
        Text(
          posLocale(context).pos57cdcf19a10a(
            (place(document['dari'])).toString(),
            (place(document['ke'])).toString(),
          ),
        ),
        if (document['transit']?['cabang_id'] != null)
          Text(
            posLocale(
              context,
            ).pos1a266eba7d88((place(document['transit'])).toString()),
          ),
        for (final row in transferMaps(document['items']))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${row['nama_inventaris']}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  posLocale(context).pos2edf59b130d4(
                    (row['qty']).toString(),
                    (row['unit']).toString(),
                    (row['received_qty'] ?? 0).toString(),
                    (row['resolved_qty'] ?? 0).toString(),
                  ),
                ),
                for (final batch in transferMaps(row['batch_allocations']))
                  Text(
                    posLocale(context).posa2f8e389c7e3(
                      (batch['no_batch']).toString(),
                      (batch['tanggal_kadaluarsa'] ?? '').toString(),
                      (batch['qty']).toString(),
                    ),
                  ),
                if ((row['serial_numbers'] as List? ?? []).isNotEmpty)
                  Text(
                    posLocale(context).pos78308eaba248(
                      ((row['serial_numbers'] as List).join(', ')).toString(),
                    ),
                  ),
              ],
            ),
          ),
        if (document['status'] == 'in_transit' && canReceive) ...[
          if (rows.isNotEmpty)
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => onAction('receive_transfer'),
                  child: const PosText('Terima Mutasi'),
                ),
                OutlinedButton(
                  onPressed: () => onAction('report_transfer'),
                  child: const PosText('Laporkan kurang/rusak'),
                ),
              ],
            )
          else
            const PosText(
              'Tidak ada sisa bebas; tunggu keputusan laporan selisih.',
            ),
        ],
        if (transferMaps(document['receipts']).isNotEmpty) ...[
          const Divider(height: 24),
          const PosText(
            'Riwayat penerimaan',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          for (final receipt in transferMaps(document['receipts']))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    posLocale(context).posb181ba4478da(
                      (receipt['received_date'] ??
                              inventoryDocumentDate(receipt['received_at']))
                          .toString(),
                      (receipt['posting_date'] ?? '-').toString(),
                    ),
                  ),
                  for (final line in transferMaps(receipt['items'])) ...[
                    Text(
                      '${transferMaps(document['items']).where((i) => i['_id'] == line['item_id']).firstOrNull?['nama_inventaris'] ?? 'Barang'} · ${line['qty']} · ${place(line['location'])}',
                    ),
                    if ((line['serial_numbers'] as List? ?? []).isNotEmpty)
                      Text(
                        posLocale(context).pos2520218913bd(
                          ((line['serial_numbers'] as List).join(
                            ', ',
                          )).toString(),
                        ),
                      ),
                    for (final batch in transferMaps(line['batch_allocations']))
                      Text(
                        posLocale(context).posa2f8e389c7e3(
                          (batch['no_batch']).toString(),
                          (batch['tanggal_kadaluarsa'] ?? '').toString(),
                          (batch['qty']).toString(),
                        ),
                      ),
                  ],
                ],
              ),
            ),
        ],
        if (transferMaps(document['discrepancies']).isNotEmpty) ...[
          const Divider(height: 24),
          const PosText(
            'Penyelesaian selisih',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          for (final report in transferMaps(document['discrepancies']))
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${report['kind'] == 'damaged' ? ('Rusak').tr(context) : ('Hilang/kurang').tr(context)} · ${report['status']}',
                    ),
                    Text('${report['reason']}'),
                    if ((report['evidence_url']?.toString() ?? '').isNotEmpty)
                      SelectableText('${report['evidence_url']}'),
                    for (final row in transferMaps(report['items']))
                      Text(
                        posLocale(context).pos256020cc43aa(
                          (row['qty']).toString(),
                          (row['serial_numbers'] ?? '').toString(),
                        ),
                      ),
                    if (report['decision_note'] != null)
                      Text(
                        posLocale(
                          context,
                        ).pos735eff437800((report['decision_note']).toString()),
                      ),
                    if (report['quarantine']?['cabang_id'] != null)
                      Text(
                        posLocale(context).pos9b789015b765(
                          (place(report['quarantine'])).toString(),
                        ),
                      ),
                    if (report['scrap_number'] != null)
                      Text(
                        posLocale(
                          context,
                        ).pos685b57405ff1((report['scrap_number']).toString()),
                      ),
                    if (report['status'] == 'pending' &&
                        canDecide &&
                        report['reported_by']?.toString() != actorId)
                      OutlinedButton(
                        onPressed: () =>
                            onAction('decide_transfer:${report['_id']}'),
                        child: const PosText('Periksa & putuskan selisih'),
                      ),
                  ],
                ),
              ),
            ),
        ],
        if ((document['total_biaya'] as num? ?? 0) > 0) ...[
          const Divider(height: 24),
          Text(
            posLocale(context).pos4ba07f7ac271(
              (document['total_biaya']).toString(),
              (document['biaya_mode']).toString(),
              (document['biaya_alokasi']).toString(),
            ),
          ),
          Text(
            posLocale(context).posd88b4d30bc43(
              (document['payment_account_name'] ??
                      document['payment_bank_account_id'] ??
                      '-')
                  .toString(),
            ),
          ),
          Text(
            posLocale(context).pos424b98aa8546(
              (document['payment_branch_name'] ??
                      document['payment_branch_id'] ??
                      '-')
                  .toString(),
            ),
          ),
          Text(
            posLocale(context).posa21c3b378169(
              (document['branch_name'] ?? '-').toString(),
              (document['project_name'] ?? '-').toString(),
            ),
          ),
          for (final cost in transferMaps(document['biaya_transfer']))
            Text(
              '${cost['jenis_biaya']} · ${cost['deskripsi'] ?? ''} · Rp${cost['nominal']}',
            ),
          Text(
            posLocale(context).pose627ba45da07(
              (document['journal_status'] ?? '-').toString(),
              (document['journal_error'] == null
                      ? ''
                      : (' · ${document['journal_error']}').tr(context))
                  .toString(),
            ),
          ),
        ],
      ],
    );
  }
}
