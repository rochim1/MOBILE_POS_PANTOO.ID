import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mobile_pos_pantoo/core/error/error_handler.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/common/pin_lock_screen.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/inactivity_wrapper.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_setup_tour.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';

class TestPosRepository extends Fake implements PosRepository {
  int runtimeReads = 0;
  @override
  Future<Map<String, dynamic>> getRuntimeConfig() async {
    runtimeReads++;
    return {
      'pos_lock_enabled': true,
      'pos_lock_on_background': false,
      'pos_auto_lock_minutes': 5,
    };
  }
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
  void seedPinError() =>
      emit(state.copyWith(errorMessage: 'PIN salah. Sisa percobaan 4.'));

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

class _PasswordRejectedLockCubit extends TestLockCubit {
  int submissions = 0;
  @override
  Future<bool> createLoginUserPin({
    required String password,
    required String pin,
  }) async {
    submissions++;
    final failure = AppErrorHandler.handle(
      OperationException(
        graphqlErrors: [
          GraphQLError(
            message: 'Password akun tidak valid',
            extensions: {'code': 'UNAUTHORIZED'},
          ),
        ],
      ),
    );
    emit(state.copyWith(errorMessage: failure.message));
    return false;
  }
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
  setUp(() async {
    SharedPreferences.setMockInitialValues({'instansi_id': 'tenant-pin-test'});
    sl.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
    sl.registerSingleton<PosRepository>(TestPosRepository());
  });
  tearDown(() async {
    await sl.reset();
  });
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(768, 800),
  ]) {
    for (final locale in [const Locale('id'), const Locale('en')]) {
      for (final scale in [1.0, 1.5]) {
        testWidgets(
          'PIN text is not shrunk at $size, ${locale.languageCode}, scale $scale',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final cubit = TestLockCubit()..seedLocked();
            addTearDown(cubit.close);
            await tester.pumpWidget(
              BlocProvider<AppLockCubit>.value(
                value: cubit,
                child: MaterialApp(
                  locale: locale,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  theme: AppTheme.light(),
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
            final title = find.text(
              locale.languageCode == 'en' ? 'Cashier Access' : 'Akses Kasir',
            );
            expect(
              MatrixUtils.transformRect(
                tester.renderObject(title).getTransformTo(null),
                const Rect.fromLTWH(0, 0, 100, 100),
              ).width,
              closeTo(100, .001),
              reason: 'readable text must never be shrunk to fit an 810px form',
            );
            expect(find.byType(FittedBox), findsNothing);
            final name = tester.widget<Text>(find.text('Kasir Satu'));
            expect(name.style?.fontSize, greaterThanOrEqualTo(16));
            await tester.ensureVisible(find.widgetWithText(TextButton, '1'));
            await tester.tap(find.widgetWithText(TextButton, '1'));
            await tester.pump();
            expect(
              cubit.enteredPins,
              isEmpty,
              reason: 'one digit must not unlock or verify',
            );
            final submit = find.byKey(posPinSubmitTourTarget);
            await tester.ensureVisible(submit);
            expect(tester.getSize(submit).height, greaterThanOrEqualTo(48));
            expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
            final logout = find.text(
              locale.languageCode == 'en'
                  ? 'Sign out of account'
                  : 'Logout akun',
            );
            await tester.ensureVisible(logout);
            await tester.pumpAndSettle();
            expect(
              tester.getRect(logout).bottom,
              lessThanOrEqualTo(size.height),
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
  }
  testWidgets(
    'PIN failure text translates without changing the locked state or retry policy',
    (tester) async {
      final cubit = TestLockCubit()
        ..seedLocked()
        ..seedPinError();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        BlocProvider<AppLockCubit>.value(
          value: cubit,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PinLockScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Incorrect PIN. 4 attempts remaining.'), findsOneWidget);
      expect(cubit.state.status, AppLockStatus.locked);
      expect(cubit.enteredPins, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'locked overlay fills a subscription column with loose horizontal constraints',
    (tester) async {
      final cubit = TestLockCubit()..seedLocked();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        BlocProvider<AppLockCubit>.value(
          value: cubit,
          child: MaterialApp(
            home: Column(
              children: [
                Expanded(
                  child: InactivityWrapper(
                    authenticated: true,
                    child: const Scaffold(body: Text('Dashboard')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(PinLockScreen)).width,
        tester.view.physicalSize.width / tester.view.devicePixelRatio,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'new account does not request tenant runtime before workspace exists',
    (tester) async {
      await sl<SharedPreferences>().remove('instansi_id');
      final cubit = TestLockCubit()..seedUnlocked();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        BlocProvider<AppLockCubit>.value(
          value: cubit,
          child: MaterialApp(
            home: InactivityWrapper(
              authenticated: true,
              child: const Scaffold(body: Text('Setup usaha')),
            ),
          ),
        ),
      );
      await tester.pump();
      expect((sl<PosRepository>() as TestPosRepository).runtimeReads, 0);
      await sl<SharedPreferences>().setString('instansi_id', 'new-tenant');
      cubit.seedLocked();
      await tester.pumpAndSettle();
      expect((sl<PosRepository>() as TestPosRepository).runtimeReads, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'PIN excludes underlying route semantics and restores them after unlock',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        final cubit = TestLockCubit()..seedUnlocked();
        addTearDown(cubit.close);
        final navigation = GlobalKey<NavigatorState>();
        await tester.pumpWidget(
          BlocProvider<AppLockCubit>.value(
            value: cubit,
            child: MaterialApp(
              navigatorKey: navigation,
              builder: (context, child) =>
                  InactivityWrapper(authenticated: true, child: child!),
              home: const Scaffold(body: Text('Private dashboard')),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Private dashboard'), findsWidgets);
        cubit.seedLocked();
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Private dashboard'), findsNothing);
        navigation.currentState!.pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Private next route')),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.bySemanticsLabel('Private next route'), findsNothing);
        cubit.seedUnlocked();
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Private next route'), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      } finally {
        semantics.dispose();
      }
    },
  );
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
      void expectTransparentNavigation(Color foreground) {
        for (final key in ['pin_marketing_previous', 'pin_marketing_next']) {
          final finder = find.byKey(Key(key));
          final button = tester.widget<IconButton>(finder);
          expect(
            button.style?.backgroundColor?.resolve({}),
            Colors.transparent,
          );
          expect(button.style?.foregroundColor?.resolve({}), foreground);
          expect(tester.getSize(finder).width, greaterThanOrEqualTo(44));
          expect(tester.getSize(finder).height, greaterThanOrEqualTo(44));
        }
      }

      expectTransparentNavigation(const Color(0xFF344054));
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
      expectTransparentNavigation(Colors.white);
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
      expectTransparentNavigation(const Color(0xFF344054));
      await tester.tap(find.byKey(const Key('pin_marketing_previous')));
      await tester.pumpAndSettle();
      expectTransparentNavigation(Colors.white);
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
    final numberKey = tester.getRect(find.widgetWithText(TextButton, '1'));
    expect(numberKey.width, greaterThanOrEqualTo(48));
    expect(numberKey.height, greaterThanOrEqualTo(48));
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

  testWidgets(
    'create PIN visibility toggles are independent and reset on reopen',
    (tester) async {
      final cubit = TestLockCubit()..seedLoginWithoutPin();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        BlocProvider<AppLockCubit>.value(
          value: cubit,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const PinLockScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Buat PIN Akun Ini'));
      await tester.pumpAndSettle();

      const values = {
        'Password akun': 'Synthetic-password!',
        'PIN baru': '123456',
        'Ulangi PIN': '123456',
      };
      for (final entry in values.entries) {
        final field = find.widgetWithText(TextField, entry.key);
        expect(tester.widget<TextField>(field).obscureText, isTrue);
        await tester.enterText(field, entry.value);
      }
      for (final label in values.keys) {
        final field = find.widgetWithText(TextField, label);
        final toggle = find.descendant(
          of: field,
          matching: find.byType(IconButton),
        );
        expect(
          toggle,
          findsOneWidget,
          reason: '$label needs its own eye button',
        );
        expect(tester.widget<IconButton>(toggle).tooltip, isNotEmpty);
        await tester.tap(toggle);
        await tester.pump();
        expect(tester.widget<TextField>(field).obscureText, isFalse);
        for (final other in values.keys.where((value) => value != label)) {
          expect(
            tester
                .widget<TextField>(find.widgetWithText(TextField, other))
                .obscureText,
            isTrue,
          );
        }
        expect(tester.widget<TextField>(field).controller?.text, values[label]);
        await tester.tap(toggle);
        await tester.pump();
        expect(tester.widget<TextField>(field).obscureText, isTrue);
        expect(tester.widget<TextField>(field).controller?.text, values[label]);
      }
      // Revealing a value must not persist when the dialog is closed.
      await tester.tap(
        find.descendant(
          of: find.widgetWithText(TextField, 'Password akun'),
          matching: find.byType(IconButton),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buat PIN Akun Ini'));
      await tester.pumpAndSettle();
      for (final label in values.keys) {
        final field = tester.widget<TextField>(
          find.widgetWithText(TextField, label),
        );
        expect(field.obscureText, isTrue);
        expect(field.controller?.text, isEmpty);
      }
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      cubit.seedUnlocked();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('akun login tanpa PIN mendapat aksi buat PIN', (tester) async {
    final cubit = TestLockCubit()..seedLoginWithoutPin();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider<AppLockCubit>.value(
        value: cubit,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const PinLockScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Buat PIN Akun Ini'), findsOneWidget);
    expect(
      find.widgetWithText(TextButton, '1'),
      findsNothing,
      reason:
          'an account without a PIN should see its create action, not an unusable keypad',
    );
    expect(
      tester.getRect(find.text('Buat PIN Akun Ini')).bottom,
      lessThanOrEqualTo(
        tester.view.physicalSize.height / tester.view.devicePixelRatio,
      ),
    );
    await tester.tap(find.text('Buat PIN Akun Ini'));
    await tester.pumpAndSettle();

    expect(find.text('Buat PIN Kasir'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password akun'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'PIN baru'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Ulangi PIN'), findsOneWidget);
    for (final label in ['Password akun', 'PIN baru', 'Ulangi PIN']) {
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, label),
      );
      expect(
        field.decoration?.floatingLabelBehavior,
        FloatingLabelBehavior.always,
        reason:
            'Label $label must remain visible with the production theme, including after typing',
      );
    }
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

  testWidgets(
    'PIN setup password rejection stays in the modal and allows correction',
    (tester) async {
      final cubit = _PasswordRejectedLockCubit()..seedLoginWithoutPin();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        BlocProvider<AppLockCubit>.value(
          value: cubit,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const PinLockScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Buat PIN Akun Ini'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Password akun'),
        'test-wrong',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'PIN baru'),
        '1234',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Ulangi PIN'),
        '1234',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Buat PIN'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Password akun tidak valid'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Sesi telah berakhir. Silakan login kembali.'),
        findsNothing,
      );
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'PIN baru'))
            .controller
            ?.text,
        '1234',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Password akun'),
        'test-retry',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Buat PIN'));
      await tester.pumpAndSettle();
      expect(cubit.submissions, 2);
      expect(cubit.state.status, AppLockStatus.locked);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      cubit.seedUnlocked();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
