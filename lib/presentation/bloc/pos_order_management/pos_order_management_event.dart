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

class UpdateItemStatus extends PosOrderManagementEvent {
  final String orderId;
  final String itemId;
  final String newStatus;
  final String tableId; // Used to reload after update

  const UpdateItemStatus({
    required this.orderId,
    required this.itemId,
    required this.newStatus,
    required this.tableId,
  });

  @override
  List<Object?> get props => [orderId, itemId, newStatus, tableId];
}
