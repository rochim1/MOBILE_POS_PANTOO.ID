import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/repositories/auth_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/auth_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/auth_state.dart';

class _Auth extends Fake implements AuthRepository {
  int logins = 0, logouts = 0;
  @override
  Future<bool> checkSession() async => true;
  @override
  String? getSavedUsername() => 'Kasir';
  @override
  Future<void> logout() async {
    logouts++;
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
}

void main() {
  test(
    'restored session remains preparing until subscription is ready',
    () async {
      final ready = Completer<bool>();
      final cubit = AuthCubit(
        authRepository: _Auth(),
        prepareSession: () => ready.future,
      );
      addTearDown(cubit.close);
      final pending = cubit.checkSession();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.isCheckingSubscription, true);
      expect(cubit.state.restoringSession, true);
      expect(cubit.state.isAuthenticated, false);
      ready.complete(true);
      await pending;
      expect(cubit.state.isAuthenticated, true);
    },
  );

  test('logout invalidates a late successful subscription check', () async {
    final ready = Completer<bool>();
    final repo = _Auth();
    final cubit = AuthCubit(
      authRepository: repo,
      prepareSession: () => ready.future,
    );
    addTearDown(cubit.close);
    final pending = cubit.login('kasir', 'password');
    await Future<void>.delayed(Duration.zero);
    await cubit.logout();
    ready.complete(true);
    await pending;
    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(repo.logouts, 1);
  });

  test(
    'exception preserves accepted identity and retry does not repeat password login',
    () async {
      var attempts = 0;
      final repo = _Auth();
      final cubit = AuthCubit(
        authRepository: repo,
        prepareSession: () async {
          if (++attempts == 1) throw StateError('network');
          return true;
        },
      );
      addTearDown(cubit.close);
      await cubit.login('kasir', 'password');
      expect(cubit.state.canRetrySubscription, true);
      expect(repo.logouts, 0);
      await cubit.login('kasir', 'password');
      expect(cubit.state.isAuthenticated, true);
      expect(repo.logins, 1);
      expect(attempts, 2);
    },
  );

  testWidgets(
    'hung verification times out to retry without opening workspace',
    (tester) async {
      final ready = Completer<bool>();
      final cubit = AuthCubit(
        authRepository: _Auth(),
        prepareSession: () => ready.future,
      );
      addTearDown(cubit.close);
      final pending = cubit.login('kasir', 'password');
      await tester.pump();
      expect(cubit.state.isCheckingSubscription, true);
      await tester.pump(const Duration(seconds: 21));
      await pending;
      expect(cubit.state.canRetrySubscription, true);
      ready.complete(true);
      await tester.pump();
      expect(cubit.state.isAuthenticated, false);
    },
  );

  test('duplicate password submissions cannot restart preparation', () async {
    final ready = Completer<bool>();
    final repo = _Auth();
    final cubit = AuthCubit(
      authRepository: repo,
      prepareSession: () => ready.future,
    );
    addTearDown(cubit.close);
    final pending = cubit.login('kasir', 'password');
    await Future<void>.delayed(Duration.zero);
    await cubit.login('kasir', 'password');
    expect(repo.logins, 1);
    ready.complete(true);
    await pending;
    expect(cubit.state.isAuthenticated, true);
  });
}
