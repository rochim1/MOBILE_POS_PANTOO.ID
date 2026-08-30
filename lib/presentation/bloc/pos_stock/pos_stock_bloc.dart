import 'package:flutter_bloc/flutter_bloc.dart';
import 'pos_stock_event.dart';
import 'pos_stock_state.dart';
import '../../../domain/repositories/pos_stock_repository.dart';
import '../../../domain/models/pos_stock.dart';

class PosStockBloc extends Bloc<PosStockEvent, PosStockState> {
  final PosStockRepository repository;

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
      stockBalanceId: event.stockBalanceId,
      locationId: event.locationId ?? state.selectedLocationId,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosStockStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (newStock) {
        final stocks = state.stocks
            .map(
              (item) => item.id == event.id
                  ? PosStock.fromJson({...item.toJson(), 'stok': newStock})
                  : item,
            )
            .toList();
        emit(
          state.copyWith(
            status: PosStockStatus.success,
            stocks: stocks,
            successMessage: 'Stok berhasil disesuaikan',
            errorMessage: '',
          ),
        );
        add(const LoadStatistics());
      },
    );
  }

  Future<void> _onLoadStocks(
    LoadStocks event,
    Emitter<PosStockState> emit,
  ) async {
    var locations = state.locations;
    if (locations.isEmpty) {
      final locationResult = await repository.getStockLocations();
      locations = locationResult.fold((_) => const [], (items) => items);
    }
    var locationId = event.locationId ?? state.selectedLocationId;
    if (locationId.isEmpty) {
      final defaultLocation = await repository.getDefaultStockLocationId();
      locationId = defaultLocation.fold(
        (_) => locations.firstOrNull?['_id']?.toString() ?? '',
        (id) => id,
      );
    }
    emit(
      state.copyWith(
        status: PosStockStatus.loading,
        currentFilter: event.stockFilter ?? state.currentFilter,
        locations: locations,
        selectedLocationId: locationId,
      ),
    );

    final result = await repository.getStocks(
      search: event.search,
      stockFilter: event.stockFilter ?? state.currentFilter,
      locationId: locationId,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosStockStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (stocks) {
        emit(state.copyWith(status: PosStockStatus.success, stocks: stocks));
        // Statistics are scoped to the selected warehouse/location too.
        add(const LoadStatistics());
      },
    );
  }

  Future<void> _onLoadStatistics(
    LoadStatistics event,
    Emitter<PosStockState> emit,
  ) async {
    final result = await repository.getStatistics(
      locationId: state.selectedLocationId,
    );
    result.fold((failure) {
      // Silently fail — statistics are supplementary
    }, (statistics) => emit(state.copyWith(statistics: statistics)));
  }
}
