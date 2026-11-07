import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';

class _Provider implements GraphQLClientProvider {
  @override
  final GraphQLClient client;
  @override
  String endpointUrl;
  _Provider(this.client, this.endpointUrl);
  @override
  void setPOSOperatorToken(String? token) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global =
      null; // This explicit loopback protocol test uses real HTTP, not widget HTTP mocks.
  const url = String.fromEnvironment('RETURN_DRAFT_QA_URL');
  test(
    'real Flutter repository recovers after HTTP connection is cut after Mongo commit',
    () async {
      expect(
        url,
        startsWith('http://127.0.0.1:'),
      ); // Must explicitly run a loopback disposable harness.
      Future<Map<String, dynamic>> get(String route) async =>
          jsonDecode(
                (await http.get(Uri.parse('$url/$route?client=mobile'))).body,
              )
              as Map<String, dynamic>;
      final fixture = await get('fixture');
      SharedPreferences.setMockInitialValues({
        'instansi_id': fixture['tenant'],
        'user_id': 'qa-http-terminal',
      });
      final prefs = await SharedPreferences.getInstance();
      PosRepository repository() {
        final client = GraphQLClient(
          cache: GraphQLCache(),
          link: HttpLink(
            '$url/graphql',
            defaultHeaders: {'x-qa-client': 'mobile'},
          ),
        );
        final repo = PosRepository(_Provider(client, '$url/graphql'), prefs);
        repo.setOperatorSessionToken('offline_operator:${fixture['actor']}');
        return repo;
      }

      final first = repository();
      expect(
        (await first.createSalesReturn(
          Map<String, dynamic>.from(fixture['input'] as Map),
        )).isLeft(),
        true,
      );
      final lost = await get('status');
      expect((lost['returns'] as List).length, 1);
      expect(first.pendingReturnDraft(), isNotNull);
      final restarted = repository();
      expect((await restarted.createSalesReturn(null)).isRight(), true);
      final finalState = await get('status');
      expect((finalState['returns'] as List).length, 1);
      expect(
        (finalState['returns'] as List).first['_id'],
        (lost['returns'] as List).first['_id'],
      );
      expect((finalState['requests'] as List).length, 2);
      expect((finalState['requests'] as List).toSet().length, 1);
      expect(finalState['journalCount'], 0);
      expect(finalState['sourceItemsUnchanged'], true);
      expect(restarted.pendingReturnDraft(), isNull);
    },
  );
}
