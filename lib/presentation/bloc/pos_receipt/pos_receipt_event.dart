import 'package:equatable/equatable.dart';

abstract class PosReceiptEvent extends Equatable {
  const PosReceiptEvent();

  @override
  List<Object?> get props => [];
}

class LoadReceiptTemplate extends PosReceiptEvent {}

class UpdateReceiptTemplate extends PosReceiptEvent {
  final Map<String, dynamic> input;

  const UpdateReceiptTemplate(this.input);

  @override
  List<Object?> get props => [input];
}
