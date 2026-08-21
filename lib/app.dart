import 'package:flutter/material.dart';
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

import 'package:chucker_flutter/chucker_flutter.dart';

class App extends StatelessWidget {
  const App({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      ChuckerFlutter.navigatorKey;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AppCubit>()..init()),
        BlocProvider(create: (_) => sl<AuthCubit>()..checkSession()),
        BlocProvider(create: (_) => AppLockCubit()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        builder: (context, child) {
          return BlocListener<AuthCubit, AuthState>(
            listener: (context, state) async {
              if (state.status == AuthStatus.authenticated) {
                await context.read<AppLockCubit>().lock();
                final prefs = sl<SharedPreferences>();
                navigatorKey.currentState?.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => PosOnboardingPage.initialDestination(prefs),
                  ),
                  (route) => false,
                );
              } else if (state.status == AuthStatus.unauthenticated) {
                context.read<AppLockCubit>().reset();
                final hasSeenIntro =
                    sl<SharedPreferences>().getBool('has_seen_intro') ?? false;
                navigatorKey.currentState?.pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) =>
                        hasSeenIntro ? const LoginPage() : const IntroPage(),
                  ),
                  (route) => false,
                );
              }
            },
            child: InactivityWrapper(child: child!),
          );
        },
        debugShowCheckedModeBanner: false,
        title: sl<FlavorConfig>().appName,
        theme: AppTheme.light(),
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final hasSeenIntro =
                sl<SharedPreferences>().getBool('has_seen_intro') ?? false;

            if (!hasSeenIntro) {
              return const IntroPage();
            }

            if (state.isAuthenticated) {
              return PosOnboardingPage.initialDestination(
                sl<SharedPreferences>(),
              );
            }
            return const LoginPage();
          },
        ),
      ),
    );
  }
}
