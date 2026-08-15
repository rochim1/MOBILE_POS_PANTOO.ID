import 'package:equatable/equatable.dart';

abstract class PosProductManagementEvent extends Equatable {
  const PosProductManagementEvent();

  @override
  List<Object?> get props => [];
}

class CreateProduct extends PosProductManagementEvent {
  final Map<String, dynamic> input;
  const CreateProduct(this.input);

  @override
  List<Object> get props => [input];
}

class UpdateProduct extends PosProductManagementEvent {
  final String id;
  final Map<String, dynamic> input;
  const UpdateProduct(this.id, this.input);

  @override
  List<Object> get props => [id, input];
}

class DeleteProduct extends PosProductManagementEvent {
  final String id;
  const DeleteProduct(this.id);

  @override
  List<Object> get props => [id];
}
