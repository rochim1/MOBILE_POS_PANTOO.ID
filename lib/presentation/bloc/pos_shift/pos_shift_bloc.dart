import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/pos_repository.dart';
import 'pos_shift_event.dart';
import 'pos_shift_state.dart';

class PosShiftBloc extends Bloc<PosShiftEvent, PosShiftState> {
  final PosRepository posRepository;
  int _requestVersion = 0;
  bool _actionInProgress = false;
  String? _pendingLoadStoreId;

  void _finishAction() {
    _actionInProgress = false;
    final pending = _pendingLoadStoreId;
    _pendingLoadStoreId = null;
    if (pending != null && !isClosed) add(LoadShiftData(pending));
  }

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
    if (_actionInProgress) {
      _pendingLoadStoreId = event.tokoId;
      return;
    }
    final request = ++_requestVersion;
    final operatorId = posRepository.activeOperatorId;
    emit(PosShiftLoading());
    try {
      // Use the selected store's ownership mode, but search all outlets.
      final activeShift = await posRepository.getActiveShiftForStore(
        event.tokoId,
      );
      if (request != _requestVersion ||
          operatorId != posRepository.activeOperatorId) {
        return;
      }
      final historyResult = await posRepository.getShiftHistory();
      if (request != _requestVersion ||
          operatorId != posRepository.activeOperatorId) {
        return;
      }
      List<Map<String, dynamic>> history = [];
      historyResult.fold((l) => null, (r) => history = r);
      emit(PosShiftLoaded(activeShift: activeShift, shiftHistory: history));
    } catch (_) {
      if (request == _requestVersion) {
        emit(
          const PosShiftError(
            'Shift belum dapat diperiksa. Periksa koneksi atau masuk ulang dengan PIN, lalu coba lagi. Jangan membuka shift pengganti.',
          ),
        );
      }
    }
  }

  Future<void> _onReloadShiftHistory(
    ReloadShiftHistory event,
    Emitter<PosShiftState> emit,
  ) async {
    final currentState = state;
    if (currentState is PosShiftLoaded) {
      final request = _requestVersion;
      emit(currentState.copyWith(isLoadingHistory: true));
      final historyResult = await posRepository.getShiftHistory();
      if (request != _requestVersion || _actionInProgress) return;
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
    if (_actionInProgress) return;
    _actionInProgress = true;
    _requestVersion++;
    final currentState = state;
    final operatorId = posRepository.activeOperatorId;
    emit(PosShiftLoading());
    try {
      final existing = await posRepository.getActiveShiftForStore(event.tokoId);
      if (operatorId != posRepository.activeOperatorId) {
        throw StateError('Operator berubah selama pemeriksaan shift');
      }
      if (existing != null) {
        emit(
          PosShiftLoaded(
            activeShift: existing,
            shiftHistory: currentState is PosShiftLoaded
                ? currentState.shiftHistory
                : const [],
            notice:
                'Shift aktif ditemukan. Lanjutkan shift tersebut atau kembali ke outlet shift aktif; tidak perlu membuka shift baru.',
          ),
        );
        return;
      }
      final result = await posRepository.openShift(
        event.tokoId,
        event.amount,
        event.notes,
      );
      await result.fold<Future<void>>(
        (failure) async {
          emit(PosShiftError(failure.message));
          // A concurrent device may have opened the shift after preflight.
          final active = await posRepository.getActiveShiftForStore(
            event.tokoId,
          );
          emit(
            PosShiftLoaded(
              activeShift: active,
              shiftHistory: currentState is PosShiftLoaded
                  ? currentState.shiftHistory
                  : const [],
            ),
          );
        },
        (_) async {
          emit(const PosShiftActionSuccess('Shift berhasil dibuka!'));
          _actionInProgress = false;
          add(LoadShiftData(event.tokoId));
        },
      );
    } catch (_) {
      emit(
        const PosShiftError(
          'Shift belum dapat diperiksa. Periksa koneksi atau PIN lalu coba lagi.',
        ),
      );
    } finally {
      _finishAction();
    }
  }

  Future<void> _onCloseShift(
    CloseShiftEvent event,
    Emitter<PosShiftState> emit,
  ) async {
    if (_actionInProgress) return;
    _actionInProgress = true;
    _requestVersion++;
    try {
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
          _actionInProgress = false;
          add(LoadShiftData(event.tokoId));
        },
      );
    } catch (_) {
      emit(
        const PosShiftError(
          'Gagal memeriksa hasil tutup shift. Muat ulang sebelum mencoba lagi.',
        ),
      );
    } finally {
      _finishAction();
    }
  }

  Future<void> _onAddPettyCash(
    AddPettyCashEvent event,
    Emitter<PosShiftState> emit,
  ) async {
    if (_actionInProgress) return;
    _actionInProgress = true;
    _requestVersion++;
    try {
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
          _actionInProgress = false;
          add(LoadShiftData(event.tokoId));
        },
      );
    } catch (_) {
      emit(
        const PosShiftError(
          'Gagal memeriksa hasil kas masuk/keluar. Muat ulang sebelum mencoba lagi.',
        ),
      );
    } finally {
      _finishAction();
    }
  }
}
