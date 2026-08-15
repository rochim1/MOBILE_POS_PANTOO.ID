import 'package:equatable/equatable.dart';
import '../../../../domain/models/pos_receipt_template.dart';

enum PosReceiptStatus { initial, loading, loaded, saving, saved, failure }

class PosReceiptState extends Equatable {
  final PosReceiptStatus status;
  final String errorMessage;
  final String successMessage;
  final PosReceiptTemplate? template;

  const PosReceiptState({
    this.status = PosReceiptStatus.initial,
    this.errorMessage = '',
    this.successMessage = '',
    this.template,
  });

  PosReceiptState copyWith({
    PosReceiptStatus? status,
    String? errorMessage,
    String? successMessage,
    PosReceiptTemplate? template,
  }) {
    return PosReceiptState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      template: template ?? this.template,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, successMessage, template];
}
