import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';

/// Owns its descendant context so readiness can read the shell's POS provider.
class PosCashierEntryButton extends StatefulWidget {
  const PosCashierEntryButton({
    super.key,
    required this.showSetupGuide,
    required this.onContinueSetup,
    required this.onOpenCashier,
  });
  final bool showSetupGuide;
  final Future<void> Function(BuildContext) onContinueSetup;
  final VoidCallback onOpenCashier;
  @override
  State<PosCashierEntryButton> createState() => _PosCashierEntryButtonState();
}

class _PosCashierEntryButtonState extends State<PosCashierEntryButton> {
  bool _busy = false;
  Future<void> _open() async {
    if (!widget.showSetupGuide) {
      widget.onOpenCashier();
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onContinueSetup(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text(
              'Kasir belum dapat dibuka. Periksa koneksi dan kesiapan toko, lalu coba lagi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FloatingActionButton.small(
    // This shell action remains visible beside nested pages with their own FAB.
    // It switches tabs, so no shared-element flight is needed.
    heroTag: null,
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    shape: const CircleBorder(),
    elevation: 2,
    tooltip: 'Buka kasir',
    onPressed: _busy ? null : _open,
    child: _busy
        ? const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : const Icon(Icons.point_of_sale, size: 20),
  );
}
