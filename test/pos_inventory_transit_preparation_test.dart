import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_inventory_flow_settings.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_flow_repository.dart';
import 'pos_inventory_flow_page_test.dart' show FlowRepo, open, submit;

FlowRepo setupRepo() => FlowRepo()
  ..canCreateLocations = true
  ..policy = {
    'inventory_profile': 'custom',
    'use_store_warehouse': true,
    'use_transfer_request': true,
    'use_in_transit': true,
  }
  ..locations = const [
    PosInventoryFlowLocation(id: 'store', name: 'Gudang Toko', type: 'store'),
  ];

void main() {
  testWidgets(
    'missing transit offers an inline opt-in and creates nothing before confirmed Save',
    (t) async {
      final repo = setupRepo();
      await open(t, repo);
      await t.scrollUntilVisible(
        find.byKey(const Key('flow-prepare-transit')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await t.ensureVisible(find.byKey(const Key('flow-prepare-transit')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('flow-prepare-transit')));
      await t.pumpAndSettle();
      expect(repo.writes, 0);
      expect(repo.preparations, 0);
      await submit(t);
      await t.pumpAndSettle();
      expect(repo.writes, 1);
      expect(repo.preparations, 1);
      expect(
        repo.policy['default_transfer_transit_location_id'],
        'auto-transit',
      );
      expect(repo.policy['use_transfer_approval'], false);
      await t.scrollUntilVisible(
        find.byKey(const Key('flow-save')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        t.widget<FilledButton>(find.byKey(const Key('flow-save'))).onPressed,
        isNull,
      );
      expect(find.byKey(const Key('flow-prepare-transit')), findsNothing);
    },
  );
  testWidgets(
    'one existing transit can be selected inline without requesting creation',
    (t) async {
      final repo = setupRepo()..canCreateLocations = false;
      repo.locations = [
        ...repo.locations,
        const PosInventoryFlowLocation(
          id: 'existing',
          name: 'Transit lama',
          type: 'in_transit',
        ),
      ];
      await open(t, repo);
      await t.scrollUntilVisible(
        find.byKey(const Key('flow-use-transit')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await t.ensureVisible(find.byKey(const Key('flow-use-transit')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('flow-use-transit')));
      await t.pumpAndSettle();
      expect(repo.writes, 0);
      await submit(t);
      await t.pumpAndSettle();
      expect(repo.preparations, 0);
      expect(repo.writes, 1);
      expect(repo.policy['default_transfer_transit_location_id'], 'existing');
    },
  );
  testWidgets(
    'without location-create permission no automatic preparation is offered',
    (t) async {
      await open(t, setupRepo()..canCreateLocations = false);
      await t.drag(find.byType(ListView).first, const Offset(0, -400));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('flow-prepare-transit')), findsNothing);
      expect(find.textContaining('Minta admin'), findsWidgets);
    },
  );
  testWidgets(
    'lost preparation response locks repeat save until explicit reload',
    (t) async {
      final repo = setupRepo()
        ..failure = const PosInventoryFlowFailure(
          InventoryFlowFailureKind.uncertain,
        );
      await open(t, repo);
      await t.scrollUntilVisible(
        find.byKey(const Key('flow-prepare-transit')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await t.ensureVisible(find.byKey(const Key('flow-prepare-transit')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('flow-prepare-transit')));
      await t.pumpAndSettle();
      await submit(t);
      await t.pumpAndSettle();
      expect(repo.writes, 1);
      await t.scrollUntilVisible(
        find.byKey(const Key('flow-save')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        t.widget<FilledButton>(find.byKey(const Key('flow-save'))).onPressed,
        isNull,
      );
    },
  );
  testWidgets(
    'multiple transit locations require a choice without creating or guessing',
    (t) async {
      final repo = setupRepo();
      repo.locations = [
        ...repo.locations,
        const PosInventoryFlowLocation(
          id: 'first',
          name: 'Transit A',
          type: 'in_transit',
        ),
        const PosInventoryFlowLocation(
          id: 'second',
          name: 'Transit B',
          type: 'in_transit',
        ),
      ];
      await open(t, repo);
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('transit:null')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(const Key('flow-prepare-transit')), findsNothing);
      expect(find.byKey(const Key('flow-use-transit')), findsNothing);
      expect(repo.writes, 0);
      expect(repo.preparations, 0);
      expect(repo.policy['default_transfer_transit_location_id'], isNull);
      expect(find.textContaining('Ada beberapa lokasi'), findsWidgets);
    },
  );
  testWidgets(
    'inline preparation fits a narrow English phone with larger text',
    (t) async {
      t.view.physicalSize = const Size(320, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final repo = setupRepo();
      await open(t, repo, english: true);
      await t.scrollUntilVisible(
        find.byKey(const Key('flow-prepare-transit')),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await t.ensureVisible(find.byKey(const Key('flow-prepare-transit')));
      await t.pumpAndSettle();
      expect(find.text('Prepare automatically when saving'), findsOneWidget);
      expect(t.takeException(), isNull);
      expect(repo.writes, 0);
    },
  );
  test('preparing transit cannot skip any other inventory validation', () {
    final policy = PosInventoryFlowPolicy({
      'inventory_profile': 'custom',
      'use_in_transit': true,
    });
    expect(
      policy.validationError(
        trackStock: true,
        locations: const [],
        prepareTransit: true,
      ),
      'transitRequiresRequest',
    );
  });
}
