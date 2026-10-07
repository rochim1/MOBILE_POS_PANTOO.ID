import 'package:flutter/material.dart';

/// Keeps an input sheet at the same height while the system keyboard opens.
///
/// Use this inside a scroll-controlled modal bottom sheet. The route remains
/// anchored to the bottom; its scrollable content can add [viewInsets] padding
/// so the focused field is still reachable above the keyboard.
class PosKeyboardStableSheet extends StatelessWidget {
  const PosKeyboardStableSheet({
    super.key,
    required this.child,
    this.heightFactor = 0.85,
  });

  final Widget child;
  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight = media.size.height - media.viewPadding.vertical;
    return SizedBox(height: availableHeight * heightFactor, child: child);
  }
}
