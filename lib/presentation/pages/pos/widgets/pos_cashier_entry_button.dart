import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';

/// Opens cashier; PIN, outlet and shift guards live in the workspace itself.
class PosCashierEntryButton extends StatelessWidget {
  const PosCashierEntryButton({super.key, required this.onOpenCashier});
  final VoidCallback onOpenCashier;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      materialTapTargetSize: MaterialTapTargetSize.padded,
      // This shell action remains visible beside nested pages with their own FAB.
      // It switches tabs, so no shared-element flight is needed.
      heroTag: null,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      tooltip: ('Buka kasir').tr(context),
      onPressed: onOpenCashier,
      child: const Icon(Icons.point_of_sale, size: 20),
    );
  }
}
