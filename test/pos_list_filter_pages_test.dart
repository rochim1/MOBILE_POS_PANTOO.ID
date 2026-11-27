import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_table.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_promo_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_table_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/purchase_return_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_promo/pos_promo_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_promo/pos_promo_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_promo/pos_promo_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_return/pos_return_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_return/pos_return_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_return/pos_return_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_shift/pos_shift_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_shift/pos_shift_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_shift/pos_shift_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_promo_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_return_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_purchase_return_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_table_management_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_shift_history_tab.dart';

class _Repo extends Fake implements PosRepository {
  @override
  Map<String, dynamic>? pendingReturnDraft() => null;
}

class _PromoRepo extends Fake implements PosPromoRepository {}

class _Pos extends PosBloc {
  _Pos() : super(posRepository: _Repo()) {
    emit(
      state.copyWith(
        activeShift: {'toko_id': 'store'},
        runtimeConfig: {
          'features': {'use_tables': true},
          'permissions': {
            'manage_tables': true,
            'create_purchase_returns': true,
          },
        },
      ),
    );
  }
}

class _Promo extends PosPromoBloc {
  _Promo() : super(promoRepository: _PromoRepo()) {
    emit(const PosPromoState(status: PosPromoStatus.success));
  }
  @override
  void add(PosPromoEvent event) {}
}

class _Returns extends PosReturnBloc {
  _Returns() : super(posRepository: _Repo()) {
    emit(const PosReturnState(status: PosReturnStatus.success));
  }
  @override
  void add(PosReturnEvent event) {}
}

class _Shifts extends PosShiftBloc {
  _Shifts() : super(posRepository: _Repo()) {
    emit(
      const PosShiftLoaded(
        shiftHistory: [
          {
            'toko': {'nama_toko': 'Toko QA'},
            'user': {'name': 'Kasir QA'},
            'status': 'open',
          },
        ],
      ),
    );
  }
  @override
  void add(PosShiftEvent event) {}
}

class _Tables extends Fake implements PosTableRepository {
  int reads = 0;
  @override
  Future<Either<Failure, List<PosTableModel>>> getTables({
    required String storeId,
    String? search,
    int limit = 100,
  }) async {
    reads++;
    return const Right([
      PosTableModel(id: 't1', name: 'Meja QA', area: 'Depan'),
    ]);
  }
}

class _PurchaseReturns extends Fake implements PurchaseReturnRepository {
  int reads = 0;
  final requests = <Map<String, String>>[];
  final pending =
      <String, Completer<Either<Failure, PurchaseReturnPageResult>>>{};
  final pages = <String, PurchaseReturnPageResult>{};
  @override
  Future<Either<Failure, Map<String, List<Map<String, dynamic>>>>>
  getTransactionOptions() async => const Right({
    'reasons': [
      {'value': 'damaged', 'label': 'Barang rusak'},
    ],
    'methods': [
      {'value': 'credit_note', 'label': 'Nota kredit'},
    ],
  });
  @override
  Future<Either<Failure, PurchaseReturnPageResult>> getAll({
    String search = '',
    String status = '',
    String reason = '',
    String method = '',
    String dateFrom = '',
    String dateTo = '',
    int page = 1,
    int limit = 20,
  }) async {
    reads++;
    requests.add({
      'search': search,
      'status': status,
      'reason': reason,
      'method': method,
    });
    if (pending[search] != null) return pending[search]!.future;
    return Right(pages[search] ?? const PurchaseReturnPageResult([], 0));
  }
}

