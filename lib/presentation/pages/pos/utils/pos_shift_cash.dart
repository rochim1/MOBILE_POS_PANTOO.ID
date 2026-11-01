/// While a shift is open, the backend stores cash movement separately from
/// opening cash. On close it replaces `closing_cash_expected` with the final
/// expected amount, so adding opening cash again would double count it.
double posShiftExpectedCash(Map<String, dynamic> shift) {
  final movement = _amount(shift['closing_cash_expected']);
  final status = shift['status']?.toString().toLowerCase();
  return status == 'open'
      ? _amount(shift['opening_cash']) + movement
      : movement;
}

double _amount(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
