import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_offline_error_copy.dart';

void main() {
  test('transport errors show a safe summary rather than stack traces', () {
    for (final detail in [
      'OperationException(linkException: ServerException(originalException: ClientException with SocketException: Connection refused, uri=http://127.0.0.1:18122/graphql, originalStackTrace: #0 IOClient.send)',
      'TimeoutException after 0:00:08.000000: No stream event',
    ]) {
      expect(posOfflineErrorCopy(detail),
          'Tidak ada koneksi internet. Silakan periksa jaringan Anda.');
    }
  });
  test('plain business rejection stays actionable; technical unknowns are hidden', () {
    expect(posOfflineErrorCopy('Shift kasir sudah ditutup'), 'Shift kasir sudah ditutup');
    expect(posOfflineErrorCopy('  '), '');
    expect(posOfflineErrorCopy('FormatException: bad payload at #0 lib/private.dart'),
        'Terjadi kesalahan tidak terduga');
    final page=File('lib/presentation/pages/pos/pos_offline_queue_page.dart').readAsStringSync();
    expect(page, contains("posOfflineErrorCopy(transaction['error'])"));
    expect(page, isNot(contains("PosText(\n                  transaction['error'].toString()")));
  });
}
