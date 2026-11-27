import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_keyboard_visibility.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_stock.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_stock_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_opening_stock_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_opening_stock_page.dart';

class _Provider extends Fake implements GraphQLClientProvider {
  @override
  String get subscriptionScope => 'server|tenant|owner|operator';
}

class _PosRepo extends Fake implements PosRepository {}

class _Bloc extends PosBloc {
  _Bloc(bool allowed) : super(posRepository: _PosRepo()) {
    emit(
      state.copyWith(
        runtimeConfig: {
          'permissions': {'initialize_stock': allowed},
        },
      ),
    );
  }
}

class _Stocks extends Fake implements PosStockRepository {
  bool offline = false;
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
  getStockLocations() async => offline
      ? const Left(ServerFailure('Offline'))
      : const Right([
          {'_id': 'wh', 'nama_cabang': 'Stok Toko'},
        ]);
  @override
  Future<Either<Failure, PosStockPageResult>> getStockPage({
    String? search,
    String? stockFilter,
    String? locationId,
    int page = 1,
    int limit = 20,
  }) async => Right(
    PosStockPageResult(
      [
        PosStock.fromJson({
          '_id': 'item',
          'nama_inventaris': 'Air Mineral',
          'stok': 0,
          'tracks_stock': true,
        }),
      ],
      1,
      const PosStockStatistics(
        totalInventaris: 1,
        totalNilaiInventaris: 0,
        lowStockCount: 0,
        outOfStockCount: 1,
      ),
    ),
  );
}

