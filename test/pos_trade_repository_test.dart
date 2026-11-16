import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_trade_repository.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';

void main() {
  for (final code in ['FORBIDDEN', 'UNAUTHENTICATED', 'BAD_USER_INPUT']) {
    test('HTTP-wrapped $code preserves the financial decision instead of freezing the request', () async {
      final client = GraphQLClient(cache: GraphQLCache(), link: Link.function((request, [forward]) async* {
        throw ServerException(parsedResponse: Response(response: const {}, errors: [
          GraphQLError(message: 'Request rejected by server', extensions: {
            'code': code, if (code == 'BAD_USER_INPUT') 'financial_write_rejected': true,
          }),
        ]));
      }));
      final failure = (await GraphQLPosTradeRepository.withClient(() => client).pay({})).fold((f) => f, (_) => null);
      if (code == 'FORBIDDEN') {
        expect(failure, isA<PosTradeAccessFailure>());
      } else if (code == 'UNAUTHENTICATED') {
        expect(failure, isA<AuthFailure>());
      } else {
        expect(failure, isA<PosTradeRejectedFailure>());
      }
    });
  }
  test(
    'uncertain financial mutations are never retried automatically',
    () async {
      var calls = 0;
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          calls++;
          throw StateError('lost connection');
        }),
      );
      final repo = GraphQLPosTradeRepository.withClient(() => client);
      final result = await repo.pay({'request_id': 'unchanged'});
      expect(
        result.fold((f) => f, (_) => null),
        isA<PosTradeUnconfirmedFailure>(),
      );
      expect(calls, 1);
    },
  );
  test(
    'only explicit rollback rejection allows a financial request to be replaced',
    () async {
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          yield Response(
            response: const {},
            errors: [
              GraphQLError(
                message: 'Invalid amount',
                extensions: {
                  'code': 'BAD_USER_INPUT',
                  'financial_write_rejected': true,
                },
              ),
            ],
          );
        }),
      );
      final result = await GraphQLPosTradeRepository.withClient(
        () => client,
      ).create({});
      expect(
        result.fold((f) => f, (_) => null),
        isA<PosTradeRejectedFailure>(),
      );
    },
  );
  test('tenant change during request invalidates the response', () async {
    var tenant = 'a';
    final gate = Completer<Response>();
    final client = GraphQLClient(
      cache: GraphQLCache(),
      link: Link.function((request, [forward]) async* {
        yield await gate.future;
      }),
    );
    final repo = GraphQLPosTradeRepository.withClient(
      () => client,
      tenant: () => tenant,
    );
    final future = repo.options();
    await Future<void>.delayed(Duration.zero);
    tenant = 'b';
    gate.complete(
      Response(
        response: const {},
        data: {
          'GetPOSTradeOptions': {'instansi_id': 'a'},
        },
      ),
    );
    expect((await future).fold((f) => f, (_) => null), isA<AuthFailure>());
  });
  test('cross-tenant document cannot acknowledge a write', () async {
    final client = GraphQLClient(
      cache: GraphQLCache(),
      link: Link.function((request, [forward]) async* {
        yield Response(
          response: const {},
          data: {
            'PayPOSTradeDocument': {'instansi_id': 'other'},
          },
        );
      }),
    );
    final result = await GraphQLPosTradeRepository.withClient(
      () => client,
      tenant: () => 'a',
    ).pay({});
    expect(
      result.fold((f) => f, (_) => null),
      isA<PosTradeUnconfirmedFailure>(),
    );
  });
  test('a timed out write remains unconfirmed', () async {
    final gate = Completer<Response>();
    final client = GraphQLClient(
      cache: GraphQLCache(),
      link: Link.function((request, [forward]) async* {
        yield await gate.future;
      }),
    );
    final result = await GraphQLPosTradeRepository.withClient(
      () => client,
      timeout: const Duration(milliseconds: 20),
    ).pay({});
    expect(
      result.fold((f) => f, (_) => null),
      isA<PosTradeUnconfirmedFailure>(),
    );
    gate.complete(Response(response: const {}, data: const {}));
  });
}
