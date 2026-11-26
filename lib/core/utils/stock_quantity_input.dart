import 'package:flutter/services.dart';

/// Input convenience only; quantity/range/business validation is unchanged.
class StockQuantityInputFormatter extends TextInputFormatter {
  const StockQuantityInputFormatter();
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed ||
        !RegExp(r'^-?\d*(?:[.,]\d*)?$').hasMatch(newValue.text)) {
      return newValue;
    }
    final normalized = newValue.text.replaceFirstMapped(
      RegExp(r'^(-?)0+(?=\d)'),
      (m) => m[1]!,
    );
    if (normalized == newValue.text) return newValue;
    final removed = newValue.text.length - normalized.length;
    int offset(int v) => v < 0 ? v : (v - removed).clamp(0, normalized.length);
    return newValue.copyWith(
      text: normalized,
      selection: TextSelection(
        baseOffset: offset(newValue.selection.baseOffset),
        extentOffset: offset(newValue.selection.extentOffset),
      ),
      composing: TextRange.empty,
    );
  }
}

String stockQuantityText(dynamic value) {
  final number = value is num
      ? value.toDouble()
      : double.tryParse('${value ?? ''}'.replaceAll(',', '.'));
  if (number == null || !number.isFinite || number == 0) return '';
  return number == number.truncateToDouble()
      ? number.toInt().toString()
      : number.toString();
}
