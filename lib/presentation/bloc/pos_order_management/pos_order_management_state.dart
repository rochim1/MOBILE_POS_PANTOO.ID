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
  final int page;
  final int total;
  final Map<String, int> statusCounts;

  const PosOrderManagementState({
    this.status = PosOrderManagementStatus.initial,
    this.errorMessage = '',
    this.successMessage = '',
    this.orders = const [],
    this.page = 0,
    this.total = 0,
    this.statusCounts = const {},
  });

  PosOrderManagementState copyWith({
    PosOrderManagementStatus? status,
    String? errorMessage,
    String? successMessage,
    List<PosOrderDetail>? orders,
    int? page,
    int? total,
    Map<String, int>? statusCounts,
  }) {
    return PosOrderManagementState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      orders: orders ?? this.orders,
      page: page ?? this.page,
      total: total ?? this.total,
      statusCounts: statusCounts ?? this.statusCounts,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    successMessage,
    orders,
    page,
    total,
    statusCounts,
  ];
}
