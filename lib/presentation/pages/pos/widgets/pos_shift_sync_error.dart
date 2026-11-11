import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:flutter/material.dart';

class PosShiftSyncError extends StatelessWidget {
  const PosShiftSyncError({
    super.key,
    required this.message,
    required this.onRetry,
    this.onClearCart,
  });
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onClearCart;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Icon(Icons.sync_problem, size: 40),
      const SizedBox(height: 12),
      const PosText('Data kasir belum siap', textAlign: TextAlign.center),
      const SizedBox(height: 8),
      PosText(message, textAlign: TextAlign.center),
      const SizedBox(height: 12),
      TextButton(onPressed: onRetry, child: const PosText('Periksa kembali')),
      if (onClearCart != null)
        TextButton(
          onPressed: onClearCart,
          child: const PosText('Kosongkan keranjang & periksa'),
        ),
    ],
  );
}
