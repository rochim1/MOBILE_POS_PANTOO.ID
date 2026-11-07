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
        Text(
          'Alur & rincian transfer',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          routing == null
              ? 'Alur historis belum tercatat; periksa status dan penerimaan.'
              : '${document['routing_snapshot'] != null ? 'Aturan saat dikirim' : 'Rencana saat ini'}: ${routing['mode'] == 'direct' ? 'Langsung selesai saat dikirim' : 'Kirim → Transit → Terima di tujuan'}',
        ),
        if (routing?['reason'] != null) Text('${routing!['reason']}'),
        Text(
          'Asal: ${place(document['dari'])}\nTujuan: ${place(document['ke'])}',
        ),
        if (document['transit']?['cabang_id'] != null)
          Text('Transit: ${place(document['transit'])}'),
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
                  'Dikirim ${row['qty']} ${row['unit']} · Diterima ${row['received_qty'] ?? 0} · Diselesaikan ${row['resolved_qty'] ?? 0}',
                ),
                for (final batch in transferMaps(row['batch_allocations']))
                  Text(
                    'Batch ${batch['no_batch']} · ${batch['tanggal_kadaluarsa'] ?? ''} · ${batch['qty']}',
                  ),
                if ((row['serial_numbers'] as List? ?? []).isNotEmpty)
                  Text('Seri: ${(row['serial_numbers'] as List).join(', ')}'),
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
                  child: const Text('Terima Mutasi'),
                ),
                OutlinedButton(
                  onPressed: () => onAction('report_transfer'),
                  child: const Text('Laporkan kurang/rusak'),
                ),
              ],
            )
          else
            const Text(
              'Tidak ada sisa bebas; tunggu keputusan laporan selisih.',
            ),
        ],
        if (transferMaps(document['receipts']).isNotEmpty) ...[
          const Divider(height: 24),
          const Text(
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
                    'Fisik ${receipt['received_date'] ?? inventoryDocumentDate(receipt['received_at'])} · Pembukuan ${receipt['posting_date'] ?? '-'}',
                  ),
                  for (final line in transferMaps(receipt['items'])) ...[
                    Text(
                      '${transferMaps(document['items']).where((i) => i['_id'] == line['item_id']).firstOrNull?['nama_inventaris'] ?? 'Barang'} · ${line['qty']} · ${place(line['location'])}',
                    ),
                    if ((line['serial_numbers'] as List? ?? []).isNotEmpty)
                      Text(
                        'Seri ${(line['serial_numbers'] as List).join(', ')}',
                      ),
                    for (final batch in transferMaps(line['batch_allocations']))
                      Text(
                        'Batch ${batch['no_batch']} · ${batch['tanggal_kadaluarsa'] ?? ''} · ${batch['qty']}',
                      ),
                  ],
                ],
              ),
            ),
        ],
        if (transferMaps(document['discrepancies']).isNotEmpty) ...[
          const Divider(height: 24),
          const Text(
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
                      '${report['kind'] == 'damaged' ? 'Rusak' : 'Hilang/kurang'} · ${report['status']}',
                    ),
                    Text('${report['reason']}'),
                    if ((report['evidence_url']?.toString() ?? '').isNotEmpty)
                      SelectableText('${report['evidence_url']}'),
                    for (final row in transferMaps(report['items']))
                      Text(
                        '${row['qty']} unit · ${row['serial_numbers'] ?? ''}',
                      ),
                    if (report['decision_note'] != null)
                      Text('Keputusan: ${report['decision_note']}'),
                    if (report['quarantine']?['cabang_id'] != null)
                      Text('Karantina: ${place(report['quarantine'])}'),
                    if (report['scrap_number'] != null)
                      Text('Bukti kehilangan: ${report['scrap_number']}'),
                    if (report['status'] == 'pending' &&
                        canDecide &&
                        report['reported_by']?.toString() != actorId)
                      OutlinedButton(
                        onPressed: () =>
                            onAction('decide_transfer:${report['_id']}'),
                        child: const Text('Periksa & putuskan selisih'),
                      ),
                  ],
                ),
              ),
            ),
        ],
        if ((document['total_biaya'] as num? ?? 0) > 0) ...[
          const Divider(height: 24),
          Text(
            'Biaya transfer Rp${document['total_biaya']} · ${document['biaya_mode']} / ${document['biaya_alokasi']}',
          ),
          Text(
            'Rekening: ${document['payment_account_name'] ?? document['payment_bank_account_id'] ?? '-'}',
          ),
          Text(
            'Cabang pembayar: ${document['payment_branch_name'] ?? document['payment_branch_id'] ?? '-'}',
          ),
          Text(
            'Penanggung jawab: ${document['branch_name'] ?? '-'} · Proyek: ${document['project_name'] ?? '-'}',
          ),
          for (final cost in transferMaps(document['biaya_transfer']))
            Text(
              '${cost['jenis_biaya']} · ${cost['deskripsi'] ?? ''} · Rp${cost['nominal']}',
            ),
          Text(
            'Jurnal: ${document['journal_status'] ?? '-'}${document['journal_error'] == null ? '' : ' · ${document['journal_error']}'}',
          ),
        ],
      ],
    );
  }
}
