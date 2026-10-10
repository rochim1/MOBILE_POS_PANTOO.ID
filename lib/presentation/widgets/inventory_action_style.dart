import 'package:flutter/material.dart';

/// Shared control sizing for Inventory toolbars.
/// Keeps action buttons aligned with form fields across every inventory page.
abstract final class InventoryActionStyle {
  static const double height = 48;
  static const double radius = 10;

  static ButtonStyle primary({
    double horizontalPadding = 16,
    double controlHeight = height,
  }) => FilledButton.styleFrom(
    minimumSize: Size(0, controlHeight),
    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
  );

  static ButtonStyle outlined({double controlHeight = height}) =>
      OutlinedButton.styleFrom(
        minimumSize: Size(0, controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      );

  static ButtonStyle filter({double controlHeight = height}) =>
      IconButton.styleFrom(
        fixedSize: Size.square(controlHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
