import 'package:equatable/equatable.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_settings.dart';
import '../../../domain/models/pos_remote_profile_catalog.dart';

enum PosSettingsStatus { initial, loading, loaded, saving, saved, failure }

class PosSettingsState extends Equatable {
  final PosSettingsStatus status;
  final String errorMessage;
  final String successMessage;
  final PosSettings? settings;
  final PosRemoteProfileCatalog? profileCatalog;

  const PosSettingsState({
    this.status = PosSettingsStatus.initial,
    this.errorMessage = '',
    this.successMessage = '',
    this.settings,
    this.profileCatalog,
  });

  PosSettingsState copyWith({
    PosSettingsStatus? status,
    String? errorMessage,
    String? successMessage,
    PosSettings? settings,
    PosRemoteProfileCatalog? profileCatalog,
  }) {
    return PosSettingsState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      settings: settings ?? this.settings,
      profileCatalog: profileCatalog ?? this.profileCatalog,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    successMessage,
    settings,
    profileCatalog,
  ];
}
