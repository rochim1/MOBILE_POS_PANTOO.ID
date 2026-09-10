import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/pos_order_repository.dart';
import 'pos_order_management_event.dart';
import 'pos_order_management_state.dart';

class PosOrderManagementBloc
    extends Bloc<PosOrderManagementEvent, PosOrderManagementState> {
  final PosOrderRepository repository;

  PosOrderManagementBloc({required this.repository})
    : super(const PosOrderManagementState()) {
    on<LoadActiveOrders>(_onLoadActiveOrders);
    on<LoadTableOrders>(_onLoadTableOrders);
    on<UpdateItemStatus>(_onUpdateItemStatus);
  }

  Future<void> _onLoadActiveOrders(
    LoadActiveOrders event,
    Emitter<PosOrderManagementState> emit,
  ) async {
    emit(state.copyWith(status: PosOrderManagementStatus.loading));
    final result = await repository.getActiveOrders(
      storeId: event.storeId,
      search: event.search,
      status: event.status,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosOrderManagementStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (orders) => emit(
        state.copyWith(
          status: PosOrderManagementStatus.loaded,
          orders: orders,
          errorMessage: '',
        ),
      ),
    );
  }

  Future<void> _onLoadTableOrders(
    LoadTableOrders event,
    Emitter<PosOrderManagementState> emit,
  ) async {
    emit(state.copyWith(status: PosOrderManagementStatus.loading));

    final result = await repository.getOrdersByTable(event.tableId);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosOrderManagementStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (orders) => emit(
        state.copyWith(status: PosOrderManagementStatus.loaded, orders: orders),
      ),
    );
  }

  Future<void> _onUpdateItemStatus(
    UpdateItemStatus event,
    Emitter<PosOrderManagementState> emit,
  ) async {
    emit(state.copyWith(status: PosOrderManagementStatus.loading));

    final result = await repository.updateOrderItemStatus(
      event.orderId,
      event.itemId,
      event.newStatus,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosOrderManagementStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        emit(
          state.copyWith(
            status: PosOrderManagementStatus.actionSuccess,
            successMessage: 'Status pesanan berhasil diubah',
          ),
        );
        if (event.storeId.isNotEmpty) {
          add(
            LoadActiveOrders(
              storeId: event.storeId,
              search: event.search,
              status: event.statusFilter,
            ),
          );
        } else {
          add(LoadTableOrders(event.tableId));
        }
      },
    );
  }
}
