import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mobile_pos_pantoo/core/error/error_handler.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';

void main() {
  test(
    'penolakan inventori eksplisit dapat diperbaiki tanpa retry tak pasti',
    () {
      final failure = AppErrorHandler.handle(
        OperationException(
          graphqlErrors: const [
            GraphQLError(
              message: 'Batch wajib diisi',
              extensions: {
                'code': 'BAD_REQUEST',
                'inventory_request_rejected': true,
              },
            ),
          ],
        ),
      );
      expect(failure, isA<InventoryRequestRejectedFailure>());
      expect(failure.message, 'Batch wajib diisi');
    },
  );

  test('error tanpa konfirmasi rollback tetap perlu rekonsiliasi', () {
    for (final extensions in [
      <String, dynamic>{'code': 'INTERNAL_SERVER_ERROR'},
      <String, dynamic>{'inventory_request_rejected': 'true'},
      <String, dynamic>{
        'code': 'INVENTORY_RECOVERY_REQUIRED',
        'inventory_request_rejected': true,
      },
    ]) {
      final failure = AppErrorHandler.handle(
        OperationException(
          graphqlErrors: [
            GraphQLError(message: 'Operasi gagal', extensions: extensions),
          ],
        ),
      );
      expect(failure, isNot(isA<InventoryRequestRejectedFailure>()));
    }
  });
}
