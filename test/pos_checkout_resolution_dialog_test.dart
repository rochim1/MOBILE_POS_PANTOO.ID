import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_checkout_resolution_dialog.dart';

void main() {
  Future<void> open(WidgetTester tester, {String language = 'id'}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const PosCheckoutResolutionDialog(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('resolution validates notes before cancelling', (tester) async {
    await open(tester);
    await tester.tap(find.text('Selesaikan percobaan'));
    await tester.pumpAndSettle();
    expect(find.text('Catatan minimal 5 karakter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'received funds expose labelled supervisor credentials with PIN visibility control',
    (tester) async {
      await open(tester);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Dana sudah dikembalikan / direkonsiliasi').last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Username supervisor'), findsOneWidget);
      expect(find.text('PIN supervisor'), findsOneWidget);
      final pin = find.byType(TextFormField).last;
      await tester.ensureVisible(pin);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('resolution copy is translated on narrow English phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester, language: 'en');
    expect(find.text('Resolve payment'), findsOneWidget);
    expect(find.text('Funds not received'), findsOneWidget);
    expect(find.text('Verification notes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
