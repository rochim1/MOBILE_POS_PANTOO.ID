import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/utils/rupiah_input_formatter.dart';

void main() {
  const formatter = RupiahInputFormatter();

  test('formats digits with Indonesian thousands separators', () {
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '3000000'),
    );
    expect(result.text, '3.000.000');
    expect(result.selection.baseOffset, result.text.length);
  });

  test('keeps only digits and parses formatted value for API payloads', () {
    final result = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: 'Rp 3.000.000'),
    );
    expect(result.text, '3.000.000');
    expect(parseRupiah(result.text), 3000000);
  });
}
