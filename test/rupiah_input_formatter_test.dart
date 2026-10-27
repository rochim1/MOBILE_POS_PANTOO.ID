import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
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
  test(
    'formatted money is parsed as full amount, including Indonesian decimals',
    () {
      expect(formatRupiahAmount(1000000), '1.000.000');
      expect(formatRupiahAmount(1000000.25), '1.000.000,25');
      expect(formatRupiahAmount(-1000000), '-1.000.000');
      expect(parseRupiahAmount('1.000.000'), 1000000);
      expect(parseRupiahAmount('1.000.000,25'), 1000000.25);
      expect(parseRupiahAmount(''), 0);
    },
  );
  test('decimal input retains comma and cents without changing thousands', () {
    const decimal = RupiahInputFormatter(decimalDigits: 2);
    expect(
      decimal
          .formatEditUpdate(
            TextEditingValue.empty,
            const TextEditingValue(text: '1000000,25'),
          )
          .text,
      '1.000.000,25',
    );
    expect(
      decimal
          .formatEditUpdate(
            TextEditingValue.empty,
            const TextEditingValue(text: '1000,'),
          )
          .text,
      '1.000,',
    );
    expect(
      decimal
          .formatEditUpdate(
            TextEditingValue.empty,
            const TextEditingValue(text: '1000,256'),
          )
          .text,
      '1.000,25',
    );
    expect(
      decimal
          .formatEditUpdate(TextEditingValue.empty, TextEditingValue.empty)
          .text,
      '',
    );
  });
  test(
    'editing in the middle preserves cursor and backspace works across dots',
    () {
      final middle = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '1.000',
          selection: TextSelection.collapsed(offset: 3),
        ),
        const TextEditingValue(
          text: '1.0500',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(middle.text, '10.500');
      expect(middle.selection.baseOffset, 4);
      final deletion = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '12.345',
          selection: TextSelection.collapsed(offset: 3),
        ),
        const TextEditingValue(
          text: '12345',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(deletion.text, '1.345');
    },
  );
  testWidgets('editing and pasting a currency field keeps API amount numeric', (
    tester,
  ) async {
    final controller = TextEditingController(text: formatRupiahAmount(1000000));
    double? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                controller: controller,
                inputFormatters: const [RupiahInputFormatter(decimalDigits: 2)],
              ),
              FilledButton(
                onPressed: () => saved = parseRupiahAmount(controller.text),
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('1.000.000'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '2500000,50');
    expect(controller.text, '2.500.000,50');
    await tester.tap(find.text('Simpan'));
    expect(saved, 2500000.5);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}
