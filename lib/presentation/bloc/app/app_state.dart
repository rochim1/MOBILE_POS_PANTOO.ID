import 'package:equatable/equatable.dart';

enum AppStatus { initial, loading, loaded, error }

class AppState extends Equatable {
  final AppStatus status;

  const AppState._(this.status);
  const AppState.initial() : this._(AppStatus.initial);
  const AppState.loading() : this._(AppStatus.loading);
  const AppState.loaded() : this._(AppStatus.loaded);
  const AppState.error() : this._(AppStatus.error);

  @override
  List<Object> get props => [status];
}
