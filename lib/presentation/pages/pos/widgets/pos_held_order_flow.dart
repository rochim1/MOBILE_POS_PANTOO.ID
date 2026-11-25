import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../domain/models/hold_order.dart';
import '../../../../l10n/pos_localization.dart';
import '../../../bloc/pos/pos_bloc.dart';
import '../../../bloc/pos/pos_event.dart';
import '../../../widgets/app_toast.dart';

/// A local write is successful only after the BLoC confirms durable storage.
Future<bool> runPosHeldCartAction(
  BuildContext context,
  PosBloc bloc,
  PosEvent Function(Completer<bool>) createEvent,
) async {
  if (!context.mounted) return false;
  final navigator = Navigator.of(context, rootNavigator: true);
  final progress = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text('Memproses...'.tr(context))),
          ],
        ),
      ),
    ),
  );
  unawaited(navigator.push(progress));
  final completion = Completer<bool>();
  var succeeded = false;
  try {
    bloc.add(createEvent(completion));
    succeeded = await completion.future;
  } finally {
    // Remove only our route, even when PIN lock or navigation changed the top.
    if (progress.isActive) navigator.removeRoute(progress);
  }
  if (!succeeded && context.mounted && bloc.state.errorMessage.isNotEmpty) {
    AppToast.error(context, bloc.state.errorMessage);
  }
  return succeeded;
}

Future<bool> restorePosHeldCart(
  BuildContext context,
  PosBloc bloc,
  HoldOrder order,
) async {
  if (bloc.state.checkoutStore?.id != order.store.id) {
    AppToast.warning(context, posLocale(context).heldCartOtherStore);
    return false;
  }
  if (bloc.state.cart.isNotEmpty) {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Pesanan tersimpan'.tr(dialogContext)),
        content: Text(posLocale(dialogContext).heldCartRestoreConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Batal'.tr(dialogContext)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(posLocale(dialogContext).heldCartSaveAndOpen),
          ),
        ],
      ),
    );
    if (approved != true || !context.mounted) return false;
    final saved = await runPosHeldCartAction(
      context,
      bloc,
      (completion) => HoldCurrentOrder('', completion: completion),
    );
    if (!saved || !context.mounted) return false;
  }
  if (!context.mounted) return false;
  return runPosHeldCartAction(
    context,
    bloc,
    (completion) => RestoreHeldOrder(order, completion: completion),
  );
}
