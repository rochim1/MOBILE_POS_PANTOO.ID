import 'package:graphql_flutter/graphql_flutter.dart';

import '../utils/logger.dart';
import 'failures.dart';

class AppErrorHandler {
  static Failure handle(dynamic error) {
    if (error is OperationException) {
      final rawError = error.toString().toLowerCase();
      if (rawError.contains('unauthorized') ||
          rawError.contains('unauthenticated') ||
          rawError.contains('token kadaluarsa') ||
          rawError.contains('token expired') ||
          rawError.contains('bearer token invalid') ||
          rawError.contains('sesi pengguna atau instansi tidak valid')) {
        return const AuthFailure('Sesi telah berakhir. Silakan login kembali.');
      }
      final responseErrors = error.linkException is ServerException
          ? (error.linkException as ServerException).parsedResponse?.errors
          : null;
      final graphQLError = error.graphqlErrors.isNotEmpty
          ? error.graphqlErrors.first
          : (responseErrors?.isNotEmpty == true ? responseErrors!.first : null);

      if (graphQLError != null) {
        final message = graphQLError.message;
        if (message.toLowerCase().contains('unauthenticated') ||
            message.toLowerCase().contains('token') ||
            message.toLowerCase().contains('auth')) {
          return AuthFailure(message);
        }
        return ServerFailure(message);
      }

      if (error.linkException != null) {
        final linkException = error.linkException!;
        final detail = linkException.toString().toLowerCase();
        final isNetworkFailure =
            detail.contains('socketexception') ||
            detail.contains('failed host lookup') ||
            detail.contains('network is unreachable') ||
            detail.contains('connection refused') ||
            detail.contains('connection reset') ||
            detail.contains('xmlhttprequest error');
        if (isNetworkFailure) return const NetworkFailure();

        if (linkException is HttpLinkParserException) {
          final response = linkException.response;
          appLogger.e(
            '[GraphQL] Respons tidak dapat diurai '
            '(HTTP ${response.statusCode}, '
            'content-type: ${response.headers['content-type'] ?? '-'})',
            error: linkException.originalException,
            stackTrace: linkException.originalStackTrace,
          );
          if (response.statusCode == 401 || response.statusCode == 403) {
            return const AuthFailure(
              'Sesi telah berakhir. Silakan login kembali.',
            );
          }
          return ServerFailure(
            'Format respons API tidak valid (HTTP ${response.statusCode}). '
            'Silakan coba lagi atau hubungi admin.',
          );
        }

        if (linkException is ServerException) {
          final statusCode = linkException.statusCode;
          appLogger.e(
            '[GraphQL] Request gagal tanpa pesan GraphQL'
            '${statusCode == null ? '' : ' (HTTP $statusCode)'}',
            error: linkException.originalException ?? linkException,
            stackTrace: linkException.originalStackTrace,
          );
          if (statusCode == 401 || statusCode == 403) {
            return const AuthFailure(
              'Sesi telah berakhir. Silakan login kembali.',
            );
          }
          if (statusCode == 421) {
            return const ServerFailure(
              'Operasi belum tersedia pada versi API yang sedang aktif.',
            );
          }
          if (statusCode != null && statusCode >= 500) {
            return ServerFailure(
              'Server sedang bermasalah (HTTP $statusCode). Silakan coba lagi.',
            );
          }
          if (statusCode != null) {
            return ServerFailure(
              'Request API gagal (HTTP $statusCode) tanpa pesan kesalahan.',
            );
          }
        }

        appLogger.e(
          '[GraphQL] Link gagal tanpa detail respons',
          error: linkException.originalException ?? linkException,
          stackTrace: linkException.originalStackTrace,
        );
        return const ServerFailure(
          'Koneksi ke API terputus sebelum respons lengkap diterima.',
        );
      }
      return const ServerFailure('Terjadi kesalahan pada server (GraphQL)');
    }

    return UnknownFailure(error.toString());
  }
}
