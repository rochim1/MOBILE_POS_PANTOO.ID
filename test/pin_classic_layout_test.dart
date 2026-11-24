import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:mobile_pos_pantoo/presentation/pages/common/pos_pin_access_viewport.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_setup_tour.dart';
import 'pin_lock_responsive_test.dart' show TestLockCubit, TestPosRepository;

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
      'instansi_id': 'pin-classic-fixture',
    });
    sl.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
    sl.registerSingleton<PosRepository>(TestPosRepository());
  });
  tearDown(() => sl.reset());
  Future<void> mount(
    WidgetTester tester,
    Size size,
    Locale locale, {
    double scale = 1,
    bool createPin = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final lock = TestLockCubit();
    if (createPin) {
      lock.seedLoginWithoutPin();
    } else {
      lock.seedLocked();
    }
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 24, bottom: 24),
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          ),
          home: const RepaintBoundary(
            key: ValueKey('classic_pin_preview'),
            child: PinLockScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ScrollPosition position(WidgetTester tester) => tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byType(PosPinAccessViewport),
          matching: find.byType(Scrollable),
        ),
      )
      .position;
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(390, 844),
    const Size(768, 800),
  ]) {
    for (final locale in [const Locale('id'), const Locale('en')]) {
      testWidgets(
        'classic PIN spacing and stacked actions stay usable at $size ${locale.languageCode}',
        (tester) async {
          await mount(tester, size, locale);
          const phase = String.fromEnvironment('PIN_CLASSIC_PHASE');
          if (phase.isNotEmpty && size == const Size(320, 568)) {
            await tester.runAsync(() async {
              final image = await tester
                  .renderObject<RenderRepaintBoundary>(
                    find.byKey(const ValueKey('classic_pin_preview')),
                  )
                  .toImage(pixelRatio: 2);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                'output/pin-classic-layout-20261125/${locale.languageCode}-$phase.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          // The user restored the roomy layout; vertical scrolling is allowed.
          // Do not scale down controls or put the footer into two columns.
          expect(tester.widget<Text>(find.text('1')).style?.fontSize, 32);
          final customer = find.widgetWithText(
            TextButton,
            locale.languageCode == 'en'
                ? 'Connect customer display'
                : 'Hubungkan layar pelanggan',
          );
          final logout = find.text(
            locale.languageCode == 'en' ? 'Sign out of account' : 'Logout akun',
          );
          expect(
            tester.getRect(customer).bottom,
            lessThanOrEqualTo(tester.getRect(logout).top),
          );
          await tester.ensureVisible(logout);
          await tester.pumpAndSettle();
          expect(
            tester.getRect(logout).bottom,
            lessThanOrEqualTo(size.height - 24),
          );
          expect(logout.hitTestable(), findsOneWidget);
          expect(find.byType(FittedBox), findsNothing);
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
            final bounds = tester.getRect(
              find.widgetWithText(TextButton, digit),
            );
            expect(bounds.height, greaterThanOrEqualTo(64));
            expect(bounds.width, greaterThanOrEqualTo(48));
          }
          final font = tester.widget<Text>(find.text('1')).style?.fontSize;
          expect(font, 32);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final scale in [1.0, 1.5]) {
    testWidgets(
      'short PIN screen keeps scroll fallback and readable controls scale $scale',
      (tester) async {
        await mount(
          tester,
          const Size(320, 320),
          const Locale('en'),
          scale: scale,
        );
        expect(position(tester).maxScrollExtent, greaterThan(0));
        final logout = find.text('Sign out of account');
        await tester.ensureVisible(logout);
        await tester.pumpAndSettle();
        expect(logout.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('new account create PIN remains visible on a small phone', (
    tester,
  ) async {
    await mount(
      tester,
      const Size(320, 568),
      const Locale('id'),
      createPin: true,
    );
    expect(find.text('Buat PIN Akun Ini').hitTestable(), findsOneWidget);
    expect(position(tester).maxScrollExtent, lessThanOrEqualTo(.1));
    expect(find.byKey(posPinSubmitTourTarget), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
