import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_reservation_time.dart';

void main() {
  test(
    'schedule payloads include an explicit UTC zone for servers in another timezone',
    () {
      final page = File(
        'lib/presentation/pages/pos/pos_payment_page.dart',
      ).readAsStringSync().replaceAll(RegExp(r'\s+'), '');
      final repository = File(
        'lib/domain/repositories/pos_repository.dart',
      ).readAsStringSync().replaceAll(RegExp(r'\s+'), '');
      expect(page, contains('appointmentAt!.toUtc().toIso8601String()'));
      expect(page, contains('start!.toUtc().toIso8601String()'));
      expect(
        repository,
        contains('reservationStartAt.toUtc().toIso8601String()'),
      );
      expect(
        repository,
        contains('reservationEndAt.toUtc().toIso8601String()'),
      );
      final picked = DateTime.parse('2026-11-03T14:15:00+07:00');
      expect(picked.toUtc().toIso8601String(), '2026-11-03T07:15:00.000Z');
    },
  );
  test(
    'ISO and legacy epoch schedules keep the same instant in local time',
    () {
      final utc = DateTime.utc(2026, 11, 2, 12, 30);
      final iso = posReservationLocalTime(utc.toIso8601String());
      final epoch = posReservationLocalTime('${utc.millisecondsSinceEpoch}');
      expect(iso?.isUtc, false);
      expect(epoch?.isUtc, false);
      expect(iso?.millisecondsSinceEpoch, utc.millisecondsSinceEpoch);
      expect(epoch, iso);
      expect(
        formatPosReservationTime(utc.toIso8601String()),
        formatPosReservationTime('${utc.millisecondsSinceEpoch}'),
      );
    },
  );
  test('invalid or missing schedules remain visibly unavailable', () {
    expect(posReservationLocalTime('invalid'), isNull);
    expect(formatPosReservationTime(null), '-');
    expect(formatPosReservationTime(''), '-');
  });
  test('only waiting reservations use reservation actions before seating', () {
    for (final status in [null, 'pending', 'confirmed', 'checked_in']) {
      expect(reservationNeedsSeating('reservation', status), true);
    }
    expect(reservationNeedsSeating('reservation', 'seated'), false);
    expect(reservationNeedsSeating('dine_in', 'pending'), false);
  });
}
