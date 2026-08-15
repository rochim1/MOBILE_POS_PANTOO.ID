import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mobile_pos_pantoo/core/error/error_handler.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/data/graphql/pos_settings_queries.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_settings.dart';

class PosSettingsRepository {
  final GraphQLClientProvider _clientProvider;

  PosSettingsRepository(this._clientProvider);

  Future<Either<Failure, PosSettings>> getSettings() async {
    try {
      final options = QueryOptions(
        document: gql(PosSettingsQueries.getSettings),
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final result = await _clientProvider.client.query(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final data = result.data?['GetInventorySettings']?['pos_defaults'];
      if (data == null) {
        return const Left(ServerFailure('Data pengaturan tidak ditemukan'));
      }

      return Right(PosSettings.fromJson(data as Map<String, dynamic>));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<Either<Failure, PosSettings>> updateSettings(
    Map<String, dynamic> input,
  ) async {
    try {
      final options = MutationOptions(
        document: gql(PosSettingsQueries.updateDefaults),
        variables: {'input': input},
        fetchPolicy: FetchPolicy.networkOnly,
      );

      final result = await _clientProvider.client.mutate(options);

      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final data = result.data?['UpdatePOSDefaults']?['pos_defaults'];
      if (data == null) {
        return const Left(ServerFailure('Gagal menyimpan pengaturan'));
      }

      return Right(PosSettings.fromJson(data as Map<String, dynamic>));
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }
}
