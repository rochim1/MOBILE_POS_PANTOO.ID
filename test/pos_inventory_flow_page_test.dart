import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_inventory_flow_settings.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_flow_repository.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_inventory_flow_settings.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/l10n/pos_inventory_flow_copy.dart';

class FlowRepo extends Fake implements PosInventoryFlowRepository {
  int reads = 0, writes = 0;
  bool canUpdate = true;
  PosInventoryFlowFailure? failure;
  Completer<PosInventoryFlowSnapshot>? pending;
  Map<String, dynamic> policy = {
    'inventory_profile': 'custom',
    'use_store_warehouse': true,
  };
  PosInventoryFlowSnapshot snapshot() => PosInventoryFlowSnapshot.fromJson(
    {'revision': 'v$reads', 'inventory_operation_defaults': policy},
    scope: 'tenant',
    canUpdate: canUpdate,
    locations: const [
      PosInventoryFlowLocation(id: 'store', name: 'Gudang Toko', type: 'store'),
      PosInventoryFlowLocation(
        id: 'central',
        name: 'Gudang Pusat',
        type: 'central',
      ),
      PosInventoryFlowLocation(
        id: 'transit',
        name: 'Transit',
        type: 'in_transit',
      ),
    ],
  );
  @override
  Future<PosInventoryFlowSnapshot> load() async {
    reads++;
    return snapshot();
  }

  @override
  Future<PosInventoryFlowSnapshot> save(
    PosInventoryFlowSnapshot baseline,
    PosInventoryFlowPolicy draft,
  ) async {
    writes++;
    if (failure != null) throw failure!;
    policy = draft.values;
    return pending?.future ?? snapshot();
  }
}

Future<void> open(
  WidgetTester t,
  FlowRepo repo, {
  bool english = false,
  Future<bool> Function()? onSaved,
}) async {
  await t.pumpWidget(
    MaterialApp(
      locale: Locale(english ? 'en' : 'id'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(english ? 1.3 : 1)),
        child: child!,
      ),
      home: Scaffold(
        body: PosInventoryFlowSettings(
          repository: repo,
          onSaved: onSaved ?? () async => true,
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Future<void> change(WidgetTester t) async {
  await t.tap(find.byKey(const Key('flow-profile')));
  await t.pumpAndSettle();
  await t.tap(find.text('Sederhana').last);
  await t.pumpAndSettle();
  await t.ensureVisible(find.byKey(const Key('flow-receiving')));
  await t.tap(find.byKey(const Key('flow-receiving')));
  await t.pumpAndSettle();
  await t.tap(find.text('Gudang Toko').last);
  await t.pumpAndSettle();
}

Future<void> submit(WidgetTester t) async {
  await t.ensureVisible(find.byKey(const Key('flow-save')));
  await t.tap(find.byKey(const Key('flow-save')));
  await t.pump(const Duration(milliseconds: 350));
  await t.tap(find.byKey(const Key('flow-confirm')));
  await t.pump();
}

void main() {
  testWidgets('read-only inventory permission never exposes an editable save', (
    t,
  ) async {
    await open(t, FlowRepo()..canUpdate = false);
    expect(find.byKey(const Key('flow-save')), findsNothing);
    final field = t.widget<DropdownButtonFormField<String>>(
      find.byKey(const Key('flow-profile')),
    );
    expect(field.onChanged, isNull);
  });
  testWidgets(
    'confirm, loading and double tap transmit once; refresh is not a save',
    (t) async {
      final repo = FlowRepo()..pending = Completer();
      var refreshes = 0;
      await open(
        t,
        repo,
        onSaved: () async {
          refreshes++;
          return false;
        },
      );
      await change(t);
      await submit(t);
      final button = t.widget<FilledButton>(find.byKey(const Key('flow-save')));
      expect(button.onPressed, isNull);
      expect(repo.writes, 1);
      repo.pending!.complete(repo.snapshot());
      await t.pumpAndSettle();
      expect(refreshes, 1);
      await t.ensureVisible(find.byKey(const Key('flow-refresh')));
      await t.tap(find.byKey(const Key('flow-refresh')));
      await t.pumpAndSettle();
      expect(refreshes, 2);
      expect(repo.writes, 1);
    },
  );
  for (final kind in [
    InventoryFlowFailureKind.conflict,
    InventoryFlowFailureKind.uncertain,
    InventoryFlowFailureKind.forbidden,
  ]) {
    testWidgets(
      '$kind locks save until a fresh read, never automatic write retry',
      (t) async {
        final repo = FlowRepo()..failure = PosInventoryFlowFailure(kind);
        await open(t, repo);
        await change(t);
        await submit(t);
        await t.pumpAndSettle();
        expect(repo.writes, 1);
        await t.scrollUntilVisible(
          find.byKey(const Key('flow-save')),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          t.widget<FilledButton>(find.byKey(const Key('flow-save'))).onPressed,
          isNull,
        );
        await t.scrollUntilVisible(
          find.byKey(const Key('flow-reload')),
          -180,
          scrollable: find.byType(Scrollable).first,
        );
        await t.tap(find.byKey(const Key('flow-reload')));
        await t.pumpAndSettle();
        expect(repo.reads, 2);
        expect(repo.writes, 1);
      },
    );
  }
  testWidgets('English narrow phone with large text has labels and no overflow', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await open(t, FlowRepo(), english: true);
    expect(find.text('Inventory flow'), findsOneWidget);
    final context = t.element(find.byType(PosInventoryFlowSettings));
    expect(
      inventoryFlowText(
        context,
        'Pilih Default Lokasi Receiving untuk Profil Inventory Simple yang memiliki lebih dari satu warehouse',
      ),
      inventoryFlowCopy['receivingRequired']!.$2,
    );
    for (final copy in inventoryFlowCopy.values) {
      expect(copy.$1.trim(), isNotEmpty);
      expect(copy.$2.trim(), isNotEmpty);
    }
    await t.scrollUntilVisible(
      find.byKey(const Key('flow-advanced')),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.byKey(const Key('flow-advanced')));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      find.byKey(const Key('flow-save')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(t.takeException(), isNull);
  });
}
