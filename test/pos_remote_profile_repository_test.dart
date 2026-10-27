import 'dart:convert';
import 'package:mobile_pos_pantoo/data/graphql/pos_settings_queries.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_remote_profile_catalog.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_settings_repository.dart';

class _Provider implements GraphQLClientProvider {
  @override
  final GraphQLClient client;
  static late GraphQLClient latestClient;
  _Provider(this.client) {
    latestClient = client;
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final payload =
      jsonDecode(jsonEncode(PosRemoteProfileCatalog.bundled().toJson()))
          as Map<String, dynamic>;
  (payload['profiles'] as List).add({
    ...Map<String, dynamic>.from((payload['profiles'] as List).first),
    'value': 'backend_only',
    'label': 'Profil Server Baru',
  });
  payload['__typename'] = 'POSProfileCatalog';
  for (final feature in payload['features'] as List) {
    feature['__typename'] = 'POSProfileFeatureOption';
  }
  for (final row in payload['profiles'] as List) {
    row['icon'] = 'ri-store-2-line';
    row['__typename'] = 'POSBusinessProfile';
    for (final option in row['fulfillment_options'] as List) {
      option['__typename'] = 'POSProfileFulfillmentOption';
    }
  }
  PosSettingsRepository repository({bool offline = false}) =>
      PosSettingsRepository(
        _Provider(
          GraphQLClient(
            cache: GraphQLCache(),
            link: Link.function((request, [forward]) async* {
              if (offline) throw Exception('offline');
              yield Response(
                data: {'__typename': 'Query', 'GetPOSProfileCatalog': payload},
                response: {},
              );
            }),
          ),
        ),
      );
  test(
    'network catalog stores new backend-only profiles in tenant cache',
    () async {
      SharedPreferences.setMockInitialValues({'instansi_id': 'tenant-test'});
      final repo = repository();
      final raw = await _Provider.latestClient.query(
        QueryOptions(
          document: gql(PosSettingsQueries.getProfileCatalog),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      expect(raw.exception, isNull);
      final catalog = await repo.getProfileCatalog();
      expect(catalog.source, 'backend');
      expect(catalog.profile('backend_only')?.label, 'Profil Server Baru');
      final prefs = await SharedPreferences.getInstance();
      expect(
        jsonDecode(
          prefs.getString('pos_profile_catalog_v1:tenant-test')!,
        )['profiles'],
        hasLength(8),
      );
    },
  );
  test('network failure uses last valid tenant catalog', () async {
    SharedPreferences.setMockInitialValues({
      'instansi_id': 'tenant-test',
      'pos_profile_catalog_v1:tenant-test': jsonEncode(payload),
    });
    final catalog = await repository(offline: true).getProfileCatalog();
    expect(catalog.source, 'cache');
    expect(catalog.profile('backend_only'), isNotNull);
  });
  test('corrupt offline cache uses bundled fallback', () async {
    SharedPreferences.setMockInitialValues({
      'instansi_id': 'tenant-test',
      'pos_profile_catalog_v1:tenant-test': 'broken',
    });
    expect(
      (await repository(offline: true).getProfileCatalog()).source,
      'bundled',
    );
  });
}
