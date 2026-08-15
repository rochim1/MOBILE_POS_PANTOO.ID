import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';
import '../../../domain/repositories/auth_repository.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({required this.authRepository})
    : super(const AuthState.unauthenticated());

  Future<void> checkSession() async {
    final hasSession = await authRepository.checkSession();
    if (hasSession) {
      emit(
        AuthState.authenticated(
          username: authRepository.getSavedUsername() ?? 'Pengguna',
        ),
      );
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      emit(const AuthState.failure('Username dan password wajib diisi'));
      return;
    }

    emit(const AuthState.authenticating());

    final result = await authRepository.login(username, password);

    result.fold(
      (failure) => emit(AuthState.failure(failure.message)),
      (name) => emit(AuthState.authenticated(username: name)),
    );
  }

  Future<void> logout() async {
    try {
      await authRepository.logout();
    } finally {
      if (!isClosed) emit(const AuthState.unauthenticated());
    }
  }
}
