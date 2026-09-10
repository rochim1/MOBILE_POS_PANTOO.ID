import 'package:equatable/equatable.dart';

abstract class PosOrderManagementEvent extends Equatable {
  const PosOrderManagementEvent();

  @override
  List<Object?> get props => [];
}

class LoadTableOrders extends PosOrderManagementEvent {
  final String tableId;

  const LoadTableOrders(this.tableId);

  @override
  List<Object?> get props => [tableId];
}

class LoadActiveOrders extends PosOrderManagementEvent {
  final String storeId;
  final String search;
  final String status;

  const LoadActiveOrders({
    required this.storeId,
    this.search = '',
    this.status = '',
  });

  @override
  List<Object?> get props => [storeId, search, status];
}

class UpdateItemStatus extends PosOrderManagementEvent {
  final String orderId;
  final String itemId;
  final String newStatus;
  final String tableId; // Used to reload after update
  final String storeId;
  final String search;
  final String statusFilter;

  const UpdateItemStatus({
    required this.orderId,
    required this.itemId,
    required this.newStatus,
    required this.tableId,
    this.storeId = '',
    this.search = '',
    this.statusFilter = '',
  });

  @override
  List<Object?> get props => [
    orderId,
    itemId,
    newStatus,
    tableId,
    storeId,
    search,
    statusFilter,
  ];
}
