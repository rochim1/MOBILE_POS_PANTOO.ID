import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mobile_pos_pantoo/core/network/sync_service.dart';

void main() {
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
}
