import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';

class PosCheckoutRecoveryPanel extends StatelessWidget {
  const PosCheckoutRecoveryPanel({
    super.key,
    required this.message,
    required this.busy,
    this.errorMessage = '',
    this.onRecover,
  });
  final String message;
  final bool busy;
  final String errorMessage;
  final VoidCallback? onRecover;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history, size: 42, color: Color(0xFF087F78)),
              const SizedBox(height: 16),
              const PosText(
                'Periksa pembayaran sebelumnya',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              PosText(message, textAlign: TextAlign.center),
              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Container(
                    key: const Key('checkout_recovery_error'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PosText(
                            errorMessage,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('recover_checkout'),
                onPressed: busy ? null : onRecover,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: PosText(
                  busy ? 'Memulihkan pembayaran...' : 'Pulihkan pembayaran',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
