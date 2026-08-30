import 'package:equatable/equatable.dart';

abstract class PosStockEvent extends Equatable {
  const PosStockEvent();

  @override
  List<Object?> get props => [];
}

class LoadStocks extends PosStockEvent {
  final String? search;
  final String? stockFilter;
  final String? locationId;

  const LoadStocks({this.search, this.stockFilter, this.locationId});

  @override
  List<Object?> get props => [search, stockFilter, locationId];
}

class LoadStatistics extends PosStockEvent {
  const LoadStatistics();
}

class AdjustStock extends PosStockEvent {
  final String id;
  final double newStock;
  final String reason;
  final String? note;
  final String stockBalanceId;
  final String? locationId;

  const AdjustStock({
    required this.id,
    required this.newStock,
    required this.reason,
    this.note,
    required this.stockBalanceId,
    this.locationId,
  });

  @override
  List<Object?> get props => [
    id,
    newStock,
    reason,
    note,
    stockBalanceId,
    locationId,
  ];
}
