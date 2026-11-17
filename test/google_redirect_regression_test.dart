import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/app.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/core/customer_display/pos_customer_display_service.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/flavor/flavor_config.dart';
import 'package:mobile_pos_pantoo/core/network/sync_service.dart';
import 'package:mobile_pos_pantoo/core/subscription/pos_subscription_service.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_settings.dart';
import 'package:mobile_pos_pantoo/domain/repositories/auth_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_settings_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/app/app_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/auth_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/register_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/pages/intro/intro_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/login/register_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/login/business_setup_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_onboarding_page.dart';

class _Auth extends Fake implements AuthRepository {
  @override
  Future<bool> checkSession() async => false;
  @override
  Future<String> googleClientId() async => throw StateError('SDK outside test');
  @override
  Future<Either<Failure, String>> loginWithGoogle(
    String token, {
    String? phone,
    bool consent = false,
  }) async => const Right('Google user');
}

class _POS extends Fake implements PosRepository {
  @override
  Future<Map<String, dynamic>> getRuntimeConfig() async => {
    'pos_lock_enabled': false,
  };
  @override
  Future<Either<Failure, Map<String, dynamic>>> getMyPOSLockStatus() async =>
      const Right({'enabled': false});
  @override
  void setOperatorSessionToken(String token) {}
}

class _Settings extends Fake implements PosSettingsRepository {
  final pending = Completer<Either<Failure, PosSettings>>();
  @override
  Future<Either<Failure, PosSettings>> getSettings() => pending.future;
}

class _Sync extends Fake implements SyncService {
  @override
  void setOperatorSessionToken(String token) {}
}

class _Display extends Fake implements PosCustomerDisplayService {
  @override
  Future<void> disconnect() async {}
  @override
  void publishIdle() {}
}

class _SlowAccess extends PosSubscriptionService {
  _SlowAccess()
    : super(
        fetch: () async => {},
        readScope: () => '',
        storage: const FlutterSecureStorage(),
      );
  final pending = Completer<void>();
  @override
  Future<void> activate() => pending.future;
}

class _Navigation extends NavigatorObserver {
  int pushes = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => pushes++;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_intro': true,
      'instansi_id': 'tenant',
      'user_id': 'google-user',
    });
    FlutterSecureStorage.setMockInitialValues({});
    final auth = _Auth();
    sl.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
    sl.registerSingleton<FlavorConfig>(FlavorConfig.production());
    sl.registerSingleton<AuthRepository>(auth);
    sl.registerFactory<AuthCubit>(() => AuthCubit(authRepository: auth));
    sl.registerFactory<RegisterCubit>(
      () => RegisterCubit(authRepository: auth),
    );
    sl.registerFactory<AppCubit>(() => AppCubit());
    sl.registerSingleton<PosRepository>(_POS());
    sl.registerSingleton<PosSettingsRepository>(_Settings());
    sl.registerSingleton<SyncService>(_Sync());
    sl.registerSingleton<PosCustomerDisplayService>(_Display());
  });
  tearDown(() async => sl.reset());

  for (final register in [false, true]) {
    testWidgets(
      'new Google identity from ${register ? 'register' : 'login'} reaches business setup',
      (tester) async {
        final prefs = sl<SharedPreferences>();
        await prefs.remove('instansi_id');
        await prefs.setBool('needs_workspace_setup', true);
        final access = _SlowAccess();
        sl.registerSingleton<PosSubscriptionService>(access);
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();
        if (register) {
          unawaited(
            App.navigatorKey.currentState!.push(
              MaterialPageRoute<void>(builder: (_) => const RegisterPage()),
            ),
          );
          await tester.pumpAndSettle();
        }
        await App.navigatorKey.currentContext!.read<AuthCubit>().loginGoogle(
          'verified-proof',
          phone: '08123456789',
          consent: true,
        );
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        expect(find.byType(BusinessSetupPage), findsOneWidget);
        expect(App.navigatorKey.currentState!.canPop(), isFalse);
        expect(prefs.getBool('has_seen_intro'), isTrue);
        await tester.pumpWidget(const SizedBox());
        access.pending.complete();
        access.dispose();
        await tester.pump();
      },
    );
    testWidgets(
      'Google ${register ? 'register' : 'login'} navigates while subscription is pending',
      (tester) async {
        final access = _SlowAccess();
        sl.registerSingleton<PosSubscriptionService>(access);
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();
        if (register) {
          unawaited(
            App.navigatorKey.currentState!.push(
              MaterialPageRoute<void>(builder: (_) => const RegisterPage()),
            ),
          );
          await tester.pumpAndSettle();
        }
        final context = App.navigatorKey.currentContext!;
        await context.read<AuthCubit>().loginGoogle('verified-proof');
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        expect(
          find.byType(PosOnboardingGate),
          findsOneWidget,
          reason:
              'Verified session must leave both public routes without waiting for subscription IO',
        );
        expect(App.navigatorKey.currentState!.canPop(), isFalse);
        await tester.pumpWidget(const SizedBox());
        access.pending.complete();
        access.dispose();
        await tester.pump();
      },
    );
  }

  testWidgets('intro does not race the central authenticated PIN redirect', (
    tester,
  ) async {
    final cubit = sl<AuthCubit>();
    await cubit.checkSession();
    final observer = _Navigation();
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          navigatorObservers: [observer],
          home: const IntroPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Build the login slide so its old listener is active.
    for (var i = 0; i < 3; i++) {
      await tester.drag(find.byType(PageView), const Offset(-700, 0));
      await tester.pumpAndSettle();
    }
    await cubit.loginGoogle('verified-proof');
    await tester.pump();
    expect(
      observer.pushes,
      1,
      reason: 'Only App may navigate, after engaging the PIN lock',
    );
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
  });
}
