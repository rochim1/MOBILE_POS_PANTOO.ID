import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/pos_repository.dart';
import 'pos_shift_event.dart';
import 'pos_shift_state.dart';

class PosShiftBloc extends Bloc<PosShiftEvent, PosShiftState> {
  final PosRepository posRepository;

  PosShiftBloc({required this.posRepository}) : super(PosShiftInitial()) {
    on<LoadShiftData>(_onLoadShiftData);
    on<ReloadShiftHistory>(_onReloadShiftHistory);
    on<OpenShiftEvent>(_onOpenShift);
    on<CloseShiftEvent>(_onCloseShift);
    on<AddPettyCashEvent>(_onAddPettyCash);
  }

  Future<void> _onLoadShiftData(
    LoadShiftData event,
    Emitter<PosShiftState> emit,
  ) async {
    emit(PosShiftLoading());

    final activeShift = await posRepository.getActiveShift(event.tokoId);

    final historyResult = await posRepository.getShiftHistory();
    List<Map<String, dynamic>> history = [];
    historyResult.fold(
      (l) => null, // ignore error for history
      (r) => history = r,
    );

    emit(PosShiftLoaded(activeShift: activeShift, shiftHistory: history));
  }

  Future<void> _onReloadShiftHistory(
    ReloadShiftHistory event,
    Emitter<PosShiftState> emit,
  ) async {
    final currentState = state;
    if (currentState is PosShiftLoaded) {
      emit(currentState.copyWith(isLoadingHistory: true));
      final historyResult = await posRepository.getShiftHistory();
      historyResult.fold(
        (l) => emit(currentState.copyWith(isLoadingHistory: false)),
        (r) => emit(
          currentState.copyWith(shiftHistory: r, isLoadingHistory: false),
        ),
      );
    }
  }

  Future<void> _onOpenShift(
    OpenShiftEvent event,
    Emitter<PosShiftState> emit,
  ) async {
    final currentState = state;
    emit(PosShiftLoading());

    final result = await posRepository.openShift(
      event.tokoId,
      event.amount,
      event.notes,
    );
    result.fold(
      (failure) {
        emit(PosShiftError(failure.message));
        if (currentState is PosShiftLoaded) emit(currentState);
      },
      (_) {
        emit(const PosShiftActionSuccess('Shift berhasil dibuka!'));
        add(LoadShiftData(event.tokoId));
      },
    );
  }

  Future<void> _onCloseShift(
    CloseShiftEvent event,
    Emitter<PosShiftState> emit,
  ) async {
    final currentState = state;
    emit(PosShiftLoading());

    final result = await posRepository.closeShift(
      event.shiftId,
      event.actualCash,
      event.notes,
    );
    result.fold(
      (failure) {
        emit(PosShiftError(failure.message));
        if (currentState is PosShiftLoaded) emit(currentState);
      },
      (_) {
        emit(const PosShiftActionSuccess('Shift berhasil ditutup!'));
        add(LoadShiftData(event.tokoId));
      },
    );
  }

  Future<void> _onAddPettyCash(
    AddPettyCashEvent event,
    Emitter<PosShiftState> emit,
  ) async {
    final currentState = state;
    emit(PosShiftLoading());

    final result = await posRepository.addPettyCash(
      event.shiftId,
      event.type,
      event.amount,
      event.notes,
    );
    result.fold(
      (failure) {
        emit(PosShiftError(failure.message));
        if (currentState is PosShiftLoaded) emit(currentState);
      },
      (_) {
        emit(
          PosShiftActionSuccess(
            'Kas ${event.type == "in" ? "Masuk" : "Keluar"} berhasil dicatat!',
          ),
        );
        add(LoadShiftData(event.tokoId));
      },
    );
  }
}
