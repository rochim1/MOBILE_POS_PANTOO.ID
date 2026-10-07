import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Keeps a form dialog at its original size while the keyboard overlays it.
///
/// [Dialog] normally adds the keyboard inset to its own padding, which can
/// compress a large form to only a few rows in landscape. Remove that inset
/// for the dialog layout, then restore it for the form content so scrollables
/// and focused fields still know where the keyboard is.
class PosKeyboardStableDialog extends StatelessWidget {
  const PosKeyboardStableDialog({
    super.key,
    required this.child,
    required this.width,
    required this.height,
    this.shape,
    this.insetPadding,
  });

  final Widget child;
  final double width;
  final double height;
  final ShapeBorder? shape;
  final EdgeInsets? insetPadding;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height -
        media.padding.vertical -
        (insetPadding?.vertical ?? 48);
    return MediaQuery(
      data: media.copyWith(viewInsets: EdgeInsets.zero),
      child: Dialog(
        clipBehavior: Clip.antiAlias,
        shape: shape,
        insetPadding:
            insetPadding ??
            const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: MediaQuery(
          data: media,
          child: SizedBox(
            width: width,
            height: math.min(height, availableHeight),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A fixed-height form dialog with a scrollable content region supplied by
/// the caller. The header and actions remain part of the full dialog instead
/// of being compressed by the keyboard in tablet landscape.
class PosKeyboardStableFormDialog extends StatelessWidget {
  const PosKeyboardStableFormDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    required this.width,
    required this.height,
    this.shape,
    this.insetPadding,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final double width;
  final double height;
  final ShapeBorder? shape;
  final EdgeInsets? insetPadding;

  @override
  Widget build(BuildContext context) => PosKeyboardStableDialog(
    width: width,
    height: height,
    shape: shape,
    insetPadding: insetPadding,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.titleLarge,
            child: title,
          ),
        ),
        const Divider(height: 1),
        Expanded(child: content),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: actions,
          ),
        ),
      ],
    ),
  );
}
