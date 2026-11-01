import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_return/pos_return_state.dart';

void main() {
  test('copyWith can clear searched invoice after return is saved', () {
    const initial = PosReturnState(searchResult: {'invoice': 'PANTOO-QA'});

    expect(initial.copyWith(status: PosReturnStatus.loading).searchResult,
        isNotNull);
    expect(initial.copyWith(searchResult: null).searchResult, isNull);
  });
}
