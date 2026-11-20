import 'dart:convert';
import 'dart:math';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/graphql_client_provider.dart';

/// One unresolved posting per authenticated endpoint/tenant/terminal/operator.
/// It must survive navigation and restart; a lost response is not a rejection.
class OpeningStockDraft {
  final SharedPreferences preferences;
  final String scope;
  OpeningStockDraft(this.preferences, this.scope);
  String get _key => 'pos-opening-stock:$scope';
  Map<String, dynamic>? get pending {
    final raw = preferences.getString(_key);
    if (raw == null) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<Map<String, dynamic>> prepare(Map<String, dynamic> payload) async {
    if (scope.isEmpty) throw StateError('Sesi belum siap. Masuk kembali.');
    final existing = pending;
    if (existing != null) {
      final comparison = {...existing}..remove('request_id');
      if (jsonEncode(comparison) != jsonEncode(payload)) {
        throw StateError(
          'Selesaikan percobaan saldo awal sebelumnya terlebih dahulu.',
        );
      }
      return existing;
    }
    final saved = {
      ...payload,
      'request_id':
          'mobile-opening-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}',
    };
    if (!await preferences.setString(_key, jsonEncode(saved))) {
      throw StateError('Draft saldo awal tidak dapat disimpan.');
    }
    return saved;
  }

  Future<void> clear() async {
    await preferences.remove(_key);
  }
}

class PosOpeningStockRepository {
  final GraphQLClientProvider provider;
  PosOpeningStockRepository(this.provider);
  OpeningStockDraft get draft =>
      OpeningStockDraft(provider.sharedPreferences, provider.subscriptionScope);
  Future<void>? _posting;

  static const detailQuery = r'''
    query POSOpeningStockItem($id: ID!) {
      GetOneInventarisUmum(_id: $id) {
        _id nama_inventaris kategori tracks_stock pos_product_type composition_type stok harga_beli
        base_unit unit unit_conversions { unit factor }
        wajib_batch_number wajib_serial_number valuation_method
      }
    }
  ''';
  static const submitMutation = r'''
    mutation SubmitInventoryOpeningBalance($input: SubmitInventoryOpeningBalanceInput!) {
      SubmitInventoryOpeningBalance(input: $input)
    }
  ''';
  Future<Map<String, dynamic>> detail(String id) async {
    final result = await provider.client.query(
      QueryOptions(
        document: gql(detailQuery),
        variables: {'id': id},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
    );
    if (result.hasException) throw result.exception!;
    final row = result.data?['GetOneInventarisUmum'];
    if (row is! Map) throw StateError('Produk tidak ditemukan.');
    return Map<String, dynamic>.from(row);
  }

  Future<void> submit(Map<String, dynamic> payload) =>
      _posting ??= _submit(payload).whenComplete(() => _posting = null);
  Future<void> _submit(Map<String, dynamic> payload) async {
    final scope = provider.subscriptionScope;
    final store = draft;
    final input = await store.prepare(payload);
    if (scope != provider.subscriptionScope) {
      throw StateError('Operator berubah. Buka ulang saldo awal.');
    }
    final result = await provider.client.mutate(
      MutationOptions(
        document: gql(submitMutation),
        variables: {'input': input},
        fetchPolicy: FetchPolicy.noCache,
      ),
    );
    if (result.hasException) {
      // Only a definitive server rejection can unlock editing. Transport errors
      // retain the exact request ID + payload for idempotent confirmation.
      const rejectedBeforePosting = {
        'BAD_USER_INPUT',
        'VALIDATION_ERROR',
        'GRAPHQL_VALIDATION_FAILED',
        'FORBIDDEN',
        'UNAUTHORIZED',
        'UNAUTHENTICATED',
        'NOT_FOUND',
      };
      if (result.exception!.graphqlErrors.isNotEmpty &&
          result.exception!.graphqlErrors.every(
            (error) =>
                rejectedBeforePosting.contains(error.extensions?['code']),
          ) &&
          result.exception!.linkException == null) {
        await store.clear();
      }
      throw result.exception!;
    }
    if (result.data?['SubmitInventoryOpeningBalance'] != true) {
      throw StateError(
        'Saldo awal belum terkonfirmasi. Coba kembali dengan draft yang sama.',
      );
    }
    await store.clear();
    if (scope != provider.subscriptionScope) {
      throw StateError('Operator berubah. Muat ulang stok.');
    }
  }
}
