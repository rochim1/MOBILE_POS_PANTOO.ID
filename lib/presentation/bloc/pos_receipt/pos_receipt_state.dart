import 'package:equatable/equatable.dart';
import '../../../../domain/models/pos_receipt_template.dart';

enum PosReceiptStatus { initial, loading, loaded, saving, saved, failure }

class PosReceiptState extends Equatable {
  final PosReceiptStatus status;
  final String errorMessage;
  final String successMessage;
  final PosReceiptTemplate? template;
  final Map<String, String> company;

  const PosReceiptState({
    this.status = PosReceiptStatus.initial,
    this.errorMessage = '',
    this.successMessage = '',
    this.template,
    this.company = const {},
  });

  PosReceiptState copyWith({
    PosReceiptStatus? status,
    String? errorMessage,
    String? successMessage,
    PosReceiptTemplate? template,
    Map<String, String>? company,
  }) {
    return PosReceiptState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      template: template ?? this.template,
      company: company ?? this.company,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    successMessage,
    template,
    company,
  ];
}
