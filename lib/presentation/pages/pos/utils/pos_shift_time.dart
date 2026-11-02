/// GraphQL can expose ISO strings or legacy epoch strings for the same instant.
DateTime? posShiftLocalTime(Object? value) {
  final raw = value?.toString().trim() ?? '';
  if (raw.isEmpty) return null;
  if (RegExp(r'^\d{10,14}$').hasMatch(raw)) {
    final epoch = int.parse(raw);
    return DateTime.fromMillisecondsSinceEpoch(
      raw.length <= 10 ? epoch * 1000 : epoch,
      isUtc: true,
    ).toLocal();
  }
  return DateTime.tryParse(raw)?.toLocal();
}
