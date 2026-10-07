import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile_pos_pantoo/core/flavor/flavor_config.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/repositories/auth_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/auth_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/auth_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/login/login_page.dart';

class _PendingAuthRepository extends Fake implements AuthRepository {
  final Completer<bool> session = Completer<bool>();
  final Completer<Either<Failure, String>> loginResult = Completer();

  @override
  Future<bool> checkSession() => session.future;

  @override
  String? getSavedUsername() => 'Kasir';

  @override
  Future<Either<Failure, String>> login(
    String username,
    String password, {
    String? captchaId,
    String? captchaAnswer,
  }) => loginResult.future;
}

void main() {
  setUp(() {
    GetIt.I.registerSingleton<FlavorConfig>(FlavorConfig.production());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test(
    'session recovery begins in loading state and remains there while pending',
    () async {
      final repository = _PendingAuthRepository();
      final cubit = AuthCubit(authRepository: repository);
      addTearDown(cubit.close);

      expect(cubit.state.status, AuthStatus.checkingSession);
      final recovery = cubit.checkSession();
      expect(cubit.state.status, AuthStatus.checkingSession);

      repository.session.complete(true);
      await recovery;
      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.username, 'Kasir');
    },
  );

  test('missing saved session ends loading and shows login state', () async {
    final repository = _PendingAuthRepository();
    final cubit = AuthCubit(authRepository: repository);
    addTearDown(cubit.close);

    final recovery = cubit.checkSession();
    repository.session.complete(false);
    await recovery;

    expect(cubit.state.status, AuthStatus.unauthenticated);
  });

  testWidgets('login screen keeps the form and shows progress in its button', (
    tester,
  ) async {
    final cubit = AuthCubit(authRepository: _PendingAuthRepository());
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: cubit,
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    expect(find.text('Memulihkan sesi kasir…'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
  });

  testWidgets('login submission keeps the form and spins only the button', (
    tester,
  ) async {
    final repository = _PendingAuthRepository();
    final cubit = AuthCubit(authRepository: repository);
    addTearDown(cubit.close);
    final recovery = cubit.checkSession();
    repository.session.complete(false);
    await recovery;

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: cubit,
        child: const MaterialApp(home: LoginPage()),
      ),
    );
    final login = cubit.login('kasir', 'password');
    await tester.pump();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );

    repository.loginResult.complete(const Right('Kasir'));
    await login;
    await tester.pump();
  });
}
