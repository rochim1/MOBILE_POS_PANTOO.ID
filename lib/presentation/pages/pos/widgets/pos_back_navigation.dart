import 'package:flutter/material.dart';

/// Shell destinations are not Navigator routes. Consume Android back here;
/// pushed routes (dialogs, editors, payment) still handle their own back first.
class PosBackNavigation extends StatelessWidget {
  const PosBackNavigation({
    super.key,
    required this.onBack,
    required this.child,
  });
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && ModalRoute.of(context)?.isCurrent == true) onBack();
    },
    child: child,
  );
}
