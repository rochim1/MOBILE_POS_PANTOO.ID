import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../l10n/pos_localization.dart';
import 'pos_setup_tour.dart';

/// Informational only: dismissing this never marks operational setup complete.
class PosFirstSaleGuide extends StatefulWidget {
  final SharedPreferences preferences;
  final String scope, stepId, title;
  final bool enabled;
  final List<PosSetupTourStage> stages;
  final Widget child;
  const PosFirstSaleGuide({
    super.key,
    required this.preferences,
    required this.scope,
    required this.stepId,
    required this.title,
    required this.enabled,
    required this.stages,
    required this.child,
  });
  @override
  State<PosFirstSaleGuide> createState() => _PosFirstSaleGuideState();
}

class _PosFirstSaleGuideState extends State<PosFirstSaleGuide> {
  Timer? _retry;
  Route<dynamic>? _dialog;
  bool _showing = false;
  int _generation = 0;
  String get _seenKey =>
      'pos-first-sale-focus-v1:${widget.scope}:${widget.stepId}';
  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant PosFirstSaleGuide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled ||
        oldWidget.scope != widget.scope ||
        oldWidget.stepId != widget.stepId) {
      _dismiss();
    }
    _schedule();
  }

  void _dismiss() {
    final route = _dialog;
    _dialog = null;
    if (route != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route.isActive) route.navigator?.removeRoute(route);
      });
    }
  }

  void _schedule() {
    _retry?.cancel();
    final generation = ++_generation;
    if (!widget.enabled || widget.scope.isEmpty || widget.stages.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _tryAuto(generation, 0),
    );
  }

  void _tryAuto(int generation, int attempts) {
    if (!mounted ||
        generation != _generation ||
        !widget.enabled ||
        _showing ||
        widget.preferences.getBool(_seenKey) == true) {
      return;
    }
    final target = widget.stages.first.target?.currentContext
        ?.findRenderObject();
    if (ModalRoute.of(context)?.isCurrent != true ||
        MediaQuery.viewInsetsOf(context).bottom > 0 ||
        target is! RenderBox ||
        !target.hasSize) {
      if (attempts < 12) {
        _retry = Timer(
          const Duration(milliseconds: 150),
          () => _tryAuto(generation, attempts + 1),
        );
      }
      return;
    }
    unawaited(_open());
  }

  Future<void> _open() async {
    if (_showing ||
        !widget.enabled ||
        widget.stages.isEmpty ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final target = widget.stages.first.target;
    if (target?.currentContext == null) return;
    _showing = true;
    final generation = _generation;
    final guideKey = _seenKey;
    try {
      await widget.preferences.setBool(_seenKey, true);
      if (!mounted || !widget.enabled || generation != _generation) return;
      await Scrollable.ensureVisible(target!.currentContext!, alignment: .5);
      if (!mounted || !widget.enabled || generation != _generation) return;
      final stages = widget.stages
          .where((stage) => stage.target?.currentContext != null)
          .toList(growable: false);
      await showInteractivePosSetupTour(
        context,
        fallbackTarget: target,
        stepTitle: widget.title,
        stages: stages,
        isActive: () => mounted && widget.enabled && _seenKey == guideKey,
        onDialogReady: (dialogContext) =>
            _dialog = ModalRoute.of(dialogContext),
      );
    } finally {
      _dialog = null;
      _showing = false;
    }
  }

  @override
  void dispose() {
    _retry?.cancel();
    _generation++;
    _dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (widget.enabled && widget.scope.isNotEmpty)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _open,
            icon: const Icon(Icons.help_outline, size: 18),
            label: Text('Panduan langkah ini'.tr(context)),
          ),
        ),
      Expanded(child: widget.child),
    ],
  );
}
