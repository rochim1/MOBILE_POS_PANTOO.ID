@TestOn('vm')
library;

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobile_pos_pantoo/core/database/database_platform_initializer.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/data/datasources/local/pos_local_database.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';

class NativeProvider extends Fake implements GraphQLClientProvider {
  NativeProvider(this.client);
  @override
  final GraphQLClient client;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;
  late SharedPreferences prefs;
  setUpAll(() async {
    initializePlatformDatabase();
    // A fresh task-owned directory, never the installed app's database.
    final folder = await Directory.systemTemp.createTemp(
      'pos-native-cache-shift-test-',
    );
    await databaseFactoryFfi.setDatabasesPath(folder.path);
    db = await PosLocalDatabase.instance.database;
  });
  tearDownAll(() => PosLocalDatabase.instance.close());
  setUp(() async {
    await db.delete('offline_transactions');
    SharedPreferences.setMockInitialValues({
      'instansi_id': 'tenant',
      'user_id': 'cashier',
    });
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> pending(
    String status, {
    String? resolution,
    String shift = 'shift',
  }) => db.insert('offline_transactions', {
    'payload': '{}',
    'status': status,
    'timestamp': DateTime.now().toIso8601String(),
    'instansi_id': 'tenant',
    'shift_id': shift,
    'client_transaction_id': 'qa-$status',
    'resolution': resolution,
  });

  for (final status in ['pending', 'syncing', 'needs_review', 'rejected']) {
    test(
      'native shift closure keeps blocking unresolved $status transactions',
      () async {
        expect(supportsOfflineDatabase, true);
        await pending(status);
        var writes = 0;
        final client = GraphQLClient(
          cache: GraphQLCache(),
          link: Link.function((request, [forward]) async* {
            writes++;
            yield Response(
              data: const {
                'ClosePOSKasirShift': {'_id': 'shift'},
              },
              response: {},
            );
          }),
        );
        final result = await PosRepository(
          NativeProvider(client),
          prefs,
        ).closeShift('shift', 1000, 'QA');
        expect(result.isLeft(), true);
        expect(
          result.fold((failure) => failure.message, (_) => ''),
          contains('transaksi offline'),
        );
        expect(writes, 0);
        expect(await db.query('offline_transactions'), hasLength(1));
      },
    );
  }

  test(
    'native shift closure permits reconciled rows and ignores another shift queue',
    () async {
      await pending('rejected', resolution: 'rejected_by_operator');
      await pending('pending', shift: 'other-shift');
      var writes = 0;
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          writes++;
          yield Response(
            data: const {
              'ClosePOSKasirShift': {'_id': 'shift'},
            },
            response: {},
          );
        }),
      );
      final result = await PosRepository(
        NativeProvider(client),
        prefs,
      ).closeShift('shift', 1000, 'QA');
      expect(result.getOrElse(() => false), true);
      expect(writes, 1);
      expect(await db.query('offline_transactions'), hasLength(2));
    },
  );

  test(
    'native shift closure still respects server denial after the local queue is clear',
    () async {
      var writes = 0;
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          writes++;
          yield Response(
            errors: [
              GraphQLError(
                message: 'Denied',
                extensions: {'code': 'FORBIDDEN'},
              ),
            ],
            response: {},
          );
        }),
      );
      final result = await PosRepository(
        NativeProvider(client),
        prefs,
      ).closeShift('shift', 1000, 'QA');
      expect(result.isLeft(), true);
      expect(writes, 1);
    },
  );

  test('native store cache preserves branch and shift mode', () async {
    final client = GraphQLClient(
      cache: GraphQLCache(),
      link: Link.function((request, [forward]) async* {
        yield Response(
          data: const {
            '__typename': 'Query',
            'GetAllPOSToko': {
              '__typename': 'POSTokoList',
              'items': [
                {
                  '__typename': 'POSToko',
                  '_id': 'qa-store',
                  'nama_toko': 'QA Toko',
                  'kode_toko': 'QA',
                  'alamat': '',
                  'telepon': '',
                  'lokasi_cabang_nama': '',
                  'status': 'active',
                  'lokasi_cabang_id': 'qa-branch',
                  'shift_mode': 'per_operator',
                },
              ],
            },
          },
          response: {},
        );
      }),
    );
    final stores = await PosRepository(
      NativeProvider(client),
      prefs,
    ).getStores();
    expect(stores.single.shiftMode, 'per_operator');
    final saved = (await db.query(
      'stores',
      where: 'id = ?',
      whereArgs: ['qa-store'],
    )).single;
    expect(saved['branchId'], 'qa-branch');
    expect(saved['shiftMode'], 'per_operator');
  });
}
