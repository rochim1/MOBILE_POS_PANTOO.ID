import 'package:graphql_flutter/graphql_flutter.dart';
import 'failures.dart';

class AppErrorHandler {
  static Failure handle(dynamic error) {
    if (error is OperationException) {
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
        final detail = error.linkException.toString().toLowerCase();
        final isNetworkFailure =
            detail.contains('socketexception') ||
            detail.contains('failed host lookup') ||
            detail.contains('network is unreachable') ||
            detail.contains('connection refused') ||
            detail.contains('connection reset') ||
            detail.contains('xmlhttprequest error');
        if (isNetworkFailure) return const NetworkFailure();
        return const ServerFailure(
          'Respons server tidak dapat diproses. Silakan coba kembali.',
        );
      }
      return const ServerFailure('Terjadi kesalahan pada server (GraphQL)');
    }

    return UnknownFailure(error.toString());
  }
}
