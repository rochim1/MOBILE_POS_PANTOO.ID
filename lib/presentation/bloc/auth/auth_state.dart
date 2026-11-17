import 'package:equatable/equatable.dart';

import '../../../core/error/failures.dart';

enum AuthStatus {
  checkingSession,
  unauthenticated,
  authenticating,
  checkingSubscription,
  authenticated,
  failure,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final String? username;
  final String? error;
  final LoginCaptchaFailure? captcha;
  final bool restoringSession;

  const AuthState._({
    required this.status,
    this.username,
    this.error,
    this.captcha,
    this.restoringSession = false,
  });
  const AuthState.checkingSession()
    : this._(status: AuthStatus.checkingSession);
  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);
  const AuthState.authenticating({LoginCaptchaFailure? captcha})
    : this._(status: AuthStatus.authenticating, captcha: captcha);
  const AuthState.authenticated({required String username})
    : this._(status: AuthStatus.authenticated, username: username);
  const AuthState.checkingSubscription({
    required String username,
    bool restoringSession = false,
  }) : this._(
         status: AuthStatus.checkingSubscription,
         username: username,
         restoringSession: restoringSession,
       );
  const AuthState.subscriptionFailure(String error, {required String username})
    : this._(status: AuthStatus.failure, error: error, username: username);
  const AuthState.failure(String error, {LoginCaptchaFailure? captcha})
    : this._(status: AuthStatus.failure, error: error, captcha: captcha);

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isCheckingSession => status == AuthStatus.checkingSession;
  bool get isCheckingSubscription => status == AuthStatus.checkingSubscription;
  bool get canRetrySubscription => isFailure && username != null;
  bool get isAuthenticating =>
      status == AuthStatus.authenticating || isCheckingSubscription;
  bool get isFailure => status == AuthStatus.failure;

  @override
  List<Object?> get props => [
    status,
    username,
    error,
    captcha,
    restoringSession,
  ];
}
