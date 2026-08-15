import 'package:equatable/equatable.dart';

abstract class PosReportEvent extends Equatable {
  const PosReportEvent();

  @override
  List<Object?> get props => [];
}

class LoadReport extends PosReportEvent {
  final int days;
  final String periodLabel;

  const LoadReport({this.days = 7, this.periodLabel = 'Minggu Ini'});

  @override
  List<Object?> get props => [days, periodLabel];
}
