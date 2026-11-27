import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_keyboard_stable_dialog.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_keyboard_stable_sheet.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_keyboard_visibility.dart';

Future<void> settleKeyboard(WidgetTester tester, double bottom) async {
  tester.view.viewInsets = FakeViewPadding(bottom: bottom);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
  await tester.pumpAndSettle();
}

void main() {
  Future<void> open(
    WidgetTester tester,
    Widget home, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const PosKeyboardScrollBehavior(),
        builder: (_, child) => PosKeyboardVisibility(child: child!),
        home: home,
      ),
    );
    await tester.pumpAndSettle();
  }

  Widget fields(ScrollController controller) => ListView(
    controller: controller,
    padding: const EdgeInsets.all(16),
    children: [
      const TextField(
        key: Key('top'),
        decoration: InputDecoration(labelText: 'Nama'),
      ),
      const SizedBox(height: 420),
      const TextField(
        key: Key('bottom'),
        decoration: InputDecoration(labelText: 'Catatan'),
      ),
      const SizedBox(height: 24),
      FilledButton(onPressed: () {}, child: const Text('Simpan')),
    ],
  );

  testWidgets('overlay page reveals a bottom field without moving its header', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await open(
      tester,
      Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(title: const Text('Form')),
        body: fields(controller),
      ),
    );
    final header = tester.getRect(find.byType(AppBar));
    await tester.tap(find.byKey(const Key('bottom')));
    await settleKeyboard(tester, 320);
    expect(controller.offset, greaterThan(0));
    expect(
      tester.getRect(find.byKey(const Key('bottom'))).bottom,
      lessThanOrEqualTo(524),
    );
    expect(tester.getRect(find.byType(AppBar)), header);
    expect(tester.takeException(), isNull);
  });

  testWidgets('field already above keyboard does not scroll', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await open(
      tester,
      Scaffold(resizeToAvoidBottomInset: false, body: fields(controller)),
    );
    final before = tester.getRect(find.byKey(const Key('top')));
    await tester.tap(find.byKey(const Key('top')));
    await settleKeyboard(tester, 320);
    expect(controller.offset, 0);
    expect(tester.getRect(find.byKey(const Key('top'))), before);
    expect(tester.takeException(), isNull);
  });

  for (final modal in ['dialog', 'sheet']) {
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      testWidgets(
        '$modal keeps its bounds while its last field is revealed at $size',
        (tester) async {
          final controller = ScrollController();
          addTearDown(controller.dispose);
          final content = ListView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            children: [
              for (var i = 0; i < 10; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    key: Key('field-$i'),
                    decoration: InputDecoration(labelText: 'Field $i'),
                  ),
                ),
            ],
          );
          await open(
            tester,
            Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () {
                    if (modal == 'dialog') {
                      showDialog<void>(
                        context: context,
                        builder: (_) => PosKeyboardStableFormDialog(
                          width: 720,
                          height: 700,
                          title: const Text('Produk'),
                          content: content,
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Tutup'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => PosKeyboardStableSheet(
                          heightFactor: .9,
                          child: Column(
                            children: [
                              const Text('Produk'),
                              Expanded(child: content),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
            size: size,
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          final outer = find.byType(
            modal == 'dialog' ? Dialog : PosKeyboardStableSheet,
          );
          final before = tester.getRect(outer);
          await tester.drag(find.byType(ListView), const Offset(0, -900));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('field-9')));
          final inset = size.height < 500 ? 170.0 : 320.0;
          await settleKeyboard(tester, inset);
          expect(tester.getRect(outer), before);
          expect(
            tester.getRect(find.byKey(const Key('field-9'))).bottom,
            lessThanOrEqualTo(size.height - inset + 1),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('resizing Scaffold is not inset twice', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await open(tester, Scaffold(body: fields(controller)));
    await tester.tap(find.byKey(const Key('bottom')));
    await settleKeyboard(tester, 320);
    expect(controller.position.viewportDimension, closeTo(524, 1));
    expect(
      tester.getRect(find.byKey(const Key('bottom'))).bottom,
      lessThanOrEqualTo(524),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'switching fields with keyboard open and changing its height stays visible',
    (tester) async {
      final controller = ScrollController();
      final lower = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(lower.dispose);
      await open(
        tester,
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: ListView(
            controller: controller,
            children: [
              const TextField(key: Key('upper')),
              const SizedBox(height: 550),
              TextField(key: const Key('lower'), focusNode: lower),
            ],
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('upper')));
      await settleKeyboard(tester, 280);
      expect(controller.offset, 0);
      lower.requestFocus();
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byKey(const Key('lower'))).bottom,
        lessThanOrEqualTo(564),
      );
      await settleKeyboard(tester, 380);
      expect(
        tester.getRect(find.byKey(const Key('lower'))).bottom,
        lessThanOrEqualTo(464),
      );
      await settleKeyboard(tester, 0);
      expect(controller.position.viewportDimension, 844);
      expect(lower.hasFocus, true);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'nested vertical and horizontal lists do not apply keyboard inset twice',
    (tester) async {
      final outer = ScrollController();
      addTearDown(outer.dispose);
      await open(
        tester,
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: ListView(
            controller: outer,
            children: [
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [Text('Kategori')],
                ),
              ),
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 500),
                  TextField(key: Key('nested')),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('nested')));
      await settleKeyboard(tester, 320);
      expect(outer.position.viewportDimension, 524);
      expect(
        tester.getRect(find.byKey(const Key('nested'))).bottom,
        lessThanOrEqualTo(524),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'large multiline field keeps active caret visible and text intact',
    (tester) async {
      final controller = TextEditingController(
        text: List.generate(25, (i) => 'Catatan $i').join('\n'),
      );
      final scroll = ScrollController();
      addTearDown(controller.dispose);
      addTearDown(scroll.dispose);
      await open(
        tester,
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: ListView(
            controller: scroll,
            children: [
              const SizedBox(height: 120),
              TextField(controller: controller, maxLines: null),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(TextField));
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length,
      );
      await settleKeyboard(tester, 360);
      final editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      final render = editable.renderEditable;
      final caret = render.localToGlobal(
        render.getLocalRectForCaret(controller.selection.extent).bottomLeft,
      );
      expect(caret.dy, lessThanOrEqualTo(484));
      expect(controller.text, contains('Catatan 24'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unfocused lists are not resized by a keyboard on another route',
    (tester) async {
      final background = ScrollController();
      addTearDown(background.dispose);
      await open(
        tester,
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: Builder(
            builder: (context) => ListView(
              controller: background,
              children: [
                TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        const AlertDialog(content: TextField(autofocus: true)),
                  ),
                  child: const Text('Open'),
                ),
              ],
            ),
          ),
        ),
      );
      final before = background.position.viewportDimension;
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await settleKeyboard(tester, 320);
      expect(background.position.viewportDimension, before);
      expect(background.offset, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'draggable sheet keeps its extent when its bottom field receives focus',
    (tester) async {
      await open(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => DraggableScrollableSheet(
                  initialChildSize: .9,
                  builder: (_, controller) => Container(
                    key: const Key('extent'),
                    child: ListView(
                      controller: controller,
                      children: [
                        const SizedBox(height: 500),
                        const TextField(key: Key('last')),
                      ],
                    ),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final before = tester.getRect(find.byKey(const Key('extent')));
      await tester.tap(find.byKey(const Key('last')));
      await settleKeyboard(tester, 320);
      expect(tester.getRect(find.byKey(const Key('extent'))), before);
      expect(
        tester.getRect(find.byKey(const Key('last'))).bottom,
        lessThanOrEqualTo(524),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keyboard rotation remeasures the active form without losing its text',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await open(
        tester,
        Scaffold(resizeToAvoidBottomInset: false, body: fields(controller)),
      );
      await tester.enterText(
        find.byKey(const Key('bottom')),
        'Tetap tersimpan',
      );
      await settleKeyboard(tester, 320);
      tester.view.physicalSize = const Size(844, 390);
      await settleKeyboard(tester, 170);
      expect(
        tester.getRect(find.byKey(const Key('bottom'))).bottom,
        lessThanOrEqualTo(220),
      );
      expect(find.text('Tetap tersimpan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'intrinsic AlertDialog does not retain a second keyboard reserve after moving',
    (tester) async {
      await open(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const AlertDialog(
                  scrollable: true,
                  title: Text('Catatan'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 160),
                      TextField(autofocus: true),
                    ],
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await settleKeyboard(tester, 320);
      final scroll = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(
        scroll.position.viewportDimension,
        closeTo(tester.getSize(find.byType(SingleChildScrollView)).height, 1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('disposal during keyboard animation does not leave callbacks', (
    tester,
  ) async {
    final controller = ScrollController();
    await open(tester, Scaffold(body: fields(controller)));
    await tester.tap(find.byKey(const Key('top')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    controller.dispose();
    expect(tester.takeException(), isNull);
  });
}
