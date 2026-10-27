import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final NumberFormat _rupiahThousands = NumberFormat.decimalPattern('id_ID');
final NumberFormat _rupiahAmount = NumberFormat('#,##0.##', 'id_ID');

/// Indonesian money input: dots group thousands; commas separate decimals.
class RupiahInputFormatter extends TextInputFormatter {
  final int decimalDigits;
  const RupiahInputFormatter({this.decimalDigits = 0})
    : assert(decimalDigits >= 0 && decimalDigits <= 2);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.composing.isCollapsed) return newValue;
    var text = newValue.text;
    var cursor = newValue.selection.isValid
        ? newValue.selection.extentOffset
        : text.length;
    // Backspace over a grouping dot also removes the preceding digit.
    final oldCursor = oldValue.selection.baseOffset;
    if (oldValue.selection.isCollapsed &&
        oldCursor > 1 &&
        oldCursor <= oldValue.text.length &&
        oldValue.text[oldCursor - 1] == '.' &&
        text == oldValue.text.replaceRange(oldCursor - 1, oldCursor, '')) {
      text = text.replaceRange(oldCursor - 2, oldCursor - 1, '');
      cursor = oldCursor - 2;
    }
    final allowed = decimalDigits > 0 ? RegExp(r'[^0-9,]') : RegExp(r'[^0-9]');
    final prefix = text
        .substring(0, cursor.clamp(0, text.length))
        .replaceAll(allowed, '');
    final cleaned = text.replaceAll(allowed, '');
    if (cleaned.isEmpty) return const TextEditingValue();
    final parts = cleaned.split(',');
    final whole = (parts.first.isEmpty ? '0' : parts.first).replaceFirst(
      RegExp(r'^0+(?=\d)'),
      '',
    );
    final hasDecimal = decimalDigits > 0 && parts.length > 1;
    final fraction = hasDecimal
        ? parts
              .skip(1)
              .join()
              .substring(0, parts.skip(1).join().length.clamp(0, decimalDigits))
        : '';
    final grouped = whole.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    final formatted = '$grouped${hasDecimal ? ',$fraction' : ''}';
    var offset = 0;
    var remaining = prefix.length;
    for (; offset < formatted.length && remaining > 0; offset++) {
      if (formatted[offset] != '.') remaining--;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

double parseRupiah(String value) =>
    double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

/// Parses the display format, never interpreting a thousands dot as a decimal.
double parseRupiahAmount(String value) {
  final amount = double.tryParse(
    value.trim().replaceAll('.', '').replaceAll(',', '.'),
  );
  return amount != null && amount.isFinite ? amount : 0;
}

String formatRupiahInput(num value) => _rupiahThousands.format(value.round());
String formatRupiahAmount(num value) =>
    value.isFinite ? _rupiahAmount.format(value) : '—';
