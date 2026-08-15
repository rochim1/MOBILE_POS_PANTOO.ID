import 'package:equatable/equatable.dart';

abstract class PosSettingsEvent extends Equatable {
  const PosSettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends PosSettingsEvent {
  const LoadSettings();
}

class UpdateSettings extends PosSettingsEvent {
  final Map<String, dynamic> input;

  const UpdateSettings({required this.input});

  @override
  List<Object?> get props => [input];
}
