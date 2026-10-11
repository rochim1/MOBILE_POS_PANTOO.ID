import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_customer_form_validation.dart';

void main() {
  test('nama pelanggan wajib dan mengikuti batas backend', () {
    expect(validatePosCustomerName('  '), isNotNull);
    expect(validatePosCustomerName('Budi Santoso'), isNull);
    expect(validatePosCustomerName(List.filled(201, 'a').join()), isNotNull);
  });

  test('telepon opsional tetapi nomor yang diisi harus valid', () {
    expect(validatePosCustomerPhone(''), isNull);
    expect(validatePosCustomerPhone('', required: true), isNotNull);
    expect(validatePosCustomerPhone('0812 3456 7890'), isNull);
    expect(validatePosCustomerPhone('+62-812-3456-7890'), isNull);
    expect(validatePosCustomerPhone('abc12345678'), isNotNull);
    expect(validatePosCustomerPhone('1234'), isNotNull);
    expect(validatePosCustomerPhone('00000000'), isNotNull);
  });

  test('email opsional dan alamat salah ditolak', () {
    expect(validatePosCustomerEmail(''), isNull);
    expect(validatePosCustomerEmail('nama@email.com'), isNull);
    expect(validatePosCustomerEmail('nama@'), isNotNull);
  });
}
