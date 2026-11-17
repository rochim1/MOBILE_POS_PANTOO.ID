import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/error/failures.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;
  bool _googleInFlight = false;
  int _sessionRevision = 0;
  final Future<void> Function()? beforeLogout;

  AuthCubit({required this.authRepository, this.beforeLogout})
    : super(const AuthState.checkingSession());

  Future<void> checkSession() async {
    final revision = ++_sessionRevision;
    try {
      final hasSession = await authRepository.checkSession();
      if (isClosed || revision != _sessionRevision) return;
      if (hasSession) {
        emit(
          AuthState.authenticated(
            username: authRepository.getSavedUsername() ?? 'Pengguna',
          ),
        );
      } else {
        emit(const AuthState.unauthenticated());
      }
    } on Failure catch (failure) {
      if (!isClosed && revision == _sessionRevision) {
        emit(AuthState.failure(failure.message));
      }
    } catch (_) {
      if (!isClosed && revision == _sessionRevision) {
        emit(
          const AuthState.failure('Sesi belum dapat diverifikasi. Coba lagi.'),
        );
      }
    }
  }

  Future<void> login(
    String username,
    String password, {
    String? captchaAnswer,
  }) async {
    if (_googleInFlight) return;
    if (username.isEmpty || password.isEmpty) {
      emit(const AuthState.failure('Username dan password wajib diisi'));
      return;
    }

    final revision = ++_sessionRevision;
    final captcha = state.captcha;
    emit(AuthState.authenticating(captcha: captcha));

    final result = await authRepository.login(
      username,
      password,
      captchaId: captcha?.captchaId,
      captchaAnswer: captcha == null ? null : captchaAnswer?.trim(),
    );
    if (isClosed || revision != _sessionRevision) return;

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

  Future<Failure?> loginGoogle(
    String token, {
    String? phone,
    bool consent = false,
  }) async {
    if (_googleInFlight ||
        state.isCheckingSession ||
        state.isAuthenticating ||
        state.isAuthenticated) {
      return null;
    }
    // Keep the current intro/register route mounted for the consent sheet.
    // The Google button owns progress until the server accepts this identity.
    _googleInFlight = true;
    final revision = ++_sessionRevision;
    try {
      final result = await authRepository
          .loginWithGoogle(token, phone: phone, consent: consent)
          // The transport itself allows30s. Allow the bounded8s runtime
          // bootstrap and secure session persistence to finish as well.
          .timeout(const Duration(seconds: 45));
      if (isClosed || revision != _sessionRevision) return null;
      return result.fold((failure) => failure, (name) {
        emit(AuthState.authenticated(username: name));
        return null;
      });
    } on TimeoutException {
      return const ServerFailure(
        'Login Google terlalu lama. Periksa koneksi lalu coba lagi.',
      );
    } catch (_) {
      return const ServerFailure(
        'Login Google belum berhasil. Silakan coba lagi.',
      );
    } finally {
      _googleInFlight = false;
    }
  }

  void clearCaptcha() {
    if (state.captcha != null && !state.isAuthenticating) {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> logout() async {
    final revision = ++_sessionRevision;
    try {
      try {
        await beforeLogout?.call();
      } catch (_) {}
      await authRepository.logout();
    } finally {
      if (!isClosed && revision == _sessionRevision) {
        emit(const AuthState.unauthenticated());
      }
    }
  }
}
