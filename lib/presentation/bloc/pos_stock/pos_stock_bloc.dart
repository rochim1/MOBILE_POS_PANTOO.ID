import 'package:flutter_bloc/flutter_bloc.dart';
import 'pos_stock_event.dart';
import 'pos_stock_state.dart';
import '../../../domain/repositories/pos_stock_repository.dart';

class PosStockBloc extends Bloc<PosStockEvent, PosStockState> {
  final PosStockRepository repository;
  int _requestVersion = 0;

  PosStockBloc({required this.repository}) : super(const PosStockState()) {
    on<LoadStocks>(_onLoadStocks);
    on<LoadStatistics>(_onLoadStatistics);
    on<AdjustStock>(_onAdjustStock);
  }

  Future<void> _onAdjustStock(
    AdjustStock event,
    Emitter<PosStockState> emit,
  ) async {
    emit(state.copyWith(status: PosStockStatus.loading, successMessage: ''));
    final result = await repository.adjustStock(
      id: event.id,
      newStock: event.newStock,
      reason: event.reason,
      note: event.note,
      reference: event.reference,
      stockBalanceId: event.stockBalanceId,
      locationId: event.locationId ?? state.selectedLocationId,
      buildingCode: event.buildingCode,
      roomCode: event.roomCode,
      rackName: event.rackName,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosStockStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) {
        emit(
          state.copyWith(
            status: PosStockStatus.success,
            successMessage: 'Stok berhasil disesuaikan',
            errorMessage: '',
          ),
        );
        add(
          LoadStocks(
            stockFilter: state.currentFilter,
            locationId: state.selectedLocationId,
          ),
        );
      },
    );
  }

  Future<void> _onLoadStocks(
    LoadStocks event,
    Emitter<PosStockState> emit,
  ) async {
    final version = ++_requestVersion;
    var locations = state.locations;
    if (locations.isEmpty) {
      final locationResult = await repository.getStockLocations();
      locations = locationResult.fold((_) => const [], (items) => items);
    }
    if (version != _requestVersion || emit.isDone) return;
    var locationId = event.locationId ?? state.selectedLocationId;
    emit(
      state.copyWith(
        status: PosStockStatus.loading,
        currentFilter: event.stockFilter ?? state.currentFilter,
        locations: locations,
        selectedLocationId: locationId,
        search: event.search ?? '',
      ),
    );

    final result = await repository.getStockPage(
      search: event.search,
      stockFilter: event.stockFilter ?? state.currentFilter,
      locationId: locationId,
      page: event.page,
    );

    if (version != _requestVersion || emit.isDone) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosStockStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (result) {
        emit(
          state.copyWith(
            status: PosStockStatus.success,
            stocks: result.items,
            statistics: result.statistics,
            page: event.page,
            total: result.total,
          ),
        );
      },
    );
  }

  Future<void> _onLoadStatistics(
    LoadStatistics event,
    Emitter<PosStockState> emit,
  ) async {
    // A stock-page response includes the full filtered summary; no second
    // download of the entire stock catalog is needed.
  }
}