class _Opening extends Fake implements PosOpeningStockRepository {
  final SharedPreferences prefs;
  final gate = Completer<void>();
  final bool failFirst;
  int calls = 0;
  final inputs = <Map<String, dynamic>>[];
  final Map<String, dynamic> detailOverrides = {};
  _Opening(this.prefs, {this.failFirst = false});
  @override
  GraphQLClientProvider get provider => _Provider();
  @override
  OpeningStockDraft get draft =>
      OpeningStockDraft(prefs, provider.subscriptionScope);
  @override
  Future<Map<String, dynamic>> detail(String id) async => {
    '_id': 'item',
    'nama_inventaris': 'Air Mineral',
    'tracks_stock': true,
    'harga_beli': 3000,
    'base_unit': 'pcs',
    'unit_conversions': [
      {'unit': 'box', 'factor': 12},
    ],
    ...detailOverrides,
  };
  @override
  Future<void> submit(Map<String, dynamic> payload) async {
    calls++;
    inputs.add(await draft.prepare(payload));
    if (failFirst && calls == 1) throw StateError('Network terputus');
    if (!failFirst) await gate.future;
    await draft.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    await sl.reset();
    sl.registerSingleton<PosStockRepository>(_Stocks());
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
    await sl.reset();
  });
  Future<_Bloc> show(
    WidgetTester tester,
    _Opening repo, {
    bool allowed = true,
    Key? key,
    Future<void> Function()? done,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final bloc = _Bloc(allowed);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const PosKeyboardScrollBehavior(),
        builder: (_, child) => PosKeyboardVisibility(child: child!),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<PosBloc>.value(
          value: bloc,
          child: Scaffold(
            body: PosOpeningStockPage(
              key: key,
              repository: repo,
              initialProductId: 'item',
              initialLocationId: 'wh',
              onComplete: done,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return bloc;
  }

  testWidgets(
    'opening form converts box quantity and cost, prevents double submit and shows spinner',
    (tester) async {
      final repo = _Opening(await SharedPreferences.getInstance());
      var done = 0;
      await show(
        tester,
        repo,
        done: () async {
          done++;
        },
      );
      await tester.ensureVisible(find.text('Satuan jumlah dan biaya'));
      await tester.tap(find.text('pcs').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('box').last);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, '36.000'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Jumlah (box)'),
        '2',
      );
      final save = find.text('Simpan stok awal & lanjutkan');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      expect(find.text('Menyimpan…'), findsOneWidget);
      expect(repo.calls, 1);
      final row = (repo.inputs.single['items'] as List).single as Map;
      expect(row['qty'], 24);
      expect(row['hpp'], 3000);
      expect(row['lokasi_cabang_id'], 'wh');
      repo.gate.complete();
      await tester.pumpAndSettle();
      expect(done, 1);
    },
  );
  testWidgets(
    'lost response restores immutable request after reopening and retry succeeds',
    (tester) async {
      final repo = _Opening(
        await SharedPreferences.getInstance(),
        failFirst: true,
      );
      await show(tester, repo, key: const ValueKey('first'));
      final save = find.text('Simpan stok awal & lanjutkan');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final id = repo.draft.pending!['request_id'];
      expect(find.text('Periksa & coba lagi'), findsOneWidget);
      await show(tester, repo, key: const ValueKey('reload'));
      final retry = find.text('Periksa & coba lagi');
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(repo.inputs.last['request_id'], id);
      expect(repo.inputs.last, repo.inputs.first);
      expect(repo.draft.pending, isNull);
    },
  );
  testWidgets('restricted cashier has no opening stock action', (tester) async {
    final repo = _Opening(await SharedPreferences.getInstance());
    await show(tester, repo, allowed: false);
    expect(find.textContaining('Minta pengelola'), findsOneWidget);
    expect(find.text('Simpan stok awal & lanjutkan'), findsNothing);
    expect(repo.calls, 0);
  });
  testWidgets(
    'pending posting can be confirmed even when master reads are offline',
    (tester) async {
      final repo = _Opening(
        await SharedPreferences.getInstance(),
        failFirst: true,
      );
      await show(tester, repo, key: const ValueKey('online'));
      final save = find.text('Simpan stok awal & lanjutkan');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final original = repo.draft.pending;
      (sl<PosStockRepository>() as _Stocks).offline = true;
      await show(tester, repo, key: const ValueKey('offline-reopen'));
      final retry = find.widgetWithText(FilledButton, 'Periksa & coba lagi');
      await tester.ensureVisible(retry);
      expect(tester.widget<FilledButton>(retry).onPressed, isNotNull);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(repo.inputs.last, original);
      expect(repo.draft.pending, isNull);
    },
  );
  testWidgets(
    'successful stock posting can retry navigation without posting again',
    (tester) async {
      final repo = _Opening(await SharedPreferences.getInstance());
      var advances = 0;
      await show(
        tester,
        repo,
        done: () async {
          if (++advances == 1) throw StateError('Readiness unavailable');
        },
      );
      final save = find.text('Simpan stok awal & lanjutkan');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      repo.gate.complete();
      await tester.pumpAndSettle();
      final proceed = find.text('Lanjutkan');
      expect(proceed, findsOneWidget);
      await tester.tap(proceed);
      await tester.pumpAndSettle();
      expect(advances, 2);
      expect(repo.calls, 1);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed initial lookups can reload and save without leaving POS',
    (tester) async {
      final stocks = sl<PosStockRepository>() as _Stocks;
      stocks.offline = true;
      final repo = _Opening(await SharedPreferences.getInstance());
      await show(tester, repo);
      expect(find.textContaining('Offline'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Simpan stok awal & lanjutkan'),
            )
            .onPressed,
        isNull,
      );
      stocks.offline = false;
      final reload = find.text('Muat ulang barang/lokasi');
      await tester.ensureVisible(reload);
      await tester.tap(reload);
      await tester.pumpAndSettle();
      final save = find.text('Simpan stok awal & lanjutkan');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      repo.gate.complete();
      await tester.pumpAndSettle();
      expect(repo.calls, 1);
      expect(
        find.textContaining('Stok awal tersimpan. Gunakan'),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'zero quantity can be corrected and zero cost stock is accepted',
    (tester) async {
      final repo = _Opening(await SharedPreferences.getInstance());
      await show(tester, repo);
      final qty = find.widgetWithText(TextField, 'Jumlah (pcs)');
      await tester.ensureVisible(qty);
      await tester.enterText(qty, '0');
      final save = find.text('Simpan stok awal & lanjutkan');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repo.calls, 0);
      expect(
        find.textContaining('Jumlah harus lebih dari nol'),
        findsOneWidget,
      );
      await tester.ensureVisible(qty);
      await tester.enterText(qty, '2');
      final cost = find.widgetWithText(TextField, 'Biaya per pcs (Rp)');
      await tester.ensureVisible(cost);
      await tester.enterText(cost, '0');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pump();
      final row = (repo.inputs.single['items'] as List).single as Map;
      expect(row['qty'], 2);
      expect(row['hpp'], 0);
      repo.gate.complete();
      await tester.pumpAndSettle();
      expect(repo.draft.pending, isNull);
    },
  );
  testWidgets('FIFO batch expiry and serials are carried into the posting', (
    tester,
  ) async {
    final repo = _Opening(await SharedPreferences.getInstance());
    repo.detailOverrides.addAll({
      'valuation_method': 'fifo',
      'wajib_batch_number': true,
      'wajib_serial_number': true,
    });
    await show(tester, repo);
    for (final entry in {
      'Tanggal saldo awal (YYYY-MM-DD)': '2026-11-20',
      'Jumlah (pcs)': '2',
      'Tanggal perolehan (YYYY-MM-DD)': '2026-11-19',
      'Nomor batch *': 'B-TEST',
      'Kedaluwarsa (YYYY-MM-DD; wajib bila ada batch)': '2027-11-20',
      'Nomor seri (satu per baris, per unit dasar)': ' SN-1 \nSN-2\n',
    }.entries) {
      final field = find.widgetWithText(TextField, entry.key);
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
    }
    final save = find.text('Simpan stok awal & lanjutkan');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pump();
    final row = (repo.inputs.single['items'] as List).single as Map;
    expect(row['tanggal_perolehan'], '2026-11-19');
    expect(row['no_batch'], 'B-TEST');
    expect(row['tanggal_kadaluarsa'], '2027-11-20');
    expect(row['serial_numbers'], ['SN-1', 'SN-2']);
    expect(row['qty'], 2);
    repo.gate.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
