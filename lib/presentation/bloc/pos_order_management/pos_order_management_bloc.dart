import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/pos_order_repository.dart';
import 'pos_order_management_event.dart';
import 'pos_order_management_state.dart';

class PosOrderManagementBloc
    extends Bloc<PosOrderManagementEvent, PosOrderManagementState> {
  final PosOrderRepository repository;
  int _activeVersion = 0;
  LoadActiveOrders? _lastActiveRequest;

  PosOrderManagementBloc({required this.repository})
    : super(const PosOrderManagementState()) {
    on<LoadActiveOrders>(_onLoadActiveOrders);
    on<LoadKitchenTickets>(_onLoadKitchenTickets);
    on<LoadTableOrders>(_onLoadTableOrders);
    on<UpdateItemStatus>(_onUpdateItemStatus);
    on<UpdateOrderStatus>(_onUpdateOrderStatus);
  }

  Future<void> _onLoadKitchenTickets(
    LoadKitchenTickets event,
    Emitter<PosOrderManagementState> emit,
  ) async {
    final version = ++_activeVersion;
    emit(state.copyWith(status: PosOrderManagementStatus.loading));
    final result = await repository.getKitchenPage(
      storeId: event.storeId,
      stationId: event.stationId,
      page: event.page,
      status: event.status,
    );
    if (version != _activeVersion || emit.isDone) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosOrderManagementStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (result) => emit(
        state.copyWith(
          status: PosOrderManagementStatus.loaded,
          orders: result.items,
          total: result.total,
          page: event.page,
          statusCounts: result.statusCounts,
          errorMessage: '',
        ),
      ),
    );
  }

  Future<void> _onLoadActiveOrders(
    LoadActiveOrders event,
    Emitter<PosOrderManagementState> emit,
  ) async {
    final version = ++_activeVersion;
    _lastActiveRequest = event;
    emit(state.copyWith(status: PosOrderManagementStatus.loading));
    final result = await repository.getActiveOrders(
      storeId: event.storeId,
      search: event.search,
      status: event.status,
      fulfillment: event.fulfillment,
      dateFrom: event.dateFrom,
      dateTo: event.dateTo,
      sort: event.sort,
      page: event.page,
    );
    if (version != _activeVersion || emit.isDone) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosOrderManagementStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (result) => emit(
        state.copyWith(
          status: PosOrderManagementStatus.loaded,
          orders: result.items,
          page: event.page,
          total: result.total,
          statusCounts: result.statusCounts,
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
      note: event.note,
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
              fulfillment: _lastActiveRequest?.fulfillment ?? '',
              dateFrom: _lastActiveRequest?.dateFrom ?? '',
              dateTo: _lastActiveRequest?.dateTo ?? '',
              sort: _lastActiveRequest?.sort ?? 'oldest',
            ),
          );
        } else {
          add(LoadTableOrders(event.tableId));
        }
      },
    );
  }

  Future<void> _onUpdateOrderStatus(
    UpdateOrderStatus event,
    Emitter<PosOrderManagementState> emit,
  ) async {
    emit(state.copyWith(status: PosOrderManagementStatus.loading));

    final result = await repository.updateOrderStatus(
      event.orderId,
      event.newStatus,
      note: event.note,
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
              fulfillment: _lastActiveRequest?.fulfillment ?? '',
              dateFrom: _lastActiveRequest?.dateFrom ?? '',
              dateTo: _lastActiveRequest?.dateTo ?? '',
              sort: _lastActiveRequest?.sort ?? 'oldest',
            ),
          );
        } else {
          add(LoadTableOrders(event.tableId));
        }
      },
    );
  }
}
