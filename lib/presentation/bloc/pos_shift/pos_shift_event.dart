import 'package:equatable/equatable.dart';

abstract class PosShiftEvent extends Equatable {
  const PosShiftEvent();

  @override
  List<Object?> get props => [];
}

class LoadShiftData extends PosShiftEvent {
  final String tokoId;
  const LoadShiftData(this.tokoId);

  @override
  List<Object?> get props => [tokoId];
}

class ReloadShiftHistory extends PosShiftEvent {}

class OpenShiftEvent extends PosShiftEvent {
  final String tokoId;
  final double amount;
  final String notes;

  const OpenShiftEvent({
    required this.tokoId,
    required this.amount,
    required this.notes,
  });

  @override
  List<Object?> get props => [tokoId, amount, notes];
}

class CloseShiftEvent extends PosShiftEvent {
  final String shiftId;
  final double actualCash;
  final String notes;
  final String tokoId; // needed to reload active shift after close

  const CloseShiftEvent({
    required this.shiftId,
    required this.actualCash,
    required this.notes,
    required this.tokoId,
  });

  @override
  List<Object?> get props => [shiftId, actualCash, notes, tokoId];
}

class AddPettyCashEvent extends PosShiftEvent {
  final String shiftId;
  final String type; // 'in' or 'out'
  final double amount;
  final String notes;
  final String tokoId;

  const AddPettyCashEvent({
    required this.shiftId,
    required this.type,
    required this.amount,
    required this.notes,
    required this.tokoId,
  });

  @override
  List<Object?> get props => [shiftId, type, amount, notes, tokoId];
}
