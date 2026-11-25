import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_system_safe_area.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    double bottom = 48,
    double right = 0,
    double keyboard = 0,
    Size size = const Size(390, 844),
    bool nestedSafeArea = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            padding: EdgeInsets.only(
              top: 24,
              bottom: keyboard > 0 ? 0 : bottom,
              right: right,
            ),
            viewPadding: EdgeInsets.only(top: 24, bottom: bottom, right: right),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: PosSystemSafeArea(child: child!),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: nestedSafeArea
                  ? SafeArea(top: false, child: _save())
                  : _save(),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () {},
              child: const Icon(Icons.add),
            ),
            appBar: AppBar(
              title: const Text('POS'),
              actions: [
                TextButton(
                  key: const Key('sheet'),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (_) => SizedBox(
                      height: 200,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _save(key: const Key('sheet_save')),
                      ),
                    ),
                  ),
                  child: const Text('Sheet'),
                ),
                TextButton(
                  key: const Key('route'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        body: Align(
                          alignment: Alignment.bottomCenter,
                          child: _save(key: const Key('route_save')),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Route'),
                ),
                TextButton(
                  key: const Key('dialog'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => Dialog(
                      child: SizedBox(
                        height: 900,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _save(key: const Key('dialog_save')),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Dialog'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final bottom in [0.0, 16.0, 24.0, 48.0, 80.0]) {
    testWidgets('body actions stay above system navigation $bottom dp', (
      tester,
    ) async {
      await open(tester, bottom: bottom);
      final action = tester.getRect(find.byKey(const Key('save')));
      expect(action.bottom, closeTo(844 - bottom, .01));
      expect(
        tester.getRect(find.byType(FloatingActionButton)).bottom,
        lessThanOrEqualTo(844 - bottom),
      );
      await tester.tap(find.byKey(const Key('save')));
      expect(tester.takeException(), isNull);
    });
  }
  for (final kind in ['sheet', 'route', 'dialog']) {
    testWidgets(
      '$kind footer inherits root protection without local SafeArea',
      (tester) async {
        await open(tester);
        await tester.tap(find.byKey(Key(kind)));
        await tester.pumpAndSettle();
        final action = find.byKey(Key('${kind}_save'));
        expect(action.hitTestable(), findsOneWidget);
        expect(tester.getRect(action).bottom, lessThanOrEqualTo(844 - 48));
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('existing SafeArea does not add the system padding twice', (
    tester,
  ) async {
    await open(tester, nestedSafeArea: true);
    expect(
      tester.getRect(find.byKey(const Key('save'))).bottom,
      closeTo(796, .01),
    );
  });
  testWidgets('landscape navigation on the right cannot cover a button', (
    tester,
  ) async {
    await open(tester, bottom: 0, right: 48, size: const Size(844, 390));
    expect(
      tester.getRect(find.byKey(const Key('save'))).right,
      lessThanOrEqualTo(796),
    );
    expect(
      tester.getRect(find.byType(FloatingActionButton)).right,
      lessThanOrEqualTo(796),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'keyboard resize keeps the body action above keyboard without double inset',
    (tester) async {
      await open(tester, keyboard: 300);
      expect(
        tester.getRect(find.byKey(const Key('save'))).bottom,
        closeTo(544, .01),
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('changing navigation mode preserves the pushed route', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('route')));
    await tester.pumpAndSettle();
    await open(tester, bottom: 80);
    expect(find.byKey(const Key('route_save')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const Key('route_save'))).bottom,
      closeTo(764, .01),
    );
    await open(tester, bottom: 0);
    expect(find.byKey(const Key('route_save')), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const Key('route_save'))).bottom,
      closeTo(844, .01),
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _save({Key key = const Key('save')}) => SizedBox(
  width: double.infinity,
  height: 48,
  child: FilledButton(key: key, onPressed: () {}, child: const Text('Simpan')),
);
