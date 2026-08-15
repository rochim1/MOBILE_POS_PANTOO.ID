import 'package:equatable/equatable.dart';

enum AuthStatus { unauthenticated, authenticating, authenticated, failure }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? username;
  final String? error;

  const AuthState._({required this.status, this.username, this.error});
  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);
  const AuthState.authenticating() : this._(status: AuthStatus.authenticating);
  const AuthState.authenticated({required String username})
    : this._(status: AuthStatus.authenticated, username: username);
  const AuthState.failure(String error)
    : this._(status: AuthStatus.failure, error: error);

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isAuthenticating => status == AuthStatus.authenticating;
  bool get isFailure => status == AuthStatus.failure;

  @override
  List<Object?> get props => [status, username, error];
}
