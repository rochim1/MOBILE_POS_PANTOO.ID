import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/data/graphql/pos_trade_queries.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_trade.dart';

class PosTradeRejectedFailure extends Failure {
  const PosTradeRejectedFailure(super.message);
}

class PosTradeAccessFailure extends Failure {
  const PosTradeAccessFailure() : super('Akses utang/piutang belum tersedia.');
}

class PosTradeUnconfirmedFailure extends Failure {
  const PosTradeUnconfirmedFailure()
    : super(
        'Hasil permintaan belum dapat dipastikan. Konfirmasi ulang dengan bukti yang sama.',
      );
}

abstract class PosTradeRepository {
  Future<Either<Failure, PosTradeOptions>> options();
  Future<Either<Failure, PosTradePage>> list(
    PosTradeKind kind, {
    String search = '',
    int page = 1,
    bool settled = false,
  });
  Future<Either<Failure, PosTradeDocument>> detail(
    PosTradeKind kind,
    String id,
  );
  Future<Either<Failure, PosTradeDocument>> create(Map<String, dynamic> input);
  Future<Either<Failure, PosTradeDocument>> pay(Map<String, dynamic> input);
}

class GraphQLPosTradeRepository implements PosTradeRepository {
  GraphQLPosTradeRepository(GraphQLClientProvider provider)
    : _client = (() => provider.client),
      _tenant = (() =>
          provider.sharedPreferences.getString('instansi_id') ?? ''),
      timeout = const Duration(seconds: 30);
  GraphQLPosTradeRepository.withClient(
    this._client, {
    this.timeout = const Duration(seconds: 30),
    String Function()? tenant,
  }) : _tenant = tenant ?? (() => '');
  final GraphQLClient Function() _client;
  final Duration timeout;
  final String Function() _tenant;
  Future<Either<Failure, T>> _read<T>(
    String source,
    String field,
    Map<String, dynamic> vars,
    T Function(Map<String, dynamic>) parse, {
    bool mutation = false,
  }) async {
    try {
      final client = _client();
      final tenant = _tenant();
      final result =
          await (mutation
                  ? client.mutate(
                      MutationOptions(
                        document: gql(source),
                        variables: vars,
                        fetchPolicy: FetchPolicy.noCache,
                      ),
                    )
                  : client.query(
                      QueryOptions(
                        document: gql(source),
                        variables: vars,
                        fetchPolicy: FetchPolicy.noCache,
                      ),
                    ))
              .timeout(timeout);
      if (!identical(client, _client()) || tenant != _tenant()) {
        return const Left(AuthFailure());
      }
      if (result.hasException) {
        final errors = result.exception!.graphqlErrors;
        if (errors.any(
          (e) => [
            'UNAUTHORIZED',
            'UNAUTHENTICATED',
          ].contains(e.extensions?['code']),
        )) {
          return const Left(AuthFailure());
        }
        if (errors.any((e) => e.extensions?['code'] == 'FORBIDDEN')) {
          return const Left(PosTradeAccessFailure());
        }
        if (errors.any(
          (e) => e.extensions?['financial_write_rejected'] == true,
        )) {
          return Left(
            PosTradeRejectedFailure(errors.map((e) => e.message).join('\n')),
          );
        }
        if (mutation) return const Left(PosTradeUnconfirmedFailure());
        return Left(
          ServerFailure(
            errors.isEmpty
                ? 'Layanan keuangan belum dapat dihubungi.'
                : errors.map((e) => e.message).join('\n'),
          ),
        );
      }
      final raw = result.data?[field];
      if (raw is! Map) {
        return mutation
            ? const Left(PosTradeUnconfirmedFailure())
            : const Left(ServerFailure());
      }
      final data = Map<String, dynamic>.from(raw);
      if (tenant.isNotEmpty) {
        final documents = field == 'GetPOSTradeDocuments'
            ? data['items'] as List
            : [data];
        if (documents.any((d) => d['instansi_id'] != tenant)) {
          return mutation
              ? const Left(PosTradeUnconfirmedFailure())
              : const Left(PosTradeAccessFailure());
        }
      }
      return Right(parse(data));
    } on TimeoutException {
      return mutation
          ? const Left(PosTradeUnconfirmedFailure())
          : const Left(NetworkFailure());
    } catch (_) {
      return mutation
          ? const Left(PosTradeUnconfirmedFailure())
          : const Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, PosTradeOptions>> options() => _read(
    PosTradeQueries.options,
    'GetPOSTradeOptions',
    {},
    PosTradeOptions.new,
  );
  @override
  Future<Either<Failure, PosTradePage>> list(
    PosTradeKind kind, {
    String search = '',
    int page = 1,
    bool settled = false,
  }) => _read(PosTradeQueries.list, 'GetPOSTradeDocuments', {
    'kind': kind.name,
    'search': search,
    'page': page,
    'settled': settled,
  }, PosTradePage.fromJson);
  @override
  Future<Either<Failure, PosTradeDocument>> detail(
    PosTradeKind kind,
    String id,
  ) => _read(PosTradeQueries.detail, 'GetPOSTradeDocument', {
    'kind': kind.name,
    'id': id,
  }, PosTradeDocument.fromJson);
  @override
  Future<Either<Failure, PosTradeDocument>> create(
    Map<String, dynamic> input,
  ) => _read(
    PosTradeQueries.create,
    'CreatePOSManualTrade',
    {'input': input},
    PosTradeDocument.fromJson,
    mutation: true,
  );
  @override
  Future<Either<Failure, PosTradeDocument>> pay(Map<String, dynamic> input) =>
      _read(
        PosTradeQueries.pay,
        'PayPOSTradeDocument',
        {'input': input},
        PosTradeDocument.fromJson,
        mutation: true,
      );
}
