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
              'Shift masih aktif di $storeName',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Lanjutkan shift tersebut, atau tutup setelah kas dan transaksi offline direkonsiliasi. Shift tidak ditutup otomatis.',
            ),
            const SizedBox(height: 12),
            if (onReturn != null)
              FilledButton(
                onPressed: onReturn,
                child: const Text('Kembali ke shift aktif'),
              )
            else ...[
              const Text(
                'Outlet shift aktif tidak ada dalam daftar akses. Minta supervisor memeriksa akses outlet; jangan membuat shift pengganti.',
              ),
              TextButton(
                onPressed: onRetry,
                child: const Text('Periksa kembali shift'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
