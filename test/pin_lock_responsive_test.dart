import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/common/pin_lock_screen.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/inactivity_wrapper.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_setup_tour.dart';

class TestPosRepository extends Fake implements PosRepository {
  @override
  Future<Map<String, dynamic>> getRuntimeConfig() async => {
    'pos_lock_enabled': true,
    'pos_lock_on_background': false,
    'pos_auto_lock_minutes': 5,
  };
}

class TestLockCubit extends AppLockCubit {
  final enteredPins = <String>[];

  @override
  Future<bool> unlock(String enteredPin) async {
    enteredPins.add(enteredPin);
    return false;
  }

  void seedLocked() => emit(
    const AppLockState(
      status: AppLockStatus.locked,
      hasPinConfigured: true,
      selectedEmployeeId: 'u1',
      employees: [
        {
          '_id': 'u1',
          'name': 'Kasir Satu',
          'username': 'kasir1',
          'has_pin': true,
        },
        {
          '_id': 'u2',
          'name': 'Kasir Dua',
          'username': 'kasir2',
          'has_pin': true,
        },
      ],
    ),
  );

  void seedUnlocked() => emit(state.copyWith(status: AppLockStatus.unlocked));

  void seedLoginWithoutPin() => emit(
    const AppLockState(
      status: AppLockStatus.locked,
      selectedEmployeeId: 'login-user',
      employees: [
        {
          '_id': 'login-user',
          'name': 'Akun Login',
          'username': 'login',
          'has_pin': false,
          'is_login_user': true,
        },
      ],
    ),
  );

