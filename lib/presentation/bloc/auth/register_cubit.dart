import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/auth_repository.dart';
import 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AuthRepository authRepository;
  int _emailRequest = 0;
  int _usernameRequest = 0;

  RegisterCubit({required this.authRepository}) : super(const RegisterState());

  String sanitizeUsername(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), '');

  Future<bool> checkEmail(String email) async {
    final value = email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      emit(state.copyWith(checkingEmail: false, clearEmailAvailability: true));
      return false;
    }
    final request = ++_emailRequest;
    emit(state.copyWith(checkingEmail: true, clearEmailAvailability: true));
    final result = await authRepository.checkEmailAvailable(value);
    if (request != _emailRequest || isClosed) return false;
    return result.fold(
      (failure) {
        emit(state.copyWith(checkingEmail: false, error: failure.message));
        return false;
      },
      (available) {
        emit(
          state.copyWith(
            checkingEmail: false,
            emailAvailable: available,
            clearError: true,
          ),
        );
        return available;
      },
    );
  }

  Future<bool> checkUsername(String username) async {
    final value = sanitizeUsername(username);
    if (value.length < 3) {
      emit(
        state.copyWith(
          checkingUsername: false,
          clearUsernameAvailability: true,
        ),
      );
      return false;
    }
    final request = ++_usernameRequest;
    emit(
      state.copyWith(checkingUsername: true, clearUsernameAvailability: true),
    );
    final result = await authRepository.checkUsernameAvailable(value);
    if (request != _usernameRequest || isClosed) return false;
    return result.fold(
      (failure) {
        emit(state.copyWith(checkingUsername: false, error: failure.message));
        return false;
      },
      (available) {
        emit(
          state.copyWith(
            checkingUsername: false,
            usernameAvailable: available,
            clearError: true,
          ),
        );
        return available;
      },
    );
  }

  Future<void> register({
    required String name,
    required String phone,
    required String username,
    required String email,
    required String password,
  }) async {
    emit(state.copyWith(status: RegisterStatus.submitting, clearError: true));
    // Always verify the submitted values. A debounced availability result may
    // belong to the previous text when the user types and immediately submits.
    final emailOk = await checkEmail(email);
    final usernameOk = await checkUsername(username);
    if (!emailOk || !usernameOk) {
      emit(
        state.copyWith(
          status: RegisterStatus.failure,
          error: 'Email atau username belum tersedia.',
        ),
      );
      return;
    }
    final result = await authRepository.register(
      name: name,
      phone: phone,
      username: sanitizeUsername(username),
      email: email,
      password: password,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: RegisterStatus.failure, error: failure.message),
      ),
      (success) => emit(
        state.copyWith(
          status: success ? RegisterStatus.success : RegisterStatus.failure,
          error: success ? null : 'Akun belum berhasil dibuat.',
          clearError: success,
        ),
      ),
    );
  }
}
