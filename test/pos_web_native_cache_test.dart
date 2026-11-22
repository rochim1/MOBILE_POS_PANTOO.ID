@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/database/database_platform_initializer.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/data/datasources/local/pos_local_database.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';

class BrowserProvider extends Fake implements GraphQLClientProvider {
  BrowserProvider(this.client);
  @override
  final GraphQLClient client;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'instansi_id': 'tenant', 'user_id': 'cashier'});
    prefs = await SharedPreferences.getInstance();
  });

  test('browser database boundary rejects SQLite before any native Platform API', () async {
    expect(supportsOfflineDatabase, false);
    await expectLater(
      PosLocalDatabase.instance.database,
      throwsA(isA<UnsupportedError>().having((error) => error.message, 'message', contains('SQLite'))),
    );
  });

  test('successful browser store reads do not attempt a native cache write or warn about offline shifts', () async {
    final logged = <String>[];
    void capture(OutputEvent event) => logged.addAll(event.lines);
    Logger.addOutputListener(capture);
    addTearDown(() => Logger.removeOutputListener(capture));
    final client = GraphQLClient(
      cache: GraphQLCache(),
      link: Link.function((request, [forward]) async* {
        yield Response(data: const {
          'GetAllPOSToko': {'items': [{'_id': 'store', 'nama_toko': 'Toko', 'shift_mode': 'per_operator'}]},
        }, response: {});
      }),
    );
    final stores = await PosRepository(BrowserProvider(client), prefs).getStores();
    expect(stores.single.id, 'store');
    expect(stores.single.shiftMode, 'per_operator');
    expect(logged.where((line) => line.contains('Cache toko belum diperbarui')), isEmpty);
    expect(logged.where((line) => line.contains('Platform._operatingSystem')), isEmpty);
  });

  test('browser shift closure reaches server without opening unsupported native SQLite', () async {
    var mutations = 0;
    final client = GraphQLClient(
      cache: GraphQLCache(),
      link: Link.function((request, [forward]) async* {
        mutations++;
        yield Response(data: const {'ClosePOSKasirShift': {'_id': 'shift', 'status': 'closed'}}, response: {});
      }),
    );
    final result = await PosRepository(BrowserProvider(client), prefs).closeShift('shift', 50000, 'QA');
    expect(result.getOrElse(() => false), true);
    expect(mutations, 1);
  });

  test('browser shift closure preserves explicit server authorization denial', () async {
    var mutations = 0;
    final client = GraphQLClient(
      cache: GraphQLCache(),
      link: Link.function((request, [forward]) async* {
        mutations++;
        yield Response(errors: [GraphQLError(message: 'Denied', extensions: {'code': 'FORBIDDEN'})], response: {});
      }),
    );
    final result = await PosRepository(BrowserProvider(client), prefs).closeShift('shift', 50000, 'QA');
    expect(result.isLeft(), true);
    expect(mutations, 1);
  });
}
