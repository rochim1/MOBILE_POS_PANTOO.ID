import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../domain/models/pos_financial_report.dart';
import '../../../../domain/repositories/pos_financial_report_repository.dart';

enum FinancialReportStatus { initial, loading, ready, denied, failure }

class PosFinancialReportState extends Equatable {
  const PosFinancialReportState({
    this.status = FinancialReportStatus.initial,
    this.options,
    this.range,
    this.report,
    this.failure,
  });
  final FinancialReportStatus status;
  final FinancialReportOptions? options;
  final FinancialReportRange? range;
  final PosProfitLossReport? report;
  final Failure? failure;
  @override
  List<Object?> get props => [status, options, range, report, failure];
}

class PosFinancialReportCubit extends Cubit<PosFinancialReportState> {
  PosFinancialReportCubit(this.repository)
    : super(const PosFinancialReportState());
  final PosFinancialReportRepository repository;
  int _request = 0;

  Future<void> initialize() async {
    final ticket = ++_request;
    final previousRange = state.range;
    final previousInstansi = state.options?.instansiId;
    emit(const PosFinancialReportState(status: FinancialReportStatus.loading));
    final result = await repository.getOptions();
    if (isClosed || ticket != _request) return;
    await result.fold((failure) async => _fail(failure), (options) async {
      final range =
          previousInstansi == options.instansiId &&
              previousRange?.validFor(options) == true
          ? previousRange!
          : FinancialReportRange.forPeriod(
              FinancialPeriod.thisMonth,
              options.today,
            );
      await _load(options, range, ticket);
    });
  }

  Future<void> load(FinancialReportRange range) async {
    final options = state.options;
    if (options == null || !range.validFor(options)) return;
    await _load(options, range, ++_request);
  }

  Future<void> _load(
    FinancialReportOptions options,
    FinancialReportRange range,
    int ticket,
  ) async {
    emit(
      PosFinancialReportState(
        status: FinancialReportStatus.loading,
        options: options,
        range: range,
      ),
    );
    final result = await repository.getProfitLoss(range);
    if (isClosed || ticket != _request) return;
    result.fold((failure) => _fail(failure, options: options, range: range), (
      report,
    ) {
      if (report.instansiId != options.instansiId || report.range != range) {
        _fail(const AuthFailure());
        return;
      }
      emit(
        PosFinancialReportState(
          status: FinancialReportStatus.ready,
          options: options,
          range: range,
          report: report,
        ),
      );
    });
  }

  void _fail(
    Failure failure, {
    FinancialReportOptions? options,
    FinancialReportRange? range,
  }) {
    final denied =
        failure is FinancialReportAccessFailure || failure is AuthFailure;
    emit(
      PosFinancialReportState(
        status: denied
            ? FinancialReportStatus.denied
            : FinancialReportStatus.failure,
        options: denied ? null : options,
        range: denied ? null : range,
        failure: failure,
      ),
    );
  }

  @override
  Future<void> close() {
    _request++;
    return super.close();
  }
}
