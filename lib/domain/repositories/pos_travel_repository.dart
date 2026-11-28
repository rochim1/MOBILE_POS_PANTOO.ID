import 'package:graphql_flutter/graphql_flutter.dart';
import '../../core/network/graphql_client_provider.dart';
import '../../core/network/pos_travel_intent_store.dart';
import '../../data/graphql/pos_travel_queries.dart';

class PosTravelRepository {
  PosTravelRepository(this.provider);
  final GraphQLClientProvider provider;
  String get scope => provider.subscriptionScope;
  PosTravelIntentStore get store =>
      PosTravelIntentStore(provider.sharedPreferences, scope);
  static final _running = <String, Future<Map<String, dynamic>>>{};
  Map<String, dynamic>? pending() => store.load();
  void _current(String expected) {
    if (expected.isEmpty ||
        scope != expected ||
        provider.requiresOperatorVerification) {
      throw StateError(
        'Sesi atau operator berubah. Masukkan PIN kembali sebelum melanjutkan Travel.',
      );
    }
  }

  Future<Map<String, dynamic>> read(
    String operation,
    Map<String, dynamic> variables,
  ) async {
    final owner = scope;
    _current(owner);
    final response = await provider.client.query(
      QueryOptions(
        document: gql(PosTravelQueries.document),
        operationName: operation,
        variables: variables,
        fetchPolicy: FetchPolicy.noCache,
        errorPolicy: ErrorPolicy.none,
      ),
    );
    _current(owner);
    if (response.hasException) {
      throw StateError(
        response.exception!.graphqlErrors.firstOrNull?.message ??
            'Travel belum dapat dimuat. Periksa koneksi lalu coba lagi.',
      );
    }
    final result = response.data?[PosTravelQueries.fields[operation]];
    if (result is! Map) {
      throw StateError('Data Travel belum lengkap. Muat ulang.');
    }
    return Map<String, dynamic>.from(result);
  }

  Future<Map<String, dynamic>> submit(
    String operation,
    Map<String, dynamic> input,
  ) {
    final owner = scope;
    _current(owner);
    if (_running.containsKey(owner)) {
      throw StateError('Permintaan Travel masih diproses.');
    }
    return _run(owner, () async {
      final saved = store;
      final row = await saved.prepare(operation, input);
      _current(owner);
      return _attempt(saved, row, owner);
    });
  }

  Future<Map<String, dynamic>> recover() {
    final owner = scope;
    _current(owner);
    if (_running.containsKey(owner)) return _running[owner]!;
    final saved = store, row = saved.load();
    if (row == null) {
      throw StateError('Tidak ada permintaan Travel yang perlu diperiksa.');
    }
    return _run(owner, () => _attempt(saved, row, owner));
  }

  Future<Map<String, dynamic>> _run(
    String owner,
    Future<Map<String, dynamic>> Function() action,
  ) {
    final future = Future<Map<String, dynamic>>.sync(action);
    _running[owner] = future;
    return future.whenComplete(() {
      if (identical(_running[owner], future)) _running.remove(owner);
    });
  }

  Future<Map<String, dynamic>> _attempt(
    PosTravelIntentStore saved,
    Map<String, dynamic> row,
    String owner,
  ) async {
    final attempt = (row['attempts'] as int) + 1;
    await saved.save({...row, 'attempts': attempt});
    _current(owner);
    final response = await provider.client.mutate(
      MutationOptions(
        document: gql(PosTravelQueries.document),
        operationName: PosTravelQueries.writes[row['operation']],
        variables: {'input': row['input']},
        fetchPolicy: FetchPolicy.noCache,
        errorPolicy: ErrorPolicy.all,
      ),
    );
    _current(owner);
    final requestId = row['input']['request_id'] as String;
    if (response.hasException) {
      final error = response.exception!;
      const rejected = {
        'BAD_REQUEST',
        'FORBIDDEN',
        'NOT_FOUND',
        'CONFLICT',
        'GRAPHQL_VALIDATION_FAILED',
        'UNAUTHENTICATED',
        'SHIFT_REQUIRED',
      };
      final stopped =
          error.linkException == null &&
          error.graphqlErrors.any(
            (e) => e.extensions?['code'] == 'TRAVEL_REQUEST_CANCELLED',
          );
      if (stopped ||
          (attempt == 1 &&
              error.linkException == null &&
              error.graphqlErrors.isNotEmpty &&
              error.graphqlErrors.every(
                (e) => rejected.contains(e.extensions?['code']),
              ))) {
        await saved.acknowledge(requestId);
      }
      throw StateError(
        error.graphqlErrors.firstOrNull?.message ??
            'Hasil belum dipastikan. Jangan menerima dana lagi; pulihkan permintaan yang sama saat koneksi tersedia.',
      );
    }
    final data =
        response.data?[PosTravelQueries.fields[PosTravelQueries
            .writes[row['operation']]]];
    if (data is! Map ||
        data['_id'] == null ||
        (['payment', 'refund', 'complete'].contains(row['operation']) &&
            (data['_id'] != row['input']['booking_id'] ||
                data['paid_amount'] is! num ||
                data['outstanding_amount'] is! num))) {
      throw StateError(
        'Bukti Travel belum lengkap. Pulihkan permintaan yang sama.',
      );
    }
    await saved.acknowledge(requestId);
    _current(owner);
    return Map<String, dynamic>.from(data);
  }

  /// Server resolves a committed request or atomically stops a not-yet-committed
  /// request. Never clears local evidence on timeout or NOT_FOUND guesses.
  Future<Map<String, dynamic>> resolve() {
    final owner = scope;
    _current(owner);
    if (_running.containsKey(owner)) {
      throw StateError('Permintaan Travel masih diproses.');
    }
    return _run(owner, () async {
      final saved = store, row = saved.load();
      if (row == null) throw StateError('Tidak ada permintaan tersimpan.');
      final input = Map<String, dynamic>.from(row['input'] as Map);
      final response = await provider.client.mutate(
        MutationOptions(
          document: gql(PosTravelQueries.document),
          operationName: 'TravelRequestResolution',
          variables: {
            'toko_id': input['toko_id'],
            'request_id': input['request_id'],
          },
          fetchPolicy: FetchPolicy.noCache,
        ),
      );
      _current(owner);
      final data = response.data?['ResolvePOSTravelRequest'];
      if (response.hasException ||
          data is! Map ||
          !['committed', 'cancelled'].contains(data['status'])) {
        throw StateError(
          'Hasil belum dipastikan. Bukti Travel tetap disimpan.',
        );
      }
      await saved.acknowledge(input['request_id'] as String);
      return {
        ...Map<String, dynamic>.from(data),
        'toko_id': input['toko_id'],
        'booking_id':
            input['booking_id'] ??
            (row['operation'] == 'createBooking' ? data['entity_id'] : null),
      };
    });
  }
}
