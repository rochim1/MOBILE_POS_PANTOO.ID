import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/core/network/pos_bootstrap_reads.dart';
import 'package:mobile_pos_pantoo/core/network/sync_service.dart';
import 'package:mobile_pos_pantoo/data/datasources/local/pos_offline_pin_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/auth_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_state.dart';

class Provider extends Fake implements GraphQLClientProvider {
  Provider(this.client);
  @override
  final GraphQLClient client;
  @override
  String endpointUrl = 'http://qa.invalid/graphql';
  @override
  String resolveMediaUrl(dynamic raw) => raw?.toString() ?? '';
  @override
  void setAccessToken(String? token) {}
  @override
  void setPOSOperatorToken(String? token) {}
  @override
  Future<bool> hasAccessToken() async => true;
}

class Sync extends Fake implements SyncService {
  @override
  void setOperatorSessionToken(String token) {}
}

class RuntimeClient extends Fake implements GraphQLClient {
  final release = Completer<void>();
  int reads = 0;
  OperationException? failure;
  @override
  Future<QueryResult<T>> query<T extends Object?>(
    QueryOptions<T> options,
  ) async {
    reads++;
    await release.future;
    return QueryResult<T>(
      options: options,
      source: QueryResultSource.network,
      exception: failure,
      data: {
        'GetPOSRuntimeConfig': {
          'instansi_id': 'tenant',
          'permissions': {'use_cashier': true},
        },
      },
    );
  }
}

class PinClient extends Fake implements GraphQLClient {
  final started = Completer<void>();
  final release = Completer<Map<String, dynamic>>();
  @override
  Future<QueryResult<T>> mutate<T extends Object?>(
    MutationOptions<T> options,
  ) async {
    started.complete();
    return QueryResult<T>(
      options: options,
      source: QueryResultSource.network,
      data: {'VerifyPOSUserPin': await release.future},
    );
  }
}

