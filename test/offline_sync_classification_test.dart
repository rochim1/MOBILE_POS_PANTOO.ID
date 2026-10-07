import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mobile_pos_pantoo/core/network/sync_service.dart';
import 'package:mobile_pos_pantoo/core/network/offline_network_failure.dart';

void main() {
  test('expired operator session needs review, not business rejection', () {
    expect(
      classifyOfflineGraphQLErrors([
        const GraphQLError(
          message: 'Sesi operator tidak valid',
          extensions: {'code': 'UNAUTHORIZED'},
        ),
      ]),
      'needs_review',
    );
  });
  test('konflik bisnis transaksi offline wajib masuk review', () {
    final status = classifyOfflineGraphQLErrors([
      const GraphQLError(
        message: 'Stok berubah sejak transaksi dibuat',
        extensions: {'code': 'CONFLICT'},
      ),
    ]);

    expect(status, 'needs_review');
  });

  test('input atau izin invalid ditandai ditolak', () {
    final status = classifyOfflineGraphQLErrors([
      const GraphQLError(
        message: 'Akses ditolak',
        extensions: {'code': 'FORBIDDEN'},
      ),
    ]);

    expect(status, 'rejected');
  });

  test('server sale with a different cash total always needs review', () {
    expect(
      offlineSaleNeedsReview(
        serverStatus: 'synced',
        expectedTotal: 10000,
        actualTotal: 12000,
      ),
      isTrue,
    );
    expect(
      offlineSaleNeedsReview(
        serverStatus: 'synced',
        expectedTotal: 10000,
        actualTotal: 10000,
      ),
      isFalse,
    );
    expect(offlineSaleNeedsReview(serverStatus: ''), isTrue);
  });

  test('only transport failures may enter the offline queue', () {
    expect(
      isRetryableOfflineNetworkFailure(OperationException(
        linkException: const ServerException(originalException: 'offline'),
      )),
      isTrue,
    );
    expect(
      isRetryableOfflineNetworkFailure(OperationException(
        graphqlErrors: const [GraphQLError(message: 'Stok habis')],
      )),
      isFalse,
    );
  });
}
