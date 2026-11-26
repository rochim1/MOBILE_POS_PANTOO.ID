import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_inventory_flow_settings.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_flow_repository.dart';
import 'pos_transfer_recovery_test.dart' show TransferProvider;

Map<String, dynamic> state({bool prepared = false}) => {
  'revision': prepared ? 'r2' : 'r1',
  'inventory_operation_defaults': {
    'inventory_profile': 'custom',
    'use_store_warehouse': true,
    'use_transfer_request': true,
    'use_in_transit': true,
    'default_transfer_transit_location_id': prepared ? 'auto' : null,
  },
};
const rows = [
  PosInventoryFlowLocation(id: 'store', name: 'Store', type: 'store'),
];
Response response(Map<String, dynamic> data) =>
    Response(response: const {}, data: data);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final lostRead in [false, true]) {
    test(
      'prepare flag uses revision, writes once and reloads actual locations ($lostRead)',
      () async {
        var writes = 0;
        Map<String, dynamic>? input;
        final provider = TransferProvider(
          await SharedPreferences.getInstance(),
          (request) async* {
            switch (request.operation.operationName) {
              case 'InventoryFlowSave':
                writes++;
                input = request.variables['input'] as Map<String, dynamic>;
                yield response({
                  'UpdateInventorySettings': state(prepared: true),
                });
              case 'InventoryFlowPermissions':
                if (lostRead) {
                  throw TimeoutException('read failed after commit');
                }
                yield response({
                  'GetMyPermissions': {'is_full_access': true},
                });
              case 'InventoryFlowSettings':
                yield response({'GetInventorySettings': state(prepared: true)});
              case 'InventoryFlowLocations':
                yield response({
                  'getAllCabangs': {
                    'info_page': [
                      {'count': 2},
                    ],
                    'cabang': [
                      {
                        '_id': 'store',
                        'nama_cabang': 'Store',
                        'status': 'active',
                        'is_warehouse': true,
                        'warehouse_type': 'store',
                      },
                      {
                        '_id': 'auto',
                        'nama_cabang': 'Barang dalam perjalanan',
                        'status': 'active',
                        'is_warehouse': true,
                        'warehouse_type': 'in_transit',
                      },
                    ],
                  },
                });
            }
          },
        );
        final baseline = PosInventoryFlowSnapshot.fromJson(
          state(),
          scope: provider.scope,
          canUpdate: true,
          canCreateLocations: true,
          locations: rows,
        );
        final repo = PosInventoryFlowRepository(provider);
        if (lostRead) {
          await expectLater(
            repo.save(baseline, baseline.policy, prepareTransit: true),
            throwsA(
              isA<PosInventoryFlowFailure>().having(
                (f) => f.requiresReload,
                'reload',
                true,
              ),
            ),
          );
        } else {
          final saved = await repo.save(
            baseline,
            baseline.policy,
            prepareTransit: true,
          );
          expect(saved.revision, 'r2');
          expect(saved.locations.last.isTransit, true);
          expect(saved.canCreateLocations, true);
        }
        expect(writes, 1);
        expect(input, {
          'expected_revision': 'r1',
          'auto_prepare_transfer_transit': true,
        });
      },
    );
  }
  test(
    'creation permission rejection is actionable and never treated as uncertain success',
    () async {
      final provider = TransferProvider(await SharedPreferences.getInstance(), (
        r,
      ) async* {
        yield const Response(
          response: {},
          errors: [
            GraphQLError(
              message: 'permission denied',
              extensions: {
                'code': 'FORBIDDEN',
                'reason': 'TRANSIT_SETUP_PERMISSION',
              },
            ),
          ],
        );
      });
      final baseline = PosInventoryFlowSnapshot.fromJson(
        state(),
        scope: provider.scope,
        canUpdate: true,
        locations: rows,
      );
      await expectLater(
        PosInventoryFlowRepository(
          provider,
        ).save(baseline, baseline.policy, prepareTransit: true),
        throwsA(
          isA<PosInventoryFlowFailure>()
              .having(
                (f) => f.kind,
                'kind',
                InventoryFlowFailureKind.validation,
              )
              .having((f) => f.detail, 'detail', 'transitSetupPermission'),
        ),
      );
    },
  );
  test('simple mode cannot request automatic preparation', () async {
    var calls = 0;
    final provider = TransferProvider(await SharedPreferences.getInstance(), (
      r,
    ) async* {
      calls++;
      yield response({});
    });
    final baseline = PosInventoryFlowSnapshot.fromJson(
      state(),
      scope: provider.scope,
      canUpdate: true,
      locations: rows,
    );
    await expectLater(
      PosInventoryFlowRepository(provider).save(
        baseline,
        baseline.policy.withProfile('simple'),
        prepareTransit: true,
      ),
      throwsA(isA<PosInventoryFlowFailure>()),
    );
    expect(calls, 0);
  });
}
