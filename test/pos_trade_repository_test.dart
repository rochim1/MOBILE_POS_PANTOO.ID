import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_trade_repository.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_trade.dart';

void main() {
  for (final wrong in ['id', 'kind', 'empty-id']) {
    test('payment ACK must match requested document and kind: $wrong', () async {
      final response = <String, dynamic>{
        'instansi_id': 'a', 'id': wrong == 'id' ? 'other' : wrong == 'empty-id' ? '' : 'doc',
        'kind': wrong == 'kind' ? 'payable' : 'receivable',
        'number': 'INV', 'reference': '', 'party': 'Customer', 'date': '2026-11-26',
        'amount': 100, 'paid': 100, 'credited': 0, 'withheld': 0, 'outstanding': 0,
        'status': 'paid', 'source': 'pos', 'basis': 'transaction', 'notes': '',
        'can_pay': false, 'payment_count': 1, 'payments': <dynamic>[],
      };
      final client = GraphQLClient(cache: GraphQLCache(), link: Link.function((request, [forward]) async* {
        yield Response(data: {'PayPOSTradeDocument': response}, response: {});
      }));
      final result = await GraphQLPosTradeRepository.withClient(() => client, tenant: () => 'a').pay({'kind': 'receivable', 'document_id': 'doc'});
      expect(result.fold((failure) => failure, (_) => null), isA<PosTradeUnconfirmedFailure>());
    });
  }
  test(
    'current tenant can read options/list/detail and parse confirmed create/payment results',
    () async {
      final document = <String, dynamic>{
        'instansi_id': 'a',
        'id': 'doc',
        'kind': 'receivable',
        'number': 'INV',
        'reference': '',
        'party': 'Customer',
        'date': '2026-11-16',
        'amount': 100,
        'paid': 0,
        'credited': 0,
        'withheld': 0,
        'outstanding': 100,
        'status': 'issued',
        'source': 'pos',
        'basis': 'transaction',
        'notes': '',
        'can_pay': true,
        'payment_count': 0,
        'payments': <dynamic>[],
        'terms': <dynamic>[],
      };
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          final dynamic definition =
              request.operation.document.definitions.single;
          final dynamic selection = (definition.selectionSet.selections as List)
              .firstWhere((dynamic field) => field.name.value != '__typename');
          final String field = selection.name.value as String;
          yield Response(
            response: const {},
            data: {
              field: field == 'GetPOSTradeOptions'
                  ? {'instansi_id': 'a', 'today': '2026-11-16', 'view_ar': true}
                  : field == 'GetPOSTradeDocuments'
                  ? {
                      'items': [document],
                      'total_count': 1,
                      'outstanding': 100,
                      'page': 1,
                      'limit': 20,
                    }
                  : document,
            },
          );
        }),
      );
      final repo = GraphQLPosTradeRepository.withClient(
        () => client,
        tenant: () => 'a',
      );
      expect(
        (await repo.options())
            .getOrElse(() => throw StateError('options'))
            .viewAR,
        true,
      );
      expect(
        (await repo.list(
          PosTradeKind.receivable,
        )).getOrElse(() => throw StateError('list')).items.single.id,
        'doc',
      );
      expect(
        (await repo.detail(
          PosTradeKind.receivable,
          'doc',
        )).getOrElse(() => throw StateError('detail')).outstanding,
        100,
      );
      expect(
        (await repo.create({})).getOrElse(() => throw StateError('create')).id,
        'doc',
      );
      expect(
        (await repo.pay({})).getOrElse(() => throw StateError('pay')).id,
        'doc',
      );
    },
  );
  for (final code in ['FORBIDDEN', 'UNAUTHENTICATED', 'BAD_USER_INPUT']) {
    test(
      'HTTP-wrapped $code preserves the financial decision instead of freezing the request',
      () async {
        final client = GraphQLClient(
          cache: GraphQLCache(),
          link: Link.function((request, [forward]) async* {
            throw ServerException(
              parsedResponse: Response(
                response: const {},
                errors: [
                  GraphQLError(
                    message: 'Request rejected by server',
                    extensions: {
                      'code': code,
                      if (code == 'BAD_USER_INPUT')
                        'financial_write_rejected': true,
                    },
                  ),
                ],
              ),
            );
          }),
        );
        final failure = (await GraphQLPosTradeRepository.withClient(
          () => client,
        ).pay({})).fold((f) => f, (_) => null);
        if (code == 'FORBIDDEN') {
          expect(failure, isA<PosTradeAccessFailure>());
        } else if (code == 'UNAUTHENTICATED') {
          expect(failure, isA<AuthFailure>());
        } else {
          expect(failure, isA<PosTradeRejectedFailure>());
        }
      },
    );
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
