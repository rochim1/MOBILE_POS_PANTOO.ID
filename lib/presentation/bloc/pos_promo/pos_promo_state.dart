import 'package:equatable/equatable.dart';
import '../../../domain/models/pos_promo.dart';

enum PosPromoStatus { initial, loading, success, failure, actionSuccess }

class PosPromoState extends Equatable {
  final PosPromoStatus status;
  final String errorMessage;
  final List<PosPromo> promos;
  final String successMessage;

  const PosPromoState({
    this.status = PosPromoStatus.initial,
    this.errorMessage = '',
    this.promos = const [],
    this.successMessage = '',
  });

  PosPromoState copyWith({
    PosPromoStatus? status,
    String? errorMessage,
    List<PosPromo>? promos,
    String? successMessage,
  }) {
    return PosPromoState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      promos: promos ?? this.promos,
      successMessage: successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, promos, successMessage];
}
