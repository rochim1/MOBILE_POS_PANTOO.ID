import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import '../utils/pos_navbar_action_policy.dart';

/// Shared action rendering for phone overflow and wider Android/tablet views.
/// Display services are only built on pages that actually use them.
class PosNavbarContextActions extends StatelessWidget {
  const PosNavbarContextActions({
    super.key,
    required this.policy,
    required this.compact,
    required this.showKeyboardIcon,
    required this.notificationButton,
    required this.customerDisplayBuilder,
    required this.onKeyboardHelp,
    required this.onToggleGuide,
    required this.onLock,
    required this.onCustomerDisplay,
  });
  final PosNavbarActionPolicy policy;
  final bool compact, showKeyboardIcon;
  final Widget notificationButton;
  final WidgetBuilder customerDisplayBuilder;
  final VoidCallback onKeyboardHelp, onToggleGuide, onLock, onCustomerDisplay;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (!compact && showKeyboardIcon && policy.keyboardHelp)
        IconButton(
          tooltip: ('Shortcut keyboard (F1)').tr(context),
          onPressed: onKeyboardHelp,
          icon: const Icon(Icons.keyboard_alt_outlined, color: Colors.white),
        ),
      if (!compact && policy.customerDisplay)
        Builder(builder: customerDisplayBuilder),
      if (!compact && policy.setupGuide)
        IconButton(
          tooltip: ('Checklist kesiapan POS').tr(context),
          onPressed: onToggleGuide,
          icon: const Icon(Icons.checklist_rounded, color: Colors.white),
        ),
      if (policy.notifications)
        SizedBox(width: compact ? 40 : 48, child: notificationButton),
      if (!compact && policy.lock)
        IconButton(
          tooltip: ('Kunci POS').tr(context),
          onPressed: onLock,
          icon: const Icon(Icons.lock_outline, color: Colors.white),
        ),
      if (compact && policy.hasOverflow)
        SizedBox(
          width: 40,
          child: PopupMenuButton<String>(
            tooltip: ('Aksi lainnya').tr(context),
            padding: EdgeInsets.zero,
            iconSize: 20,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) => switch (value) {
              'keyboard_help' => onKeyboardHelp(),
              'setup' => onToggleGuide(),
              'customer_display' => onCustomerDisplay(),
              'lock' => onLock(),
              _ => null,
            },
            itemBuilder: (_) => [
              if (policy.keyboardHelp)
                _entry(
                  'keyboard_help',
                  Icons.keyboard_alt_outlined,
                  'Shortcut keyboard',
                ),
              if (policy.setupGuide)
                _entry('setup', Icons.checklist_rounded, 'Checklist kesiapan'),
              if (policy.customerDisplay)
                _entry(
                  'customer_display',
                  Icons.connected_tv_outlined,
                  'Layar pelanggan',
                ),
              if (policy.lock) _entry('lock', Icons.lock_outline, 'Kunci POS'),
            ],
          ),
        ),
    ],
  );

  PopupMenuItem<String> _entry(String value, IconData icon, String label) =>
      PopupMenuItem(
        value: value,
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Flexible(child: PosText(label)),
          ],
        ),
      );
}
