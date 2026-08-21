import 'package:equatable/equatable.dart';
import '../../../domain/models/pos_product.dart';

enum PosProductManagementStatus { initial, loading, success, failure }

class PosProductManagementState extends Equatable {
  final PosProductManagementStatus status;
  final String errorMessage;
  final String successMessage;
  final String operation;
  final PosProduct? product;
  final String affectedProductId;

  const PosProductManagementState({
    this.status = PosProductManagementStatus.initial,
    this.errorMessage = '',
    this.successMessage = '',
    this.operation = '',
    this.product,
    this.affectedProductId = '',
  });

  PosProductManagementState copyWith({
    PosProductManagementStatus? status,
    String? errorMessage,
    String? successMessage,
    String? operation,
    PosProduct? product,
    bool clearProduct = false,
    String? affectedProductId,
  }) {
    return PosProductManagementState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      operation: operation ?? this.operation,
      product: clearProduct ? null : (product ?? this.product),
      affectedProductId: affectedProductId ?? this.affectedProductId,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    successMessage,
    operation,
    product,
    affectedProductId,
  ];
}
