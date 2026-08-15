import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/pos_report_repository.dart';
import 'pos_report_event.dart';
import 'pos_report_state.dart';

class PosReportBloc extends Bloc<PosReportEvent, PosReportState> {
  final PosReportRepository repository;

  PosReportBloc({required this.repository}) : super(const PosReportState()) {
    on<LoadReport>(_onLoadReport);
  }

  Future<void> _onLoadReport(
    LoadReport event,
    Emitter<PosReportState> emit,
  ) async {
    emit(
      state.copyWith(
        status: PosReportStatus.loading,
        selectedPeriod: event.periodLabel,
      ),
    );

    final result = await repository.getReportData(days: event.days);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosReportStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (data) => emit(
        state.copyWith(status: PosReportStatus.loaded, reportData: data),
      ),
    );
  }
}
