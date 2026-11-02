import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_forced_profile_change_dialog.dart';

void main() {
  Future<void> open(WidgetTester tester, ValueChanged<String?> result) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final reason = await showDialog<String>(
                  context: context,
                  builder: (_) => const PosForcedProfileChangeDialog(
                    message: '1 shift terbuka',
                  ),
                );
                result(reason);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Uji profil restoran');
  }

  for (final dismissal in ['cancel', 'escape', 'barrier', 'back']) {
    testWidgets(
      'typed reason can dismiss by $dismissal during route transition',
      (tester) async {
        String? result = 'not returned';
        await open(tester, (value) => result = value);
        if (dismissal == 'cancel') {
          await tester.tap(find.text('Batal'));
        } else if (dismissal == 'escape') {
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        } else if (dismissal == 'barrier') {
          await tester.tapAt(const Offset(5, 5));
        } else {
          await tester.binding.handlePopRoute();
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
        await tester.pumpAndSettle();
        expect(result, isNull);
        expect(find.byType(PosForcedProfileChangeDialog), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('force requires both an audit reason and acknowledgement', (
    tester,
  ) async {
    String? result;
    await open(tester, (value) => result = value);
    await tester.tap(find.text('Paksa lanjutkan'));
    await tester.pump();
    expect(find.textContaining('Isi alasan minimal'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.enterText(find.byType(TextFormField), 'short');
    await tester.tap(find.text('Paksa lanjutkan'));
    await tester.pump();
    expect(result, isNull);
    expect(find.byType(PosForcedProfileChangeDialog), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField),
      '  Uji profil restoran  ',
    );
    await tester.tap(find.text('Paksa lanjutkan'));
    await tester.pumpAndSettle();
    expect(result, 'Uji profil restoran');
    expect(tester.takeException(), isNull);
  });
}
