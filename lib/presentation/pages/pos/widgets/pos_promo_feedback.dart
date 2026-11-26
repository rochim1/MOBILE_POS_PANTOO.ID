import 'package:flutter/material.dart';
import '../../../../l10n/pos_localization.dart';
import '../../../bloc/pos/pos_state.dart';

/// The same verification result is visible in compact and expanded checkout.
class PosPromoFeedback extends StatelessWidget {
  const PosPromoFeedback({required this.state, super.key});
  final PosState state;

  @override
  Widget build(BuildContext context) {
    if (state.promoCode.isEmpty) return const SizedBox.shrink();
    if (state.pricingPreviewLoading) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(posLocale(context).promoValidating)),
        ],
      );
    }
    final serverMessage =
        state.pricingPreview?['promo_message']?.toString().trim() ?? '';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          state.promoApplied ? Icons.check_circle : Icons.info_outline,
          size: 18,
          color: state.promoApplied ? Colors.teal : Colors.deepOrange,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: PosText(
            serverMessage.isNotEmpty
                ? serverMessage
                : state.promoApplied
                ? 'Promo berhasil diterapkan'
                : 'Promo belum memenuhi ketentuan',
          ),
        ),
      ],
    );
  }
}
