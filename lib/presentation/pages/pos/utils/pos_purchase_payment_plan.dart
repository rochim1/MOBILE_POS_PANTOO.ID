/// A PO payment schedule is a commercial agreement, never a cash/AP posting.
List<Map<String, dynamic>> purchaseInstallmentSchedule({
  required List<Map<String, dynamic>> saved,
  required int count,
  required double total,
  required DateTime date,
}) {
  if (saved.isNotEmpty) {
    return saved.map((row) => Map<String, dynamic>.from(row)).toList();
  }
  if (count < 2 || count > 12) return [];
  final amount = (total / count).floorToDouble();
  return List.generate(
    count,
    (index) => {
      'no_termin': index + 1,
      'amount': index == count - 1 ? total - amount * (count - 1) : amount,
      'due_date': date
          .add(Duration(days: (index + 1) * 30))
          .toIso8601String()
          .split('T')
          .first,
    },
  );
}

String? validatePurchaseInstallments(
  List<Map<String, dynamic>> rows,
  int count,
  double total,
) {
  if (count < 2 || count > 12 || rows.length != count) {
    return 'Jumlah cicilan harus 2 sampai 12 dan sesuai jadwal';
  }
  var sum = 0.0;
  for (var index = 0; index < rows.length; index++) {
    final row = rows[index];
    final amount = (row['amount'] as num?)?.toDouble() ?? double.nan;
    final dateText = row['due_date']?.toString() ?? '';
    final date = DateTime.tryParse(dateText);
    if (row['no_termin'] != index + 1 ||
        !amount.isFinite ||
        amount <= 0 ||
        date == null ||
        date.toIso8601String().split('T').first != dateText) {
      return 'Isi nominal positif dan tanggal setiap cicilan';
    }
    sum += amount;
  }
  if (!total.isFinite || (sum - total).abs() > 0.01) {
    return 'Total pembayaran cicilan harus sama dengan total PO';
  }
  return null;
}
