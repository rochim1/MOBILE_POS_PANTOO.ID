class PosPurchaseProgress {
  const PosPurchaseProgress._();

  static double _number(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static double orderedBase(Map<dynamic, dynamic> item) {
    final explicit = item['qty_ordered_base'];
    if (explicit != null) return _number(explicit);
    return _number(item['qty_ordered']) *
        (_number(item['conversion_factor']) <= 0
            ? 1
            : _number(item['conversion_factor']));
  }

  static double receivedBase(Map<dynamic, dynamic> item) {
    final explicit = item['qty_received_base'];
    if (explicit != null) return _number(explicit);
    return _number(item['qty_received']) *
        (_number(item['conversion_factor']) <= 0
            ? 1
            : _number(item['conversion_factor']));
  }

  static double remainingInOrderedUnit(Map<dynamic, dynamic> item) {
    final factor = _number(item['conversion_factor']) <= 0
        ? 1
        : _number(item['conversion_factor']);
    return ((orderedBase(item) - receivedBase(item)) / factor).clamp(
      0,
      double.infinity,
    );
  }

  static bool hasRemaining(Map<dynamic, dynamic> purchase) =>
      (purchase['items'] as List? ?? const []).whereType<Map>().any(
        (item) => orderedBase(item) - receivedBase(item) > .000001,
      );

  static String effectiveStatus(Map<dynamic, dynamic> purchase) {
    final raw = purchase['status']?.toString() ?? '';
    if (raw == 'completed' && hasRemaining(purchase)) {
      return 'partially_received';
    }
    return raw;
  }

  static double completionRatio(Map<dynamic, dynamic> purchase) {
    final items = (purchase['items'] as List? ?? const [])
        .whereType<Map>()
        .where((item) => orderedBase(item) > 0)
        .toList();
    if (items.isEmpty) return 0;
    final sum = items.fold<double>(0, (value, item) {
      return value +
          (receivedBase(item) / orderedBase(item)).clamp(0, 1).toDouble();
    });
    return sum / items.length;
  }
}
