import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mobile_pos_pantoo/core/flavor/flavor_config.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('favorit pending terisolasi per akun dan dikirim saat online', () async {
    dotenv.loadFromString(envString: 'API_URL=http://localhost/graphql');
    SharedPreferences.setMockInitialValues({
      'instansi_id': 'tenant-a',
      'user_id': 'user-a',
      'pos_favorite_product_ids': <String>['favorite-from-old-account'],
    });
    final prefs = await SharedPreferences.getInstance();
    final provider = GraphQLClientProvider(
      prefs,
      const FlutterSecureStorage(),
      environment: FlavorEnvironment.development,
    );
    var rejectSave = true;
    final sentIds = <List<String>>[];
    provider.client = GraphQLClient(
      cache: GraphQLCache(store: InMemoryStore()),
      link: Link.function((request, [forward]) async* {
        if (request.variables.containsKey('productIds')) {
          sentIds.add(
            (request.variables['productIds'] as List)
                .map((value) => value.toString())
                .toList(),
          );
          yield Response(
            response: const {},
            data: rejectSave
                ? null
                : const {
                    '__typename': 'Mutation',
                    'SaveMyPOSFavoriteProductIds': true,
                  },
            errors: rejectSave
                ? [const GraphQLError(message: 'API belum tersedia')]
                : null,
          );
        } else {
          yield const Response(
            response: {},
            data: {'__typename': 'Query', 'GetMyPOSFavoriteProductIds': []},
          );
        }
      }),
    );
    final repository = PosRepository(provider, prefs);

    await repository.saveFavoriteProductIds({'product-a'});
    expect(
      prefs.getBool('pos_favorite_product_ids:tenant-a:user-a:pending'),
      isTrue,
    );
    expect(prefs.getStringList('pos_favorite_product_ids:tenant-a:user-a'), [
      'product-a',
    ]);

    await prefs.setString('user_id', 'user-b');
    expect(await repository.getFavoriteProductIds(), isEmpty);
    expect(prefs.getStringList('pos_favorite_product_ids'), isNull);

    await prefs.setString('user_id', 'user-a');
    rejectSave = false;
    await repository.syncPendingFavoriteProductIds();
    expect(sentIds.last, ['product-a']);
    expect(
      prefs.getBool('pos_favorite_product_ids:tenant-a:user-a:pending'),
      isFalse,
    );
  });
}
