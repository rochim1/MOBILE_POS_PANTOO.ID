import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_shift_time.dart';

void main() {
  test('UTC/offset/epoch shift times identify the same local instant', () {
    final expected = DateTime.utc(2026, 11, 2, 11, 23).toLocal();
    for (final value in [
      '2026-11-02T11:23:00.000Z',
      '2026-11-02T18:23:00+07:00',
      expected.millisecondsSinceEpoch.toString(),
      (expected.millisecondsSinceEpoch ~/ 1000).toString(),
    ]) {
      final result = posShiftLocalTime(value);
      expect(result, expected);
      expect(result!.isUtc, isFalse);
    }
  });
  test('null/empty/invalid and already local shift times are safe', () {
    for (final value in [null, '', '   ', 'bad']) {
      expect(posShiftLocalTime(value), isNull);
    }
    expect(
      posShiftLocalTime('2026-11-02T18:23:00'),
      DateTime(2026, 11, 2, 18, 23),
    );
  });
}
