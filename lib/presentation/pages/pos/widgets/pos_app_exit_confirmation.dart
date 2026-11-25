import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/pos_localization.dart';

/// Closing the Android activity is not logout or shift closure. The caller
/// rechecks its PIN/payment/navigation guards after the dialog completes.
class PosAppExitConfirmation {
  bool _open = false;

  Future<void> request(
    BuildContext context, {
    required bool Function() canExit,
    bool Function()? isSameSession,
  }) async {
    if (_open ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        !context.mounted ||
        !canExit()) {
      return;
    }
    _open = true;
    var resolved = false;
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final l = posLocale(dialogContext);
          void choose(bool value) {
            if (resolved) return;
            resolved = true;
            Navigator.pop(dialogContext, value);
          }

          return AlertDialog(
            title: Text(l.exitAppTitle),
            content: Text(l.exitAppMessage),
            actions: [
              TextButton(
                autofocus: true,
                onPressed: () => choose(false),
                child: const PosText('Batal'),
              ),
              FilledButton(
                onPressed: () => choose(true),
                child: Text(l.exitAppConfirm),
              ),
            ],
          );
        },
      );
      if (confirmed == true &&
          context.mounted &&
          canExit() &&
          (isSameSession?.call() ?? true)) {
        await SystemNavigator.pop();
      }
    } on PlatformException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(posLocale(context).exitAppFailed)),
        );
      }
    } finally {
      _open = false;
    }
  }
}
