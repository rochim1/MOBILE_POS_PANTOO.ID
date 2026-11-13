import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_financial_report.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_business_report.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_financial_report_repository.dart';
import 'pos_financial_report_cubit.dart';

class PosBusinessReportState extends Equatable {
  const PosBusinessReportState({
    this.status = FinancialReportStatus.initial,
    this.options,
    this.filter,
    this.report,
    this.failure,
  });
  final FinancialReportStatus status;
  final FinancialReportOptions? options;
  final PosBusinessReportFilter? filter;
  final PosBusinessReport? report;
  final Failure? failure;
  @override
  List<Object?> get props => [status, options, filter, report, failure];
}

class PosBusinessReportCubit extends Cubit<PosBusinessReportState> {
  PosBusinessReportCubit(this.repository, this.initialKind)
    : super(const PosBusinessReportState());
  final PosFinancialReportRepository repository;
  final PosBusinessReportKind initialKind;
  int _request = 0;
  PosBusinessReportFilter _default(
    PosBusinessReportKind kind,
    FinancialReportOptions options,
  ) => PosBusinessReportFilter(
    kind: kind,
    range: FinancialReportRange.forPeriod(
      kind.cutoff ? FinancialPeriod.today : FinancialPeriod.thisMonth,
      options.today,
    ),
  );
  Future<void> initialize() async {
    final ticket = ++_request, old = state;
    emit(const PosBusinessReportState(status: FinancialReportStatus.loading));
    final result = await repository.getOptions();
    if (isClosed || ticket != _request) return;
    await result.fold((failure) async => _fail(failure), (options) async {
      final filter =
          old.options?.instansiId == options.instansiId &&
              old.filter?.range.validFor(options) == true &&
              (old.filter?.kind != PosBusinessReportKind.restock ||
                  old.filter?.range.end == options.today)
          ? old.filter!
          : _default(old.filter?.kind ?? initialKind, options);
      await _load(options, filter, 1, ticket);
    });
  }

  Future<void> load(PosBusinessReportFilter filter, {int page = 1}) async {
    final options = state.options;
    if (options == null || !filter.range.validFor(options) || page < 1) return;
    await _load(options, filter, page, ++_request);
  }

  Future<void> changeKind(PosBusinessReportKind kind) async {
    final options = state.options;
    if (options != null) await load(_default(kind, options));
  }

  Future<void> _load(
    FinancialReportOptions options,
    PosBusinessReportFilter filter,
    int page,
    int ticket,
  ) async {
    emit(
      PosBusinessReportState(
        status: FinancialReportStatus.loading,
        options: options,
        filter: filter,
      ),
    );
    final result = await repository.getBusinessReport(filter, page: page);
    if (isClosed || ticket != _request) return;
    result.fold((failure) => _fail(failure, options: options, filter: filter), (
      report,
    ) {
      if (report.instansiId != options.instansiId ||
          report.filter != filter ||
          report.page != page) {
        _fail(const AuthFailure());
        return;
      }
      emit(
        PosBusinessReportState(
          status: FinancialReportStatus.ready,
          options: options,
          filter: filter,
          report: report,
        ),
      );
    });
  }

  void _fail(
    Failure failure, {
    FinancialReportOptions? options,
    PosBusinessReportFilter? filter,
  }) {
    final denied =
        failure is FinancialReportAccessFailure || failure is AuthFailure;
    // Keep only filter/options after a source-specific denial so another permitted tab can be selected.
    emit(
      PosBusinessReportState(
        status: denied
            ? FinancialReportStatus.denied
            : FinancialReportStatus.failure,
        options: failure is AuthFailure ? null : options,
        filter: failure is AuthFailure ? null : filter,
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
