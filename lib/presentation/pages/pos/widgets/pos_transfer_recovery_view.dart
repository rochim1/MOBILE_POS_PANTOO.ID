import 'package:flutter/material.dart';
import '../../../../l10n/pos_localization.dart';

String transferRecoveryText(BuildContext context, String id, String en) =>
    posLocale(context).localeName == 'en' ? en : id;

class PosTransferRecoveryView extends StatelessWidget {
  const PosTransferRecoveryView({
    super.key,
    required this.intent,
    required this.busy,
    required this.onRecover,
  });
  final Map<String, dynamic> intent;
  final bool busy;
  final VoidCallback onRecover;
  @override
  Widget build(BuildContext context) {
    final variables = intent['variables'] as Map? ?? {};
    final input = variables['input'] as Map? ?? variables;
    final rows = input['items'] as List? ?? [];
    String t(String id, String en) => transferRecoveryText(context, id, en);
    final process = switch (intent['root']) {
      'CreateInventoryTransfer' => t('Pembuatan transfer', 'Create transfer'),
      'ReceiveInventoryTransfer' => t(
        'Penerimaan transfer',
        'Receive transfer',
      ),
      'ReportInventoryTransferDiscrepancy' => t(
        'Laporan selisih',
        'Discrepancy report',
      ),
      'DecideInventoryTransferDiscrepancy' => t(
        'Keputusan selisih',
        'Discrepancy decision',
      ),
      'PostInventoryTransfer' => t('Pengiriman transfer', 'Dispatch transfer'),
      'CancelInventoryTransfer' => t('Pembatalan transfer', 'Cancel transfer'),
      _ => t('Perubahan status transfer', 'Transfer status change'),
    };
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.history, size: 40),
        const SizedBox(height: 16),
        Text(
          t('Periksa transfer sebelumnya', 'Check previous transfer'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(
          t(
            'Hasil sebelumnya belum terkonfirmasi. Periksa permintaan yang sama; jangan membuat transfer atau penerimaan pengganti.',
            'The previous result is unconfirmed. Check the same request; do not create a replacement transfer or receipt.',
          ),
        ),
        const SizedBox(height: 16),
        Text(process),
        if (input['dari'] is Map)
          Text(
            '${t('Asal', 'Source')}: ${input['dari']['cabang_nama'] ?? input['dari']['cabang_id']}',
          ),
        if (input['ke'] is Map)
          Text(
            '${t('Tujuan', 'Destination')}: ${input['ke']['cabang_nama'] ?? input['ke']['cabang_id']}',
          ),
        SelectableText('${intent['request_id']}\n${intent['saved_at'] ?? ''}'),
        if (variables['id'] != null)
          Text('${t('Dokumen', 'Document')}: ${variables['id']}'),
        for (final row in rows.whereType<Map>())
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${row['nama_inventaris'] ?? row['inventaris_id'] ?? row['item_id'] ?? '-'} · ${row['qty']}',
            ),
          ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: busy ? null : onRecover,
          icon: busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.sync),
          label: Text(
            busy
                ? t('Memeriksa...', 'Checking...')
                : t('Periksa transfer sebelumnya', 'Check previous transfer'),
          ),
        ),
      ],
    );
  }
}
