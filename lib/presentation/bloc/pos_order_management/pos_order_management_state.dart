import 'package:equatable/equatable.dart';
import '../../../../domain/models/pos_order_detail.dart';

enum PosOrderManagementStatus {
  initial,
  loading,
  loaded,
  failure,
  actionSuccess,
}

class PosOrderManagementState extends Equatable {
  final PosOrderManagementStatus status;
  final String errorMessage;
  final String successMessage;
  final List<PosOrderDetail> orders;

  const PosOrderManagementState({
    this.status = PosOrderManagementStatus.initial,
    this.errorMessage = '',
    this.successMessage = '',
    this.orders = const [],
  });

  PosOrderManagementState copyWith({
    PosOrderManagementStatus? status,
    String? errorMessage,
    String? successMessage,
    List<PosOrderDetail>? orders,
  }) {
    return PosOrderManagementState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      orders: orders ?? this.orders,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, successMessage, orders];
}
