import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final NumberFormat _rupiahThousands = NumberFormat.decimalPattern('id_ID');

/// Formats digit-only monetary input as Indonesian thousands while typing.
/// Example: `3000000` becomes `3.000.000`.
class RupiahInputFormatter extends TextInputFormatter {
  const RupiahInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final value = int.tryParse(digits);
    if (value == null) return oldValue;
    final formatted = _rupiahThousands.format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

double parseRupiah(String value) =>
    double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

String formatRupiahInput(num value) => _rupiahThousands.format(value.round());
