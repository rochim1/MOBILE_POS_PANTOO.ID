import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mobile_pos_pantoo/core/network/pos_bootstrap_reads.dart';

void main() {
  test(
    'deadline closes a stalled startup stream once and cancels its subscription',
    () async {
      var cancelled = false;
      final source = StreamController<Response>(
        onCancel: () => cancelled = true,
      );
      final link = posBootstrapReadDeadlineLink(
        timeout: const Duration(milliseconds: 20),
      ).concat(Link.function((request, [forward]) => source.stream));
      await expectLater(
        link.request(
          Request(
            operation: Operation(
              document: gql(
                'query GetPOSPinUsers { GetPOSPinUsers { items { _id } } }',
              ),
            ),
          ),
        ),
        emitsInOrder([emitsError(isA<TimeoutException>()), emitsDone]),
      );
      expect(cancelled, true);
      await source.close();
    },
  );
  test(
    'deadline never applies to a financial mutation even with a bootstrap-like name',
    () async {
      final link =
          posBootstrapReadDeadlineLink(
            timeout: const Duration(milliseconds: 1),
          ).concat(
            Link.function((request, [forward]) async* {
              await Future<void>.delayed(const Duration(milliseconds: 10));
              yield Response(data: const {'ok': true}, response: {});
            }),
          );
      final result = await link
          .request(
            Request(
              operation: Operation(
                document: gql('mutation GetPOSPinUsers { Pay }'),
              ),
            ),
          )
          .single;
      expect(result.data, {'ok': true});
    },
  );
  test('single-flight is scoped and removes settled or failed reads', () async {
    final reads = PosBootstrapReads();
    var calls = 0;
    final pending = Completer<int>();
    Future<int> read() {
      calls++;
      return pending.future;
    }

    final a = reads.run('tenant:a', read);
    final b = reads.run('tenant:a', read);
    final c = reads.run('tenant:b', read);
    pending.complete(1);
    expect(await Future.wait([a, b, c]), [1, 1, 1]);
    expect(calls, 2);
    await reads.run('tenant:a', read);
    expect(calls, 3);
    await expectLater(
      reads.run<int>('bad', () => throw StateError('QA')),
      throwsStateError,
    );
    expect(await reads.run('bad', () async => 2), 2);
  });
}
