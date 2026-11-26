import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/pos_bootstrap_reads.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'pos_login_roster_resilience_test.dart' show Provider;

const roster = {'GetPOSPinUsers': {'items': [{'_id': 'cashier', 'name': 'Kasir QA', 'has_pin': true}]}};
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  Completer<List<String>>? connectivity;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'instansi_id': 'tenant', 'user_id': 'cashier'});
    FlutterSecureStorage.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    connectivity = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity'),
      (_) => connectivity?.future ?? Future.value(['wifi']),
    );
  });
  PosRepository repository(Stream<Response> Function(Request) respond) => PosRepository(
    Provider(GraphQLClient(cache: GraphQLCache(), link: posBootstrapReadDeadlineLink().concat(Link.function((request, [forward]) => respond(request))))), prefs,
  );
  test('temporary roster transport failure retries once without signing out', () async {
    var calls = 0;
    final repo = repository((request) async* {
      if (++calls == 1) throw TimeoutException('temporary handover');
      yield Response(data: roster, response: {});
    });
    final results = await Future.wait([repo.getPOSPinUsers(hasPin: true), repo.getPOSPinUsers(hasPin: true)]);
    expect(results.every((result) => result.isRight()), true);
    expect(calls, 2);
  });
  test('two failed attempts end promptly and a manual retry uses a fresh request', () async {
    var calls = 0;
    final repo = repository((request) async* {
      if (++calls <= 2) throw TimeoutException('temporary handover');
      yield Response(data: roster, response: {});
    });
    expect((await repo.getPOSPinUsers(hasPin: true)).isLeft(), true);
    expect(calls, 2);
    expect((await repo.getPOSPinUsers(hasPin: true)).isRight(), true);
    expect(calls, 3);
  });
  for (final code in ['FORBIDDEN', 'UNAUTHORIZED', 'GRAPHQL_VALIDATION_FAILED', 'INTERNAL_SERVER_ERROR']) {
    test('authoritative $code is not retried or treated as an offline success', () async {
      var calls = 0;
      final repo = repository((request) async* {
        calls++;
        yield Response(errors: [GraphQLError(message: 'QA rejection', extensions: {'code': code})], response: {});
      });
      expect((await repo.getPOSPinUsers(hasPin: true)).isLeft(), true);
      expect(calls, 1);
    });
  }
  testWidgets('a stalled connectivity plugin does not block a working roster API', (tester) async {
    connectivity = Completer<List<String>>();
    var calls = 0, done = false, succeeded = false;
    final repo = repository((request) async* { calls++; yield Response(data: roster, response: {}); });
    final pending = repo.getPOSPinUsers(hasPin: true).then((result) { done = true; succeeded = result.isRight(); });
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    final completedInTime = done;
    connectivity!.complete(['wifi']);
    await tester.pump();
    await pending;
    expect(completedInTime, true);
    expect(succeeded, true);
    expect(calls, 1);
  });
  testWidgets('a stalled first request is cancelled and retried within the existing startup budget', (tester) async {
    var calls = 0, cancelled = false, done = false;
    final source = StreamController<Response>(onCancel: () => cancelled = true);
    final repo = repository((request) {
      if (++calls == 1) return source.stream;
      return Stream.value(Response(data: roster, response: {}));
    });
    final pending = repo.getPOSPinUsers(hasPin: true).then((result) { done = result.isRight(); });
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    final retriedInTime = done && calls == 2 && cancelled;
    await tester.pump(const Duration(seconds: 4));
    await pending;
    await source.close();
    expect(retriedInTime, true);
  });
}
