import 'package:equatable/equatable.dart';
import '../../../../domain/models/pos_report.dart';

enum PosReportStatus { initial, loading, loaded, failure }

class PosReportState extends Equatable {
  final PosReportStatus status;
  final String errorMessage;
  final PosReportData? reportData;
  final String selectedPeriod;

  const PosReportState({
    this.status = PosReportStatus.initial,
    this.errorMessage = '',
    this.reportData,
    this.selectedPeriod = 'Minggu Ini',
  });

  PosReportState copyWith({
    PosReportStatus? status,
    String? errorMessage,
    PosReportData? reportData,
    String? selectedPeriod,
  }) {
    return PosReportState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      reportData: reportData ?? this.reportData,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, reportData, selectedPeriod];
}
