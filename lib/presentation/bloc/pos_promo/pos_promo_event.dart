import 'package:equatable/equatable.dart';

abstract class PosPromoEvent extends Equatable {
  const PosPromoEvent();
  @override
  List<Object?> get props => [];
}

class LoadPromos extends PosPromoEvent {
  final String? search;
  final bool? isActive;
  const LoadPromos({this.search, this.isActive});
  @override
  List<Object?> get props => [search, isActive];
}

class CreatePromo extends PosPromoEvent {
  final Map<String, dynamic> input;
  const CreatePromo(this.input);
  @override
  List<Object?> get props => [input];
}

class UpdatePromo extends PosPromoEvent {
  final String id;
  final Map<String, dynamic> input;
  const UpdatePromo(this.id, this.input);
  @override
  List<Object?> get props => [id, input];
}

class DeletePromo extends PosPromoEvent {
  final String id;
  const DeletePromo(this.id);
  @override
  List<Object?> get props => [id];
}

class TogglePromoStatus extends PosPromoEvent {
  final String id;
  const TogglePromoStatus(this.id);
  @override
  List<Object?> get props => [id];
}
