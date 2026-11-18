import 'package:flutter/material.dart';
import '../../core/themes/colors_theme.dart';
import '../../l10n/language_picker.dart';

/// Shared setup shell. Language stays outside the scrollable/busy form so it
/// remains discoverable during workspace creation, configuration and retries.
class PosSetupScaffold extends StatelessWidget {
  const PosSetupScaffold({
    super.key,
    required this.body,
    this.backgroundColor = AppColors.primary,
    this.backgroundDecoration,
  });

  final Widget body;
  final Color backgroundColor;
  final Decoration? backgroundDecoration;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: backgroundColor,
    body: DecoratedBox(
      decoration: backgroundDecoration ?? const BoxDecoration(),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PosSetupLanguageBar(),
            Expanded(child: body),
          ],
        ),
      ),
    ),
  );
}

/// Fill the viewport before limiting card width: gestures on the surrounding
/// background must reach the same scrollable as gestures on the form itself.
class PosSetupScrollBody extends StatelessWidget {
  const PosSetupScrollBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      hitTestBehavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: constraints.hasBoundedHeight
              ? (constraints.maxHeight - 40).clamp(0, double.infinity)
              : 0,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        ),
      ),
    ),
  );
}

class PosSetupLanguageBar extends StatelessWidget {
  const PosSetupLanguageBar({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        shape: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: const LanguagePicker(),
        ),
      ),
    ),
  );
}
