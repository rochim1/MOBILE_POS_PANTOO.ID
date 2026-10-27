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
  final List<Map<String, dynamic>> locations;
  final String selectedLocationId;
  final int page;
  final int total;
  final String search;

  const PosStockState({
    this.status = PosStockStatus.initial,
    this.errorMessage = '',
    this.stocks = const [],
    this.statistics,
    this.currentFilter = 'all',
    this.successMessage = '',
    this.locations = const [],
    this.selectedLocationId = '',
    this.page = 1,
    this.total = 0,
    this.search = '',
  });

  PosStockState copyWith({
    PosStockStatus? status,
    String? errorMessage,
    List<PosStock>? stocks,
    PosStockStatistics? statistics,
    String? currentFilter,
    String? successMessage,
    List<Map<String, dynamic>>? locations,
    String? selectedLocationId,
    int? page,
    int? total,
    String? search,
  }) {
    return PosStockState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      stocks: stocks ?? this.stocks,
      statistics: statistics ?? this.statistics,
      currentFilter: currentFilter ?? this.currentFilter,
      successMessage: successMessage ?? this.successMessage,
      locations: locations ?? this.locations,
      selectedLocationId: selectedLocationId ?? this.selectedLocationId,
      page: page ?? this.page,
      total: total ?? this.total,
      search: search ?? this.search,
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
    locations,
    selectedLocationId,
    page,
    total,
    search,
  ];
}
