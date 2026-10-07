import 'dart:convert';

import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure([this.message = 'Terjadi kesalahan tidak terduga']);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Terjadi kesalahan pada server']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message =
        'Tidak ada koneksi internet. Silakan periksa jaringan Anda.',
  ]);
}

class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Sesi telah berakhir atau otentikasi gagal',
  ]);
}

class LoginCaptchaFailure extends Failure {
  final String captchaId;
  final String image;

  const LoginCaptchaFailure({
    required this.captchaId,
    required this.image,
    String message = 'Selesaikan CAPTCHA untuk melanjutkan login',
  }) : super(message);

  static LoginCaptchaFailure? fromExtensions(
    Map<String, dynamic>? extensions, {
    String? message,
  }) {
    if (extensions?['code'] != 'CAPTCHA_REQUIRED') return null;
    final challenge = extensions?['captcha'];
    if (challenge is! Map) return null;
    final id = challenge['id'];
    final image = challenge['image'];
    const prefix = 'data:image/png;base64,';
    if (id is! String ||
        !RegExp(r'^[a-f0-9]{36}$').hasMatch(id) ||
        image is! String ||
        !image.startsWith(prefix) ||
        image.length > 256 * 1024) {
      return null;
    }
    try {
      final bytes = base64Decode(image.substring(prefix.length));
      const signature = [137, 80, 78, 71, 13, 10, 26, 10];
      if (bytes.length <= signature.length) return null;
      for (var index = 0; index < signature.length; index++) {
        if (bytes[index] != signature[index]) return null;
      }
    } on FormatException {
      return null;
    }
    return LoginCaptchaFailure(
      captchaId: id,
      image: image,
      message: message ?? 'Selesaikan CAPTCHA untuk melanjutkan login',
    );
  }

  @override
  List<Object?> get props => [message, captchaId, image];
}

class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Gagal menyimpan atau mengambil data lokal',
  ]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Terjadi kesalahan tidak terduga']);
}
