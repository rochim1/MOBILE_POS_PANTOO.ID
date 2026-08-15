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

class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Gagal menyimpan atau mengambil data lokal',
  ]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Terjadi kesalahan tidak terduga']);
}
