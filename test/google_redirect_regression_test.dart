import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:mobile_pos_pantoo/l10n/app_language_controller.dart';
import 'package:mobile_pos_pantoo/core/auth/google_identity_service.dart';
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
import 'package:mobile_pos_pantoo/presentation/pages/login/login_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_subscription_page.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/auth_state.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/login/google_account_button.dart';
import 'pos_subscription_test.dart' as subscription;

class _Auth extends Fake implements AuthRepository {
  int logins = 0, googleLogins = 0;
  bool hasSession = false;
  bool sdkEnabled = false, requireGoogleDetails = false;
  Failure? googleFailure;
  @override
  String? getSavedUsername() => 'Kasir';
  @override
  Future<void> logout() async {
    hasSession = false;
  }

  @override
  Future<Either<Failure, String>> login(
    String username,
    String password, {
    String? captchaId,
    String? captchaAnswer,
  }) async {
    logins++;
    return const Right('Kasir');
  }

  @override
  Future<bool> checkSession() async => hasSession;
  @override
  Future<String> googleClientId() async {
    if (!sdkEnabled) throw StateError('SDK outside test');
    return 'qa-native.apps.googleusercontent.com';
  }

  @override
  Future<Either<Failure, String>> loginWithGoogle(
    String token, {
    String? phone,
    bool consent = false,
  }) async {
    googleLogins++;
    if (googleFailure != null) return Left(googleFailure!);
    if (requireGoogleDetails) {
      if (!consent || phone == null)
        return const Left(GoogleRegistrationRequiredFailure());
      await sl<SharedPreferences>().remove('instansi_id');
      await sl<SharedPreferences>().setBool('needs_workspace_setup', true);
    }
    return const Right('Google user');
  }
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

class _NativeGoogle extends GoogleSignInPlatform {
  int calls = 0, initializations = 0;
  GoogleSignInException? failure;
  Completer<AuthenticationResults>? pending;
  String? token = 'google-native-proof';
  @override
  Future<void> init(InitParameters params) async {
    initializations++;
  }

