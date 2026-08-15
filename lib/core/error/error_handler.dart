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
        return const NetworkFailure();
      }
      return const ServerFailure('Terjadi kesalahan pada server (GraphQL)');
    }

    return UnknownFailure(error.toString());
  }
}
