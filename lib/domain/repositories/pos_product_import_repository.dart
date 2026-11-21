import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../../core/network/graphql_client_provider.dart';

class PosProductImportResult {
  final int importedCount, failedCount, skippedCount, totalProcessed;
  final String message;
  final List<String> stockItemIds;
  final List<Map<String, dynamic>> errors, warnings, previewRows;
  PosProductImportResult.fromJson(Map<String, dynamic> data)
    : importedCount = (data['importedCount'] as num?)?.toInt() ?? 0,
      failedCount = (data['failedCount'] as num?)?.toInt() ?? 0,
      skippedCount = (data['skippedCount'] as num?)?.toInt() ?? 0,
      totalProcessed = (data['totalProcessed'] as num?)?.toInt() ?? 0,
      message = data['message']?.toString() ?? '',
      stockItemIds = (data['stockItemIds'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      errors = _rows(data['errors']),
      warnings = _rows(data['warnings']),
      previewRows = _rows(data['previewRows']);
  static List<Map<String, dynamic>> _rows(dynamic value) =>
      (value as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
}

class PosProductImportRepository {
  final GraphQLClientProvider provider;
  final http.Client? client;
  PosProductImportRepository(this.provider, {this.client});
  static const template =
      'nama_inventaris,kode_inventaris,kategori,brand,model,unit,kondisi,lokasi_penyimpanan,harga_beli,harga_jual,supplier,stok_minimum,deskripsi,catatan,tags\n';
  static String requestId(List<int> bytes) =>
      'inventory-import-${sha256.convert(bytes)}-barang_dagangan';
  static const mutation =
      r'''mutation ImportPOSProducts($file: Upload!, $kategori: KategoriInventaris, $requestId: String, $preview: Boolean) {
    ImportInventarisUmum(file:$file, kategori:$kategori, request_id:$requestId, preview:$preview) {
      success message importedCount failedCount skippedCount totalProcessed stockItemIds importedIds
      errors { row no field message } warnings { row no field message }
      previewRows { row name unit price }
    }
  }''';
  String get _key => 'pos-product-import:${provider.subscriptionScope}';
  Map<String, dynamic>? get pending {
    final raw = provider.sharedPreferences.getString(_key);
    return raw == null
        ? null
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<PosProductImportResult>? _inFlight;
  Future<PosProductImportResult> upload({
    required Uint8List bytes,
    required String filename,
    required bool preview,
  }) => _inFlight ??= _upload(
    bytes,
    filename,
    preview,
  ).whenComplete(() => _inFlight = null);
  Future<PosProductImportResult> _upload(
    Uint8List bytes,
    String filename,
    bool preview,
  ) async {
    if (!const [
      'csv',
      'xls',
      'xlsx',
    ].contains(filename.split('.').last.toLowerCase())) {
      throw StateError('Pilih file Excel (.xlsx/.xls) atau CSV.');
    }
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw StateError('File harus berisi data dan maksimal 5 MB.');
    }
    final scope = provider.subscriptionScope, key = _key, id = requestId(bytes);
    if (scope.isEmpty || provider.requiresOperatorVerification) {
      throw StateError('Sesi belum siap. Buka PIN kembali.');
    }
    if (pending != null && pending!['request_id'] != id) {
      throw StateError(
        'Pilih file sebelumnya (${pending!['filename']}) untuk memeriksa hasil import yang belum pasti.',
      );
    }
    final denied = await provider.subscriptionGuard?.call({
      'ImportInventarisUmum',
    });
    if (denied != null) throw StateError(denied.message);
    final headers = await provider.authenticatedRequestHeaders();
    if (scope != provider.subscriptionScope) {
      throw StateError('Operator berubah. Buka ulang import.');
    }
    if (!preview &&
        !await provider.sharedPreferences.setString(
          key,
          jsonEncode({'filename': filename, 'request_id': id}),
        )) {
      throw StateError('Permintaan import belum dapat disimpan.');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(provider.endpointUrl),
    );
    request.headers.addAll({...headers, 'Apollo-Require-Preflight': 'true'});
    request.fields['operations'] = jsonEncode({
      'query': mutation,
      'variables': {
        'file': null,
        'kategori': 'barang_dagangan',
        'requestId': id,
        'preview': preview,
      },
    });
    request.fields['map'] = jsonEncode({
      '0': ['variables.file'],
    });
    request.files.add(
      http.MultipartFile.fromBytes('0', bytes, filename: filename),
    );
    final transport = client ?? http.Client();
    try {
      final response = await (() async => http.Response.fromStream(
        await transport.send(request),
      ))().timeout(const Duration(seconds: 60));
      final decoded = jsonDecode(response.body) as Map;
      final errors = decoded['errors'] as List? ?? [];
      if (errors.isNotEmpty) {
        final first = errors.first as Map;
        final code = (first['extensions'] as Map?)?['code'];
        if (!preview &&
            const [
              'BAD_REQUEST',
              'BAD_USER_INPUT',
              'FORBIDDEN',
              'UNAUTHORIZED',
              'UNAUTHENTICATED',
              'GRAPHQL_VALIDATION_FAILED',
            ].contains(code)) {
          await provider.sharedPreferences.remove(key);
        }
        throw StateError(first['message']?.toString() ?? 'Import gagal.');
      }
      final data = (decoded['data'] as Map?)?['ImportInventarisUmum'];
      if (response.statusCode != 200 || data is! Map) {
        throw StateError(
          'Hasil import belum pasti. Pilih file yang sama untuk konfirmasi.',
        );
      }
      final counts = ['importedCount','failedCount','skippedCount','totalProcessed'].map((key)=>data[key]).toList();
      if (counts.any((value)=>value is! num || !value.isFinite || value < 0 || value != value.round()) ||
          counts[0] + counts[1] + counts[2] != counts[3]) {
        throw StateError('Hasil import belum lengkap. Periksa kembali dengan file yang sama.');
      }
      final result = PosProductImportResult.fromJson(
        Map<String, dynamic>.from(data),
      );
      if (!preview) await provider.sharedPreferences.remove(key);
      if (scope != provider.subscriptionScope) {
        throw StateError('Operator berubah. Muat ulang katalog.');
      }
      return result;
    } finally {
      if (client == null) transport.close();
    }
  }
}
