import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/l10n/language_picker.dart';
import 'package:mobile_pos_pantoo/presentation/pages/login/business_setup_page.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_setup_scaffold.dart';

Future<void> _open(
  WidgetTester tester,
  Size size, {
  bool keyboard = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  if (keyboard) tester.view.viewInsets = const FakeViewPadding(bottom: 240);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light(), home: const BusinessSetupPage()),
  );
  await tester.pumpAndSettle();
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('short setup remains centered without unnecessary scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const PosSetupScaffold(
          body: PosSetupScrollBody(
            child: Card(child: SizedBox(width: double.infinity, height: 150)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final card = tester.getRect(find.byType(Card));
    final viewport = tester.getRect(find.byType(PosSetupScrollBody));
    expect(card.center, viewport.center);
    expect(card.width, lessThanOrEqualTo(480));
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .maxScrollExtent,
      0,
    );
    expect(find.byType(LanguagePicker).hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final size in [
    const Size(390, 600),
    const Size(1024, 600),
    const Size(1440, 600),
  ]) {
    testWidgets('dragging either green side scrolls the setup form at $size', (
      tester,
    ) async {
      await _open(tester, size);
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      expect(position.maxScrollExtent, greaterThan(0));
      final pickerPosition = tester.getTopLeft(find.byType(LanguagePicker));
      for (final x in [8.0, size.width - 8]) {
        position.jumpTo(0);
        await tester.pump();
        final card = tester.getRect(find.byType(Card));
        expect(
          x < card.left || x > card.right,
          true,
          reason: 'Gesture must start on the green background, not the card',
        );
        await tester.dragFrom(
          Offset(x, size.height - 100),
          const Offset(0, -180),
        );
        await tester.pumpAndSettle();
        expect(position.pixels, greaterThan(0));
        expect(tester.getTopLeft(find.byType(LanguagePicker)), pickerPosition);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'mouse wheel on green background scrolls the form on tablet/web',
    (tester) async {
      await _open(tester, const Size(1024, 600));
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      await tester.sendEventToBinding(
        const PointerScrollEvent(
          position: Offset(20, 400),
          scrollDelta: Offset(0, 200),
        ),
      );
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'background scroll still works while keyboard is visible and fields keep their values',
    (tester) async {
      await _open(tester, const Size(390, 700), keyboard: true);
      await tester.enterText(find.byType(TextFormField).first, 'Usaha QA');
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      position.jumpTo(0);
      await tester.pump();
      await tester.dragFrom(const Offset(8, 350), const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'Usaha QA',
      );
      expect(find.byType(LanguagePicker).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
