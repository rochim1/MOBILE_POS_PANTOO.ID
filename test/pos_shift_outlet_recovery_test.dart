import 'dart:async';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_shift/pos_shift_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_shift/pos_shift_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_shift/pos_shift_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_shift_recovery_card.dart';

class _Repository extends Fake implements PosRepository {
  final Map<String, Completer<Map<String, dynamic>?>> pending = {};
  bool failRead = false;
  bool deferred = false;
  Map<String, dynamic>? active;
  int opens = 0;
  String operatorId = 'cashier-a';
  @override
  String get activeOperatorId => operatorId;
  @override
  Future<Map<String, dynamic>?> getActiveShiftForStore(String tokoId) async {
    if (failRead) throw StateError('Offline');
    if (deferred) {
      return (pending[tokoId] ??= Completer<Map<String, dynamic>?>()).future;
    }
    return active;
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getShiftHistory({
    int page = 0,
    int limit = 100,
  }) async => const Right([]);
  @override
  Future<Either<Failure, bool>> openShift(
    String tokoId,
    double amount, [
    String notes = '',
  ]) async {
    opens++;
    active = {'_id': 'new-shift', 'toko_id': tokoId};
    return const Right(true);
  }
}

Future<void> waitFor(bool Function() condition) async {
  for (var i = 0; i < 100 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue);
}

void main() {
  test('active shift elsewhere prevents a second open', () async {
    final repo = _Repository()..active = {'_id': 'old', 'toko_id': 'A'};
    final bloc = PosShiftBloc(posRepository: repo);
    addTearDown(bloc.close);
    bloc.add(const OpenShiftEvent(tokoId: 'B', amount: 1000, notes: ''));
    await waitFor(() => bloc.state is PosShiftLoaded);
    expect(repo.opens, 0);
    expect((bloc.state as PosShiftLoaded).activeShift?['toko_id'], 'A');
    expect(
      (bloc.state as PosShiftLoaded).notice,
      contains('Shift aktif ditemukan'),
    );
  });

  test('old outlet response cannot replace new outlet response', () async {
    final repo = _Repository()..deferred = true;
    final bloc = PosShiftBloc(posRepository: repo);
    addTearDown(bloc.close);
    bloc.add(const LoadShiftData('A'));
    await waitFor(() => repo.pending.containsKey('A'));
    bloc.add(const LoadShiftData('B'));
    await waitFor(() => repo.pending.containsKey('B'));
    repo.pending['B']!.complete({'_id': 'shift-b', 'toko_id': 'B'});
    await waitFor(() => bloc.state is PosShiftLoaded);
    repo.pending['A']!.complete({'_id': 'shift-a', 'toko_id': 'A'});
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect((bloc.state as PosShiftLoaded).activeShift?['toko_id'], 'B');
  });

  test(
    'read failure shows error rather than an empty open-shift form',
    () async {
      final repo = _Repository()..failRead = true;
      final bloc = PosShiftBloc(posRepository: repo);
      addTearDown(bloc.close);
      bloc.add(const OpenShiftEvent(tokoId: 'B', amount: 0, notes: ''));
      await waitFor(() => bloc.state is PosShiftError);
      expect(repo.opens, 0);
    },
  );

  test(
    'successful open reload is not swallowed by the mutation lock',
    () async {
      final repo = _Repository();
      final bloc = PosShiftBloc(posRepository: repo);
      addTearDown(bloc.close);
      bloc.add(const OpenShiftEvent(tokoId: 'B', amount: 0, notes: ''));
      await waitFor(() => bloc.state is PosShiftLoaded);
      expect(repo.opens, 1);
      expect((bloc.state as PosShiftLoaded).activeShift?['toko_id'], 'B');
    },
  );

  test(
    'duplicate open events while preflight waits do not duplicate mutation',
    () async {
      final repo = _Repository()..deferred = true;
      final bloc = PosShiftBloc(posRepository: repo);
      addTearDown(bloc.close);
      bloc.add(const OpenShiftEvent(tokoId: 'B', amount: 0, notes: ''));
      await waitFor(() => repo.pending.containsKey('B'));
      bloc.add(const OpenShiftEvent(tokoId: 'B', amount: 0, notes: ''));
      repo.pending['B']!.complete({'_id': 'existing', 'toko_id': 'B'});
      await waitFor(() => bloc.state is PosShiftLoaded);
      expect(repo.opens, 0);
    },
  );

  test(
    'operator change during preflight prevents opening under the replacement operator',
    () async {
      final repo = _Repository()..deferred = true;
      final bloc = PosShiftBloc(posRepository: repo);
      addTearDown(bloc.close);
      bloc.add(const OpenShiftEvent(tokoId: 'B', amount: 2000, notes: ''));
      await waitFor(() => repo.pending.containsKey('B'));
      repo.operatorId = 'cashier-b';
      repo.pending['B']!.complete(null);
      await waitFor(() => bloc.state is PosShiftError);
      expect(repo.opens, 0);
    },
  );

  test(
    'load requested during mutation preflight is replayed after the lock is released',
    () async {
      final repo = _Repository()..deferred = true;
      final bloc = PosShiftBloc(posRepository: repo);
      addTearDown(bloc.close);
      bloc.add(const OpenShiftEvent(tokoId: 'B', amount: 0, notes: ''));
      await waitFor(() => repo.pending.containsKey('B'));
      bloc.add(const LoadShiftData('C'));
      await Future<void>.delayed(const Duration(milliseconds: 15));
      repo.pending['B']!.complete({'_id': 'active-b', 'toko_id': 'B'});
      await waitFor(() => repo.pending.containsKey('C'));
      repo.pending['C']!.complete({'_id': 'active-c', 'toko_id': 'C'});
      await waitFor(
        () =>
            bloc.state is PosShiftLoaded &&
            (bloc.state as PosShiftLoaded).activeShift?['toko_id'] == 'C',
      );
      expect(repo.opens, 0);
    },
  );

  testWidgets(
    'recovery card names outlet and returns only after explicit tap on narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var returned = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PosShiftRecoveryCard(
                storeName: 'Outlet Bandung',
                onRetry: () {},
                onReturn: () => returned++,
              ),
            ),
          ),
        ),
      );
      expect(find.text('Shift masih aktif di Outlet Bandung'), findsOneWidget);
      expect(returned, 0);
      await tester.tap(find.text('Kembali ke shift aktif'));
      expect(returned, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing outlet access offers retry, never a bypass button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PosShiftRecoveryCard(storeName: 'Outlet lama', onRetry: () {}),
        ),
      ),
    );
    expect(find.text('Kembali ke shift aktif'), findsNothing);
    expect(find.text('Periksa kembali shift'), findsOneWidget);
  });

  test('store-context query and filtered-cache protection remain wired', () {
    final query = File('lib/data/graphql/pos_queries.dart').readAsStringSync();
    final repository = File(
      'lib/domain/repositories/pos_repository.dart',
    ).readAsStringSync();
    expect(query, contains('include_other_outlets: \$includeOtherOutlets'));
    expect(repository, contains('previous?.data[\'toko_id\'] == tokoId'));
  });
}
