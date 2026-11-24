import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/pages/common/pin_lock_screen.dart';
import 'package:mobile_pos_pantoo/presentation/pages/common/pos_pin_access_viewport.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_setup_tour.dart';
import 'pin_lock_responsive_test.dart' show TestLockCubit, TestPosRepository;

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'instansi_id': 'pin-width-fixture',
    });
    sl.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
    sl.registerSingleton<PosRepository>(TestPosRepository());
  });
  tearDown(() async => sl.reset());
  for (final width in [200.0, 240.0, 280.0, 320.0, 390.0, 1024.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'PIN panel and keypad fit local viewport $width at text scale $scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 640);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final cubit = TestLockCubit()..seedLocked();
          addTearDown(cubit.close);
          await tester.pumpWidget(
            BlocProvider<AppLockCubit>.value(
              value: cubit,
              child: MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: const PinLockScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final viewport = tester.getRect(find.byType(PosPinAccessViewport));
          final panel = tester.getRect(find.byKey(posPinSetupTourTarget));
          expect(panel.width, lessThanOrEqualTo(420));
          expect(panel.left, greaterThanOrEqualTo(viewport.left));
          expect(panel.right, lessThanOrEqualTo(viewport.right));
          for (final digit in [
            '0',
            '1',
            '2',
            '3',
            '4',
            '5',
            '6',
            '7',
            '8',
            '9',
          ]) {
            final button = find.widgetWithText(TextButton, digit);
            final bounds = tester.getRect(button);
            expect(bounds.left, greaterThanOrEqualTo(panel.left));
            expect(bounds.right, lessThanOrEqualTo(panel.right));
            expect(bounds.width, greaterThanOrEqualTo(48));
          }
          final deleteBounds = tester.getRect(
            find.widgetWithIcon(TextButton, Icons.backspace_outlined),
          );
          expect(deleteBounds.left, greaterThanOrEqualTo(panel.left));
          expect(deleteBounds.right, lessThanOrEqualTo(panel.right));
          expect(deleteBounds.width, greaterThanOrEqualTo(48));
          final zero = find.widgetWithText(TextButton, '0');
          await tester.ensureVisible(zero);
          await tester.tap(zero);
          await tester.pump();
          expect(
            cubit.enteredPins,
            isEmpty,
            reason: 'layout must not bypass PIN verification',
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('local panel constraint wins over the full device width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = TestLockCubit()..seedLocked();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider<AppLockCubit>.value(
        value: cubit,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(child: SizedBox(width: 260, child: PinLockScreen())),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final panel = tester.getRect(find.byKey(posPinSetupTourTarget));
    expect(panel.width, lessThanOrEqualTo(228));
    final one = tester.getRect(find.widgetWithText(TextButton, '1'));
    final three = tester.getRect(find.widgetWithText(TextButton, '3'));
    expect(one.left, greaterThanOrEqualTo(panel.left));
    expect(three.right, lessThanOrEqualTo(panel.right));
  });
  testWidgets(
    'resizing to a narrow viewport preserves entered PIN and selected operator',
    (tester) async {
      tester.view.physicalSize = const Size(390, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cubit = TestLockCubit()..seedLocked();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        BlocProvider<AppLockCubit>.value(
          value: cubit,
          child: const MaterialApp(home: PinLockScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      tester.view.physicalSize = const Size(240, 400);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(cubit.enteredPins, ['1234']);
      expect(cubit.state.selectedEmployeeId, 'u1');
    },
  );
}
