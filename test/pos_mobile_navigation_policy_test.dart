import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_mobile_navigation_policy.dart';

void main() {
  test('Back dari halaman sekunder kembali ke asal', () {
    expect(mobilePosBackDestination(5, 4), 4); // Lainnya → Pesanan
    expect(mobilePosBackDestination(5, 1), 1); // Kasir → Pesanan
    expect(mobilePosBackDestination(7, 0), 0); // Beranda → Inventori
  });

  test('Back dari tab utama kembali ke beranda lalu keluar', () {
    expect(mobilePosBackDestination(4, 4), 0);
    expect(mobilePosBackDestination(1, 4), 0);
    expect(mobilePosBackDestination(0, 4), isNull);
  });

  test('asal halaman sekunder yang tidak valid jatuh ke Lainnya', () {
    expect(mobilePosBackDestination(18, -1), 4);
    expect(mobilePosBackDestination(18, 9), 4);
  });
}
