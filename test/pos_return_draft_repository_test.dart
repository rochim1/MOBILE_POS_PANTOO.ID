import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_return/pos_return_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_return/pos_return_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_return/pos_return_state.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_return_draft_recovery.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_add_return_page.dart';

class _Provider implements GraphQLClientProvider {
  @override
  final GraphQLClient client;
  @override
  String endpointUrl = 'https://qa.invalid/graphql';
  _Provider(this.client);
  @override
  void setPOSOperatorToken(String? token) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final input = <String, dynamic>{
    'sumber': 'pos',
    'sumber_id': 'sale-1',
    'sumber_no': 'QA-1',
    'items': [
      {'inventaris_id': 'item', 'qty_returned': 1},
    ],
  };
  final response = <String, dynamic>{
    '__typename': 'Mutation',
    'CreateSalesReturn': {
      '__typename': 'SalesReturn',
      '_id': 'return-1',
      'no_retur': 'QA-RET-1',
      'status': 'draft',
      'total_refund': 10000,
    },
  };
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'instansi_id': 'tenant',
      'user_id': 'terminal',
    }),
  );
  Future<PosRepository> repository(Link link) async {
    final repo = PosRepository(
      _Provider(GraphQLClient(cache: GraphQLCache(), link: link)),
      await SharedPreferences.getInstance(),
    );
    repo.setOperatorSessionToken('offline_operator:actor');
    return repo;
  }

  test(
    'repository restart after lost ACK sends original identity and payload, not edited form',
    () async {
      String? requestId;
      var sends = 0;
      final link = Link.function((request, [forward]) async* {
        final payload = request.variables['input'] as Map;
        sends++;
        if (requestId == null) {
          requestId = payload['client_request_id'] as String;
          throw Exception('QA response lost after commit');
        }
        expect(payload['client_request_id'], requestId);
        expect(payload['sumber_id'], 'sale-1');
        expect((payload['items'] as List).first['qty_returned'], 1);
        yield Response(data: response, response: {});
      });
      final first = await repository(link);
      expect((await first.createSalesReturn(input)).isLeft(), isTrue);
      expect(first.pendingReturnDraft(), isNotNull);
      final restarted = await repository(link);
      expect(
        (await restarted.createSalesReturn({
          ...input,
          'sumber_id': 'other',
        })).isRight(),
        isTrue,
      );
      expect(sends, 2);
      expect(restarted.pendingReturnDraft(), isNull);
    },
  );
  test(
    'rapid double submit is blocked before another request starts',
    () async {
      final gate = Completer<void>(), entered = Completer<void>();
      var sends = 0;
      final repo = await repository(
        Link.function((request, [forward]) async* {
          sends++;
          entered.complete();
          await gate.future;
          yield Response(data: response, response: {});
        }),
      );
      final first = repo.createSalesReturn(input);
      await entered.future;
      expect((await repo.createSalesReturn(input)).isLeft(), isTrue);
      gate.complete();
      expect((await first).isRight(), isTrue);
      expect(sends, 1);
    },
  );
  test(
    'only a terminal server rejection clears proof; permission denial and malformed ACK keep it',
    () async {
      var mode = 'denied';
      final repo = await repository(
        Link.function((request, [forward]) async* {
          if (mode == 'empty') {
            yield Response(
              data: {'__typename': 'Mutation', 'CreateSalesReturn': null},
              response: {},
            );
            return;
          }
          yield Response(
            errors: [
              GraphQLError(
                message: 'QA reject',
                extensions: mode == 'terminal'
                    ? {'return_draft_write_rejected': true}
                    : {'code': 'FORBIDDEN'},
              ),
            ],
            response: {},
          );
        }),
      );
      expect((await repo.createSalesReturn(input)).isLeft(), isTrue);
      expect(repo.pendingReturnDraft(), isNotNull);
      mode = 'empty';
      expect((await repo.createSalesReturn(null)).isLeft(), isTrue);
      expect(repo.pendingReturnDraft(), isNotNull);
      mode = 'terminal';
      expect((await repo.createSalesReturn(null)).isLeft(), isTrue);
      expect(repo.pendingReturnDraft(), isNull);
    },
  );
  test(
    'changing PIN operator never replays another operator pending return',
    () async {
      var sends = 0;
      final repo = await repository(
        Link.function((request, [forward]) async* {
          sends++;
          throw Exception('QA lost');
        }),
      );
      await repo.createSalesReturn(input);
      repo.setOperatorSessionToken('offline_operator:other');
      expect(repo.pendingReturnDraft(), isNull);
      expect((await repo.createSalesReturn(null)).isLeft(), isTrue);
      expect(sends, 1);
      repo.setOperatorSessionToken('offline_operator:actor');
      expect(repo.pendingReturnDraft(), isNotNull);
    },
  );
  testWidgets(
    'successful modal save closes only its dialog even when the list reload finishes during the exit animation',
    (tester) async {
      final repo = await repository(
        Link.function((request, [forward]) async* {
          yield Response(
            data: request.variables.containsKey('filter')
                ? {
                    '__typename': 'Query',
                    'GetAllSalesReturns': {
                      '__typename': 'SalesReturnList',
                      'items': <Map<String, dynamic>>[],
                      'totalCount': 0,
                    },
                  }
                : response,
            response: {},
          );
        }),
      );
      final bloc = PosReturnBloc(posRepository: repo);
      addTearDown(bloc.close);
      bloc.emit(
        const PosReturnState(
          status: PosReturnStatus.success,
          searchResult: {'_id': 'sale-1', 'invoice': 'QA-1'},
          returnItems: [
            {
              'selected': true,
              'inventaris_id': 'item',
              'qty_returned': 1,
              'qty_original': 2,
              'unit': 'unit',
              'harga_jual': 1000,
              'kondisi': 'baik',
              'masuk_ke_stok': true,
            },
          ],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: bloc,
                    child: const PosAddReturnPage(),
                  ),
                ),
                child: const Text('Return list remains visible'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Return list remains visible'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Draft Retur'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Return list remains visible'), findsOneWidget);
      expect(find.byType(PosAddReturnPage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'return fields cannot be edited while the save acknowledgement is pending',
    (tester) async {
      final gate = Completer<void>();
      final repo = await repository(
        Link.function((request, [forward]) async* {
          await gate.future;
          yield Response(
            data: request.variables.containsKey('filter')
                ? {
                    '__typename': 'Query',
                    'GetAllSalesReturns': {
                      '__typename': 'SalesReturnList',
                      'items': <Map<String, dynamic>>[],
                      'totalCount': 0,
                    },
                  }
                : response,
            response: {},
          );
        }),
      );
      final bloc = PosReturnBloc(posRepository: repo);
      addTearDown(bloc.close);
      bloc.emit(
        const PosReturnState(
          status: PosReturnStatus.success,
          searchResult: {'_id': 'sale-1', 'invoice': 'QA-1'},
          returnItems: [
            {
              'selected': true,
              'inventaris_id': 'item',
              'qty_returned': 1,
              'qty_original': 2,
              'unit': 'unit',
              'harga_jual': 1000,
              'kondisi': 'baik',
              'masuk_ke_stok': true,
            },
          ],
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const PosAddReturnPage(),
          ),
        ),
      );
      await tester.tap(find.text('Simpan Draft Retur'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      await tester.tap(find.byType(TextField).first, warnIfMissed: false);
      await tester.pump();
      try {
        expect(
          tester.testTextInput.isVisible,
          isFalse,
          reason:
              'The submitted invoice must not remain editable while its ACK is unknown',
        );
      } finally {
        gate.complete();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
      }
    },
  );
  testWidgets(
    'recovery banner survives bloc recreation, offers recovery without invoice search and shows progress',
    (tester) async {
      var sends = 0;
      final gate = Completer<void>();
      final repo = await repository(
        Link.function((request, [forward]) async* {
          if (request.variables.containsKey('filter')) {
            yield Response(
              data: {
                '__typename': 'Query',
                'GetAllSalesReturns': {
                  '__typename': 'SalesReturnList',
                  'items': [],
                  'totalCount': 0,
                },
              },
              response: {},
            );
            return;
          }
          sends++;
          if (sends == 1) throw Exception('QA ACK lost');
          await gate.future;
          yield Response(data: response, response: {});
        }),
      );
      await repo.createSalesReturn(input);
      final bloc = PosReturnBloc(posRepository: repo)..add(const LoadReturns());
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: bloc,
              child: const PosReturnDraftRecovery(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Invoice QA-1'), findsOneWidget);
      await tester.tap(find.text('Pulihkan draft retur'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.text('Memastikan draft...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
      expect(bloc.state.pendingDraft, isNull);
      expect(bloc.state.status, PosReturnStatus.success);
      expect(sends, 2);
      expect(find.text('Pulihkan draft retur'), findsNothing);
    },
  );
}
