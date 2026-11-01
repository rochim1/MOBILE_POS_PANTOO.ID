import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/flavor/flavor_config.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('production selalu menggunakan endpoint GraphQL Pantoo', () async {
    dotenv.loadFromString(envString: 'API_URL=http://localhost:4000/graphql');
    SharedPreferences.setMockInitialValues({
      'custom_endpoint': 'http://10.0.2.2:4000/graphql',
    });
    final preferences = await SharedPreferences.getInstance();

    final provider = GraphQLClientProvider(
      preferences,
      const FlutterSecureStorage(),
      environment: FlavorEnvironment.production,
    );

    expect(provider.endpointUrl, GraphQLClientProvider.productionEndpoint);
    expect(provider.endpointUrl, 'https://graphql.pantoo.id/');
  });
  test(
    'development menggunakan endpoint pilihan dan dapat kembali ke default',
    () async {
      dotenv.loadFromString(envString: 'API_URL=http://localhost:8080/graphql');
      SharedPreferences.setMockInitialValues({
        'custom_endpoint': 'http://localhost:9090/graphql',
      });
      final preferences = await SharedPreferences.getInstance();
      final provider = GraphQLClientProvider(
        preferences,
        const FlutterSecureStorage(),
        environment: FlavorEnvironment.development,
      );
      expect(provider.endpointUrl, 'http://localhost:9090/graphql');
      await preferences.remove('custom_endpoint');
      provider.rebuild();
      expect(provider.endpointUrl, GraphQLClientProvider.developmentEndpoint);
    },
  );
  test('development fallback tetap localhost 8080 tanpa API_URL', () async {
    dotenv.loadFromString(envString: 'MOBILE_API_KEY=test');
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final provider = GraphQLClientProvider(
      preferences,
      const FlutterSecureStorage(),
      environment: FlavorEnvironment.development,
    );
    expect(provider.endpointUrl, 'http://localhost:8080/graphql');
  });
  test('ganti operator membuang cache GraphQL operator sebelumnya', () async {
    dotenv.loadFromString(envString: 'MOBILE_API_KEY=test');
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final provider = GraphQLClientProvider(
      preferences,
      const FlutterSecureStorage(),
      environment: FlavorEnvironment.development,
    );
    final before = provider.client;
    provider.setPOSOperatorToken('operator-a');
    final first = provider.client;
    provider.setPOSOperatorToken('operator-b');
    expect(first, isNot(same(before)));
    expect(provider.client, isNot(same(first)));
    provider.setPOSOperatorToken('');
    expect(provider.client, isNot(same(first)));
  });
}
