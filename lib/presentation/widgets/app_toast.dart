import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';

/// Toast overlay kompak yang tidak menutup area aksi di bagian bawah POS.
class AppToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void success(BuildContext context, String message) => _show(
    context,
    message: message,
    icon: Icons.check_circle,
    color: AppColors.success,
    background: AppColors.successBackground,
    border: AppColors.successBorder,
    duration: const Duration(seconds: 2),
  );

  static void error(BuildContext context, String message) => _show(
    context,
    message: message,
    icon: Icons.error_outline,
    color: AppColors.danger,
    background: AppColors.dangerBackground,
    border: AppColors.dangerBorder,
    duration: const Duration(seconds: 4),
  );

  static void info(BuildContext context, String message) => _show(
    context,
    message: message,
    icon: Icons.info_outline,
    color: AppColors.primary,
    background: AppColors.infoBackground,
    border: AppColors.infoBorder,
    duration: const Duration(seconds: 2),
  );

  static void warning(BuildContext context, String message) => _show(
    context,
    message: message,
    icon: Icons.warning_amber_rounded,
    color: AppColors.warning,
    background: AppColors.warningBackground,
    border: AppColors.warningBorder,
    duration: const Duration(seconds: 3),
  );

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
    required Color background,
    required Color border,
    required Duration duration,
  }) {
    _dismiss();
    final overlay = Overlay.of(context, rootOverlay: true);
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width > 384
        ? 360.0
        : mediaQuery.size.width - 24;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: mediaQuery.padding.top + 12,
        left: 12,
        width: width,
        child: Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.18),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Tutup',
                    onPressed: _dismiss,
                    icon: Icon(Icons.close, color: color, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
    _dismissTimer = Timer(duration, _dismiss);
  }

  static void _dismiss() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}
