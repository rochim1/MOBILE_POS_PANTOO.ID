import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/domain/repositories/auth_repository.dart';

class _Provider extends Fake implements GraphQLClientProvider {
  @override
  late GraphQLClient client;
  String? currentToken;

  @override
  void setAccessToken(String? token) => currentToken = token;
}

String _token(String userId) =>
    'header.${base64Url.encode(utf8.encode(jsonEncode({'_id': userId})))}.signature';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'needs_workspace_setup': true,
      'username': 'Operator QA',
      'user_id': 'old-user',
    });
    FlutterSecureStorage.setMockInitialValues({
      'auth_token': _token('old-user'),
      'refresh_token': 'old-refresh',
    });
  });

  test(
    'unprovisioned but valid account is checked online before setup',
    () async {
      final provider = _Provider();
      final operations = <String>[];
      provider.client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          operations.add(request.operation.operationName ?? '');
          yield Response(
            data: {
              'GetOneUser': {'_id': 'old-user', 'instansi_id': null},
            },
            response: {},
          );
        }),
      );
      final prefs = await SharedPreferences.getInstance();
      final repository = AuthRepository(
        provider,
        prefs,
        const FlutterSecureStorage(),
      );

      expect(await repository.checkSession(), isTrue);
      expect(operations, hasLength(1));
      expect(provider.currentToken, isNotNull);
      expect(prefs.getBool('needs_workspace_setup'), isTrue);
    },
  );

  test(
    'removed account cannot open workspace setup with a stale token',
    () async {
      final provider = _Provider();
      provider.client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          yield Response(
            errors: [
              GraphQLError(
                message: 'Pengguna tidak ditemukan atau status tidak aktif',
                extensions: {'code': 'UNAUTHORIZED'},
              ),
            ],
            response: {},
          );
        }),
      );
      final prefs = await SharedPreferences.getInstance();
      const storage = FlutterSecureStorage();
      final repository = AuthRepository(provider, prefs, storage);

      expect(await repository.checkSession(), isFalse);
      expect(provider.currentToken, isNull);
      expect(await storage.read(key: 'auth_token'), isNull);
      expect(await storage.read(key: 'refresh_token'), isNull);
      expect(prefs.getBool('needs_workspace_setup'), isNull);
    },
  );
}
