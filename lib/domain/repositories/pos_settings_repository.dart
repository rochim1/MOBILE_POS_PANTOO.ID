import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mobile_pos_pantoo/core/error/error_handler.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/data/graphql/pos_settings_queries.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_settings.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pos_remote_profile_catalog.dart';

class PosSettingsRepository {
  final GraphQLClientProvider _clientProvider;

  PosSettingsRepository(this._clientProvider);

  Future<PosRemoteProfileCatalog> getProfileCatalog() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      /* Cache is optional. */
    }
    final key =
        'pos_profile_catalog_v1:${prefs?.getString('instansi_id') ?? 'unknown'}';
    try {
      final result = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosSettingsQueries.getProfileCatalog),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) throw result.exception!;
      final value = result.data?['GetPOSProfileCatalog'];
      if (value is! Map) {
        throw const FormatException('Katalog profil tidak tersedia');
      }
      final catalog = PosRemoteProfileCatalog.fromJson(
        Map<String, dynamic>.from(value),
      );
      try {
        await prefs?.setString(key, jsonEncode(catalog.toJson()));
      } catch (_) {
        /* Cache is optional. */
      }
      return catalog;
    } catch (_) {
      try {
        final raw = prefs?.getString(key);
        if (raw != null) {
          return PosRemoteProfileCatalog.fromJson(
            Map<String, dynamic>.from(jsonDecode(raw) as Map),
            source: 'cache',
          );
        }
      } catch (_) {
        /* Ignore invalid offline cache. */
      }
      return PosRemoteProfileCatalog.bundled();
    }
  }

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

  Future<Either<Failure, bool>> markOperationalSetupCompleted() async {
    try {
      final result = await _clientProvider.client.mutate(
        MutationOptions(
          document: gql(PosSettingsQueries.markOperationalSetupCompleted),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (result.hasException) {
        return Left(AppErrorHandler.handle(result.exception!));
      }
      return Right(result.data?['MarkPOSOperationalSetupCompleted'] == true);
    } catch (e) {
      return Left(AppErrorHandler.handle(e));
    }
  }
}
