import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/pages/common/pin_lock_screen.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_setup_tour.dart';
import 'pin_lock_responsive_test.dart' show TestLockCubit, TestPosRepository;

class _Lock extends TestLockCubit {
  Completer<bool>? pending;
  @override
  Future<bool> unlock(String pin) async {
    enteredPins.add(pin);
    return pending == null ? false : pending!.future;
  }

  void seedLockout() => emit(
    state.copyWith(
      lockedUntil: DateTime.now().add(const Duration(seconds: 20)),
    ),
  );
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Roboto',
    )..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'instansi_id': 'pin-submit-fixture',
    });
    sl.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
    sl.registerSingleton<PosRepository>(TestPosRepository());
  });
  tearDown(() => sl.reset());
  Future<void> mount(
    WidgetTester tester,
    _Lock lock, {
    Size size = const Size(320, 640),
    Locale locale = const Locale('id'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(lock.close);
    await tester.pumpWidget(
      BlocProvider<AppLockCubit>.value(
        value: lock,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light().copyWith(
            textTheme: AppTheme.light().textTheme.apply(fontFamily: 'Roboto'),
          ),
          home: const PinLockScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> digits(
    WidgetTester tester,
    List<LogicalKeyboardKey> keys,
  ) async {
    for (final key in keys) {
      await tester.sendKeyEvent(key);
    }
    await tester.pump();
  }

  for (final width in [200.0, 320.0, 390.0, 768.0]) {
    for (final locale in [const Locale('id'), const Locale('en')]) {
      testWidgets(
        'check submit sits right of zero and delete left at $width ${locale.languageCode}',
        (tester) async {
          final lock = _Lock()..seedLocked();
          await mount(tester, lock, size: Size(width, 640), locale: locale);
          final submit = find.byKey(posPinSubmitTourTarget);
          expect(submit, findsOneWidget);
          expect(
            find.descendant(of: submit, matching: find.byIcon(Icons.check)),
            findsOneWidget,
          );
          final zero = tester.getRect(find.widgetWithText(TextButton, '0'));
          final check = tester.getRect(submit);
          final delete = tester.getRect(
            find.widgetWithIcon(TextButton, Icons.backspace_outlined),
          );
          expect(check.center.dy, closeTo(zero.center.dy, .01));
          expect(check.left, greaterThanOrEqualTo(zero.right));
          expect(delete.right, lessThanOrEqualTo(zero.left));
          expect(check.width, greaterThanOrEqualTo(48));
          expect(check.height, greaterThanOrEqualTo(48));
          final panel = tester.getRect(find.byKey(posPinSetupTourTarget));
          expect(check.right, lessThanOrEqualTo(panel.right));
          expect(find.text('Masuk sebagai Kasir'), findsNothing);
          expect(find.text('Sign In as Cashier'), findsNothing);
          expect(
            find.byTooltip(
              locale.languageCode == 'en'
                  ? 'Sign In as Cashier'
                  : 'Masuk sebagai Kasir',
            ),
            findsOneWidget,
          );
          expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'check requires four digits, disables after delete and submits once with spinner',
    (tester) async {
      final lock = _Lock()..seedLocked();
      lock.pending = Completer<bool>();
      await mount(tester, lock);
      final submit = find.byKey(posPinSubmitTourTarget);
      await digits(tester, [
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
      ]);
      expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
      await digits(tester, [LogicalKeyboardKey.digit4]);
      expect(tester.widget<ElevatedButton>(submit).onPressed, isNotNull);
      final delete = find.widgetWithIcon(TextButton, Icons.backspace_outlined);
      await tester.ensureVisible(delete);
      await tester.tap(delete);
      await tester.pump();
      expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
      expect(lock.enteredPins, isEmpty);
      await digits(tester, [LogicalKeyboardKey.digit4]);
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      expect(lock.enteredPins, ['1234']);
      expect(
        find.descendant(
          of: submit,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
      expect(tester.widget<TextButton>(delete).onPressed, isNull);
      await tester.tap(submit);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(lock.enteredPins, ['1234']);
      lock.pending!.complete(false);
      await tester.pumpAndSettle();
      expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('six digits still auto verify and lockout never enables check', (
    tester,
  ) async {
    final lock = _Lock()..seedLocked();
    await mount(tester, lock);
    await digits(tester, [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
    ]);
    await tester.pumpAndSettle();
    expect(lock.enteredPins, ['123456']);
    lock.seedLockout();
    await tester.pump();
    expect(
      tester
          .widget<ElevatedButton>(find.byKey(posPinSubmitTourTarget))
          .onPressed,
      isNull,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(lock.enteredPins, ['123456']);
  });
  testWidgets(
    'account without PIN keeps create PIN action instead of sign-in check',
    (tester) async {
      final lock = _Lock()..seedLoginWithoutPin();
      await mount(tester, lock);
      expect(find.text('Buat PIN Akun Ini'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byKey(posPinSubmitTourTarget), findsOneWidget);
      expect(find.widgetWithText(TextButton, '0'), findsNothing);
      await tester.tap(find.text('Buat PIN Akun Ini'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
