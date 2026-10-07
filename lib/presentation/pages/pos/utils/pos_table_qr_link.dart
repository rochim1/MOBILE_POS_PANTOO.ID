class PosTableQrLink {
  const PosTableQrLink._();

  static const configuredBaseUrl = String.fromEnvironment(
    'WEB_ORDER_BASE_URL',
    defaultValue: 'https://order.pantoo.id',
  );

  static Uri? parseBaseUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || uri.host.isEmpty || uri.hasQuery || uri.hasFragment) {
      return null;
    }
    if (uri.scheme != 'https' ||
        uri.host == 'localhost' ||
        uri.host == '127.0.0.1') {
      return null;
    }
    return uri;
  }

  static Uri? forTable({
    required String baseUrl,
    required String instansiId,
    required String storeId,
    required String tableId,
  }) {
    final base = parseBaseUrl(baseUrl);
    final ids = [instansiId, storeId, tableId];
    if (base == null || ids.any((id) => !_isMongoId(id))) return null;
    return base.replace(
      pathSegments: [
        ...base.pathSegments.where((segment) => segment.isNotEmpty),
        ...ids,
      ],
    );
  }

  static bool _isMongoId(String value) =>
      RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(value);
}
