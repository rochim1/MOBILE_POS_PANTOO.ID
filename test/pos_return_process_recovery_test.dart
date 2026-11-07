import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mobile_pos_pantoo/data/graphql/pos_return_queries.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_return/pos_return_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_return/pos_return_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_return/pos_return_state.dart';

class _Provider implements GraphQLClientProvider {
  _Provider(this.client);
  @override
  final GraphQLClient client;
  @override
  String endpointUrl = 'https://qa.invalid/graphql';
  @override
  void setPOSOperatorToken(String? token) {}
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'instansi_id': 'tenant',
      'user_id': 'terminal',
    }),
  );
  test(
    'pending refund rejects duplicate clicks before the first response',
    () async {
      var writes = 0;
      final release = Completer<void>();
      final started = Completer<void>();
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          writes++;
          if (!started.isCompleted) started.complete();
          await release.future;
          yield Response(
            data: {'__typename': 'Mutation'},
            errors: [
              const GraphQLError(
                message: 'QA denied',
                extensions: {'code': 'FORBIDDEN'},
              ),
            ],
            response: {},
          );
        }),
      );
      final bloc = PosReturnBloc(
        posRepository: PosRepository(
          _Provider(client),
          await SharedPreferences.getInstance(),
        ),
      );
      bloc.add(const ProcessReturn('ret-1'));
      await started.future;
      bloc.add(const ProcessReturn('ret-1'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.status, PosReturnStatus.loading);
      expect(writes, 1);
      final failed = bloc.stream.firstWhere(
        (s) => s.status == PosReturnStatus.failure,
      );
      release.complete();
      await failed;
      await bloc.close();
    },
  );
  for (final scenario in [
    'completed',
    'approved',
    'offline',
    'foreign',
    'denied',
  ]) {
    test('process refund lost ACK recovery: $scenario', () async {
      var writes = 0, reads = 0;
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          if (request.operation.document ==
              gql(PosReturnQueries.processSalesReturn)) {
            writes++;
            if (scenario == 'denied') {
              yield Response(
                data: {'__typename': 'Mutation'},
                errors: [
                  const GraphQLError(
                    message: 'QA forbidden',
                    extensions: {'code': 'FORBIDDEN'},
                  ),
                ],
                response: {},
              );
              return;
            }
            throw ServerException(
              originalException: Exception('QA response lost after commit'),
            );
          }
          reads++;
          expect(request.variables['_id'], 'ret-1');
          if (scenario == 'offline') {
            throw ServerException(
              originalException: Exception('QA still offline'),
            );
          }
          yield Response(
            data: {
              '__typename': 'Query',
              'GetOneSalesReturn': {
                '__typename': 'SalesReturn',
                '_id': scenario == 'foreign' ? 'ret-2' : 'ret-1',
                'status': scenario == 'approved' ? 'approved' : 'completed',
              },
            },
            response: {},
          );
        }),
      );
      final repo = PosRepository(
        _Provider(client),
        await SharedPreferences.getInstance(),
      );
      final result = await repo.processSalesReturn('ret-1');
      expect(writes, 1);
      expect(result.isRight(), scenario == 'completed');
      expect(reads, scenario == 'denied' ? 0 : 1);
      if (scenario != 'completed' && scenario != 'denied') {
        expect(
          result.fold((f) => f.message, (_) => ''),
          contains('Jangan keluarkan uang lagi'),
        );
      }
    });
  }
}