void main() {
  setUpAll(initializeDateFormatting);
  setUp(() => sl.pushNewScope());
  tearDown(() => sl.popScope());
  Future<void> openPurchaseReturns(
    WidgetTester tester,
    _PurchaseReturns repository,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    sl.registerSingleton<PurchaseReturnRepository>(repository);
    final pos = _Pos();
    addTearDown(pos.close);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<PosBloc>.value(
            value: pos,
            child: const PosPurchaseReturnPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'supplier return filter cancel does not query, Apply commits one coherent filter',
    (tester) async {
      final repository = _PurchaseReturns();
      await openPurchaseReturns(tester, repository);
      await tester.enterText(find.byType(TextField), 'INV-QA');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      final reads = repository.reads;
      final toggle = find.byKey(const Key('purchase_return_filter_toggle'));
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      var choices = find.byType(DropdownButtonFormField<String>);
      tester.widget<DropdownButtonFormField<String>>(choices.at(0)).onChanged!(
        'approved',
      );
      await tester.pumpAndSettle();
      expect(repository.reads, reads);
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      choices = find.byType(DropdownButtonFormField<String>);
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(choices.at(0))
            .initialValue,
        '',
      );
      tester.widget<DropdownButtonFormField<String>>(choices.at(0)).onChanged!(
        'approved',
      );
      tester.widget<DropdownButtonFormField<String>>(choices.at(1)).onChanged!(
        'damaged',
      );
      tester.widget<DropdownButtonFormField<String>>(choices.at(2)).onChanged!(
        'credit_note',
      );
      await tester.pumpAndSettle();
      final apply = find.text('Terapkan');
      await tester.ensureVisible(apply);
      await tester.tap(apply);
      await tester.pumpAndSettle();
      expect(repository.reads, reads + 1);
      expect(repository.requests.last, {
        'search': 'INV-QA',
        'status': 'approved',
        'reason': 'damaged',
        'method': 'credit_note',
      });
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('late supplier return search cannot replace newer results', (
    tester,
  ) async {
    final repository = _PurchaseReturns();
    repository.pending['old'] = Completer();
    repository.pages['new'] = const PurchaseReturnPageResult([
      {
        '_id': 'new',
        'no_return': 'NEW-QA',
        'approval_status': 'draft',
        'supplier_name': 'Vendor QA',
      },
    ], 1);
    await openPurchaseReturns(tester, repository);
    await tester.enterText(find.byType(TextField), 'old');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.enterText(find.byType(TextField), 'new');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    repository.pending['old']!.complete(
      const Right(
        PurchaseReturnPageResult([
          {'_id': 'old', 'no_return': 'OLD-QA', 'approval_status': 'draft'},
        ], 1),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('NEW-QA'), findsOneWidget);
    expect(find.text('OLD-QA'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final page in [
    'promo',
    'return',
    'purchase_return',
    'table',
    'shift_history',
  ]) {
    for (final width in [320.0, 390.0, 800.0]) {
      testWidgets('$page compact filters at $width', (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        sl.registerSingleton<SharedPreferences>(
          await SharedPreferences.getInstance(),
        );
        final tables = _Tables();
        final purchaseReturns = _PurchaseReturns();
        sl.registerSingleton<PosTableRepository>(tables);
        sl.registerSingleton<PurchaseReturnRepository>(purchaseReturns);
        sl.registerFactory<PosPromoBloc>(_Promo.new);
        final pos = _Pos(), returns = _Returns(), shifts = _Shifts();
        final child = switch (page) {
          'promo' => const PosPromoPage(),
          'return' => BlocProvider<PosReturnBloc>.value(
            value: returns,
            child: const PosReturnView(permissions: {'create_returns': true}),
          ),
          'purchase_return' => const PosPurchaseReturnPage(),
          'table' => const PosTableManagementPage(),
          _ => BlocProvider<PosShiftBloc>.value(
            value: shifts,
            child: const PosShiftHistoryTab(),
          ),
        };
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(width == 390 ? 'en' : 'id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BlocProvider<PosBloc>.value(
              value: pos,
              child: Scaffold(body: child),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final toggle = find.byKey(Key('${page}_filter_toggle'));
        if (['return', 'purchase_return', 'shift_history'].contains(page)) {
          expect(toggle, findsOneWidget);
          expect(find.byType(TextField), findsOneWidget);
          await tester.enterText(find.byType(TextField), 'QA');
          await tester.pump(const Duration(milliseconds: 600));
          await tester.pumpAndSettle();
          final reads = purchaseReturns.reads;
          await tester.tap(toggle);
          await tester.pumpAndSettle();
          if (page == 'purchase_return') {
            expect(find.byType(BottomSheet), findsOneWidget);
            expect(
              find.byType(DropdownButtonFormField<String>),
              findsNWidgets(3),
            );
            await tester.tapAt(const Offset(8, 8));
          } else {
            expect(
              find.byType(DropdownButtonFormField<String>),
              findsOneWidget,
            );
            await tester.tap(toggle);
          }
          await tester.pumpAndSettle();
          expect(find.text('QA'), findsOneWidget);
          expect(purchaseReturns.reads, reads);
        } else if (width < 600) {
          expect(toggle, findsOneWidget);
          expect(find.byType(TextField), findsNothing);
          if (page == 'table') {
            expect(
              find.byTooltip(
                width == 390
                    ? 'Print QR codes for all tables'
                    : 'Cetak QR semua meja',
              ),
              findsOneWidget,
            );
          }
          if (page == 'return' ||
              page == 'promo' ||
              page == 'purchase_return') {
            expect(find.byIcon(Icons.add), findsOneWidget);
          }
          final initialReads = tables.reads + purchaseReturns.reads;
          await tester.tap(toggle);
          await tester.pumpAndSettle();
          expect(find.byType(TextField), findsOneWidget);
          await tester.enterText(find.byType(TextField), 'QA');
          await tester.pump(const Duration(milliseconds: 600));
          await tester.pumpAndSettle();
          final afterSearch = tables.reads + purchaseReturns.reads;
          expect(afterSearch, greaterThanOrEqualTo(initialReads));
          await tester.tap(toggle);
          await tester.pumpAndSettle();
          expect(find.byType(TextField), findsNothing);
          await tester.tap(toggle);
          await tester.pumpAndSettle();
          expect(find.text('QA'), findsOneWidget);
          expect(tables.reads + purchaseReturns.reads, afterSearch);
        } else {
          expect(toggle, findsNothing);
          expect(find.byType(TextField), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(() async {
          await pos.close();
          await returns.close();
          await shifts.close();
        });
      });
    }
  }
}