  @override
  Future<AuthenticationResults> authenticate(
    AuthenticateParameters params,
  ) async {
    calls++;
    if (failure != null) throw failure!;
    if (pending != null) return pending!.future;
    return AuthenticationResults(
      user: const GoogleSignInUserData(
        email: 'qa@example.test',
        id: 'qa-google',
      ),
      authenticationTokens: AuthenticationTokenData(idToken: token),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _disposeTestTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  // These tests intentionally hold the workspace gate. Finish its settings
  // fixture after unmount so the bounded preparation timeout can be cancelled.
  final settings = sl<PosSettingsRepository>() as _Settings;
  if (!settings.pending.isCompleted) {
    settings.pending.complete(const Left(ServerFailure('Test completed')));
  }
  await tester.pump(const Duration(seconds: 16));
  await tester.pumpAndSettle();
}

void main() {
  final nativeGoogle = _NativeGoogle();
  setUpAll(() async {
    GoogleSignInPlatform.instance = nativeGoogle;
    await GoogleIdentityService.initialize(_Auth()..sdkEnabled = true);
  });
  setUp(() async {
    nativeGoogle.calls = 0;
    nativeGoogle.failure = null;
    nativeGoogle.pending = null;
    nativeGoogle.token = 'google-native-proof';
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
    await AppLanguageController.instance.select('id');
    sl.registerSingleton<FlavorConfig>(FlavorConfig.production());
    sl.registerSingleton<AuthRepository>(auth);
    sl.registerFactory<AuthCubit>(
      () => AuthCubit(
        authRepository: auth,
        prepareSession: preparePosLoginSession,
      ),
    );
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
      'native Google ${register ? "register" : "login"} cancellation has visible feedback and retry',
      (tester) async {
        (sl<AuthRepository>() as _Auth).sdkEnabled = true;
        final access = subscription.service(() async => subscription.status());
        sl.registerSingleton<PosSubscriptionService>(access);
        nativeGoogle.failure = const GoogleSignInException(
          code: GoogleSignInExceptionCode.canceled,
        );
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
        final button = find
            .widgetWithText(OutlinedButton, 'Lanjutkan dengan Google')
            .last;
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        expect(nativeGoogle.calls, 1);
        expect(find.byKey(const Key('google_auth_error')), findsOneWidget);
        expect(
          find.textContaining('dibatalkan atau belum selesai'),
          findsWidgets,
        );
        expect((sl<AuthRepository>() as _Auth).googleLogins, 0);
        expect(
          tester
              .widget<OutlinedButton>(
                find
                    .widgetWithText(OutlinedButton, 'Coba hubungkan Google')
                    .last,
              )
              .onPressed,
          isNotNull,
        );
        await _disposeTestTree(tester);
        access.dispose();
      },
    );
    testWidgets(
      'native Google ${register ? "register" : "login"} actually redirects from account picker',
      (tester) async {
        final auth = sl<AuthRepository>() as _Auth;
        auth.sdkEnabled = true;
        auth.requireGoogleDetails = register;
        final access = subscription.service(() async => subscription.status());
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
        final button = find
            .widgetWithText(OutlinedButton, 'Lanjutkan dengan Google')
            .last;
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump();
        if (register) {
          // Google remains single-flight while the consent sheet awaits input.
          // Its progress animation must not be mistaken for an unsettled route.
          for (var i = 0; i < 20; i++) {
            await tester.pump(const Duration(milliseconds: 30));
          }
          expect(find.text('Lengkapi akun Pantoo'), findsOneWidget);
          await tester.enterText(
            find.byType(TextFormField).last,
            '08123456789',
          );
          final consent = find.descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(CheckboxListTile),
          );
          expect(consent, findsOneWidget);
          await tester.tap(consent);
          await tester.pump();
          final submit = find.text('Buat akun dan lanjutkan');
          await tester.ensureVisible(submit);
          await tester.tap(submit);
        }
        for (var i = 0; i < 35; i++) {
          await tester.pump(const Duration(milliseconds: 30));
        }
        expect(nativeGoogle.calls, 1);
        expect(auth.googleLogins, register ? 2 : 1);
        expect(
          nativeGoogle.initializations,
          1,
          reason:
              'SDK initialization is shared by recreated login/register widgets',
        );
        expect(
          find.byType(register ? BusinessSetupPage : PosOnboardingGate),
          findsOneWidget,
        );
        expect(App.navigatorKey.currentState!.canPop(), isFalse);
        await _disposeTestTree(tester);
        access.dispose();
      },
    );
  }

  for (final (code, language) in [
    (GoogleSignInExceptionCode.clientConfigurationError, 'id'),
    (GoogleSignInExceptionCode.providerConfigurationError, 'en'),
    (GoogleSignInExceptionCode.interrupted, 'en'),
  ]) {
    testWidgets('native Google $code shows localized safe feedback $language', (
      tester,
    ) async {
      (sl<AuthRepository>() as _Auth).sdkEnabled = true;
      await AppLanguageController.instance.select(language);
      nativeGoogle.failure = GoogleSignInException(
        code: code,
        description: 'private-sdk-detail',
      );
      final access = subscription.service(() async => subscription.status());
      sl.registerSingleton<PosSubscriptionService>(access);
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      final button = find.ancestor(
        of: find.byIcon(Icons.g_mobiledata),
        matching: find.byType(OutlinedButton),
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('google_auth_error')), findsOneWidget);
      expect(find.textContaining('private-sdk-detail'), findsNothing);
      expect(
        find.textContaining(
          language == 'en' ? 'Google sign-in' : 'Konfigurasi login Google',
        ),
        findsWidgets,
      );
      expect((sl<AuthRepository>() as _Auth).googleLogins, 0);
      await _disposeTestTree(tester);
      access.dispose();
    });
  }

