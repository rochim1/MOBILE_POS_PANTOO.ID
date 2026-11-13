import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_financial_report_repository.dart';

void main() {
  test(
    'read-only reports retry one dropped transport but not denied responses',
    () async {
      var calls = 0;
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          calls++;
          if (calls == 1) throw StateError('dropped QA connection');
          yield Response(
            response: const {},
            data: {
              'GetPOSFinancialReportOptions': {
                'instansi_id': 'tenant-a',
                'scope': 'instansi',
                'currency': 'IDR',
                'timezone': 'Asia/Jakarta',
                'today': '2026-11-13',
                'max_period_days': 366,
              },
            },
          );
        }),
      );
      final repo = GraphQLPosFinancialReportRepository.withClient(() => client);
      expect((await repo.getOptions()).isRight(), true);
      expect(calls, 2);
    },
  );
  test(
    'a stalled report request times out without retaining a cached balance',
    () async {
      final pending = Completer<Response>();
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          yield await pending.future;
        }),
      );
      final repo = GraphQLPosFinancialReportRepository.withClient(
        () => client,
        requestTimeout: const Duration(milliseconds: 20),
      );
      final result = await repo.getOptions();
      expect(
        result.fold((failure) => failure, nullValue),
        isA<NetworkFailure>(),
      );
      pending.complete(Response(response: const {}, data: const {}));
    },
  );

  test(
    'financial options are read from the network every time without reusing a cache',
    () async {
      var calls = 0;
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          calls++;
          yield Response(
            response: const {},
            data: {
              'GetPOSFinancialReportOptions': {
                'instansi_id': 'tenant-a',
                'scope': 'instansi',
                'currency': 'IDR',
                'timezone': 'Asia/Jakarta',
                'today': '2026-11-13',
                'max_period_days': 366,
              },
            },
          );
        }),
      );
      final repo = GraphQLPosFinancialReportRepository.withClient(() => client);
      expect((await repo.getOptions()).isRight(), true);
      expect((await repo.getOptions()).isRight(), true);
      expect(calls, 2);
    },
  );
  test(
    'FORBIDDEN is access denied rather than an empty financial report',
    () async {
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          yield Response(
            response: const {},
            errors: [
              GraphQLError(
                message: 'No permission',
                extensions: {'code': 'FORBIDDEN'},
              ),
            ],
          );
        }),
      );
      final repo = GraphQLPosFinancialReportRepository.withClient(() => client);
      final result = await repo.getOptions();
      expect(
        result.fold((failure) => failure, nullValue),
        isA<FinancialReportAccessFailure>(),
      );
    },
  );
  test(
    'a late response from the previous authenticated client is discarded',
    () async {
      final response = Completer<Response>();
      final original = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          yield await response.future;
        }),
      );
      var current = original;
      final repo = GraphQLPosFinancialReportRepository.withClient(
        () => current,
      );
      final pending = repo.getOptions();
      await Future<void>.delayed(Duration.zero);
      current = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          yield Response(response: const {}, data: {});
        }),
      );
      response.complete(
        Response(
          response: const {},
          data: {
            'GetPOSFinancialReportOptions': {
              'instansi_id': 'tenant-a',
              'scope': 'instansi',
              'currency': 'IDR',
              'timezone': 'Asia/Jakarta',
              'today': '2026-11-13',
              'max_period_days': 366,
            },
          },
        ),
      );
      final result = await pending;
      expect(result.fold((failure) => failure, nullValue), isA<AuthFailure>());
    },
  );
}

Object? nullValue(Object? value) => null;
