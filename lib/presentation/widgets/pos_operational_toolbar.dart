import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/themes/colors_theme.dart';
import '../../l10n/pos_localization.dart';
import 'inventory_action_style.dart';

/// Primary search is always visible. Only secondary filters may collapse.
class PosOperationalToolbar extends StatefulWidget {
  const PosOperationalToolbar({
    super.key,
    required this.search,
    this.primaryAction,
    this.filters,
    this.filterAction,
    this.filterToggleKey,
    this.activeCount = 0,
  });
  final Widget search;
  final Widget? primaryAction, filters, filterAction;
  final Key? filterToggleKey;
  final int activeCount;
  @override
  State<PosOperationalToolbar> createState() => _PosOperationalToolbarState();
}

class _PosOperationalToolbarState extends State<PosOperationalToolbar> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
        ),
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          floatingLabelBehavior: FloatingLabelBehavior.always,
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD7E0E5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inline =
              constraints.maxWidth >= 680 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.3;
          final filter =
              widget.filterAction ??
              (widget.filters == null
                  ? null
                  : Semantics(
                      expanded: _expanded,
                      child: IconButton.outlined(
                        key: widget.filterToggleKey,
                        tooltip: 'Filter'.tr(context),
                        style: InventoryActionStyle.filter(),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          setState(() => _expanded = !_expanded);
                        },
                        icon: Badge(
                          isLabelVisible: widget.activeCount > 0,
                          label: Text('${widget.activeCount}'),
                          child: Icon(
                            _expanded
                                ? Icons.filter_list_off
                                : Icons.tune_rounded,
                          ),
                        ),
                      ),
                    ));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: widget.search),
                  if (filter != null) ...[const SizedBox(width: 8), filter],
                  if (inline && widget.primaryAction != null) ...[
                    const SizedBox(width: 12),
                    widget.primaryAction!,
                  ],
                ],
              ),
              if (!inline && widget.primaryAction != null) ...[
                const SizedBox(height: 10),
                widget.primaryAction!,
              ],
              if (widget.filters != null)
                Visibility(
                  visible: _expanded,
                  maintainState: true,
                  child: ExcludeFocus(
                    excluding: !_expanded,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Material(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFE1E5E9)),
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: math.max(
                              80,
                              math.min(
                                240,
                                MediaQuery.sizeOf(context).height * .3,
                              ),
                            ),
                          ),
                          child: SingleChildScrollView(
                            primary: false,
                            padding: const EdgeInsets.all(14),
                            child: widget.filters,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Optional explanations stay available without displacing operational data.
class PosOperationalHelp extends StatelessWidget {
  const PosOperationalHelp({
    super.key,
    required this.title,
    required this.message,
  });
  final String title, message;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF0F7F6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFDCEBE7)),
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      leading: const Icon(
        Icons.info_outline,
        size: 20,
        color: AppColors.primary,
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF475467),
            ),
          ),
        ),
      ],
    ),
  );
}
