import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/core/themes/colors_theme.dart';

void main() {
  testWidgets('mobile pills keep readable text in selected and idle states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white),
              child: Wrap(
                children: [
                  InputChip(
                    label: const Text('Channel Penjualan Aktif'),
                    onDeleted: () {},
                  ),
                  const InputChip(label: Text('Retail')),
                  ChoiceChip(
                    label: const Text('Semua'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  ChoiceChip(
                    label: const Text('Dipilih'),
                    selected: true,
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Color? labelColor(String label) =>
        DefaultTextStyle.of(tester.element(find.text(label))).style.color;

    expect(labelColor('Channel Penjualan Aktif'), AppColors.body);
    expect(labelColor('Retail'), AppColors.body);
    expect(labelColor('Semua'), AppColors.body);
    expect(labelColor('Dipilih'), AppColors.white);

    final selectedChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Dipilih'),
    );
    expect(selectedChip.selected, isTrue);
    expect(
      Theme.of(tester.element(find.text('Dipilih'))).chipTheme.selectedColor,
      AppColors.primary,
    );
  });
}
