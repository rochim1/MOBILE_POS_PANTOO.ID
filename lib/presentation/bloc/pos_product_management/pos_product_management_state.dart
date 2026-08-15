import 'package:equatable/equatable.dart';

enum PosProductManagementStatus { initial, loading, success, failure }

class PosProductManagementState extends Equatable {
  final PosProductManagementStatus status;
  final String errorMessage;
  final String successMessage;

  const PosProductManagementState({
    this.status = PosProductManagementStatus.initial,
    this.errorMessage = '',
    this.successMessage = '',
  });

  PosProductManagementState copyWith({
    PosProductManagementStatus? status,
    String? errorMessage,
    String? successMessage,
  }) {
    return PosProductManagementState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object> get props => [status, errorMessage, successMessage];
}
