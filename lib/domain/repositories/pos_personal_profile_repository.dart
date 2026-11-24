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

class PosPersonalProfile {
  const PosPersonalProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.address,
    required this.photo,
    required this.version,
    this.cached = false,
  });
  final String id, name, username, email, phone, address, photo, version;
  final bool cached;
  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'username': username,
    'email': email,
    'phone': phone,
    'address': address,
    'photo': photo,
    'version': version,
  };
}

String? personalPhotoValidation(PickedProductImage image) {
  if (image.bytes.isEmpty) return 'File foto kosong';
  if (image.bytes.length > 5 * 1024 * 1024) return 'Ukuran foto maksimal 5 MB';
  if (![
    'jpg',
    'jpeg',
    'png',
    'webp',
  ].contains(image.name.split('.').last.toLowerCase())) {
    return 'Foto harus JPG, PNG, atau WebP';
  }
  return null;
}

class PosPersonalProfileRepository {
  PosPersonalProfileRepository(this.provider, this.prefs, {this.uploadClient});
  final GraphQLClientProvider provider;
  final SharedPreferences prefs;
  final http.Client? uploadClient;
  static const query =
      r'''query GetMyPOSPersonalProfile {GetMyPOSPersonalProfile {_id name username email phone address photo version}}''';
  static const mutation =
      r'''mutation UpdateMyPOSPersonalProfile($input:POSPersonalProfileInput!,$photo:Upload){UpdateMyPOSPersonalProfile(input:$input,photo:$photo){_id name username email phone address photo version}}''';
  String _key(String scope) =>
      'pos_personal_profile_v1:${Uri.encodeComponent(scope)}';
  PosPersonalProfile _decode(Map value, {bool cached = false}) {
    if (value['_id'] == null ||
        value['name'] == null ||
        value['version'] == null) {
      throw const FormatException('Profil tidak lengkap');
    }
    return PosPersonalProfile(
      id: value['_id'].toString(),
      name: value['name'].toString(),
      username: value['username']?.toString() ?? '',
      email: value['email']?.toString() ?? '',
      phone: value['phone']?.toString() ?? '',
      address: value['address']?.toString() ?? '',
      photo: provider.resolveMediaUrl(value['photo']),
      version: value['version'].toString(),
      cached: cached,
    );
  }

  Future<void> _cache(String scope, PosPersonalProfile value) async {
    if (scope != provider.subscriptionScope) return;
    try {
      await prefs.setString(_key(scope), jsonEncode(value.toJson()));
    } catch (_) {
      /* Optional display cache, never an authorization grant. */
    }
  }

  Future<Either<Failure, PosPersonalProfile>> getProfile() async {
    final scope = provider.subscriptionScope;
    if (scope.isEmpty) {
      return const Left(AuthFailure('Sesi kasir tidak tersedia'));
    }
    try {
      final result = await provider.client
          .query(
            QueryOptions(
              document: gql(query),
              fetchPolicy: FetchPolicy.networkOnly,
            ),
          )
          .timeout(const Duration(seconds: 15));
      if (result.hasException) throw result.exception!;
      if (scope != provider.subscriptionScope) {
        return const Left(AuthFailure('Sesi telah berubah'));
      }
      final profile = _decode(result.data?['GetMyPOSPersonalProfile'] as Map);
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
          /* Invalid cache does not block retry. */
        }
      }
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Either<Failure, PosPersonalProfile>> save({
    required String name,
    required String phone,
    required String address,
    required String expectedVersion,
    PickedProductImage? photo,
    bool removePhoto = false,
  }) async {
    final scope = provider.subscriptionScope;
    if (scope.isEmpty) {
      return const Left(AuthFailure('Sesi kasir tidak tersedia'));
    }
    if (name.trim().isEmpty ||
        name.trim().length > 160 ||
        address.trim().length > 1000 ||
        (phone.trim().isNotEmpty &&
            !RegExp(r'^\+?\d{8,15}$').hasMatch(phone.trim()))) {
      return const Left(
        ServerFailure('Nama, nomor telepon, atau alamat tidak valid'),
      );
    }
    if (photo != null) {
      final error = personalPhotoValidation(photo);
      if (error != null) return Left(ServerFailure(error));
      if (removePhoto) {
        return const Left(
          ServerFailure('Pilih unggah atau hapus foto, bukan keduanya'),
        );
      }
    }
    final input = <String, dynamic>{
      'name': name.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'expected_version': expectedVersion,
      if (removePhoto) 'remove_photo': true,
    };
    try {
      Map<String, dynamic>? data;
      if (photo == null) {
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
          photo,
          scope,
        ).timeout(const Duration(seconds: 25));
      }
      if (scope != provider.subscriptionScope) {
        return const Left(AuthFailure('Sesi telah berubah'));
      }
      final profile = _decode(data?['UpdateMyPOSPersonalProfile'] as Map);
      await _cache(scope, profile);
      if (profile.id == prefs.getString('user_id')) {
        await prefs.setString('username', profile.name);
      }
      return Right(profile);
    } catch (error) {
      return Left(AppErrorHandler.handle(error));
    }
  }

  Future<Map<String, dynamic>> _upload(
    Map<String, dynamic> input,
    PickedProductImage image,
    String scope,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(provider.endpointUrl),
    );
    request.headers.addAll(await provider.authenticatedRequestHeaders());
    if (scope != provider.subscriptionScope) {
      throw const AuthFailure('Sesi telah berubah');
    }
    request.fields['operations'] = jsonEncode({
      'query': mutation,
      'variables': {'input': input, 'photo': null},
    });
    request.fields['map'] = jsonEncode({
      '0': ['variables.photo'],
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
    final response = await http.Response.fromStream(
      await (uploadClient == null
          ? request.send()
          : uploadClient!.send(request)),
    );
    final payload = jsonDecode(response.body) as Map;
    final errors = payload['errors'];
    if (errors is List && errors.isNotEmpty) {
      throw OperationException(
        graphqlErrors: errors
            .map(
              (e) => GraphQLError(
                message:
                    (e as Map)['message']?.toString() ?? 'Unggah foto gagal',
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
        'Foto belum berhasil diunggah. Periksa koneksi lalu coba lagi.',
      );
    }
    return Map<String, dynamic>.from(payload['data'] as Map);
  }
}
