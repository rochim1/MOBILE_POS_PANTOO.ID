class LocalCustomerDisplayHost {
  Future<String> start(
    String token, {
    required void Function(int) onClientCountChanged,
    String? advertisedHost,
  }) async => throw UnsupportedError(
    'Layar pelanggan melalui Wi-Fi lokal hanya tersedia di aplikasi Android.',
  );

  void publish(Map<String, dynamic> data) {}

  Future<void> stop() async {}
}
