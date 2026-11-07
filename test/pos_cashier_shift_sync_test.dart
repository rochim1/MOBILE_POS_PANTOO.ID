import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/hold_order.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/domain/services/pos_shift_sync.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_shift/pos_shift_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_active_shift_tab.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_shift_sync_error.dart';

PosStore store(String id, {String mode = 'per_operator', String? branch}) =>
    PosStore(
      id: id,
      name: 'Outlet $id',
      status: 'active',
      branchId: branch ?? 'branch-$id',
      shiftMode: mode,
    );
Map<String, dynamic> shift(String id, {String owner = 'cashier'}) => {
  '_id': 'shift-$id',
  'toko_id': id,
  'kasir_user_id': owner,
  'status': 'open',
  'toko': {'nama_toko': 'Outlet $id'},
};

class _Repo extends Fake implements PosRepository {
  String operatorId = 'cashier';
  String accountId = 'terminal';
  List<PosStore> stores = [store('A'), store('B')];
  Map<String, dynamic>? active = shift('B');
  final List<String> requests = [], branches = [];
  Future<Map<String, dynamic>?> Function(String)? read;
  @override
  String get activeOperatorId => operatorId;
  @override
  String get terminalUserId => accountId;
  @override
  Future<Map<String, dynamic>> getRuntimeConfig() async => {
    // Match the actual runtime contract: shift discovery is separately allowed.
    'permissions': {'use_cashier': true, 'view_shifts': true},
  };
  @override
  Future<List<PosStore>> getStores() async => stores;
  @override
  Future<Map<String, dynamic>?> getActiveShiftForStore(String id) async {
    requests.add(id);
    return read == null ? active : await read!(id);
  }

  @override
  Future<Map<String, dynamic>?> getActiveShift([String? id]) async =>
      throw StateError('Unscoped lookup is forbidden');
  @override
  Future<List<PosProduct>> getProducts({String? branchId}) async {
    branches.add(branchId ?? '');
    return [];
  }

  @override
  Future<List<HoldOrder>> getHeldOrders({
    String? storeId,
    String? shiftId,
  }) async => [];
  @override
  Future<Map<String, dynamic>> getDashboardData({int days = 7}) async => {};
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getShiftHistory({
    int page = 0,
    int limit = 100,
  }) async => const Right([]);
}

class _Lock extends Fake implements AppLockCubit {
  @override
  AppLockState get state => const AppLockState(
    activeEmployeeId: 'cashier',
    activeEmployeeName: 'Kasir QA',
  );
  @override
  Stream<AppLockState> get stream => const Stream.empty();
}

class _SeededBloc extends PosBloc {
  _SeededBloc(PosRepository repository) : super(posRepository: repository);
  void seed(PosState value) => emit(value);
}

