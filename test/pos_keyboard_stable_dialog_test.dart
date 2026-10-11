import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_keyboard_stable_dialog.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_table_qr_print_settings_dialog.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_table_qr_print_settings.dart';

void main() {
  testWidgets('pengaturan cetak QR memiliki jarak dari tepi modal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<PosTableQrPrintSettings>(
                context: context,
                builder: (_) => const PosTableQrPrintSettingsDialog(
                  initial: PosTableQrPrintSettings(),
                ),
              ),
              child: const Text('Buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();
    final dialog = tester.getRect(find.byType(Dialog));
    final firstField = tester.getRect(find.byType(TextField).first);
    expect(firstField.left - dialog.left, greaterThanOrEqualTo(16));
    expect(firstField.top - dialog.top, greaterThan(70));
    expect(dialog.right - firstField.right, greaterThanOrEqualTo(16));
  });

  testWidgets('pengaturan cetak QR tetap muat di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: PosTableQrPrintSettingsDialog(
              initial: PosTableQrPrintSettings(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final dialog = tester.getRect(find.byType(Dialog));
    final firstField = tester.getRect(find.byType(TextField).first);
    expect(firstField.left, greaterThan(dialog.left));
    expect(firstField.right, lessThan(dialog.right));
  });

  testWidgets('landscape form dialog does not shrink when keyboard opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 600);
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
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const PosKeyboardStableDialog(
                  width: 720,
                  height: 680,
                  child: SizedBox(key: Key('form-content')),
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
    final before = tester.getSize(find.byKey(const Key('form-content')));

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    final after = tester.getSize(find.byKey(const Key('form-content')));

    expect(before.height, greaterThan(500));
    expect(after, before);
    expect(
      MediaQuery.viewInsetsOf(
        tester.element(find.byKey(const Key('form-content'))),
      ).bottom,
      300,
    );
  });

  testWidgets('form content remains scrollable above the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 600);
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
              onPressed: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => PosKeyboardStableFormDialog(
                  width: 520,
                  height: 540,
                  title: const Text('Form'),
                  content: ListView(
                    key: const Key('form-list'),
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.viewInsetsOf(dialogContext).bottom,
                    ),
                    children: List.generate(
                      12,
                      (index) => SizedBox(
                        height: 80,
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Field $index',
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Tutup'),
                    ),
                  ],
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
    final before = tester.getSize(find.byKey(const Key('form-list'))).height;
    final beforeScroll = tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byKey(const Key('form-list')),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position
        .maxScrollExtent;

    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pumpAndSettle();
    final after = tester.getSize(find.byKey(const Key('form-list'))).height;
    final afterScroll = tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byKey(const Key('form-list')),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position
        .maxScrollExtent;

    expect(after, before);
    expect(afterScroll, greaterThan(beforeScroll));
  });
}
