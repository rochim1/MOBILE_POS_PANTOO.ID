import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chucker_flutter/chucker_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/logger.dart';

class GraphQLClientProvider {
  final SharedPreferences sharedPreferences;
  final void Function()? onUnauthorized;
  final FlutterSecureStorage secureStorage;
  late GraphQLClient client;
  late String endpointUrl;
  String? _sessionToken;
  bool _unauthorizedNotified = false;
  DateTime? _tokenActivatedAt;
  Future<bool>? _refreshInFlight;

  GraphQLClientProvider(
    this.sharedPreferences,
    this.secureStorage, {
    this.onUnauthorized,
  }) {
    final customEndpoint = kDebugMode
        ? sharedPreferences.getString('custom_endpoint')
        : null;
    final envUrl = dotenv.env['API_URL'];
    endpointUrl = (customEndpoint != null && customEndpoint.isNotEmpty)
        ? customEndpoint
        : (envUrl ?? 'http://10.0.2.2:4000/graphql');

    appLogger.d('[GraphQL] custom_endpoint from prefs: "$customEndpoint"');
    appLogger.d('[GraphQL] API_URL from .env: "$envUrl"');
    appLogger.i('[GraphQL] USING ENDPOINT: "$endpointUrl"');

    _initClient();
  }

  void _initClient() {
    final httpLink = HttpLink(
      endpointUrl,
      httpClient: kDebugMode ? ChuckerHttpClient(http.Client()) : http.Client(),
      defaultHeaders: {
        'X-API-Key': dotenv.env['MOBILE_API_KEY'] ?? '',
        // POS is an internal-user client, but it must remain distinguishable
        // from the web admin application. Backend authentication resolves every
        // non-student/non-reseller channel against the internal user model.
        'apps': 'pos',
        'x-iid': sharedPreferences.getString('instansi_id') ?? '',
      },
    );

    final authLink = AuthLink(
      getToken: () async =>
          _sessionToken == null ? null : 'Bearer $_sessionToken',
    );

    final errorLink = ErrorLink(
      onGraphQLError: (request, forward, response) {
        final errors = response.errors;
        if (errors != null && errors.isNotEmpty) {
          for (final error in errors) {
            if (_shouldInvalidateSession(
              error.message,
              error.extensions?['code'],
            )) {
              return _refreshAndRetry(request, forward);
            }
          }
        }
        return null;
      },
      onException: (request, forward, exception) {
        // HttpLink places GraphQL errors returned together with HTTP 401 in a
        // ServerException. Inspect its parsed response so an expired session
        // cannot leave the app looping on fallback/offline data.
        if (exception is ServerException) {
          final errors = exception.parsedResponse?.errors ?? const [];
          for (final error in errors) {
            if (_shouldInvalidateSession(
              error.message,
              error.extensions?['code'],
            )) {
              return _refreshAndRetry(request, forward);
            }
          }
        }
        return null;
      },
    );

    final link = Link.from([errorLink, authLink, httpLink]);

    client = GraphQLClient(
      cache: GraphQLCache(store: InMemoryStore()),
      link: link,
      queryRequestTimeout: const Duration(seconds: 30),
    );
  }

  void setAccessToken(String? rawToken) {
    final token = rawToken
        ?.replaceFirst(RegExp(r'^Bearer\s+', caseSensitive: false), '')
        .trim();
    _sessionToken = token == null || token.isEmpty ? null : token;
    if (_sessionToken != null) {
      _unauthorizedNotified = false;
      _tokenActivatedAt = DateTime.now();
    } else {
      _tokenActivatedAt = null;
    }
    appLogger.d('[GraphQL] Session token tersedia: ${_sessionToken != null}');
    _initClient();
  }

  Stream<Response> _refreshAndRetry(Request request, NextLink forward) async* {
    final refreshed = await refreshAccessToken();
    if (refreshed) {
      yield* forward(request);
    } else {
      _notifyUnauthorized();
    }
  }

  Future<bool> refreshAccessToken() {
    final active = _refreshInFlight;
    if (active != null) return active;
    final future = _performRefresh();
    _refreshInFlight = future;
    return future.whenComplete(() {
      if (identical(_refreshInFlight, future)) _refreshInFlight = null;
    });
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await secureStorage.read(key: 'refresh_token');
    if (refreshToken == null || refreshToken.trim().isEmpty) return false;
    try {
      final response = await http.post(
        Uri.parse(endpointUrl),
        headers: {
          'content-type': 'application/json',
          'X-API-Key': dotenv.env['MOBILE_API_KEY'] ?? '',
          'apps': 'pos',
          'x-iid': sharedPreferences.getString('instansi_id') ?? '',
        },
        body: jsonEncode({
          'query': r'''mutation RefreshMobileSession($refreshToken: String!) {
            RefreshMobileSession(refresh_token: $refreshToken) {
              token refresh_token
            }
          }''',
          'variables': {'refreshToken': refreshToken},
        }),
      );
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final data = payload['data']?['RefreshMobileSession'] as Map?;
      final accessToken = data?['token']?.toString().trim() ?? '';
      final nextRefreshToken = data?['refresh_token']?.toString().trim() ?? '';
      if (response.statusCode >= 400 ||
          accessToken.isEmpty ||
          nextRefreshToken.isEmpty) {
        return false;
      }
      await secureStorage.write(key: 'auth_token', value: accessToken);
      await secureStorage.write(key: 'refresh_token', value: nextRefreshToken);
      _sessionToken = accessToken;
      _unauthorizedNotified = false;
      _tokenActivatedAt = DateTime.now();
      appLogger.i('[Auth] Access token berhasil diperbarui');
      return true;
    } catch (error, stackTrace) {
      appLogger.w(
        '[Auth] Refresh token gagal',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  bool _shouldInvalidateSession(String rawMessage, dynamic code) {
    final message = rawMessage.toLowerCase();
    final explicitlyExpired =
        code == 'UNAUTHENTICATED' ||
        message.contains('token kadaluarsa') ||
        message.contains('token expired');
    if (explicitlyExpired) return true;

    final ambiguousUnauthorized =
        message.contains('sesi pengguna atau instansi tidak valid') ||
        message.contains('bearer token invalid');
    if (!ambiguousUnauthorized) return false;

    // Requests dispatched by the previous anonymous client can finish just
    // after login. They must not revoke the newly issued token.
    final activatedAt = _tokenActivatedAt;
    if (activatedAt != null &&
        DateTime.now().difference(activatedAt) < const Duration(seconds: 3)) {
      appLogger.d('[GraphQL] Mengabaikan respons 401 dari request sesi lama');
      return false;
    }
    return true;
  }

  void _notifyUnauthorized() {
    if (_unauthorizedNotified || onUnauthorized == null) return;
    _unauthorizedNotified = true;
    onUnauthorized!();
  }

  Future<bool> hasAccessToken() async {
    final token = _sessionToken ?? await secureStorage.read(key: 'auth_token');
    return token != null && token.trim().isNotEmpty;
  }

  /// Rebuild the client (e.g. after changing custom endpoint)
  void rebuild() {
    final customEndpoint = kDebugMode
        ? sharedPreferences.getString('custom_endpoint')
        : null;
    final envUrl = dotenv.env['API_URL'];
    endpointUrl = (customEndpoint != null && customEndpoint.isNotEmpty)
        ? customEndpoint
        : (envUrl ?? 'http://10.0.2.2:4000/graphql');
    appLogger.i('[GraphQL] Rebuilding client with endpoint: "$endpointUrl"');
    _initClient();
  }
}
