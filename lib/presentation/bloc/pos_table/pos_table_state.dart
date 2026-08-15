import 'package:equatable/equatable.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_table.dart';

enum PosTableStatus { initial, loading, success, failure, actionSuccess }

class PosTableState extends Equatable {
  final PosTableStatus status;
  final String errorMessage;
  final List<PosTableModel> tables;
  final String successMessage;

  const PosTableState({
    this.status = PosTableStatus.initial,
    this.errorMessage = '',
    this.tables = const [],
    this.successMessage = '',
  });

  PosTableState copyWith({
    PosTableStatus? status,
    String? errorMessage,
    List<PosTableModel>? tables,
    String? successMessage,
  }) {
    return PosTableState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      tables: tables ?? this.tables,
      successMessage: successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, tables, successMessage];
}
