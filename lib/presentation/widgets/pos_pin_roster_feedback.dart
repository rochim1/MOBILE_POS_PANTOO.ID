import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';

/// A failed read is not the same as an empty employee search.
class PosPinRosterFeedback extends StatelessWidget {
  const PosPinRosterFeedback({
    super.key,
    required this.error,
    required this.retryKey,
    required this.onRetry,
  });
  final String error;
  final Key retryKey;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            (error.isEmpty ? 'Karyawan tidak ditemukan' : error).tr(context),
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          if (error.isNotEmpty) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              key: retryKey,
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text('Coba lagi'.tr(context)),
            ),
          ],
        ],
      ),
    ),
  );
}
