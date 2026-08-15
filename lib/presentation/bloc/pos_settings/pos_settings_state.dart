import 'package:equatable/equatable.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_settings.dart';

enum PosSettingsStatus { initial, loading, loaded, saving, saved, failure }

class PosSettingsState extends Equatable {
  final PosSettingsStatus status;
  final String errorMessage;
  final String successMessage;
  final PosSettings? settings;

  const PosSettingsState({
    this.status = PosSettingsStatus.initial,
    this.errorMessage = '',
    this.successMessage = '',
    this.settings,
  });

  PosSettingsState copyWith({
    PosSettingsStatus? status,
    String? errorMessage,
    String? successMessage,
    PosSettings? settings,
  }) {
    return PosSettingsState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, successMessage, settings];
}
