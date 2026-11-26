import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_remote_profile_catalog.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_settings.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_flow_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_settings_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_settings/pos_settings_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_inventory_flow_settings.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_inventory_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_settings_page.dart';
import 'pos_inventory_flow_page_test.dart' show FlowRepo;
import 'pos_inventory_flow_runtime_test.dart' show RuntimeRepository;

class EmptyInventory extends Fake implements PosInventoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getDocuments) {
      return Future<Either<Failure, PosInventoryDocumentPage>>.value(
        const Right(PosInventoryDocumentPage([], 0)),
      );
    }
    return super.noSuchMethod(invocation);
  }
}

class LegacySettings extends Fake implements PosSettingsRepository {
  final pending = Completer<Either<Failure, PosSettings>>();
  @override
  Future<PosRemoteProfileCatalog> getProfileCatalog() async =>
      PosRemoteProfileCatalog.bundled();
  @override
  Future<Either<Failure, PosSettings>> getSettings() => pending.future;
}

Future<void> refresh(WidgetTester tester, PosBloc bloc) async {
  final done = Completer<bool>();
  bloc.add(RefreshPosRuntimeConfig(preserveCheckout: true, completion: done));
  await tester.pump();
  expect(await done.future, true);
}

void main() {
  tearDown(() async => sl.reset());
  testWidgets(
    'inventory settings opens from POS settings without waiting for the legacy loader',
    (t) async {
      final repo = LegacySettings();
      addTearDown(() {
        if (!repo.pending.isCompleted) {
          repo.pending.complete(const Left(ServerFailure('Unavailable')));
        }
      });
      sl.registerFactory<PosSettingsBloc>(
        () => PosSettingsBloc(repository: repo),
      );
      sl.registerSingleton<PosInventoryFlowRepository>(FlowRepo());
      final bloc = PosBloc(posRepository: RuntimeRepository());
      addTearDown(bloc.close);
      await t.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const Scaffold(body: PosSettingsPage()),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('Transaksi & Penjualan').first);
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('Inventori').last);
      await t.pumpAndSettle();
      expect(find.byType(PosInventoryFlowSettings), findsOneWidget);
      expect(find.byKey(const Key('flow-profile')), findsOneWidget);
      await t.scrollUntilVisible(
        find.byKey(const Key('flow-save')),
        180,
        scrollable: find
            .descendant(
              of: find.byType(PosInventoryFlowSettings),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.byKey(const Key('flow-save')), findsOneWidget);
      repo.pending.complete(const Left(ServerFailure('Unavailable')));
      await t.pump();
      expect(find.text('Unavailable'), findsNothing);
      expect(find.byType(PosInventoryFlowSettings), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'verified settings refresh immediately reveals Mutasi Stok without reopening inventory',
    (t) async {
      sl.registerSingleton<PosInventoryRepository>(EmptyInventory());
      final repo = RuntimeRepository();
      Map<String, dynamic> config(String profile) => {
        'features': {'track_stock': true},
        'permissions': {'view_inventory_transfers': true},
        'inventory_policy': {'inventory_profile': profile},
      };
      repo.runtime = config('simple');
      final bloc = PosBloc(posRepository: repo);
      addTearDown(bloc.close);
      await refresh(t, bloc);
      await t.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const Scaffold(body: PosInventoryPage()),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Mutasi Stok'), findsNothing);
      repo.runtime = config('custom');
      await refresh(t, bloc);
      await t.pumpAndSettle();
      expect(find.text('Mutasi Stok'), findsWidgets);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
    },
  );
}
