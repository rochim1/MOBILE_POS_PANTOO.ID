import 'package:flutter/widgets.dart';

String travelText(BuildContext context, String id, String en) =>
    Localizations.localeOf(context).languageCode == 'en' ? en : id;

String travelCategory(BuildContext context, dynamic value) => switch (value) {
  'adult' => travelText(context, 'Dewasa', 'Adult'),
  'child' => travelText(context, 'Anak', 'Child'),
  'infant' => travelText(context, 'Bayi', 'Infant'),
  _ => '$value',
};

String travelMethod(BuildContext context, dynamic value) => switch (value) {
  'tunai' => travelText(context, 'Tunai', 'Cash'),
  'transfer' => travelText(context, 'Transfer manual', 'Manual bank transfer'),
  _ => '$value',
};

String travelStatus(BuildContext context, dynamic value) {
  const labels = {
    'draft': ('Draf', 'Draft'),
    'held': ('Kuota ditahan', 'Seats held'),
    'confirmed': ('Terkonfirmasi', 'Confirmed'),
    'completed': ('Perjalanan selesai', 'Trip completed'),
    'cancelled': ('Dibatalkan', 'Cancelled'),
    'expired': ('Kuota kedaluwarsa', 'Hold expired'),
    'unpaid': ('Belum dibayar', 'Unpaid'),
    'partial': ('DP / Sebagian', 'Deposit / Partial'),
    'paid': ('Lunas', 'Paid'),
    'refunded': ('Dana dikembalikan', 'Refunded'),
  };
  final label = labels[value];
  return label == null ? '$value' : travelText(context, label.$1, label.$2);
}

String travelError(Object e) => e is StateError ? e.message : '$e';

String travelDate(dynamic value) {
  final parsed = DateTime.tryParse('$value')?.toLocal();
  if (parsed == null) return '—';
  String two(int n) => '$n'.padLeft(2, '0');
  return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year} ${two(parsed.hour)}:${two(parsed.minute)}';
}
