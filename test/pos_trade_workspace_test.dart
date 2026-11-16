import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/network/pos_financial_request_store.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_trade.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_trade_repository.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_trade_workspace_page.dart';

PosTradeDocument document({
  PosTradeKind kind = PosTradeKind.payable,
  double outstanding = 60000,
}) => PosTradeDocument(
  instansiId: 'tenant',
  id: 'doc',
  kind: kind,
  number: 'MAN-001',
  reference: 'INV-001',
  party: 'Pemasok QA',
  date: '2026-11-12',
  dueDate: '2026-11-20',
  amount: 100000,
  paid: 100000 - outstanding,
  credited: 0,
  withheld: 0,
  outstanding: outstanding,
  status: 'partial',
  source: 'manual',
  basis: 'transaction',
  notes: '',
  canPay: outstanding > 0,
  paymentCount: 0,
  payments: const [],
);

class TradeRepository implements PosTradeRepository {
  bool createAllowed = true, uncertain = false;
  Failure? paymentFailure;
  final List<Map<String, dynamic>> writes = [];
  @override
  Future<Either<Failure, PosTradeOptions>> options() async => Right(
    PosTradeOptions({
      'today': '2026-11-13',
      'ar_scope': 'tenant',
      'view_ar': true,
      'view_ap': true,
      'create_ar': createAllowed,
      'create_ap': createAllowed,
      'receive_ar': true,
      'pay_ap': true,
      'ap_cash_available': true,
      'ap_cash_name': 'Kas Operasional',
      'ar_accounts': [
        {'code': '1200', 'name': 'Piutang'},
      ],
      'ap_accounts': [
        {'code': '2100', 'name': 'Utang'},
      ],
      'expense_accounts': [
        {'code': '6100', 'name': 'Operasional'},
      ],
      'income_accounts': [
        {'code': '4100', 'name': 'Penjualan'},
      ],
      'opening_accounts': [
        {'code': '3100', 'name': 'Modal'},
      ],
      'cash_accounts': [
        {'code': '1001', 'name': 'Kas'},
      ],
      'banks': [],
      'customers': [],
    }),
  );
  @override
  Future<Either<Failure, PosTradePage>> list(
    PosTradeKind kind, {
    String search = '',
    int page = 1,
    bool settled = false,
  }) async => Right(PosTradePage([document(kind: kind)], 1, 60000, 1, 20));
  @override
  Future<Either<Failure, PosTradeDocument>> detail(
    PosTradeKind kind,
    String id,
  ) async => Right(document(kind: kind));
  @override
  Future<Either<Failure, PosTradeDocument>> create(
    Map<String, dynamic> input,
  ) async {
    writes.add(Map.of(input));
    return Right(document());
  }

  @override
  Future<Either<Failure, PosTradeDocument>> pay(
    Map<String, dynamic> input,
  ) async {
    writes.add(Map.of(input));
    if (paymentFailure != null) return Left(paymentFailure!);
    return uncertain
        ? const Left(PosTradeUnconfirmedFailure())
        : Right(
            document(
              kind: PosTradeKind.values.byName(input['kind'] as String),
              outstanding: 0,
            ),
          );
  }
}

