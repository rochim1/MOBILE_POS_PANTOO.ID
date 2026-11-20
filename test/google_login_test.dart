import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/domain/repositories/auth_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/auth_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/login/google_registration_details.dart';

class _Provider extends Fake implements GraphQLClientProvider {
  @override
  late GraphQLClient client;
  String? savedToken;
  @override
  void setAccessToken(String? token) {
    savedToken = token;
  }
}

class _GoogleRepository extends Fake implements AuthRepository {
  final pending = Completer<Either<Failure, String>>();
  int calls = 0;
  @override
  Future<bool> checkSession() async => false;
  @override
  Future<Either<Failure, String>> loginWithGoogle(
    String token, {
    String? phone,
    bool consent = false,
  }) {
    calls++;
    return pending.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (_) async => ['wifi'],
        );
  });
  test(
    'Google registration sends POS attribution and explicit consent; stores only Pantoo session',
    () async {
      final provider = _Provider();
      final requests = <Request>[];
      provider.client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          requests.add(request);
          yield Response(
            data: {
              'Login': {
                'token': 'pantoo-session',
                'refresh_token': 'pantoo-refresh',
                'user': {
                  '_id': 'user-google',
                  'name': 'Pemilik',
                  'instansi_id': null,
                },
              },
            },
            response: {},
          );
        }),
      );
      final prefs = await SharedPreferences.getInstance();
      const storage = FlutterSecureStorage();
      final repository = AuthRepository(provider, prefs, storage);
      final result = await repository.loginWithGoogle(
        'google-proof',
        phone: '08123456789',
        consent: true,
      );
      expect(result.isRight(), isTrue);
      final input = requests.single.variables['input'] as Map;
      expect(input['primary_product'], 'pos');
      expect(input['registration_source'], 'mobile_pos');
      expect(input['access_via'], 'mobile_app');
      expect(input['provider'], 'google');
      expect(input['tokenId'], 'google-proof');
      expect(input['legal_consent'], isTrue);
      expect(input['telp_number'], '08123456789');
      expect(input.containsKey('password'), isFalse);
      expect(input.containsKey('captcha_id'), isFalse);
      expect(await storage.read(key: 'auth_token'), 'pantoo-session');
      expect(await storage.read(key: 'refresh_token'), 'pantoo-refresh');
      expect((await storage.readAll()).values, isNot(contains('google-proof')));
      expect(prefs.getBool('needs_workspace_setup'), isTrue);
    },
  );
  test(
    'new Google identity requests details without saving a session',
    () async {
      final provider = _Provider();
      provider.client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          yield Response(
            errors: [
              GraphQLError(
                message: 'Details required',
                extensions: {'code': 'GOOGLE_REGISTRATION_DETAILS_REQUIRED'},
              ),
            ],
            response: {},
          );
        }),
      );
      final prefs = await SharedPreferences.getInstance();
      const storage = FlutterSecureStorage();
      final result = await AuthRepository(
        provider,
        prefs,
        storage,
      ).loginWithGoogle('google-proof');
      expect(
        result.fold((failure) => failure, (_) => null),
        isA<GoogleRegistrationRequiredFailure>(),
      );
      expect(await storage.readAll(), isEmpty);
      expect(prefs.getBool('needs_workspace_setup'), isNull);
    },
  );
  test(
    'duplicate Google callbacks submit only once and keep route mounted for details',
    () async {
      final repository = _GoogleRepository();
      final cubit = AuthCubit(authRepository: repository);
      await cubit.checkSession();
      final first = cubit.loginGoogle('proof');
      await cubit.loginGoogle('proof');
      expect(repository.calls, 1);
      expect(cubit.state.isAuthenticating, isFalse);
      repository.pending.complete(
        const Left(GoogleRegistrationRequiredFailure()),
      );
      expect(await first, isA<GoogleRegistrationRequiredFailure>());
      expect(cubit.state.isAuthenticated, isFalse);
      await cubit.close();
    },
  );
  testWidgets(
    'verified Google session redirects even if runtime bootstrap never replies',
    (tester) async {
      final provider = _Provider();
      final bootstrap = Completer<Response>();
      bool bootstrapStarted = false;
      Map? loginInput;
      provider.client = GraphQLClient(
        cache: GraphQLCache(),
        queryRequestTimeout: const Duration(minutes: 2),
        link: Link.function((request, [forward]) async* {
          if (request.variables.containsKey('input')) {
            loginInput = request.variables['input'] as Map;
            yield Response(
              data: {
                'Login': {
                  'token': 'pantoo-session',
                  'refresh_token': 'pantoo-refresh',
                  'user': {
                    '_id': 'google-user',
                    'name': 'Kasir',
                    'instansi_id': {'_id': 'tenant'},
                  },
                },
              },
              response: {},
            );
          } else {
            bootstrapStarted = true;
            yield await bootstrap.future;
          }
        }),
      );
      final prefs = await SharedPreferences.getInstance();
      final cubit = AuthCubit(
        authRepository: AuthRepository(
          provider,
          prefs,
          const FlutterSecureStorage(),
        ),
      );
      // checkSession would inspect an empty storage; isolate submission state.
      await cubit.checkSession();
      final login = cubit.loginGoogle('verified-proof');
      for (var i = 0; i < 50 && !bootstrapStarted; i++) {
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(loginInput?['access_via'], 'mobile_app');
      expect(bootstrapStarted, isTrue);
      await tester.pump(const Duration(seconds: 10));
      expect(
        cubit.state.isAuthenticated,
        isTrue,
        reason:
            'Optional bootstrap must not consume the entire Google login timeout after credentials were persisted',
      );
      bootstrap.complete(
        Response(
          data: {
            'GetPOSRuntimeConfig': {'instansi_id': 'late-tenant'},
          },
          response: {},
        ),
      );
      await login;
      await tester.pump();
      expect(prefs.getString('instansi_id'), 'tenant');
      expect(prefs.getString('pos_runtime_config'), isNull);
      await cubit.close();
    },
  );
  testWidgets(
    'Google deadline includes verified session storage and bounded bootstrap',
    (tester) async {
      final repository = _GoogleRepository();
      final cubit = AuthCubit(authRepository: repository);
      await cubit.checkSession();
      final login = cubit.loginGoogle('proof');
      // The GraphQL transport allows30s; accepted credentials can still need
      // secure persistence and the bounded8s runtime request afterwards.
      await tester.pump(const Duration(seconds: 33));
      repository.pending.complete(const Right('Kasir'));
      expect(
        await login,
        isNull,
        reason:
            'Do not report a false login timeout after valid credentials were saved',
      );
      expect(cubit.state.isAuthenticated, isTrue);
      await cubit.close();
    },
  );
  test(
    'runtime authorization rejection still invalidates Google session',
    () async {
      final provider = _Provider();
      provider.client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          if (request.variables.containsKey('input')) {
            yield Response(
              data: {
                'Login': {
                  'token': 'pantoo-session',
                  'refresh_token': 'pantoo-refresh',
                  'user': {
                    '_id': 'google-user',
                    'name': 'Kasir',
                    'instansi_id': {'_id': 'tenant'},
                  },
                },
              },
              response: {},
            );
          } else {
            yield Response(
              errors: [
                GraphQLError(
                  message: 'Session revoked',
                  extensions: {'code': 'UNAUTHORIZED'},
                ),
              ],
              response: {},
            );
          }
        }),
      );
      final prefs = await SharedPreferences.getInstance();
      const storage = FlutterSecureStorage();
      final result = await AuthRepository(
        provider,
        prefs,
        storage,
      ).loginWithGoogle('proof');
      expect(
        result.fold((failure) => failure, (_) => null),
        isA<AuthFailure>(),
      );
      expect(provider.savedToken, isNull);
      expect(await storage.read(key: 'auth_token'), isNull);
      expect(await storage.read(key: 'refresh_token'), isNull);
    },
  );
  testWidgets('registration requires phone and unchecked-by-default consent', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: GoogleRegistrationDetails())),
    );
    expect(
      tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      isFalse,
    );
    await tester.tap(find.text('Buat akun dan lanjutkan'));
    await tester.pump();
    expect(find.text('Masukkan nomor telepon 8–15 digit.'), findsOneWidget);
    expect(
      find.text('Persetujuan diperlukan untuk membuat akun.'),
      findsOneWidget,
    );
  });
}
