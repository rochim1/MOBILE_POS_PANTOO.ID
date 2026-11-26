// Diagnostic reproducer only. No production state or app code is changed.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import '../../test/pos_checkout_recovery_test.dart' as fixture;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'instansi_id': 'tenant', 'user_id': 'terminal'});
    prefs = await SharedPreferences.getInstance();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'), (_) async => ['wifi'],
    );
  });
  Future<dynamic> pay(PosRepository repo, {String store = 'store-a', String shift = 'old-shift'}) => repo.submitTransaction(
    cart: {fixture.product: 1}, total: 100, paymentMethod: 'transfer', tokoId: store, shiftId: shift, cashReceived: 100,
  );
  const denied = 'Shift asal transaksi offline sudah ditutup atau bukan milik kasir ini. Tinjau transaksi dan selisih kas sebelum pencatatan.';

  test('DIAGNOSIS: lost result then closed shift loops with original ID and blocks another store', () async {
    final calls = <Map<String, dynamic>>[];
    final client = GraphQLClient(cache: GraphQLCache(), link: Link.function((request, [forward]) async* {
      calls.add(Map<String, dynamic>.from(request.variables['input'] as Map));
      if (calls.length == 1) throw ServerException(originalException: Exception('response lost'));
      yield Response(data: const {'__typename': 'Mutation'}, errors: const [GraphQLError(message: denied, extensions: {'code': 'CONFLICT'})], response: {});
    }));
    final repo = PosRepository(fixture.Provider(client), prefs);
    expect((await pay(repo)).isLeft(), true);
    final original = repo.pendingCheckout;
    for (var attempt = 0; attempt < 2; attempt++) {
      final result = await repo.recoverPendingCheckout();
      expect(result.isLeft(), true);
      expect(result.fold((f) => f.message, (_) => ''), denied);
      expect(repo.pendingCheckout, original);
    }
    expect((await pay(repo, store: 'store-b', shift: 'new-shift')).isLeft(), true);
    expect(calls.length, 3, reason: 'new store is fenced before its request can be sent');
    expect(calls.every((c) => c['shift_id'] == 'old-shift' && c['toko_id'] == 'store-a'), true);
    expect(calls.map((c) => c['client_transaction_id']).toSet().length, 1);
  });

  test('CONTROL: a definite rejection on first attempt releases proof unlike uncertain replay', () async {
    final calls = <String>[];
    final client = GraphQLClient(cache: GraphQLCache(), link: Link.function((request, [forward]) async* {
      calls.add((request.variables['input'] as Map)['client_transaction_id'] as String);
      yield Response(data: const {'__typename': 'Mutation'}, errors: const [GraphQLError(message: denied, extensions: {'code': 'CONFLICT'})], response: {});
    }));
    final repo = PosRepository(fixture.Provider(client), prefs);
    expect((await pay(repo)).isLeft(), true);
    expect(repo.pendingCheckout, isNull);
    expect((await pay(repo, store: 'store-b', shift: 'new-shift')).isLeft(), true);
    expect(repo.pendingCheckout, isNull);
    expect(calls.length, 2);
    expect(calls[0], isNot(calls[1]));
  });
}
