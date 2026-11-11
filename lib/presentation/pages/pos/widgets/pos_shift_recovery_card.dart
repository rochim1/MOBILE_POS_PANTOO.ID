import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:flutter/material.dart';

class PosShiftRecoveryCard extends StatelessWidget {
  const PosShiftRecoveryCard({
    super.key,
    required this.storeName,
    required this.onRetry,
    this.onReturn,
  });

  final String storeName;
  final VoidCallback onRetry;
  final VoidCallback? onReturn;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              posLocale(context).posdabd37d4fec2((storeName).toString()),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            const PosText(
              'Lanjutkan shift tersebut, atau tutup setelah kas dan transaksi offline direkonsiliasi. Shift tidak ditutup otomatis.',
            ),
            const SizedBox(height: 12),
            if (onReturn != null)
              FilledButton(
                onPressed: onReturn,
                child: const PosText('Kembali ke shift aktif'),
              )
            else ...[
              const PosText(
                'Outlet shift aktif tidak ada dalam daftar akses. Minta supervisor memeriksa akses outlet; jangan membuat shift pengganti.',
              ),
              TextButton(
                onPressed: onRetry,
                child: const PosText('Periksa kembali shift'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
