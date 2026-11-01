import 'package:equatable/equatable.dart';

const _unchangedSearchResult = Object();

enum PosReturnStatus { initial, loading, success, failure }

class PosReturnState extends Equatable {
  final PosReturnStatus status;
  final String errorMessage;
  final List<Map<String, dynamic>> returns;
  final Map<String, dynamic>? searchResult;
  final List<Map<String, dynamic>> returnItems;

  const PosReturnState({
    this.status = PosReturnStatus.initial,
    this.errorMessage = '',
    this.returns = const [],
    this.searchResult,
    this.returnItems = const [],
  });

  PosReturnState copyWith({
    PosReturnStatus? status,
    String? errorMessage,
    List<Map<String, dynamic>>? returns,
    Object? searchResult = _unchangedSearchResult,
    List<Map<String, dynamic>>? returnItems,
  }) {
    return PosReturnState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      returns: returns ?? this.returns,
      searchResult: identical(searchResult, _unchangedSearchResult)
          ? this.searchResult
          : searchResult as Map<String, dynamic>?,
      returnItems: returnItems ?? this.returnItems,
    );
  }

  @override
  List<Object?> get props => [
    status,
    errorMessage,
    returns,
    searchResult,
    returnItems,
  ];
}
