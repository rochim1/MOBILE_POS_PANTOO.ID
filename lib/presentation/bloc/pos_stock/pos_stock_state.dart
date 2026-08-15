import 'package:equatable/equatable.dart';
import '../../../domain/models/pos_stock.dart';

enum PosStockStatus { initial, loading, success, failure }

class PosStockState extends Equatable {
  final PosStockStatus status;
  final String errorMessage;
  final List<PosStock> stocks;
  final PosStockStatistics? statistics;
  final String currentFilter;
  final String successMessage;

  const PosStockState({
    this.status = PosStockStatus.initial,
    this.errorMessage = '',
    this.stocks = const [],
    this.statistics,
    this.currentFilter = 'all',
    this.successMessage = '',
  });

  PosStockState copyWith({
    PosStockStatus? status,
    String? errorMessage,
    List<PosStock>? stocks,
    PosStockStatistics? statistics,
    String? currentFilter,
    String? successMessage,
  }) {
    return PosStockState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      stocks: stocks ?? this.stocks,
      statistics: statistics ?? this.statistics,
      currentFilter: currentFilter ?? this.currentFilter,
      successMessage: successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    stocks,
    statistics,
    currentFilter,
    successMessage,
  ];
}