class RosterRepo extends Fake implements PosRepository {
  Completer<Either<Failure, Map<String, dynamic>>>? pinResponse;
  final roster = Completer<Either<Failure, List<Map<String, dynamic>>>>();
  final status = Completer<Either<Failure, Map<String, dynamic>>>();
  int statusReads = 0;
  int verifies = 0;
  @override
  void setOperatorSessionToken(String token) {}
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPOSPinUsers({
    String search = '',
    bool? hasPin,
  }) => roster.future;
  @override
  Future<Either<Failure, Map<String, dynamic>>> getMyPOSLockStatus() {
    statusReads++;
    return status.future;
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> verifyPOSUserPin(
    String user,
    String pin,
  ) async {
    verifies++;
    if (pinResponse != null) return pinResponse!.future;
    return const Right({'success': false, 'message': 'PIN salah'});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  var network = 'wifi';
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'instansi_id': 'tenant',
      'user_id': 'cashier',
      'username': 'Kasir',
      'pos_runtime_config': '{"safe":"preserve"}',
    });
    FlutterSecureStorage.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    network = 'wifi';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (_) async => [network],
        );
    sl.registerSingleton<SharedPreferences>(prefs);
    sl.registerSingleton<SyncService>(Sync());
  });
  tearDown(() => sl.reset());

  test(
    'late online PIN response cannot cache credentials under a different tenant',
    () async {
      final client = PinClient();
      final repo = PosRepository(Provider(client), prefs);
      final pending = repo.verifyPOSUserPin('cashier', '123456');
      await client.started.future;
      await prefs.setString('instansi_id', 'other-tenant');
      client.release.complete({
        'success': true,
        'user_id': 'cashier',
        'operator_token': 'old-actor',
      });
      expect((await pending).isLeft(), true);
      expect(
        await PosOfflinePinStore(
          scope: 'other-tenant',
        ).verify('cashier', '123456'),
        isNull,
      );
    },
  );
  test(
    'a successful PIN response for another user cannot be cached or accepted',
    () async {
      final client = PinClient();
      final repo = PosRepository(Provider(client), prefs);
      final pending = repo.verifyPOSUserPin('cashier', '123456');
      await client.started.future;
      client.release.complete({
        'success': true,
        'user_id': 'foreign-cashier',
        'operator_token': 'wrong-actor',
      });
      expect((await pending).isLeft(), true);
      expect(
        await PosOfflinePinStore(scope: 'tenant').verify('cashier', '123456'),
        isNull,
      );
    },
  );
  testWidgets(
    'own PIN setup appears only after explicit has_pin=false, never on a failed status check',
    (tester) async {
      final repo = RosterRepo();
      sl.registerSingleton<PosRepository>(repo);
      final cubit = AppLockCubit();
      final pending = cubit.lock();
      repo.roster.complete(const Right([]));
      await tester.pump();
      expect(cubit.state.employees, isEmpty);
      expect(cubit.state.status, AppLockStatus.locked);
      repo.status.complete(const Right({'has_pin': false}));
      await pending;
      expect(cubit.state.employees.single['is_login_user'], true);
      expect(cubit.state.employees.single['has_pin'], false);
      expect(cubit.state.status, AppLockStatus.locked);
      await cubit.close();
    },
  );
  testWidgets('an incomplete own-PIN status must not offer PIN creation', (
    tester,
  ) async {
    final repo = RosterRepo();
    sl.registerSingleton<PosRepository>(repo);
    final cubit = AppLockCubit();
    final pending = cubit.lock();
    repo.roster.complete(const Right([]));
    await tester.pump();
    repo.status.complete(const Right({}));
    await pending;
    expect(cubit.state.employees, isEmpty);
    expect(cubit.state.status, AppLockStatus.locked);
    expect(cubit.state.errorMessage, isNotEmpty);
    await cubit.close();
  });
  testWidgets(
    'first-time device without a verified cache fails promptly and stays PIN locked',
    (tester) async {
      final release = Completer<Response>();
      final repo = PosRepository(
        Provider(
          GraphQLClient(
            queryRequestTimeout: const Duration(seconds: 30),
            cache: GraphQLCache(),
            link: posBootstrapReadDeadlineLink().concat(
              Link.function((request, [forward]) async* {
                yield await release.future;
              }),
            ),
          ),
        ),
        prefs,
      );
      sl.registerSingleton<PosRepository>(repo);
      final cubit = AppLockCubit();
      final pending = cubit.lock();
      await tester.pump();
      await tester.pump(const Duration(seconds: 9));
      expect(cubit.state.loadingEmployees, false);
      expect(cubit.state.employees, isEmpty);
      expect(cubit.state.status, AppLockStatus.locked);
      expect(cubit.state.errorMessage, contains('cache PIN'));
      release.complete(
        Response(
          data: const {
            'GetPOSPinUsers': {'items': []},
          },
          response: {},
        ),
      );
      await pending;
      await cubit.close();
    },
  );

  for (final code in ['FORBIDDEN', 'UNAUTHORIZED']) {
    test(
      'explicit $code never falls back to cached PIN and revokes its offline proof',
      () async {
        final cache = PosOfflinePinStore(scope: 'tenant');
        await cache.cacheVerifiedPin(
          userId: 'cashier',
          pin: '123456',
          response: {'name': 'Kasir'},
        );
        final client = GraphQLClient(
          cache: GraphQLCache(),
          link: Link.function((request, [forward]) async* {
            yield Response(
              errors: [
                GraphQLError(message: 'QA denied', extensions: {'code': code}),
              ],
              response: {},
            );
          }),
        );
        final repo = PosRepository(Provider(client), prefs);
        expect((await repo.getPOSPinUsers(hasPin: true)).isLeft(), true);
        network = 'none';
        expect((await repo.getPOSPinUsers(hasPin: true)).isLeft(), true);
        expect(
          (await repo.verifyPOSUserPin('cashier', '123456')).isLeft(),
          true,
        );
      },
    );
  }
  test(
    'offline verified roster stays locked until the correct cached PIN is entered',
    () async {
      final cache = PosOfflinePinStore(scope: 'tenant');
      await cache.cacheVerifiedPin(
        userId: 'cashier',
        pin: '123456',
        response: {'name': 'Kasir'},
      );
      network = 'none';
      final repo = PosRepository(
        Provider(
          GraphQLClient(
            cache: GraphQLCache(),
            link: Link.function((request, [forward]) async* {
              throw StateError('Offline PIN must not need network');
            }),
          ),
        ),
        prefs,
      );
      sl.registerSingleton<PosRepository>(repo);
      final cubit = AppLockCubit();
      await cubit.lock();
      expect(cubit.state.employees, hasLength(1));
      expect(cubit.state.status, AppLockStatus.locked);
      expect(await cubit.unlock('000000'), false);
      expect(cubit.state.status, AppLockStatus.locked);
      expect(await cubit.unlock('123456'), true);
      expect(cubit.state.activeEmployeeId, 'cashier');
      await cubit.close();
    },
  );
  test(
    'expired PIN proof and an unverified roster cannot authorize offline access',
    () async {
      final old = PosOfflinePinStore(
        scope: 'tenant',
        clock: () => DateTime.now().subtract(const Duration(days: 8)),
      );
      await old.cacheVerifiedPin(
        userId: 'cashier',
        pin: '123456',
        response: {'name': 'Kasir'},
      );
      await PosOfflinePinStore(scope: 'tenant').cacheEmployees([
        {'_id': 'other', 'has_pin': true},
      ]);
      network = 'none';
      final repo = PosRepository(
        Provider(
          GraphQLClient(
            cache: GraphQLCache(),
            link: Link.function((request, [forward]) => const Stream.empty()),
          ),
        ),
        prefs,
      );
      expect((await repo.getPOSPinUsers(hasPin: true)).isLeft(), true);
      expect((await repo.verifyPOSUserPin('cashier', '123456')).isLeft(), true);
    },
  );
  test(
    'late runtime response cannot overwrite a changed tenant or endpoint cache',
    () async {
      final client = RuntimeClient();
      final provider = Provider(client);
      final repo = PosRepository(provider, prefs);
      final pending = repo.getRuntimeConfig();
      await Future<void>.delayed(Duration.zero);
      await prefs.setString('instansi_id', 'different-tenant');
      provider.endpointUrl = 'http://other.invalid/graphql';
      final rejected = expectLater(pending, throwsA(isA<AuthFailure>()));
      client.release.complete();
      await rejected;
      expect(
        prefs.getKeys().where(
          (key) => key.startsWith('pos_runtime_config_v2:'),
        ),
        isEmpty,
      );
    },
  );
  test(
    'revoked runtime permissions are not reused from cache when later offline',
    () async {
      final client = RuntimeClient()..release.complete();
      final repo = PosRepository(Provider(client), prefs);
      expect(
        (await repo.getRuntimeConfig())['permissions']['use_cashier'],
        true,
      );
      client.failure = OperationException(
        graphqlErrors: [
          const GraphQLError(
            message: 'QA revoked',
            extensions: {'code': 'FORBIDDEN'},
          ),
        ],
      );
      await expectLater(
        repo.getRuntimeConfig(),
        throwsA(isA<OperationException>()),
      );
      network = 'none';
      expect(
        (await repo.getRuntimeConfig())['permissions']['use_cashier'],
        false,
      );
    },
  );

  test(
    'restoring a session verifies current user without the full runtime query',
    () async {
      FlutterSecureStorage.setMockInitialValues({
        'auth_token': 'saved-session',
      });
      final operations = <String>[];
      final provider = Provider(
        GraphQLClient(
          cache: GraphQLCache(),
          link: Link.function((request, [forward]) async* {
            final name =
                request.operation.document.definitions
                    .whereType<dynamic>()
                    .first
                    .name
                    ?.value
                    ?.toString() ??
                '';
            operations.add(name);
            if (name == 'GetCurrentPOSUser') {
              yield Response(
                data: {
                  'GetOneUser': {
                    '_id': 'cashier',
                    'instansi_id': {'_id': 'tenant'},
                  },
                },
                response: {},
              );
            } else {
              yield Response(
                errors: [
                  const GraphQLError(
                    message: 'Full runtime must not block restore',
                  ),
                ],
                response: {},
              );
            }
          }),
        ),
      );
      expect(
        await AuthRepository(
          provider,
          prefs,
          const FlutterSecureStorage(),
        ).checkSession(),
        true,
      );
      expect(operations, ['GetCurrentPOSUser']);
    },
  );
  test(
    'a delayed successful PIN response cannot unlock after logout/reset',
    () async {
      final repo = RosterRepo()..pinResponse = Completer();
      sl.registerSingleton<PosRepository>(repo);
      final cubit = AppLockCubit();
      final loading = cubit.lock();
      repo.roster.complete(
        Right([
          <String, dynamic>{'_id': 'cashier', 'has_pin': true},
        ]),
      );
      repo.status.complete(const Right({'has_pin': true}));
      await loading;
      final unlock = cubit.unlock('123456');
      cubit.reset();
      repo.pinResponse!.complete(
        const Right({
          'success': true,
          'user_id': 'cashier',
          'operator_token': 'must-not-be-applied',
        }),
      );
      expect(await unlock, false);
      expect(cubit.state.operatorSessionToken, isEmpty);
      await cubit.close();
    },
  );

  test(
    'accepted username login sends no optional runtime query and preserves same-account cache',
    () async {
      final operations = <String>[];
      final provider = Provider(
        GraphQLClient(
          cache: GraphQLCache(),
          link: Link.function((request, [forward]) async* {
            operations.add(
              request.operation.operationName ??
                  request.operation.document.toString(),
            );
            if (request.variables.containsKey('input')) {
              yield Response(
                data: {
                  'Login': {
                    'token': 'access',
                    'refresh_token': 'refresh',
                    'user': {
                      '_id': 'cashier',
                      'name': 'Kasir',
                      'instansi_id': {'_id': 'tenant'},
                    },
                  },
                },
                response: {},
              );
            } else {
              yield Response(
                errors: [const GraphQLError(message: 'QA runtime unavailable')],
                response: {},
              );
            }
          }),
        ),
      );
      final result = await AuthRepository(
        provider,
        prefs,
        const FlutterSecureStorage(),
      ).login('qa', 'not-a-real-password');
      expect(result.isRight(), true);
      expect(operations, hasLength(1));
      expect(prefs.getString('pos_runtime_config'), '{"safe":"preserve"}');
    },
  );

  testWidgets(
    'ready roster displays while optional own-PIN status is pending; wrong PIN never unlocks',
    (tester) async {
      final repo = RosterRepo();
      sl.registerSingleton<PosRepository>(repo);
      final cubit = AppLockCubit();
      final loading = cubit.lock();
      repo.roster.complete(
        const Right([
          {'_id': 'other-cashier', 'name': 'Kasir lain', 'has_pin': true},
        ]),
      );
      await tester.pump();
      try {
        expect(cubit.state.loadingEmployees, false);
        expect(cubit.state.employees.single['_id'], 'other-cashier');
        expect(cubit.state.status, AppLockStatus.locked);
        expect(await cubit.unlock('000000'), false);
        expect(cubit.state.status, AppLockStatus.locked);
      } finally {
        repo.status.complete(
          const Left(NetworkFailure('QA status unavailable')),
        );
        await loading;
      }
      expect(cubit.state.employees, hasLength(1));
      await cubit.close();
    },
  );
  test('roster containing login PIN needs no second status request', () async {
    final repo = RosterRepo();
    sl.registerSingleton<PosRepository>(repo);
    final cubit = AppLockCubit();
    final loading = cubit.lock();
    repo.roster.complete(
      const Right([
        {'_id': 'cashier', 'has_pin': true},
      ]),
    );
    repo.status.complete(const Right({'has_pin': true}));
    await loading;
    expect(repo.statusReads, 0);
    expect(cubit.state.status, AppLockStatus.locked);
    await cubit.close();
  });
  test('denied roster never requests optional status or unlocks', () async {
    final repo = RosterRepo();
    sl.registerSingleton<PosRepository>(repo);
    final cubit = AppLockCubit();
    final loading = cubit.lock();
    repo.roster.complete(const Left(AuthFailure('QA revoked')));
    repo.status.complete(const Right({'has_pin': false}));
    await loading;
    expect(repo.statusReads, 0);
    expect(cubit.state.status, AppLockStatus.locked);
    expect(cubit.state.employees, isEmpty);
    await cubit.close();
  });

  testWidgets(
    'network roster deadline falls back to verified PIN cache before the UI deadline',
    (tester) async {
      final cache = PosOfflinePinStore(scope: 'tenant');
      await cache.cacheVerifiedPin(
        userId: 'cashier',
        pin: '123456',
        response: {'name': 'Kasir'},
      );
      final release = Completer<Response>();
      final client = GraphQLClient(
        queryRequestTimeout: const Duration(seconds: 30),
        cache: GraphQLCache(),
        link: posBootstrapReadDeadlineLink().concat(
          Link.function((request, [forward]) async* {
            yield await release.future;
          }),
        ),
      );
      final repo = PosRepository(Provider(client), prefs);
      Either<Failure, List<Map<String, dynamic>>>? result;
      final reading = repo
          .getPOSPinUsers(hasPin: true)
          .then((value) => result = value);
      await tester.pump();
      await tester.pump(const Duration(seconds: 9));
      try {
        expect(result?.isRight(), true);
        expect(result!.getOrElse(() => []).single['offline_cached'], true);
      } finally {
        release.complete(
          Response(
            data: const {
              'GetPOSPinUsers': {'items': []},
            },
            response: {},
          ),
        );
        await reading;
      }
    },
  );
  test(
    'concurrent runtime consumers share one request without memoizing settled authorization',
    () async {
      final client = RuntimeClient();
      final repo = PosRepository(Provider(client), prefs);
      final a = repo.getRuntimeConfig();
      final b = repo.getRuntimeConfig();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      client.release.complete();
      await Future.wait([a, b]);
      expect(client.reads, 1);
      await repo.getRuntimeConfig();
      expect(client.reads, 2);
    },
  );
}
