import 'dart:collection';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/flavor/flavor_config.dart';
import 'package:mobile_pos_pantoo/domain/repositories/auth_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/auth_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/auth_state.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/login/login_form.dart';

const _captchaImage =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/lXcAAAAASUVORK5CYII=';

class _LoginAttempt {
  const _LoginAttempt(this.username, this.captchaId, this.captchaAnswer);
  final String username;
  final String? captchaId;
  final String? captchaAnswer;
}

class _CaptchaAuthRepository extends Fake implements AuthRepository {
  final responses = Queue<Either<Failure, String>>();
  final attempts = <_LoginAttempt>[];

  @override
  Future<bool> checkSession() async => false;

  @override
  Future<Either<Failure, String>> login(
    String username,
    String password, {
    String? captchaId,
    String? captchaAnswer,
  }) async {
    attempts.add(_LoginAttempt(username, captchaId, captchaAnswer));
    return responses.removeFirst();
  }
}

void main() {
  setUp(() {
    GetIt.I.registerSingleton<FlavorConfig>(FlavorConfig.production());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('CAPTCHA extension accepts only a valid PNG challenge', () {
    const id = '0123456789abcdef0123456789abcdefabcd';
    final challenge = LoginCaptchaFailure.fromExtensions({
      'code': 'CAPTCHA_REQUIRED',
      'captcha': {'id': id, 'image': _captchaImage},
    });
    expect(challenge?.captchaId, id);
    expect(challenge?.image, _captchaImage);
    expect(
      LoginCaptchaFailure.fromExtensions({
        'code': 'CAPTCHA_REQUIRED',
        'captcha': {'id': id, 'image': 'data:image/png;base64,invalid'},
      }),
      isNull,
    );
  });

  testWidgets('POS login shows CAPTCHA and sends its answer on retry', (
    tester,
  ) async {
    final repository = _CaptchaAuthRepository();
    const id = '0123456789abcdef0123456789abcdefabcd';
    repository.responses.add(
      const Left(LoginCaptchaFailure(captchaId: id, image: _captchaImage)),
    );
    final cubit = AuthCubit(authRepository: repository);
    addTearDown(cubit.close);
    await cubit.checkSession();

    await tester.pumpWidget(
      BlocProvider<AuthCubit>.value(
        value: cubit,
        child: const MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: LoginForm())),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField).at(0), 'kasir');
    await tester.enterText(find.byType(TextFormField).at(1), 'sandi');
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    expect(find.text('Verifikasi CAPTCHA'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(find.byType(TextFormField), findsNWidgets(3));
    expect(repository.attempts.single.captchaId, isNull);

    await tester.tap(find.text('Masuk'));
    await tester.pump();
    expect(repository.attempts.length, 1);
    expect(find.text('Masukkan enam karakter CAPTCHA'), findsOneWidget);

    repository.responses.add(const Right('Kasir'));
    await tester.enterText(find.byType(TextFormField).at(2), 'ABC123');
    await tester.tap(find.text('Masuk'));
    await tester.pump();

    expect(repository.attempts.length, 2);
    expect(repository.attempts.last.username, 'kasir');
    expect(repository.attempts.last.captchaId, id);
    expect(repository.attempts.last.captchaAnswer, 'ABC123');
    expect(cubit.state.status, AuthStatus.authenticated);
  });
}
