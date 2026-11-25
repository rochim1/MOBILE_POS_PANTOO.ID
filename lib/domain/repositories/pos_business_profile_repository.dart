import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/error/error_handler.dart';
import '../../core/error/failures.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../core/network/offline_network_failure.dart';
import '../../core/utils/product_image_picker.dart';

class PosBusinessProfile {
  const PosBusinessProfile({
    required this.id,
    required this.name,
    required this.phone,
    this.address = '',
    this.logo = '',
    this.cached = false,
  });
  final String id, name, phone, address, logo;
  final bool cached;
  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'phone': phone,
    'address': address,
    'logo': logo,
  };
}

String? businessLogoValidation(PickedProductImage image) {
  if (image.bytes.isEmpty) return 'File logo kosong';
  if (image.bytes.length > 5 * 1024 * 1024) return 'Ukuran logo maksimal 5 MB';
  if (![
    'jpg',
    'jpeg',
    'png',
    'webp',
  ].contains(image.name.split('.').last.toLowerCase())) {
    return 'Logo harus JPG, PNG, atau WebP';
  }
  return null;
}

class PosBusinessProfileRepository {
  PosBusinessProfileRepository(
    this.provider,
    this.prefs, {
    this.uploadClient,
    this.onSaved,
  });
  final GraphQLClientProvider provider;
  final SharedPreferences prefs;
  final http.Client? uploadClient;
  final void Function(PosBusinessProfile)? onSaved;
  static const query = r'''query GetMyPOSBusinessProfile {
    GetMyPOSBusinessProfile { _id name phone address logo }
  }''';
  static const mutation =
      r'''mutation UpdateMyPOSBusinessProfile($input: POSBusinessProfileInput!, $logo: Upload) {
    UpdateMyPOSBusinessProfile(input: $input, logo: $logo) { _id name phone address logo }
  }''';
  String _key(String scope) =>
      'pos_business_profile_v1:${Uri.encodeComponent(scope)}';
  PosBusinessProfile _decode(Map data, {bool cached = false}) {
    if (data['_id'] == null || data['name'] == null) {
      throw const FormatException('Profil usaha tidak lengkap');
    }
    return PosBusinessProfile(
      id: data['_id'].toString(),
      name: data['name'].toString(),
      phone: data['phone']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      logo: provider.resolveMediaUrl(data['logo']),
      cached: cached,
    );
  }

  Future<void> _cache(String scope, PosBusinessProfile value) async {
    if (scope != provider.subscriptionScope) return;
    try {
      await prefs.setString(_key(scope), jsonEncode(value.toJson()));
    } catch (_) {
      /* Optional cache. */
    }
  }

  Future<Either<Failure, PosBusinessProfile>> getProfile() async {
    final scope = provider.subscriptionScope;
    if (scope.isEmpty) {
      return const Left(AuthFailure('Sesi instansi tidak tersedia'));
    }
    try {
      final result = await provider.client
          .query(
            QueryOptions(
              document: gql(query),
              fetchPolicy: FetchPolicy.networkOnly,
            ),
          )
          .timeout(const Duration(seconds: 20));
      if (result.hasException) throw result.exception!;
      if (scope != provider.subscriptionScope) {
        return const Left(AuthFailure('Sesi telah berubah'));
      }
      final profile = _decode(result.data?['GetMyPOSBusinessProfile'] as Map);
      await _cache(scope, profile);
      return Right(profile);
    } catch (error) {
      if (scope == provider.subscriptionScope && isOfflineReadFailure(error)) {
        try {
          final raw = prefs.getString(_key(scope));
          if (raw != null) {
            return Right(_decode(jsonDecode(raw) as Map, cached: true));
          }
        } catch (_) {
          /* Invalid cache must not block retry. */
        }
      }
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, PosBusinessProfile>> save({
    required String name,
    required String phone,
    String? address,
    PickedProductImage? logo,
    bool removeLogo = false,
  }) async {
    final scope = provider.subscriptionScope;
    if (scope.isEmpty) {
      return const Left(AuthFailure('Sesi instansi tidak tersedia'));
    }
    if (logo != null) {
      final error = businessLogoValidation(logo);
      if (error != null) return Left(ServerFailure(error));
      if (removeLogo) {
        return const Left(
          ServerFailure('Pilih unggah atau hapus logo, bukan keduanya'),
        );
      }
    }
    final input = {
      'name': name.trim(),
      'phone': phone.trim(),
      if (address != null) 'address': address.trim(),
      if (removeLogo) 'remove_logo': true,
    };
    try {
      Map<String, dynamic>? data;
      if (logo == null) {
        final result = await provider.client
            .mutate(
              MutationOptions(
                document: gql(mutation),
                variables: {'input': input},
                fetchPolicy: FetchPolicy.networkOnly,
              ),
            )
            .timeout(const Duration(seconds: 25));
        if (result.hasException) throw result.exception!;
        data = result.data;
      } else {
        data = await _upload(
          input,
          logo,
          scope,
        ).timeout(const Duration(seconds: 25));
      }
      if (scope != provider.subscriptionScope) {
        return const Left(AuthFailure('Sesi telah berubah'));
      }
      final profile = _decode(data?['UpdateMyPOSBusinessProfile'] as Map);
      await _cache(scope, profile);
      if (scope == provider.subscriptionScope) onSaved?.call(profile);
      return Right(profile);
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Map<String, dynamic>> _upload(
    Map<String, dynamic> input,
    PickedProductImage image,
    String expectedScope,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(provider.endpointUrl),
    );
    request.headers.addAll(await provider.authenticatedRequestHeaders());
    if (provider.subscriptionScope != expectedScope) {
      throw const AuthFailure(
        'Sesi telah berubah. Silakan ulangi dari akun yang aktif.',
      );
    }
    request.fields['operations'] = jsonEncode({
      'query': mutation,
      'variables': {'input': input, 'logo': null},
    });
    request.fields['map'] = jsonEncode({
      '0': ['variables.logo'],
    });
    final extension = image.name.split('.').last.toLowerCase();
    request.files.add(
      http.MultipartFile.fromBytes(
        '0',
        image.bytes,
        filename: image.name,
        contentType: MediaType(
          'image',
          extension == 'jpg' ? 'jpeg' : extension,
        ),
      ),
    );
    final streamed = uploadClient == null
        ? await request.send()
        : await uploadClient!.send(request);
    final response = await http.Response.fromStream(streamed);
    final payload = jsonDecode(response.body) as Map;
    final errors = payload['errors'];
    if (errors is List && errors.isNotEmpty) {
      throw OperationException(
        graphqlErrors: errors
            .map(
              (e) => GraphQLError(
                message:
                    (e as Map)['message']?.toString() ?? 'Unggah logo gagal',
                extensions: e['extensions'] is Map
                    ? Map<String, dynamic>.from(e['extensions'] as Map)
                    : null,
              ),
            )
            .toList(),
      );
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        payload['data'] is! Map) {
      throw const ServerFailure(
        'Logo belum berhasil diunggah. Periksa koneksi lalu coba lagi.',
      );
    }
    return Map<String, dynamic>.from(payload['data'] as Map);
  }
}
