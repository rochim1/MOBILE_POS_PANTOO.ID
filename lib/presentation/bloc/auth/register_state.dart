import 'package:equatable/equatable.dart';

enum RegisterStatus { initial, submitting, success, failure }

class RegisterState extends Equatable {
  final RegisterStatus status;
  final bool checkingEmail;
  final bool checkingUsername;
  final bool? emailAvailable;
  final bool? usernameAvailable;
  final String? error;

  const RegisterState({
    this.status = RegisterStatus.initial,
    this.checkingEmail = false,
    this.checkingUsername = false,
    this.emailAvailable,
    this.usernameAvailable,
    this.error,
  });

  bool get isSubmitting => status == RegisterStatus.submitting;

  RegisterState copyWith({
    RegisterStatus? status,
    bool? checkingEmail,
    bool? checkingUsername,
    bool? emailAvailable,
    bool? usernameAvailable,
    bool clearEmailAvailability = false,
    bool clearUsernameAvailability = false,
    String? error,
    bool clearError = false,
  }) {
    return RegisterState(
      status: status ?? this.status,
      checkingEmail: checkingEmail ?? this.checkingEmail,
      checkingUsername: checkingUsername ?? this.checkingUsername,
      emailAvailable: clearEmailAvailability
          ? null
          : emailAvailable ?? this.emailAvailable,
      usernameAvailable: clearUsernameAvailability
          ? null
          : usernameAvailable ?? this.usernameAvailable,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    checkingEmail,
    checkingUsername,
    emailAvailable,
    usernameAvailable,
    error,
  ];
}
