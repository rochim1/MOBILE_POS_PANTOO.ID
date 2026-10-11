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
      isRetryableOfflineNetworkFailure(
        OperationException(
          linkException: const ServerException(originalException: 'offline'),
        ),
      ),
      isTrue,
    );
    expect(
      isRetryableOfflineNetworkFailure(
        OperationException(
          graphqlErrors: const [GraphQLError(message: 'Stok habis')],
        ),
      ),
      isFalse,
    );
  });

  test('read snapshots are not used for GraphQL business errors', () {
    expect(
      isOfflineReadFailure(
        OperationException(
          linkException: const ServerException(originalException: 'offline'),
        ),
      ),
      isTrue,
    );
    expect(
      isOfflineReadFailure(
        OperationException(
          graphqlErrors: const [
            GraphQLError(
              message: 'Tidak berhak',
              extensions: {'code': 'FORBIDDEN'},
            ),
          ],
        ),
      ),
      isFalse,
    );
  });

  test('offline shift snapshot expires and rejects clock rollback', () {
    final now = DateTime.utc(2026, 10, 11, 12);
    expect(
      isOfflineShiftSnapshotUsable(
        now.subtract(const Duration(hours: 7)),
        now: now,
      ),
      isTrue,
    );
    expect(
      isOfflineShiftSnapshotUsable(
        now.subtract(const Duration(hours: 9)),
        now: now,
      ),
      isFalse,
    );
    expect(
      isOfflineShiftSnapshotUsable(
        now.add(const Duration(minutes: 1)),
        now: now,
      ),
      isFalse,
    );
  });
}
