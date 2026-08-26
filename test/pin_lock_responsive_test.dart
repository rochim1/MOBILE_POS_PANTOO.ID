import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/common/pin_lock_screen.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/inactivity_wrapper.dart';

class TestLockCubit extends AppLockCubit {
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
    expect(find.text('Pantoo POS'), findsOneWidget);
    expect(find.text('Aplikasi Kasir Online'), findsOneWidget);
    expect(find.text('Akses Kasir'), findsOneWidget);
    expect(find.text('Logout akun'), findsOneWidget);
  });

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
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    cubit.seedUnlocked();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
