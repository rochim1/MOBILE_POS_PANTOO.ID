import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mobile_pos_pantoo/core/flavor/flavor_config.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/core/utils/product_image_picker.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_business_profile_repository.dart';

class _Provider extends Fake implements GraphQLClientProvider {
  @override
  late GraphQLClient client;
  @override
  String subscriptionScope = 'endpoint|tenant|user|operator';
  @override
  String endpointUrl = 'http://localhost:8080/graphql';
  @override
  String resolveMediaUrl(dynamic value) => value == null || value == ''
      ? ''
      : Uri.parse(
          'http://localhost:8080/',
        ).resolve(value.toString()).toString();
  @override
  Future<Map<String, String>> authenticatedRequestHeaders() async => {
    'Authorization': 'Bearer fixture',
    'apps': 'pos',
  };
}

class _Upload extends http.BaseClient {
  late http.MultipartRequest request;
  Map<String, dynamic> payload = {
    'data': {'UpdateMyPOSBusinessProfile': _data},
  };
  @override
  Future<http.StreamedResponse> send(http.BaseRequest value) async {
    request = value as http.MultipartRequest;
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(payload))),
      200,
    );
  }
}

const _data = {
  '__typename': 'POSBusinessProfile',
  '_id': 'tenant',
  'name': 'Usaha Uji',
  'phone': '081234567890',
  'address': 'Jalan Uji',
  'logo': '/static/tenant/logo/fixture.png',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Provider provider;
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    provider = _Provider();
  });

  test(
    'multipart headers preserve the selected PIN operator rather than using only the login owner',
    () async {
      dotenv.loadFromString(
        envString: 'API_URL=http://localhost:8080/graphql\n',
      );
      FlutterSecureStorage.setMockInitialValues({});
      final real = GraphQLClientProvider(
        prefs,
        const FlutterSecureStorage(),
        environment: FlavorEnvironment.development,
      );
      real.setAccessToken('fixture-session');
      real.setPOSOperatorToken('fixture-operator');
      final headers = await real.authenticatedRequestHeaders();
      expect(headers['x-pos-operator-token'], 'fixture-operator');
      real.setPOSOperatorToken(null);
      expect(
        (await real.authenticatedRequestHeaders()).containsKey(
          'x-pos-operator-token',
        ),
        false,
      );
    },
  );
  void response(Map<String, dynamic> data) {
    provider.client = GraphQLClient(
      cache: GraphQLCache(),
      link: Link.function((request, [forward]) async* {
        yield Response(data: {'__typename': 'Query', ...data}, response: {});
      }),
    );
  }

  test(
    'profile loads from server with absolute logo URL and scoped offline cache',
    () async {
      response({'GetMyPOSBusinessProfile': _data});
      final repository = PosBusinessProfileRepository(provider, prefs);
      final loaded = await repository.getProfile();
      expect(
        loaded.getOrElse(() => throw StateError('failed')).logo,
        'http://localhost:8080/static/tenant/logo/fixture.png',
      );
      provider.client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          throw OperationException(
            linkException: ServerException(originalException: 'offline'),
          );
        }),
      );
      final cached = await repository.getProfile();
      expect(cached.getOrElse(() => throw StateError('failed')).cached, true);
      provider.subscriptionScope = 'endpoint|other-tenant|user|operator';
      expect((await repository.getProfile()).isLeft(), true);
    },
  );

  test(
    'permission errors never fall back to a previous cached profile',
    () async {
      response({'GetMyPOSBusinessProfile': _data});
      final repository = PosBusinessProfileRepository(provider, prefs);
      await repository.getProfile();
      provider.client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          yield const Response(
            errors: [
              GraphQLError(
                message: 'denied',
                extensions: {'code': 'FORBIDDEN'},
              ),
            ],
            response: {},
          );
        }),
      );
      expect((await repository.getProfile()).isLeft(), true);
    },
  );

  test(
    'save without image sends only profile fields and explicit remove flag',
    () async {
      Map<String, dynamic>? variables;
      provider.client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          variables = request.variables;
          yield const Response(
            data: {
              '__typename': 'Mutation',
              'UpdateMyPOSBusinessProfile': _data,
            },
            response: {},
          );
        }),
      );
      final repository = PosBusinessProfileRepository(provider, prefs);
      expect(
        (await repository.save(
          name: ' Usaha Uji ',
          phone: '081234567890',
          removeLogo: true,
        )).isRight(),
        true,
      );
      expect(variables?['input'], {
        'name': 'Usaha Uji',
        'phone': '081234567890',
        'remove_logo': true,
      });
      expect((variables?['input'] as Map).containsKey('instansi_id'), false);
    },
  );

  test(
    'logo upload follows GraphQL multipart mapping and retains auth headers',
    () async {
      final client = _Upload();
      final repository = PosBusinessProfileRepository(
        provider,
        prefs,
        uploadClient: client,
      );
      final result = await repository.save(
        name: 'Usaha Uji',
        phone: '081234567890',
        logo: PickedProductImage(
          name: 'logo.jpg',
          bytes: Uint8List.fromList([255, 216, 255]),
        ),
      );
      expect(result.isRight(), true);
      expect(client.request.headers['Authorization'], 'Bearer fixture');
      expect(jsonDecode(client.request.fields['map']!), {
        '0': ['variables.logo'],
      });
      expect(
        jsonDecode(client.request.fields['operations']!)['variables']['logo'],
        isNull,
      );
      expect(client.request.files.single.contentType.toString(), 'image/jpeg');
    },
  );

  test(
    'upload reports GraphQL permission denial instead of pretending to save',
    () async {
      final client = _Upload()
        ..payload = {
          'errors': [
            {
              'message': 'denied',
              'extensions': {'code': 'FORBIDDEN'},
            },
          ],
        };
      final repository = PosBusinessProfileRepository(
        provider,
        prefs,
        uploadClient: client,
      );
      final result = await repository.save(
        name: 'Usaha Uji',
        phone: '081234567890',
        logo: PickedProductImage(
          name: 'logo.png',
          bytes: Uint8List.fromList([1]),
        ),
      );
      expect(result.isLeft(), true);
      expect(prefs.getKeys(), isEmpty);
    },
  );

  test(
    'late profile response cannot populate a different identity cache',
    () async {
      final pending = Completer<void>();
      provider.client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          await pending.future;
          yield const Response(
            data: {'__typename': 'Query', 'GetMyPOSBusinessProfile': _data},
            response: {},
          );
        }),
      );
      final result = PosBusinessProfileRepository(provider, prefs).getProfile();
      await Future<void>.delayed(Duration.zero);
      provider.subscriptionScope = 'endpoint|other|user|operator';
      pending.complete();
      expect(
        (await result).fold((failure) => failure is AuthFailure, (_) => false),
        true,
      );
      expect(prefs.getKeys(), isEmpty);
    },
  );

  test(
    'invalid, empty and oversized files are rejected before upload',
    () async {
      final repository = PosBusinessProfileRepository(provider, prefs);
      for (final image in [
        PickedProductImage(name: 'a.png', bytes: Uint8List(0)),
        PickedProductImage(name: 'a.html', bytes: Uint8List(1)),
        PickedProductImage(
          name: 'a.png',
          bytes: Uint8List(5 * 1024 * 1024 + 1),
        ),
      ]) {
        expect(
          (await repository.save(
            name: 'Usaha',
            phone: '081234567890',
            logo: image,
          )).isLeft(),
          true,
        );
      }
    },
  );
}
