import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Applied above the Navigator, including forms on pushed/modal routes.
/// Only obscured editable fields are revealed; PIN shortcuts and visible
/// fields do not cause a scroll. No focus or text value is changed here.
class PosKeyboardVisibility extends StatefulWidget {
  const PosKeyboardVisibility({super.key, required this.child});
  final Widget child;

  @override
  State<PosKeyboardVisibility> createState() => _PosKeyboardVisibilityState();
}

class _PosKeyboardVisibilityState extends State<PosKeyboardVisibility>
    with WidgetsBindingObserver {
  Timer? _settle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_schedule);
  }

  @override
  void didChangeMetrics() => _schedule();

  void _schedule() {
    _settle?.cancel();
    // Coalesce keyboard animation metrics, then use the final form layout.
    _settle = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
      WidgetsBinding.instance.ensureVisualUpdate();
    });
  }

  void _reveal() {
    if (!mounted) return;
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null || !focusContext.mounted) return;
    final editable = focusContext.findAncestorStateOfType<EditableTextState>();
    if (editable == null || !editable.mounted) return;
    var belongsHere = false;
    focusContext.visitAncestorElements((element) {
      if (element == context) belongsHere = true;
      return !belongsHere;
    });
    if (!belongsHere) return;
    final view = View.of(context);
    final inset = view.viewInsets.bottom / view.devicePixelRatio;
    if (inset <= 0) return;

    BuildContext fieldContext = editable.context;
    editable.context.visitAncestorElements((element) {
      if (element.widget is TextField) {
        fieldContext = element;
        return false;
      }
      return true;
    });
    var rect = _globalRect(fieldContext);
    if (rect == null) return;
    var top = view.viewPadding.top / view.devicePixelRatio;
    var bottom =
        (view.physicalSize.height - view.viewInsets.bottom) /
        view.devicePixelRatio;
    var scroll = Scrollable.maybeOf(fieldContext);
    while (scroll != null) {
      if (axisDirectionToAxis(scroll.position.axisDirection) == Axis.vertical) {
        final viewport = _globalRect(
          scroll.position.context.notificationContext,
        );
        if (viewport != null) {
          top = math.max(top, viewport.top);
          bottom = math.min(bottom, viewport.bottom);
        }
      }
      scroll = Scrollable.maybeOf(scroll.context);
    }
    const gap = 20.0;
    if (bottom <= top) return;
    // A large multiline field cannot fit as a whole; keep its active caret
    // visible instead of oscillating between the top and bottom of the field.
    if (rect.height + gap * 2 > bottom - top) {
      final selection = editable.textEditingValue.selection;
      if (!selection.isValid) return;
      final render = editable.renderEditable;
      rect = MatrixUtils.transformRect(
        render.getTransformTo(null),
        render.getLocalRectForCaret(selection.extent),
      );
      if (rect.top >= top + gap && rect.bottom <= bottom - gap) return;
      final caretGap = math.min(
        gap,
        math.max(0.0, (bottom - top - rect.height) / 2),
      );
      render.showOnScreen(
        rect: render.getLocalRectForCaret(selection.extent).inflate(caretGap),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
      return;
    }
    if (rect.top >= top + gap && rect.bottom <= bottom - gap) return;
    unawaited(
      Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignmentPolicy: rect.bottom > bottom - gap
            ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
            : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
      ),
    );
  }

  @override
  void dispose() {
    _settle?.cancel();
    FocusManager.instance.removeListener(_schedule);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Rect? _globalRect(BuildContext? context) {
  if (context == null || !context.mounted) return null;
  final render = context.findRenderObject();
  if (render is! RenderBox || !render.attached || !render.hasSize) return null;
  return MatrixUtils.transformRect(
    render.getTransformTo(null),
    Offset.zero & render.size,
  );
}

/// Reserves only the portion of the active vertical scroll viewport actually
/// covered by the keyboard. Unlike padding on the whole route this keeps a
/// dialog/sheet's outer bounds, title and actions stable. Resizing Scaffolds
/// already end above the keyboard, so they receive no second inset.
class PosKeyboardScrollBehavior extends MaterialScrollBehavior {
  const PosKeyboardScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    final decorated = super.buildScrollbar(context, child, details);
    if (axisDirectionToAxis(details.direction) != Axis.vertical ||
        context.findAncestorWidgetOfExactType<EditableText>() != null ||
        context
                .dependOnInheritedWidgetOfExactType<_KeyboardViewportScope>()
                ?.enabled ==
            true) {
      return decorated;
    }
    return _KeyboardViewport(child: decorated);
  }
}

class _KeyboardViewportScope extends InheritedWidget {
  const _KeyboardViewportScope({required this.enabled, required super.child});
  final bool enabled;
  @override
  bool updateShouldNotify(_KeyboardViewportScope oldWidget) =>
      enabled != oldWidget.enabled;
}

class _KeyboardViewport extends StatefulWidget {
  const _KeyboardViewport({required this.child});
  final Widget child;
  @override
  State<_KeyboardViewport> createState() => _KeyboardViewportState();
}

class _KeyboardViewportState extends State<_KeyboardViewport>
    with WidgetsBindingObserver {
  double _covered = 0;
  bool _bounded = true;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_measureAfterLayout);
  }

  @override
  void didChangeMetrics() => _measureAfterLayout();

  void _measureAfterLayout() {
    if (_scheduled || !mounted) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted) return;
      var ownsFocus = false;
      final focusContext = FocusManager.instance.primaryFocus?.context;
      if (focusContext?.findAncestorStateOfType<EditableTextState>() != null) {
        focusContext!.visitAncestorElements((element) {
          if (element == context) ownsFocus = true;
          return !ownsFocus;
        });
      }
      final view = View.of(context);
      final rect = _globalRect(context);
      final render = context.findRenderObject();
      final bounded =
          render is RenderBox && render.constraints.hasBoundedHeight;
      var covered = 0.0;
      if (bounded && ownsFocus && rect != null && view.viewInsets.bottom > 0) {
        final keyboardTop =
            (view.physicalSize.height - view.viewInsets.bottom) /
            view.devicePixelRatio;
        covered = (rect.bottom - keyboardTop).clamp(
          0.0,
          math.max(0.0, rect.height),
        );
      }
      if (_bounded != bounded || (_covered - covered).abs() > .5) {
        setState(() {
          _bounded = bounded;
          _covered = covered;
        });
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_measureAfterLayout);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _measureAfterLayout();
    // Padding supports intrinsic measurement used by AlertDialog. A
    // LayoutBuilder here would break cash/note dialogs before they can open.
    // Unbounded shrink-wrapped lists release the scope to bounded descendants.
    return _KeyboardViewportScope(
      enabled: _bounded,
      child: Padding(
        padding: EdgeInsets.only(bottom: _covered),
        child: widget.child,
      ),
    );
  }
}
