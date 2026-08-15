import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_settings_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_settings/pos_settings_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_settings/pos_settings_state.dart';

class PosSettingsBloc extends Bloc<PosSettingsEvent, PosSettingsState> {
  final PosSettingsRepository repository;

  PosSettingsBloc({required this.repository})
    : super(const PosSettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateSettings>(_onUpdateSettings);
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<PosSettingsState> emit,
  ) async {
    emit(state.copyWith(status: PosSettingsStatus.loading));

    final result = await repository.getSettings();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosSettingsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (settings) => emit(
        state.copyWith(status: PosSettingsStatus.loaded, settings: settings),
      ),
    );
  }

  Future<void> _onUpdateSettings(
    UpdateSettings event,
    Emitter<PosSettingsState> emit,
  ) async {
    emit(state.copyWith(status: PosSettingsStatus.saving));

    final result = await repository.updateSettings(event.input);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosSettingsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (settings) => emit(
        state.copyWith(
          status: PosSettingsStatus.saved,
          settings: settings,
          successMessage: 'Pengaturan berhasil disimpan',
        ),
      ),
    );
  }
}
