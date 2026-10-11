String? validatePosCustomerName(String? value) {
  final name = (value ?? '').trim();
  if (name.isEmpty) return 'Nama pelanggan wajib diisi';
  if (name.length > 200) return 'Nama maksimal 200 karakter';
  return null;
}

String? validatePosCustomerPhone(String? value, {bool required = false}) {
  final phone = (value ?? '').trim();
  if (phone.isEmpty) {
    return required ? 'Nomor telepon wajib diisi' : null;
  }
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (!RegExp(r'^\+?[\d\s().-]+$').hasMatch(phone) ||
      digits.length < 8 ||
      digits.length > 15 ||
      RegExp(r'^0+$').hasMatch(digits)) {
    return 'Gunakan nomor telepon valid (8–15 digit)';
  }
  return null;
}

String? validatePosCustomerEmail(String? value) {
  final email = (value ?? '').trim();
  if (email.isEmpty) return null;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
      ? null
      : 'Format email tidak valid';
}
