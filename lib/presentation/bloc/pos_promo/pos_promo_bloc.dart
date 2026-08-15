import 'package:flutter_bloc/flutter_bloc.dart';
import 'pos_promo_event.dart';
import 'pos_promo_state.dart';
import '../../../domain/repositories/pos_promo_repository.dart';

class PosPromoBloc extends Bloc<PosPromoEvent, PosPromoState> {
  final PosPromoRepository promoRepository;

  PosPromoBloc({required this.promoRepository}) : super(const PosPromoState()) {
    on<LoadPromos>(_onLoadPromos);
    on<CreatePromo>(_onCreatePromo);
    on<UpdatePromo>(_onUpdatePromo);
    on<DeletePromo>(_onDeletePromo);
    on<TogglePromoStatus>(_onTogglePromoStatus);
  }

  Future<void> _onLoadPromos(
    LoadPromos event,
    Emitter<PosPromoState> emit,
  ) async {
    emit(state.copyWith(status: PosPromoStatus.loading));
    final result = await promoRepository.getPromos(
      search: event.search,
      isActive: event.isActive,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosPromoStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (data) =>
          emit(state.copyWith(status: PosPromoStatus.success, promos: data)),
    );
  }

  Future<void> _onCreatePromo(
    CreatePromo event,
    Emitter<PosPromoState> emit,
  ) async {
    emit(state.copyWith(status: PosPromoStatus.loading));
    final result = await promoRepository.createPromo(event.input);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosPromoStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (promo) {
        emit(
          state.copyWith(
            status: PosPromoStatus.actionSuccess,
            successMessage: 'Promo "${promo.name}" berhasil dibuat',
          ),
        );
        add(const LoadPromos());
      },
    );
  }

  Future<void> _onUpdatePromo(
    UpdatePromo event,
    Emitter<PosPromoState> emit,
  ) async {
    emit(state.copyWith(status: PosPromoStatus.loading));
    final result = await promoRepository.updatePromo(event.id, event.input);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosPromoStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (promo) {
        emit(
          state.copyWith(
            status: PosPromoStatus.actionSuccess,
            successMessage: 'Promo "${promo.name}" berhasil diupdate',
          ),
        );
        add(const LoadPromos());
      },
    );
  }

  Future<void> _onDeletePromo(
    DeletePromo event,
    Emitter<PosPromoState> emit,
  ) async {
    emit(state.copyWith(status: PosPromoStatus.loading));
    final result = await promoRepository.deletePromo(event.id);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosPromoStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (success) {
        emit(
          state.copyWith(
            status: PosPromoStatus.actionSuccess,
            successMessage: 'Promo berhasil dihapus',
          ),
        );
        add(const LoadPromos());
      },
    );
  }

  Future<void> _onTogglePromoStatus(
    TogglePromoStatus event,
    Emitter<PosPromoState> emit,
  ) async {
    emit(state.copyWith(status: PosPromoStatus.loading));
    final result = await promoRepository.togglePromoStatus(event.id);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosPromoStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (promo) {
        final statusText = promo.isActive ? 'diaktifkan' : 'dinonaktifkan';
        emit(
          state.copyWith(
            status: PosPromoStatus.actionSuccess,
            successMessage: 'Promo "${promo.name}" berhasil $statusText',
          ),
        );
        add(const LoadPromos());
      },
    );
  }
}
