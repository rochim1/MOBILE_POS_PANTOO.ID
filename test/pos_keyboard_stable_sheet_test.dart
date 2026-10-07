import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_keyboard_stable_sheet.dart';

void main() {
  testWidgets('sheet height stays fixed when keyboard inset changes', (
    tester,
  ) async {
    const sheetKey = Key('sheet');
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    Future<void> pumpWithInset(double keyboardInset) => tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: const Size(400, 800),
          viewPadding: const EdgeInsets.only(top: 24, bottom: 16),
          viewInsets: EdgeInsets.only(bottom: keyboardInset),
        ),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: PosKeyboardStableSheet(
              heightFactor: .9,
              child: SizedBox(key: sheetKey),
            ),
          ),
        ),
      ),
    );

    await pumpWithInset(0);
    final before = tester.getSize(find.byKey(sheetKey)).height;
    await pumpWithInset(320);
    final after = tester.getSize(find.byKey(sheetKey)).height;

    expect(before, 684);
    expect(after, before);
  });

  testWidgets('modal bottom sheet does not collapse over the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const PosKeyboardStableSheet(
                  heightFactor: .9,
                  child: SizedBox(key: Key('modal-content')),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final before = tester
        .getSize(find.byKey(const Key('modal-content')))
        .height;

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    final after = tester.getSize(find.byKey(const Key('modal-content'))).height;

    expect(before, greaterThan(600));
    expect(after, before);
  });

  testWidgets('draggable input sheet keeps its extent when keyboard opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => DraggableScrollableSheet(
                  initialChildSize: .9,
                  minChildSize: .5,
                  maxChildSize: .95,
                  builder: (_, controller) => Container(
                    key: const Key('draggable-content'),
                    child: ListView(
                      controller: controller,
                      children: const [TextField()],
                    ),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final before = tester
        .getSize(find.byKey(const Key('draggable-content')))
        .height;

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    final after = tester
        .getSize(find.byKey(const Key('draggable-content')))
        .height;

    expect(before, greaterThan(600));
    expect(after, before);

    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const Key('draggable-content'))).height,
      greaterThan(after),
    );
  });
}
