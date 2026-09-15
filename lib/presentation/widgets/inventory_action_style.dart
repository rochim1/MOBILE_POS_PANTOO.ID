import 'package:flutter/material.dart';

/// Shared control sizing for Inventory toolbars.
/// Keeps action buttons aligned with form fields across every inventory page.
abstract final class InventoryActionStyle {
  static const double height = 48;
  static const double radius = 10;

  static ButtonStyle primary({double horizontalPadding = 16}) =>
      FilledButton.styleFrom(
        minimumSize: const Size(0, height),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      );

  static ButtonStyle filter() => IconButton.styleFrom(
    fixedSize: const Size.square(height),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
  );
}
