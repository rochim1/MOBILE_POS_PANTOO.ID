import 'package:flutter/material.dart';

/// Material's time input has a fixed minimum height. Compact POS typography
/// can otherwise shrink its calculated maximum below that minimum. Keep the
/// picker at normal scale or larger, without changing the rest of the app.
Future<TimeOfDay?> showPosTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) => showTimePicker(
  context: context,
  initialTime: initialTime,
  builder: (context, child) =>
      MediaQuery.withClampedTextScaling(minScaleFactor: 1, child: child!),
);
