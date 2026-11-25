import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';

/// Compact list filters, not transaction inputs or recovery/submit actions.
/// The mounted subtree keeps edits and selections when hidden or resized.
class PosCollapsibleFilters extends StatefulWidget {
  const PosCollapsibleFilters({
    super.key,
    required this.child,
    this.activeCount = 0,
    this.actions = const [],
    this.toggleKey,
    this.forceExpanded = false,
    this.breakpoint = 600,
  });

  final Widget child;
  final int activeCount;
  final List<Widget> actions;
  final Key? toggleKey;
  final bool forceExpanded;
  final double breakpoint;

  @override
  State<PosCollapsibleFilters> createState() => _PosCollapsibleFiltersState();
}

class _PosCollapsibleFiltersState extends State<PosCollapsibleFilters> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Use the viewport, not a narrow desktop column, to identify a phone.
      final compact = MediaQuery.sizeOf(context).width < widget.breakpoint;
      final visible = !compact || _expanded || widget.forceExpanded;
      final available =
          MediaQuery.sizeOf(context).height -
          MediaQuery.viewInsetsOf(context).bottom;
      final panelHeight = math.max(48.0, math.min(240.0, available * .35));
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact && !widget.forceExpanded)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: widget.actions.isEmpty
                      ? constraints.maxWidth
                      : math.min(152, constraints.maxWidth),
                  child: Semantics(
                    expanded: _expanded,
                    child: OutlinedButton.icon(
                      key: widget.toggleKey,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: () {
                        if (_expanded) FocusScope.of(context).unfocus();
                        setState(() => _expanded = !_expanded);
                      },
                      icon: Badge(
                        isLabelVisible: widget.activeCount > 0,
                        label: Text('${widget.activeCount}'),
                        child: const Icon(Icons.filter_list_rounded),
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(child: Text('Filter'.tr(context))),
                          const SizedBox(width: 4),
                          Icon(
                            _expanded ? Icons.expand_less : Icons.expand_more,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ...widget.actions,
              ],
            )
          else if (widget.actions.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: widget.actions),
          Visibility(
            key: const ValueKey('filter_content'),
            visible: visible,
            maintainState: true,
            child: ExcludeFocus(
              excluding: !visible,
              child: Padding(
                padding: EdgeInsets.only(
                  top:
                      (compact && !widget.forceExpanded) ||
                          widget.actions.isNotEmpty
                      ? 8
                      : 0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: compact && !widget.forceExpanded
                        ? panelHeight
                        : double.infinity,
                  ),
                  child: SingleChildScrollView(
                    primary: false,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}
