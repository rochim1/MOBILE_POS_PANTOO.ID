import 'package:graphql_flutter/graphql_flutter.dart';
import '../network/graphql_client_provider.dart';

abstract class PosPushTokenRepository {
  Future<void> register({
    required String token,
    required String projectId,
    required String installationId,
  });
  Future<void> unregister({
    required String token,
    required String installationId,
  });
}

class GraphqlPosPushTokenRepository implements PosPushTokenRepository {
  GraphqlPosPushTokenRepository(this.provider);
  final GraphQLClientProvider provider;

  @override
  Future<void> register({
    required String token,
    required String projectId,
    required String installationId,
  }) async {
    final result = await provider.client
        .mutate(
          MutationOptions(
            document: gql(r'''mutation RegisterPOSPush($input: messagingInput) {
        saveDeviceAppsID(input: $input) { apps_id }
      }'''),
            variables: {
              'input': {
                'apps_id': token,
                'device': 'mobile',
                'model_device': 'Pantoo POS Android',
                'firebase_project_id': projectId,
                'client_app': 'pantoo_pos',
                'installation_id': installationId,
              },
            },
          ),
        )
        .timeout(const Duration(seconds: 10));
    if (result.hasException ||
        result.data?['saveDeviceAppsID']?['apps_id'] != token) {
      throw StateError('POS push registration failed');
    }
  }

  @override
  Future<void> unregister({
    required String token,
    required String installationId,
  }) async {
    final result = await provider.client
        .mutate(
          MutationOptions(
            document: gql(r'''mutation RemovePOSPush($input: messagingInput) {
        removeDeviceAppsID(input: $input)
      }'''),
            variables: {
              'input': {
                'apps_id': token,
                'client_app': 'pantoo_pos',
                'installation_id': installationId,
              },
            },
          ),
        )
        .timeout(const Duration(seconds: 3));
    if (result.hasException) throw StateError('POS push removal failed');
  }
}
