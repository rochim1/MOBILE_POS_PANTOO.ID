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
}
