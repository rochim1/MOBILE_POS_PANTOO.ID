import 'core/subscription/pos_subscription_service.dart';
import 'presentation/widgets/pos_subscription_boundary.dart';
import 'presentation/widgets/pos_system_safe_area.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'dart:async';
import 'core/notifications/pos_push_service.dart';
import 'presentation/pages/pos/pos_notification_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_language_controller.dart';
import 'l10n/generated/app_localizations.dart';
import 'core/auth/pos_login_navigation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/_core.dart';
import 'injections.dart';
import 'presentation/_presentation.dart';
import 'presentation/bloc/auth/auth_cubit.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/pages/intro/intro_page.dart';
import 'presentation/bloc/lock/lock_cubit.dart';
import 'presentation/widgets/inactivity_wrapper.dart';
import 'domain/repositories/pos_repository.dart';
import 'core/customer_display/pos_customer_display_service.dart';

import 'package:chucker_flutter/chucker_flutter.dart';

/// Mengikuti text scaling dari perangkat, lalu memadatkannya sedikit pada
/// layar ponsel. Diletakkan di atas Navigator agar turut berlaku pada dialog,
/// bottom sheet, popup menu, tabel, dan route lain yang ditampilkan sebagai
/// overlay.
final class _CompactMobileTextScaler extends TextScaler {
  const _CompactMobileTextScaler(this.base);

  final TextScaler base;
  static const double factor = .84;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  double get textScaleFactor => scale(14) / 14;

  @override
  bool operator ==(Object other) =>
      other is _CompactMobileTextScaler && other.base == base;

  @override
  int get hashCode => Object.hash(base, factor);
}

class App extends StatelessWidget {
  const App({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      ChuckerFlutter.navigatorKey;
  static final subscriptionRoutes = PosSubscriptionRouteObserver();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AppCubit>()..init()),
        BlocProvider(create: (_) => sl<AuthCubit>()..checkSession()),
        BlocProvider(create: (_) => AppLockCubit()),
      ],
      child: ValueListenableBuilder<Locale?>(
        valueListenable: AppLanguageController.instance,
        builder: (_, selectedLocale, _) => MaterialApp(
          locale: selectedLocale,
          supportedLocales: const [Locale('id'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (device, _) =>
              AppLanguageController.resolve(device),
          navigatorKey: navigatorKey,
          navigatorObservers: [subscriptionRoutes],
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final compactMobile = mediaQuery.size.width < 600;
            final app = BlocListener<AuthCubit, AuthState>(
              listener: (context, state) async {
                if (state.status == AuthStatus.authenticated) {
                  final prefs = sl<SharedPreferences>();
                  final lockCubit = context.read<AppLockCubit>();
                  final authCubit = context.read<AuthCubit>();
                  final needsWorkspace =
                      prefs.getBool('needs_workspace_setup') == true ||
                      (prefs.getString('instansi_id')?.trim().isEmpty ?? true);
                  await prefs.setBool('has_seen_intro', true);
                  // AuthCubit completes bounded subscription verification on
                  // the login form before this single, PIN-safe redirect.
                  if (!context.mounted || !identical(authCubit.state, state)) {
                    return;
                  }
                  await finishPosLoginNavigation(
                    needsWorkspace: needsWorkspace,
                    readLockEnabled: () async =>
                        (await sl<PosRepository>().getMyPOSLockStatus()).fold(
                          (_) => true,
                          (status) => status['enabled'] != false,
                        ),
                    lock: lockCubit.lock,
                    resetLock: lockCubit.reset,
                    isCurrent: () =>
                        context.mounted &&
                        !authCubit.isClosed &&
                        identical(authCubit.state, state),
                    navigate: () =>
                        navigatorKey.currentState?.pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) =>
                                PosOnboardingPage.initialDestination(prefs),
                          ),
                          (route) => false,
                        ),
                  );
                  if (context.mounted &&
                      identical(authCubit.state, state) &&
                      sl.isRegistered<PosPushService>()) {
                    final push = sl<PosPushService>();
                    push.onOpen = () => navigatorKey.currentState?.push(
                      MaterialPageRoute(
                        builder: (_) => const PosNotificationPage(),
                      ),
                    );
                    unawaited(push.activate());
                  }
                } else if (state.status == AuthStatus.unauthenticated) {
                  sl<PosSubscriptionService>().deactivate();
                  await sl<PosCustomerDisplayService>().disconnect();
                  if (!context.mounted) return;
                  context.read<AppLockCubit>().reset();
                  final hasSeenIntro =
                      sl<SharedPreferences>().getBool('has_seen_intro') ??
                      false;
                  navigatorKey.currentState?.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) =>
                          hasSeenIntro ? const LoginPage() : const IntroPage(),
                    ),
                    (route) => false,
                  );
                }
              },
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, authState) => PosSubscriptionBoundary(
                  service: sl<PosSubscriptionService>(),
                  authenticated: authState.isAuthenticated,
                  navigatorKey: navigatorKey,
                  receiptVisible: subscriptionRoutes.receiptVisible,
                  onLogout: () => context.read<AuthCubit>().logout(),
                  onRestricted: () =>
                      sl<PosCustomerDisplayService>().publishIdle(),
                  child: InactivityWrapper(
                    authenticated: authState.isAuthenticated,
                    child: child!,
                  ),
                ),
              ),
            );
            final safeApp = PosSystemSafeArea(child: app);
            if (!compactMobile) return safeApp;
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: _CompactMobileTextScaler(mediaQuery.textScaler),
              ),
              child: safeApp,
            );
          },
          debugShowCheckedModeBanner: false,
          title: sl<FlavorConfig>().appName,
          theme: AppTheme.light(),
          home: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              // Keep the branded startup view until the saved session and POS
              // lock have finished loading. Login submissions stay on LoginPage
              // so their progress remains on the button.
              if (state.isCheckingSession ||
                  state.isAuthenticated ||
                  (state.isCheckingSubscription && state.restoringSession)) {
                return const _StartupSplash();
              }
              if (state.isAuthenticating) {
                return const LoginPage();
              }
              final hasSeenIntro =
                  sl<SharedPreferences>().getBool('has_seen_intro') ?? false;

              if (!hasSeenIntro) {
                return const IntroPage();
              }

              return const LoginPage();
            },
          ),
        ),
      ),
    );
  }
}

class _StartupSplash extends StatelessWidget {
  const _StartupSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: AssetImage('assets/images/pantoo_pos_icon.png'),
              width: 152,
              height: 152,
            ),
            SizedBox(height: 20),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: 12),
            PosText('Menyiapkan Pantoo POS…'),
          ],
        ),
      ),
    );
  }
}
