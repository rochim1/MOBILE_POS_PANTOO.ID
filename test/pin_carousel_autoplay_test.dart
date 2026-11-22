import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/common/pin_lock_screen.dart';

class CarouselLockCubit extends AppLockCubit {
  final pins = <String>[];

  void seed() => emit(const AppLockState(
    status: AppLockStatus.locked,
    selectedEmployeeId: 'cashier',
    hasPinConfigured: true,
    employees: [{'_id': 'cashier', 'name': 'Kasir', 'has_pin': true}],
  ));

  @override
  Future<bool> unlock(String enteredPin) async {
    pins.add(enteredPin);
    return false;
  }
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'));
    await font.load();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({'user_id': 'cashier'});
    sl.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());
  });
  tearDown(() => sl.reset());

  Future<CarouselLockCubit> mount(WidgetTester tester, {bool reduceMotion = false}) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cubit = CarouselLockCubit()..seed();
    addTearDown(cubit.close);
    await tester.pumpWidget(BlocProvider<AppLockCubit>.value(
      value: cubit,
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'Roboto'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
          child: child!,
        ),
        home: const PinLockScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    return cubit;
  }

  double currentPage(WidgetTester tester) => tester.widget<PageView>(
    find.byKey(const Key('pin_marketing_slides')),
  ).controller!.page!;

  testWidgets('carousel advances every five seconds, loops, and preserves PIN input', (tester) async {
    final cubit = await mount(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(currentPage(tester), 1);
    for (final key in [LogicalKeyboardKey.digit2, LogicalKeyboardKey.digit3, LogicalKeyboardKey.digit4, LogicalKeyboardKey.digit5, LogicalKeyboardKey.digit6]) {
      await tester.sendKeyEvent(key);
    }
    expect(cubit.pins, ['123456']);
    expect(cubit.state.status, AppLockStatus.locked);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(currentPage(tester), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('manual navigation restarts the five second autoplay interval', (tester) async {
    await mount(tester);
    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.byKey(const Key('pin_marketing_next')));
    await tester.pumpAndSettle();
    expect(currentPage(tester), 1);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(currentPage(tester), 1);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(currentPage(tester), 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('autoplay pauses in background and resumes without disposing PIN', (tester) async {
    await mount(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 12));
    expect(currentPage(tester), 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(currentPage(tester), 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion disables autoplay but keeps manual navigation', (tester) async {
    await mount(tester, reduceMotion: true);
    await tester.pump(const Duration(seconds: 12));
    expect(currentPage(tester), 0);
    await tester.tap(find.byKey(const Key('pin_marketing_next')));
    await tester.pumpAndSettle();
    expect(currentPage(tester), 1);
    await tester.pumpWidget(const SizedBox());
  });
}
