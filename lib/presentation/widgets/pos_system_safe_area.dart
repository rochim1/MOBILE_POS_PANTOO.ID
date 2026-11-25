import 'package:flutter/material.dart';

/// Reserves device navigation/cutout space above the root Navigator, including
/// pushed routes, modal sheets, dialogs and overlays that omit a local SafeArea.
/// SafeArea consumes MediaQuery padding so protected children do not add it twice.
/// Top status-bar handling remains with the existing Scaffold/AppBar/PIN layout.
class PosSystemSafeArea extends StatelessWidget {
  const PosSystemSafeArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: SafeArea(top: false, child: child),
  );
}
