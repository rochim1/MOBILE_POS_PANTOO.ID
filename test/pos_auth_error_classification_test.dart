import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';

void main() {
  final now = DateTime.utc(2026, 11, 1, 8);

  test('deleted terminal account requires a fresh login', () {
    expect(
      GraphQLClientProvider.shouldRefreshForAuthError(
        'Pengguna tidak ditemukan atau status tidak aktif',
        'UNAUTHORIZED',
        tokenActivatedAt: now.subtract(const Duration(minutes: 1)),
        now: now,
      ),
      isTrue,
    );
  });

  test('missing selected cashier does not revoke a valid terminal login', () {
    expect(
      GraphQLClientProvider.shouldRefreshForAuthError(
        'Pengguna tidak ditemukan pada instansi ini',
        'NOT_FOUND',
        tokenActivatedAt: now.subtract(const Duration(minutes: 1)),
        now: now,
      ),
      isFalse,
    );
  });

  test('late response from previous session cannot log out a new login', () {
    expect(
      GraphQLClientProvider.shouldRefreshForAuthError(
        'Pengguna tidak ditemukan atau status tidak aktif',
        'UNAUTHORIZED',
        tokenActivatedAt: now.subtract(const Duration(seconds: 1)),
        now: now,
      ),
      isFalse,
    );
  });
}
