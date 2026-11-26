import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/pos_localization.dart';
import '../../../bloc/pos/pos_bloc.dart';
import '../../../bloc/pos/pos_event.dart';
import '../../../bloc/pos/pos_state.dart';
import 'pos_promo_feedback.dart';

class PosDiscountDialog extends StatefulWidget {
  const PosDiscountDialog({super.key});

  @override
  State<PosDiscountDialog> createState() => _PosDiscountDialogState();
}

class _PosDiscountDialogState extends State<PosDiscountDialog> {
  late final TextEditingController _discount;
  late final TextEditingController _promo;

  @override
  void initState() {
    super.initState();
    final state = context.read<PosBloc>().state;
    _discount = TextEditingController(
      text: state.effectiveManualDiscountPercent.toStringAsFixed(0),
    );
    _promo = TextEditingController(text: state.effectivePromoCode);
  }

  @override
  void dispose() {
    _discount.dispose();
    _promo.dispose();
    super.dispose();
  }

  void _apply(PosState state) {
    if (state.pricingPreviewLoading) return;
    final canOverride =
        (state.runtimeConfig['permissions'] as Map?)?['manage_settings'] ==
            true &&
        state.manualDiscountAllowed;
    final discount = canOverride
        ? double.tryParse(_discount.text)
        : state.effectiveManualDiscountPercent;
    if (discount == null ||
        !discount.isFinite ||
        discount < 0 ||
        discount > 100) {
      setState(() => _invalidDiscount = true);
      return;
    }
    setState(() => _invalidDiscount = false);
    context.read<PosBloc>().add(
      UpdateDiscount(
        manualDiscountPercent: discount,
        promoCode: state.promoCodeAllowed ? _promo.text : '',
        discountPolicy: state.effectiveDiscountPolicy,
      ),
    );
  }

  bool _invalidDiscount = false;

  @override
  Widget build(BuildContext context) => BlocBuilder<PosBloc, PosState>(
    builder: (context, state) {
      final canOverride =
          (state.runtimeConfig['permissions'] as Map?)?['manage_settings'] ==
              true &&
          state.manualDiscountAllowed;
      return AlertDialog(
        title: const PosText('Diskon & Promo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canOverride) ...[
                TextField(
                  controller: _discount,
                  keyboardType: TextInputType.number,
                  enabled: !state.pricingPreviewLoading,
                  decoration: InputDecoration(
                    labelText: 'Diskon manual (%)'.tr(context),
                    errorText: _invalidDiscount
                        ? 'Diskon harus antara 0–100%'.tr(context)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (state.promoCodeAllowed)
                TextField(
                  controller: _promo,
                  textCapitalization: TextCapitalization.characters,
                  enabled: !state.pricingPreviewLoading,
                  onSubmitted: (_) => _apply(state),
                  decoration: InputDecoration(
                    labelText: 'Kode promo'.tr(context),
                  ),
                ),
              if (state.promoCodeAllowed && state.promoCode.isNotEmpty) ...[
                const SizedBox(height: 16),
                PosPromoFeedback(state: state),
              ],
            ],
          ),
        ),
        actions: [
          if (state.promoCodeAllowed && state.promoCode.isNotEmpty)
            TextButton(
              onPressed: state.pricingPreviewLoading
                  ? null
                  : () {
                      _promo.clear();
                      _apply(state);
                    },
              child: const PosText('Hapus'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const PosText('Tutup'),
          ),
          FilledButton(
            onPressed: state.pricingPreviewLoading ? null : () => _apply(state),
            child: state.pricingPreviewLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const PosText('Terapkan'),
          ),
        ],
      );
    },
  );
}
