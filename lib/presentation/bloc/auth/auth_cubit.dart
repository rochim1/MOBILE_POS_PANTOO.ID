import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/error/failures.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({required this.authRepository})
    : super(const AuthState.checkingSession());

  Future<void> checkSession() async {
    try {
      final hasSession = await authRepository.checkSession();
      if (isClosed) return;
      if (hasSession) {
        emit(
          AuthState.authenticated(
            username: authRepository.getSavedUsername() ?? 'Pengguna',
          ),
        );
      } else {
        emit(const AuthState.unauthenticated());
      }
    } catch (_) {
      if (!isClosed) emit(const AuthState.unauthenticated());
    }
  }

  Future<void> login(
    String username,
    String password, {
    String? captchaAnswer,
  }) async {
    if (username.isEmpty || password.isEmpty) {
      emit(const AuthState.failure('Username dan password wajib diisi'));
      return;
    }

    final captcha = state.captcha;
    emit(AuthState.authenticating(captcha: captcha));

    final result = await authRepository.login(
      username,
      password,
      captchaId: captcha?.captchaId,
      captchaAnswer: captcha == null ? null : captchaAnswer?.trim(),
    );
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        AuthState.failure(
          failure.message,
          captcha: failure is LoginCaptchaFailure ? failure : null,
        ),
      ),
      (name) => emit(AuthState.authenticated(username: name)),
    );
  }

  void clearCaptcha() {
    if (state.captcha != null && !state.isAuthenticating) {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> logout() async {
    try {
      await authRepository.logout();
    } finally {
      if (!isClosed) emit(const AuthState.unauthenticated());
    }
  }
}