  testWidgets(
    'native Google missing proof cannot authenticate or silently continue',
    (tester) async {
      (sl<AuthRepository>() as _Auth).sdkEnabled = true;
      nativeGoogle.token = null;
      final access = subscription.service(() async => subscription.status());
      sl.registerSingleton<PosSubscriptionService>(access);
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      final button = find.widgetWithText(
        OutlinedButton,
        'Lanjutkan dengan Google',
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('google_auth_error')), findsOneWidget);
      expect(
        find.textContaining('Google belum memberikan verifikasi akun'),
        findsWidgets,
      );
      expect((sl<AuthRepository>() as _Auth).googleLogins, 0);
      expect(find.byType(LoginPage), findsOneWidget);
      await _disposeTestTree(tester);
      access.dispose();
    },
  );

  testWidgets(
    'native Google server rejection shows persistent error without redirect',
    (tester) async {
      final auth = sl<AuthRepository>() as _Auth;
      auth.sdkEnabled = true;
      auth.googleFailure = const ServerFailure('Akun ditolak server QA');
      final access = subscription.service(() async => subscription.status());
      sl.registerSingleton<PosSubscriptionService>(access);
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      final button = find.widgetWithText(
        OutlinedButton,
        'Lanjutkan dengan Google',
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('google_auth_error')), findsOneWidget);
      expect(find.text('Akun ditolak server QA'), findsWidgets);
      expect(find.byType(LoginPage), findsOneWidget);
      await _disposeTestTree(tester);
      access.dispose();
    },
  );

  testWidgets('native Google stalled picker shows timeout and unlocks retry', (
    tester,
  ) async {
    (sl<AuthRepository>() as _Auth).sdkEnabled = true;
    nativeGoogle.pending = Completer<AuthenticationResults>();
    final access = subscription.service(() async => subscription.status());
    sl.registerSingleton<PosSubscriptionService>(access);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    final button = find.widgetWithText(
      OutlinedButton,
      'Lanjutkan dengan Google',
    );
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await tester.pump();
    }
    expect(find.byType(LinearProgressIndicator), findsWidgets);
    await tester.pump(const Duration(seconds: 91));
    await tester.pump();
    expect(
      find.text('Login Google terlalu lama. Periksa koneksi lalu coba lagi.'),
      findsWidgets,
    );
    expect(find.byKey(const Key('google_auth_error')), findsOneWidget);
    await _disposeTestTree(tester);
    access.dispose();
  });

  testWidgets(
    'saved session prepares behind branded startup, not billing or login',
    (tester) async {
      (sl<AuthRepository>() as _Auth).hasSession = true;
      final response = Completer<Map<String, dynamic>>();
      final access = subscription.service(() => response.future);
      sl.registerSingleton<PosSubscriptionService>(access);
      await tester.pumpWidget(const App());
      for (var i = 0; i < 5; i++) {
        await tester.pump();
      }
      final cubit = App.navigatorKey.currentContext!.read<AuthCubit>();
      expect(cubit.state.isCheckingSubscription, true);
      expect(find.byType(LoginPage), findsNothing);
      expect(find.byType(PosSubscriptionPage), findsNothing);
      expect(find.byType(PosOnboardingGate), findsNothing);
      response.complete(subscription.status());
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.byType(PosOnboardingGate), findsOneWidget);
      await _disposeTestTree(tester);
      access.dispose();
    },
  );

  for (final google in [false, true]) {
    testWidgets(
      '${google ? 'Google' : 'password'} login waits in form, retries verification without credentials',
      (tester) async {
        var response = Completer<Map<String, dynamic>>();
        final access = subscription.service(() => response.future);
        sl.registerSingleton<PosSubscriptionService>(access);
        await tester.pumpWidget(const App());
        await tester.pumpAndSettle();
        final cubit = App.navigatorKey.currentContext!.read<AuthCubit>();
        final login = google
            ? cubit.loginGoogle('verified-proof')
            : cubit.login('kasir', 'password');
        await tester.pump();
        await tester.pump();
        expect(cubit.state.isCheckingSubscription, true);
        expect(find.byType(LoginPage), findsOneWidget);
        expect(find.text('Memeriksa langganan…'), findsWidgets);
        expect(find.byType(PosSubscriptionPage), findsNothing);
        expect(find.byType(PosOnboardingGate), findsNothing);
        response.completeError(StateError('offline'));
        await login;
        await tester.pump();
        expect(cubit.state.canRetrySubscription, true);
        expect(find.textContaining('Status langganan belum'), findsWidgets);
        response = Completer<Map<String, dynamic>>();
        final button = find.byType(ElevatedButton);
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pump();
        await tester.pump();
        expect(cubit.state.isCheckingSubscription, true);
        response.complete(subscription.status());
        for (var i = 0; i < 30; i++) {
          await tester.pump(const Duration(milliseconds: 20));
        }
        expect(cubit.state.status, AuthStatus.authenticated);
        expect(find.byType(PosOnboardingGate), findsOneWidget);
        expect(find.byType(PosSubscriptionPage), findsNothing);
        expect((sl<AuthRepository>() as _Auth).logins, google ? 0 : 1);
        expect((sl<AuthRepository>() as _Auth).googleLogins, google ? 1 : 0);
        await _disposeTestTree(tester);
        access.dispose();
      },
    );
  }

  testWidgets(
    'confirmed expired login opens subscription recovery only after check',
    (tester) async {
      final response = Completer<Map<String, dynamic>>();
      final access = subscription.service(() => response.future);
      sl.registerSingleton<PosSubscriptionService>(access);
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      final cubit = App.navigatorKey.currentContext!.read<AuthCubit>();
      final login = cubit.login('kasir', 'password');
      await tester.pump();
      expect(find.byType(PosSubscriptionPage), findsNothing);
      response.complete(
        subscription.status(level: 'billing_only', state: 'recovery'),
      );
      await login;
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.byType(PosSubscriptionPage), findsOneWidget);
      expect(find.byKey(const Key('subscription_open_web')), findsOneWidget);
      expect(access.canSell, false);
      await _disposeTestTree(tester);
      access.dispose();
    },
  );

  testWidgets(
    'existing Google account on register retries access without reopening Google',
    (tester) async {
      var online = false;
      final response = Completer<Map<String, dynamic>>();
      final access = subscription.service(() async {
        if (!online) throw StateError('offline');
        return response.future;
      });
      sl.registerSingleton<PosSubscriptionService>(access);
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      unawaited(
        App.navigatorKey.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => const RegisterPage()),
        ),
      );
      await tester.pumpAndSettle();
      final cubit = App.navigatorKey.currentContext!.read<AuthCubit>();
      await cubit.loginGoogle('verified-proof');
      await tester.pump();
      await tester.pump();
      expect(cubit.state.canRetrySubscription, true);
      expect(find.byType(RegisterPage), findsOneWidget);
      expect(find.byType(PosSubscriptionPage), findsNothing);
      final retry = find.descendant(
        of: find.byType(GoogleAccountButton).last,
        matching: find.byType(OutlinedButton),
      );
      await tester.ensureVisible(retry);
      online = true;
      await tester.tap(retry);
      await tester.pump();
      await tester.pump();
      expect(cubit.state.isCheckingSubscription, true);
      response.complete(subscription.status());
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.byType(PosOnboardingGate), findsOneWidget);
      expect((sl<AuthRepository>() as _Auth).googleLogins, 1);
      await _disposeTestTree(tester);
      access.dispose();
    },
  );

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
        await _disposeTestTree(tester);
        access.pending.complete();
        access.dispose();
        await tester.pump();
      },
    );
    testWidgets(
      'Google ${register ? 'register' : 'login'} without required subscription scope navigates without waiting',
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
              'A flow without a required subscription scope must not wait for access IO',
        );
        expect(App.navigatorKey.currentState!.canPop(), isFalse);
        await _disposeTestTree(tester);
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
    await _disposeTestTree(tester);
    await cubit.close();
  });
}
