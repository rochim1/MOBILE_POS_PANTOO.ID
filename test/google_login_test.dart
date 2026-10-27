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