Widget app(
  TradeRepository repo,
  PosFinancialRequestStore store, {
  String? id,
  PosTradeKind kind = PosTradeKind.payable,
  double scale = 1,
}) => MaterialApp(
  locale: const Locale('id'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  builder: (ctx, child) => MediaQuery(
    data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: PosTradeWorkspacePage(
      operatorId: 'qa',
      repository: repo,
      requestStore: store,
      initialKind: kind,
      initialDocumentId: id,
    ),
  ),
);
void main() {
  setUpAll(() async => initializeDateFormatting());
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'customer collection can be corrected after a confirmed rejection',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = TradeRepository()
        ..paymentFailure = const PosTradeRejectedFailure(
          'Nominal ditolak server',
        );
      final store = PosFinancialRequestStore(
        await SharedPreferences.getInstance(),
        'qa',
      );
      final original = await store.begin('pay:receivable:doc', {
        'kind': 'receivable',
        'document_id': 'doc',
        'amount': 40000,
        'date': '2026-11-13',
        'method': 'cash',
        'cash_account': '1001',
        'reference': 'REJECTED',
      });
      await tester.pumpWidget(
        app(repo, store, kind: PosTradeKind.receivable, id: 'doc'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Konfirmasi ulang').first);
      await tester.pumpAndSettle();
      expect(store.pendingInvoiceIds, isEmpty);
      expect(find.text('Nominal ditolak server'), findsOneWidget);
      repo.paymentFailure = null;
      final receive = find.text('Catat Penerimaan');
      await tester.scrollUntilVisible(
        receive,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(receive);
      await tester.pumpAndSettle();
      await tester.tap(receive);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '20000');
      await tester.enterText(find.byType(TextFormField).at(1), 'CORRECTED');
      await tester.scrollUntilVisible(
        receive.last,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(receive.last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya, catat'));
      await tester.pumpAndSettle();
      expect(repo.writes.last['amount'], 20000);
      expect(repo.writes.last['cash_account'], '1001');
      expect(repo.writes.last['request_id'], isNot(original['request_id']));
      expect(store.pendingInvoiceIds, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'narrow phone shows unified ledger and hides unauthorized manual creation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = TradeRepository()..createAllowed = false;
      final store = PosFinancialRequestStore(
        await SharedPreferences.getInstance(),
        'qa',
      );
      await tester.pumpWidget(app(repo, store, scale: 1.4));
      await tester.pumpAndSettle();
      expect(find.text('Utang & Piutang'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Pemasok QA'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Pemasok QA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'lost supplier payment response preserves original evidence across restart',
    (tester) async {
      final prefs = await SharedPreferences.getInstance(),
          store = PosFinancialRequestStore(prefs, 'qa'),
          repo = TradeRepository()..uncertain = true;
      final frozen = await store.begin('pay:payable:doc', {
        'kind': 'payable',
        'document_id': 'doc',
        'amount': 40000,
        'date': '2026-11-13',
        'method': 'cash',
        'reference': 'PAY-ONE',
        'notes': '',
      });
      await tester.pumpWidget(app(repo, store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Konfirmasi ulang').first);
      await tester.pumpAndSettle();
      expect(repo.writes.single['request_id'], frozen['request_id']);
      expect(store.load('pay:payable:doc'), isNotNull);
      await tester.pumpWidget(const SizedBox());
      repo.uncertain = false;
      await tester.pumpWidget(app(repo, store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Konfirmasi ulang').first);
      await tester.pumpAndSettle();
      expect(repo.writes.last, repo.writes.first);
      expect(store.pendingInvoiceIds, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'legacy POS receipts replay canonical destination and request ID',
    (tester) async {
      final store = PosFinancialRequestStore(
            await SharedPreferences.getInstance(),
            'qa',
          ),
          repo = TradeRepository();
      final old = await store.begin('doc', {
        'invoice_id': 'doc',
        'amount': 40000,
        'date': '2026-11-13',
        'payment_method': 'cash',
        'cash_account_code': '1001',
        'reference': 'OLD-RECEIPT',
      });
      await tester.pumpWidget(app(repo, store, kind: PosTradeKind.receivable));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Konfirmasi ulang').first);
      await tester.pumpAndSettle();
      expect(repo.writes.single['request_id'], old['request_id']);
      expect(repo.writes.single['cash_account'], '1001');
      expect(repo.writes.single['document_id'], 'doc');
      expect(store.pendingInvoiceIds, isEmpty);
    },
  );
  testWidgets(
    'manual supplier entry requires confirmation and creates with account mapping',
    (tester) async {
      final repo = TradeRepository(),
          store = PosFinancialRequestStore(
            await SharedPreferences.getInstance(),
            'qa',
          );
      await tester.pumpWidget(app(repo, store));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Catat Tagihan Manual'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Vendor Baru');
      await tester.enterText(find.byType(TextFormField).at(1), 'INV-MANUAL');
      await tester.enterText(find.byType(TextFormField).at(2), '100000');
      final save = find.text('Simpan Tagihan');
      await tester.scrollUntilVisible(
        save,
        250,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repo.writes, isEmpty);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Ya, catat'));
      await tester.pumpAndSettle();
      expect(repo.writes.single['counter_account'], '6100');
      expect(repo.writes.single['control_account'], '2100');
      expect(repo.writes.single['amount'], 100000);
      expect(store.pendingInvoiceIds, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'supplier payment captures partial amount and evidence only after confirmation',
    (tester) async {
      final repo = TradeRepository(),
          store = PosFinancialRequestStore(
            await SharedPreferences.getInstance(),
            'qa',
          );
      await tester.pumpWidget(app(repo, store, id: 'doc'));
      await tester.pumpAndSettle();
      final pay = find.text('Catat Pembayaran');
      await tester.scrollUntilVisible(
        pay,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(pay);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '20000');
      await tester.enterText(find.byType(TextFormField).at(1), 'PAY-PARTIAL');
      await tester.scrollUntilVisible(
        pay.last,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(pay.last);
      await tester.pumpAndSettle();
      expect(repo.writes, isEmpty);
      await tester.tap(find.text('Ya, catat'));
      await tester.pumpAndSettle();
      expect(repo.writes.single['amount'], 20000);
      expect(repo.writes.single['reference'], 'PAY-PARTIAL');
      expect(repo.writes.single['method'], 'cash');
      expect(tester.takeException(), isNull);
    },
  );
}
