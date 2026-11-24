import 'package:flutter/material.dart';

/// Preserve real text and touch sizes; short screens scroll instead of scaling.
class PosPinAccessViewport extends StatelessWidget {
  const PosPinAccessViewport({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: SizedBox(
            width: constraints.maxWidth.clamp(0.0, 420.0),
            child: child,
          ),
        ),
      ),
    ),
  );
}
