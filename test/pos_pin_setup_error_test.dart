import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mobile_pos_pantoo/core/error/error_handler.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';

void main() {
  test('duplicated GraphQL and parsed HTTP password errors remain retryable', () {
    final error = GraphQLError(message: 'Password akun tidak valid', extensions: {'code': 'UNAUTHORIZED'});
    final exception = OperationException(
      graphqlErrors: [error],
      linkException: ServerException(statusCode: 401, parsedResponse: Response(errors: [error], response: {})),
    );
    expect(AppErrorHandler.handle(exception), isA<ServerFailure>());
  });
  for (final code in ['INVALID_PASSWORD', 'UNAUTHORIZED']) {
    for (final httpError in [false, true]) {
      test(
        'PIN password rejection $code via ${httpError ? 'HTTP' : 'GraphQL'} is not session expiry',
        () {
          final error = GraphQLError(
            message: 'Password akun tidak valid',
            extensions: {'code': code},
          );
          final exception = httpError
              ? OperationException(
                  linkException: ServerException(
                    statusCode: code == 'UNAUTHORIZED' ? 401 : 400,
                    parsedResponse: Response(errors: [error], response: {}),
                  ),
                )
              : OperationException(graphqlErrors: [error]);
          final failure = AppErrorHandler.handle(exception);
          expect(failure, isA<ServerFailure>());
          expect(failure, isNot(isA<AuthFailure>()));
          expect(failure.message, 'Password akun tidak valid');
          expect(
            GraphQLClientProvider.shouldRefreshForAuthError(
              error.message,
              code,
            ),
            isFalse,
          );
        },
      );
    }
  }
  test(
    'an expired session must not be hidden by a simultaneous password rejection',
    () {
      final exception = OperationException(
        graphqlErrors: [
          GraphQLError(
            message: 'Password akun tidak valid',
            extensions: {'code': 'UNAUTHORIZED'},
          ),
          GraphQLError(
            message: 'Token expired',
            extensions: {'code': 'UNAUTHENTICATED'},
          ),
        ],
      );
      expect(AppErrorHandler.handle(exception), isA<AuthFailure>());
    },
  );
  test('real unauthorized or invalid tenant responses still require login', () {
    for (final error in [
      GraphQLError(
        message: 'Sesi pengguna atau instansi tidak valid',
        extensions: {'code': 'UNAUTHORIZED'},
      ),
      GraphQLError(
        message: 'Password akun tidak valid',
        extensions: {'code': 'UNAUTHENTICATED'},
      ),
    ]) {
      expect(
        AppErrorHandler.handle(OperationException(graphqlErrors: [error])),
        isA<AuthFailure>(),
      );
    }
  });
}
