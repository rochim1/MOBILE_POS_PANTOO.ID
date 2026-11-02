import 'package:intl/intl.dart';

DateTime? posReservationLocalTime(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final raw = value.trim();
  if (RegExp(r'^\d{11,14}$').hasMatch(raw)) {
    return DateTime.fromMillisecondsSinceEpoch(
      int.parse(raw),
      isUtc: true,
    ).toLocal();
  }
  return DateTime.tryParse(raw)?.toLocal();
}

String formatPosReservationTime(String? value) {
  final date = posReservationLocalTime(value);
  return date == null ? '-' : DateFormat('dd MMM yyyy, HH:mm').format(date);
}

bool reservationNeedsSeating(String? type, String? status) =>
    type == 'reservation' &&
    const ['pending', 'confirmed', 'checked_in'].contains(status ?? 'pending');
