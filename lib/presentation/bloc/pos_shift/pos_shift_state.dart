import 'package:equatable/equatable.dart';

abstract class PosShiftState extends Equatable {
  const PosShiftState();

  @override
  List<Object?> get props => [];
}

class PosShiftInitial extends PosShiftState {}

class PosShiftLoading extends PosShiftState {}

class PosShiftLoaded extends PosShiftState {
  final Map<String, dynamic>? activeShift;
  final List<Map<String, dynamic>> shiftHistory;
  final bool isLoadingHistory;

  const PosShiftLoaded({
    this.activeShift,
    this.shiftHistory = const [],
    this.isLoadingHistory = false,
  });

  PosShiftLoaded copyWith({
    Map<String, dynamic>? activeShift,
    List<Map<String, dynamic>>? shiftHistory,
    bool? isLoadingHistory,
  }) {
    return PosShiftLoaded(
      activeShift: activeShift ?? this.activeShift,
      shiftHistory: shiftHistory ?? this.shiftHistory,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    );
  }

  @override
  List<Object?> get props => [activeShift, shiftHistory, isLoadingHistory];
}

class PosShiftActionSuccess extends PosShiftState {
  final String message;
  const PosShiftActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class PosShiftError extends PosShiftState {
  final String message;
  const PosShiftError(this.message);

  @override
  List<Object?> get props => [message];
}
