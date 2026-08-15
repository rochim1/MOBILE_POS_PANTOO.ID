import 'dart:convert';

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../../core/error/error_handler.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../data/graphql/pos_queries.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../data/datasources/local/pos_local_database.dart';
import '../../core/utils/logger.dart';
import '../../core/database/database_platform_initializer.dart';

class AuthRepository {
  final GraphQLClientProvider _clientProvider;
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  AuthRepository(this._clientProvider, this._prefs, this._secureStorage);

  String? _userIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final userId = payload is Map ? payload['_id']?.toString() : null;
      return userId == null || userId.isEmpty ? null : userId;
    } catch (_) {
      return null;
    }
  }

  Future<Either<Failure, String>> login(
    String username,
    String password,
  ) async {
    try {
      final MutationOptions options = MutationOptions(
        document: gql(PosQueries.login),
        variables: {
          'input': {'email_or_username': username, 'password': password},
        },
      );

      appLogger.i('[Auth] Attempting login for: $username');
      final QueryResult result = await _clientProvider.client.mutate(options);
      appLogger.d(
        '[Auth] Result received. hasException: ${result.hasException}, '
        'hasToken: ${result.data?['Login']?['token'] != null}',
      );

      if (result.hasException) {
        appLogger.e('[Auth] GraphQL request failed', error: result.exception);
        if (result.exception?.linkException != null) {
          appLogger.e(
            '[Auth] LinkException',
            error: result.exception!.linkException,
          );
          appLogger.d(
            '❌ [Auth] LinkException type: ${result.exception!.linkException.runtimeType}',
          );
        }
        if (result.exception?.graphqlErrors.isNotEmpty == true) {
          appLogger.e(
            '[Auth] GraphQL errors: ${result.exception!.graphqlErrors}',
          );
        }
        return Left(AppErrorHandler.handle(result.exception!));
      }

      final data = result.data?['Login'];
      if (data != null && data['token'] != null) {
        final name = data['user']?['name'] ?? username;
        final token = data['token']
            .toString()
            .replaceFirst(RegExp(r'^Bearer\s+', caseSensitive: false), '')
            .trim();
        if (token.isEmpty) {
          return const Left(ServerFailure('Token login tidak valid'));
        }
        await _secureStorage.write(key: 'auth_token', value: token);
        final persistedToken = await _secureStorage.read(key: 'auth_token');
        if (persistedToken == null || persistedToken.trim().isEmpty) {
          return const Left(
            ServerFailure('Sesi login gagal disimpan dengan aman'),
          );
        }
        await _prefs.setString('username', name);
        final userId = data['user']?['_id']?.toString();
        if (userId != null && userId.isNotEmpty) {
          await _prefs.setString('user_id', userId);
        }
        final instansiId = data['user']?['instansi_id']?['_id']?.toString();
        if (instansiId != null && instansiId.isNotEmpty) {
          await _prefs.setString('instansi_id', instansiId);
        }
        // Rebuild only after both the credential and tenant context exist.
        _clientProvider.setAccessToken(token);
        final sessionCheck = await _clientProvider.client.query(
          QueryOptions(
            document: gql(PosQueries.getPOSRuntimeConfig),
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        );
        if (sessionCheck.hasException ||
            sessionCheck.data?['GetPOSRuntimeConfig'] == null) {
          _clientProvider.setAccessToken(null);
          await _secureStorage.delete(key: 'auth_token');
          await _prefs.remove('username');
          await _prefs.remove('instansi_id');
          return Left(
            sessionCheck.hasException
                ? AppErrorHandler.handle(sessionCheck.exception!)
                : const AuthFailure(
                    'Akun tidak memiliki konteks instansi POS yang valid',
                  ),
          );
        }
        final effectiveInstansiId = sessionCheck
            .data?['GetPOSRuntimeConfig']?['instansi_id']
            ?.toString();
        if (effectiveInstansiId != null && effectiveInstansiId.isNotEmpty) {
          await _prefs.setString('instansi_id', effectiveInstansiId);
        }
        await _prefs.setString(
          'pos_runtime_config',
          jsonEncode(sessionCheck.data!['GetPOSRuntimeConfig']),
        );
        appLogger.i('[Auth] Login success for: $name');
        return Right(name);
      }
      appLogger.e('[Auth] No token in response data: ${result.data}');
      return const Left(ServerFailure('Format respon tidak valid'));
    } catch (e, stackTrace) {
      appLogger.e(
        '[Auth] Unexpected login error',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(AppErrorHandler.handle(e));
    }
  }

  Future<void> logout() async {
    _clientProvider.setAccessToken(null);
    await _secureStorage.delete(key: 'auth_token');
    await _prefs.remove('username');
    await _prefs.remove('user_id');
    await _prefs.remove('instansi_id');
    await _prefs.remove('pos_runtime_config');
    if (!supportsOfflineDatabase) return;
    try {
      final db = await PosLocalDatabase.instance.database;
      await db.transaction((txn) async {
        await txn.delete('products');
        await txn.delete('customers');
        await txn.delete('stores');
        await txn.delete('employees');
        await txn.delete('held_orders');
      });
    } catch (error, stackTrace) {
      // A database/cache failure must never trap the user in an expired
      // authenticated session. Credentials above are already revoked.
      appLogger.w(
        '[Auth] Cache lokal gagal dibersihkan saat logout',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> checkSession() async {
    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null || token.trim().isEmpty) return false;
    final restoredUserId = _userIdFromToken(token);
    if (restoredUserId != null) {
      await _prefs.setString('user_id', restoredUserId);
    }
    _clientProvider.setAccessToken(token);
    try {
      final result = await _clientProvider.client.query(
        QueryOptions(
          document: gql(PosQueries.getPOSRuntimeConfig),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
      );
      if (!result.hasException && result.data?['GetPOSRuntimeConfig'] != null) {
        final effectiveInstansiId = result
            .data?['GetPOSRuntimeConfig']?['instansi_id']
            ?.toString();
        if (effectiveInstansiId != null && effectiveInstansiId.isNotEmpty) {
          await _prefs.setString('instansi_id', effectiveInstansiId);
        }
        await _prefs.setString(
          'pos_runtime_config',
          jsonEncode(result.data!['GetPOSRuntimeConfig']),
        );
        return true;
      }
      if (result.hasException &&
          AppErrorHandler.handle(result.exception!) is! AuthFailure) {
        return true;
      }
    } catch (_) {
      // Keep the locally authenticated session when the server is offline.
      return true;
    }
    _clientProvider.setAccessToken(null);
    await _secureStorage.delete(key: 'auth_token');
    await _prefs.remove('username');
    await _prefs.remove('user_id');
    await _prefs.remove('instansi_id');
    await _prefs.remove('pos_runtime_config');
    return false;
  }

  String? getSavedUsername() {
    final name = _prefs.getString('username')?.trim();
    return name == null || name.isEmpty ? null : name;
  }
}