Future<void> until(bool Function() done) async {
  for (var i = 0; i < 100 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(done(), isTrue);
}

Future<Map<String, dynamic>?> _discover(
  _Repo repo, {
  String? preferredStoreId,
  Map<String, dynamic> runtime = const {},
  bool Function()? current,
}) => discoverCheckoutShift(
  stores: repo.stores,
  runtimeConfig: runtime,
  operatorId: repo.operatorId,
  terminalUserId: repo.accountId,
  preferredStoreId: preferredStoreId,
  readShift: repo.getActiveShiftForStore,
  isCurrent: current ?? () => true,
);

void main() {
  test(
    'a populated cart is preserved across a conflicting shift until explicitly cleared',
    () async {
      final repo = _Repo();
      final bloc = _SeededBloc(repo);
      addTearDown(bloc.close);
      repo.active = shift('A');
      bloc.add(LoadPosData());
      await until(() => bloc.state.status == PosStatus.success);
      const product = PosProduct(
        id: 'item',
        code: 'item',
        name: 'Barang A',
        category: '',
        price: 1000,
        stock: 10,
      );
      bloc.seed(bloc.state.copyWith(cart: {product: 1}));
      repo.active = shift('B');
      bloc.add(LoadPosData());
      await until(() => bloc.state.status == PosStatus.failure);
      expect(bloc.state.checkoutSyncFailed, isTrue);
      expect(bloc.state.cart[product], 1);
      bloc.add(ClearCart());
      await until(() => bloc.state.cart.isEmpty);
      bloc.add(LoadPosData());
      await until(
        () =>
            bloc.state.status == PosStatus.success &&
            bloc.state.activeShift?['toko_id'] == 'B',
      );
      expect(bloc.state.checkoutStore?.id, 'B');
      expect(bloc.state.checkoutSyncFailed, isFalse);
    },
  );
  test(
    'cashier loads the active outlet and its catalog without selecting the first store',
    () async {
      final repo = _Repo();
      final bloc = PosBloc(posRepository: repo);
      addTearDown(bloc.close);
      bloc.add(LoadPosData());
      await until(() => bloc.state.status == PosStatus.success);
      expect(bloc.state.activeShift?['toko_id'], 'B');
      expect(bloc.state.checkoutStore?.id, 'B');
      expect(repo.branches, ['branch-B']);
      expect(repo.requests, ['A']);
    },
  );

  test(
    'legacy unknown store mode requires online refresh, never guesses terminal ownership',
    () async {
      final repo = _Repo()..stores = [store('A', mode: '')];
      await expectLater(_discover(repo), throwsA(isA<StateError>()));
      expect(repo.requests, isEmpty);
    },
  );

  test(
    'offline snapshot of another ownership mode does not block the matching outlet',
    () async {
      final repo = _Repo()
        ..stores = [store('A', mode: 'shared_register'), store('B')]
        ..active = {
          ...shift('B'),
          'shift_mode': 'per_operator',
          '_offline_snapshot': true,
        };
      expect((await _discover(repo))?['toko_id'], 'B');
      expect(repo.requests, ['A', 'B']);
    },
  );

  test(
    'shared default cannot hide an existing PIN shift in another outlet',
    () async {
      final repo = _Repo()
        ..stores = [
          store('A', mode: 'shared_register'),
          store('B'),
          store('C'),
        ];
      repo.read = (id) async => id == 'A' ? null : shift('B');
      expect((await _discover(repo))?['toko_id'], 'B');
      expect(repo.requests, ['A', 'B']);
    },
  );

  test(
    'preferred store ownership wins rather than whichever global shift is newest',
    () async {
      final repo = _Repo()
        ..stores = [store('A', mode: 'shared_register'), store('B')];
      repo.read = (id) async =>
          id == 'A' ? shift('A', owner: 'terminal') : shift('B');
      expect((await _discover(repo, preferredStoreId: 'B'))?['toko_id'], 'B');
      expect(repo.requests, ['B']);
    },
  );

  test(
    'different PIN or account cannot inherit another owners shift including an offline snapshot',
    () async {
      for (final mode in ['per_operator', 'shared_register']) {
        final repo = _Repo()..stores = [store('A', mode: mode)];
        repo.active = {
          ...shift('A', owner: 'unrelated-user'),
          '_offline_snapshot': true,
        };
        await expectLater(_discover(repo), throwsStateError);
      }
      final repo = _Repo()..active = null;
      expect(await _discover(repo), isNull);
    },
  );

  test(
    'cached shift for the correct operator and outlet can be used without choosing a store',
    () async {
      final repo = _Repo()..active = {...shift('B'), '_offline_snapshot': true};
      expect((await _discover(repo))?['toko_id'], 'B');
    },
  );

  test('inaccessible or no-longer-selling shift outlet fails closed', () async {
    final repo = _Repo()..stores = [store('A')];
    await expectLater(_discover(repo), throwsStateError);
    repo.stores = [store('A'), store('B')];
    await expectLater(
      _discover(
        repo,
        runtime: {
          'inventory_policy': {
            'inventory_profile': 'simple',
            'default_receiving_location_id': 'branch-A',
          },
        },
      ),
      throwsStateError,
    );
  });

  test(
    'read failures never become a no-shift state or trigger catalog loading',
    () async {
      final repo = _Repo()
        ..read = (_) async =>
            throw StateError('Offline and no trusted snapshot');
      final bloc = PosBloc(posRepository: repo);
      addTearDown(bloc.close);
      bloc.add(LoadPosData());
      await until(() => bloc.state.status == PosStatus.failure);
      expect(bloc.state.activeShift, isNull);
      expect(repo.branches, isEmpty);
    },
  );

  test('no PIN cannot perform a per-operator shift lookup', () async {
    final repo = _Repo()..operatorId = '';
    await expectLater(_discover(repo), throwsStateError);
    expect(repo.requests, isEmpty);
  });

  test('a response after the cashier identity changes is rejected', () async {
    final repo = _Repo();
    final pending = Completer<Map<String, dynamic>?>();
    repo.read = (_) => pending.future;
    var current = true;
    final result = _discover(repo, current: () => current);
    current = false;
    pending.complete(shift('B'));
    await expectLater(result, throwsStateError);
  });

  test(
    'a slow previous load cannot overwrite the newly selected cashier',
    () async {
      final repo = _Repo();
      final old = Completer<Map<String, dynamic>?>();
      var first = true;
      repo.read = (_) async {
        if (first) {
          first = false;
          return old.future;
        }
        return shift('A', owner: 'new-cashier');
      };
      final bloc = PosBloc(posRepository: repo);
      addTearDown(bloc.close);
      bloc.add(LoadPosData());
      await until(() => repo.requests.isNotEmpty);
      repo.operatorId = 'new-cashier';
      bloc.add(LoadPosData());
      await until(() => bloc.state.status == PosStatus.success);
      old.complete(shift('B'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.activeShift?['kasir_user_id'], 'new-cashier');
      expect(bloc.state.checkoutStore?.id, 'A');
      expect(repo.branches, ['branch-A']);
    },
  );

  testWidgets(
    'active shift tab follows a discovered outlet without pressing return or choosing a store',
    (tester) async {
      final repo = _Repo()
        ..active = {
          ...shift('B'),
          'opening_cash': 20000,
          'closing_cash_expected': 9000,
          'cash_refund_total': 1000,
        };
      final bloc = PosBloc(posRepository: repo);
      final shifts = PosShiftBloc(posRepository: repo);
      addTearDown(bloc.close);
      addTearDown(shifts.close);
      bloc.add(LoadPosData());
      await tester.runAsync(
        () => until(() => bloc.state.status == PosStatus.success),
      );
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<PosBloc>.value(value: bloc),
            BlocProvider<PosShiftBloc>.value(value: shifts),
            BlocProvider<AppLockCubit>.value(value: _Lock()),
          ],
          child: const MaterialApp(home: Scaffold(body: PosActiveShiftTab())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Shift sedang berjalan'), findsOneWidget);
      expect(find.text('Refund tunai'), findsOneWidget);
      expect(find.textContaining('29.000'), findsOneWidget);
      expect(find.text('Kembali ke shift aktif'), findsNothing);
      final selector = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(selector.value, 'B');
      expect(selector.onChanged, isNull);
      expect(repo.requests.last, 'B');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shift tab corrects a stale first-store selection automatically after its own lookup',
    (tester) async {
      final repo = _Repo();
      final bloc = _SeededBloc(repo)
        ..seed(PosState(status: PosStatus.success, stores: repo.stores));
      final shifts = PosShiftBloc(posRepository: repo);
      addTearDown(bloc.close);
      addTearDown(shifts.close);
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<PosBloc>.value(value: bloc),
            BlocProvider<PosShiftBloc>.value(value: shifts),
            BlocProvider<AppLockCubit>.value(value: _Lock()),
          ],
          child: const MaterialApp(home: Scaffold(body: PosActiveShiftTab())),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
            .value,
        'B',
      );
      expect(find.text('Shift sedang berjalan'), findsOneWidget);
      expect(find.text('Kembali ke shift aktif'), findsNothing);
      expect(repo.requests, ['A']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'shift lookup error has a usable retry on a narrow phone, not an opening form',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosShiftSyncError(
              message: 'Periksa koneksi dan PIN',
              onRetry: () => retries++,
            ),
          ),
        ),
      );
      expect(find.text('Buka Shift Kasir'), findsNothing);
      await tester.tap(find.text('Periksa kembali'));
      expect(retries, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
