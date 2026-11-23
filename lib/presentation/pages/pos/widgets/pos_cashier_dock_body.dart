import 'package:flutter/material.dart';

/// A center-docked FAB extends into the body. Reserve that space so bottom
/// payment/save actions remain fully visible and receive the intended taps.
class PosCashierDockBody extends StatelessWidget {
  const PosCashierDockBody({
    super.key,
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      bottom: enabled ? (MediaQuery.sizeOf(context).width < 600 ? 32 : 24) : 0,
    ),
    child: child,
  );
}