  @override
  Future<void> loadEmployees({String search = ''}) async {}
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  setUp(() {
    sl.registerSingleton<PosRepository>(TestPosRepository());
  });
  tearDown(() async {
    await sl.reset();
  });
  testWidgets(
    'carousel changes only the left panel while PIN stays usable on the right',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final cubit = TestLockCubit()..seedLocked();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        BlocProvider<AppLockCubit>.value(
          value: cubit,
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'Roboto'),
            home: const RepaintBoundary(
              key: Key('pin_carousel_preview'),
              child: PinLockScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(
          find.byKey(const Key('pin_marketing_carousel')),
        );
        await precacheImage(
          const AssetImage('assets/images/pin_bni_edc_promo.jpg'),
          context,
        );
        if (!context.mounted) return;
        await precacheImage(
          const AssetImage('assets/images/pantoo_brand_ambassador.png'),
          context,
        );
      });
      await tester.pumpAndSettle();
      final panelBefore = tester.getRect(find.byKey(posPinSetupTourTarget));
      final carousel = tester.getRect(
        find.byKey(const Key('pin_marketing_carousel')),
      );
      expect(carousel.right, lessThanOrEqualTo(600));
      expect(panelBefore.left, greaterThanOrEqualTo(600));
      expect(find.byKey(const Key('pin_bni_promo')), findsOneWidget);
      final preview = Platform.environment['PANTOO_PIN_CAROUSEL_PREVIEW'];
      if (preview != null) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const Key('pin_carousel_preview')),
        );
        await tester.runAsync(() async {
          final snapshot = await boundary.toImage(pixelRatio: 1);
          final bytes = await snapshot.toByteData(
            format: ui.ImageByteFormat.png,
          );
          await File(preview).writeAsBytes(bytes!.buffer.asUint8List());
          snapshot.dispose();
        });
      }

      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.tap(find.byKey(const Key('pin_marketing_next')));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(posPinSetupTourTarget)), panelBefore);
      for (final key in [
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
        LogicalKeyboardKey.digit4,
        LogicalKeyboardKey.digit5,
        LogicalKeyboardKey.digit6,
      ]) {
        await tester.sendKeyEvent(key);
      }
      await tester.pump();
      expect(cubit.enteredPins, ['123456']);
      await tester.drag(
        find.byKey(const Key('pin_marketing_slides')),
        const Offset(500, 0),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(posPinSetupTourTarget)), panelBefore);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('PIN tidak menutupi intro atau login tanpa sesi autentikasi', (
    tester,
  ) async {
    final cubit = TestLockCubit()..seedLocked();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider<AppLockCubit>.value(
        value: cubit,
        child: const MaterialApp(
          home: InactivityWrapper(
            authenticated: false,
            inactivityDuration: Duration(milliseconds: 1),
            child: Scaffold(body: Text('Onboarding publik')),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('Onboarding publik'), findsOneWidget);
    expect(find.text('Akses Kasir'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PIN lock screen does not overflow on a short phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = AppLockCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: PinLockScreen()),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('pin_marketing_carousel')), findsNothing);
    expect(find.text('Pantoo POS'), findsNothing);
    expect(find.text('Aplikasi Kasir Online'), findsNothing);
    expect(find.text('Akses Kasir'), findsOneWidget);
    expect(find.text('Logout akun'), findsOneWidget);
  });

  testWidgets('PIN entry panel is anchored to the right on a wide screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
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
    await tester.pump();

    final panelRect = tester.getRect(find.byKey(posPinSetupTourTarget));
    expect(panelRect.center.dx, greaterThan(600));
    expect(panelRect.center.dx, closeTo(900, 1));
    expect(find.byKey(const Key('pin_keyboard_focus')), findsOneWidget);
    expect(find.byKey(const Key('pin_keyboard_input')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PIN accepts keyboard digits, numpad, Backspace, and Enter', (
    tester,
  ) async {
    final cubit = TestLockCubit()..seedLocked();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider<AppLockCubit>.value(
        value: cubit,
        child: const MaterialApp(home: PinLockScreen()),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyEvent(LogicalKeyboardKey.numpad2);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(cubit.enteredPins, ['1245']);
    for (final key in [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
    ]) {
      await tester.sendKeyEvent(key);
    }
    await tester.pump();
    expect(cubit.enteredPins, ['1245', '123456']);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'PIN receives keyboard focus after locking over a focused field',
    (tester) async {
      final cubit = TestLockCubit()..seedUnlocked();
      addTearDown(cubit.close);
      final dashboardFocus = FocusNode();
      final dashboardText = TextEditingController();
      addTearDown(dashboardFocus.dispose);
      addTearDown(dashboardText.dispose);
      await tester.pumpWidget(
        BlocProvider<AppLockCubit>.value(
          value: cubit,
          child: MaterialApp(
            builder: (context, child) =>
                InactivityWrapper(authenticated: true, child: child!),
            home: Scaffold(
              body: TextField(
                autofocus: true,
                focusNode: dashboardFocus,
                controller: dashboardText,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<EditableText>(),
        isNotNull,
      );

      cubit.seedLocked();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Focus>(find.byKey(const Key('pin_keyboard_focus')))
            .focusNode
            ?.hasFocus,
        isTrue,
      );
      // A stale dashboard control must not prevent direct PIN typing.
      dashboardFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(cubit.enteredPins, ['1234']);
      expect(dashboardText.text, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('employee picker modal opens from lock overlay navigator', (
    tester,
  ) async {
    final cubit = TestLockCubit()..seedLocked();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider<AppLockCubit>.value(
        value: cubit,
        child: MaterialApp(
          builder: (context, child) =>
              InactivityWrapper(authenticated: true, child: child!),
          home: const Scaffold(body: Text('Dashboard')),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Kasir Satu').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Kasir Dua'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Cari nama atau username…'),
      findsOneWidget,
    );

    await tester.tap(find.text('Kasir Dua'));
    await tester.pumpAndSettle();
    cubit.seedUnlocked();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Dashboard'), findsOneWidget);
  });

  testWidgets('akun login tanpa PIN mendapat aksi buat PIN', (tester) async {
    final cubit = TestLockCubit()..seedLoginWithoutPin();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider<AppLockCubit>.value(
        value: cubit,
        child: const MaterialApp(home: PinLockScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Buat PIN Akun Ini'), findsOneWidget);
    await tester.tap(find.text('Buat PIN Akun Ini'));
    await tester.pumpAndSettle();

    expect(find.text('Buat PIN Kasir'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password akun'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'PIN baru'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Ulangi PIN'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'PIN baru'),
      '12ab34567',
    );
    final pinField = tester.widget<TextField>(
      find.widgetWithText(TextField, 'PIN baru'),
    );
    expect(pinField.controller?.text, '123456');
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    cubit.seedUnlocked();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
