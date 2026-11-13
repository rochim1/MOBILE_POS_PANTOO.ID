import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/pos_financial_request_store.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_trade.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_trade_repository.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_trade_workspace_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android records manual supplier invoice and partial payment in real Finance',
    (tester) async {
      await initializeDateFormatting();
      final http = HttpClient();
      final response = await (await http.getUrl(
        Uri.parse('http://127.0.0.1:18097/qa/session'),
      )).close();
      final session =
          jsonDecode(await response.transform(utf8.decoder).join())
              as Map<String, dynamic>;
      http.close();
      final client = GraphQLClient(
        cache: GraphQLCache(),
        link: HttpLink(
          'http://127.0.0.1:18097/graphql',
          defaultHeaders: {
            'authorization': 'Bearer ${session['token']}',
            'apps': 'pos',
            'x-iid': session['tenant'] as String,
          },
        ),
      );
      final repo = GraphQLPosTradeRepository.withClient(
        () => client,
        tenant: () => session['tenant'] as String,
      );
      SharedPreferences.setMockInitialValues({});
      final store = PosFinancialRequestStore(
        await SharedPreferences.getInstance(),
        'isolated-trade-qa',
      );
      Widget app({String? id, PosTradeKind kind = PosTradeKind.payable}) =>
          MaterialApp(
            locale: const Locale('id'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: [
              AppLocalizations.delegate,
              ...GlobalMaterialLocalizations.delegates,
            ],
            home: Scaffold(
              body: PosTradeWorkspacePage(
                key: ValueKey('$kind:$id'),
                operatorId: 'isolated-qa',
                repository: repo,
                requestStore: store,
                initialKind: kind,
                initialDocumentId: id,
              ),
            ),
          );
      Future<void> settle() async {
        await tester.pumpAndSettle();
        for (
          var i = 0;
          i < 160 &&
              find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      final ref = 'ANDROID-${DateTime.now().millisecondsSinceEpoch}';
      await tester.pumpWidget(app());
      await settle();
      expect(find.text('Utang & Piutang'), findsOneWidget);
      await tester.tap(find.text('Catat Tagihan Manual'));
      await settle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'Pemasok Android Uji',
      );
      await tester.enterText(find.byType(TextFormField).at(1), ref);
      await tester.enterText(find.byType(TextFormField).at(2), '100000');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Simpan Tagihan'),
        220,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Simpan Tagihan'));
      await settle();
      await tester.tap(find.text('Ya, catat'));
      await settle();
      final page = (await repo.list(
        PosTradeKind.payable,
        search: ref,
      )).fold((f) => throw StateError(f.message), (p) => p);
      expect(page.items.length, 1);
      final doc = page.items.single;
      expect(doc.outstanding, 100000);
      final pay = find.text('Catat Pembayaran');
      await tester.scrollUntilVisible(
        pay,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(pay);
      await settle();
      await tester.enterText(find.byType(TextFormField).at(0), '40000');
      await tester.enterText(find.byType(TextFormField).at(1), '$ref-PAY');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        pay.last,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(pay.last);
      await settle();
      await tester.tap(find.text('Ya, catat'));
      await settle();
      final paid = (await repo.detail(
        PosTradeKind.payable,
        doc.id,
      )).fold((f) => throw StateError(f.message), (d) => d);
      expect(paid.outstanding, 60000);
      expect(paid.paymentCount, 1);
      expect(paid.payments.single.verified, true);
      expect(store.pendingInvoiceIds, isEmpty);
      // Exercise real AR + opening journals through the same mobile repository.
      for (final basis in ['transaction', 'opening']) {
        final ar = (await repo.create({
          'kind': 'receivable',
          'basis': basis,
          'party_name': 'Pelanggan Android Uji',
          'reference': '$ref-$basis',
          'date': session['today'],
          'due_date': session['today'],
          'amount': 50000,
          'control_account': '1200',
          'counter_account': basis == 'opening' ? '3100' : '4100',
          'request_id':
              'android_${basis}_${DateTime.now().microsecondsSinceEpoch}',
        })).fold((f) => throw StateError(f.message), (d) => d);
        final request = {
          'kind': 'receivable',
          'document_id': ar.id,
          'amount': 20000,
          'date': session['today'],
          'method': 'cash',
          'cash_account': '1000',
          'reference': '$ref-AR-$basis',
          'request_id': 'android_pay_${DateTime.now().microsecondsSinceEpoch}',
        };
        for (var i = 0; i < 2; i++) {
          final receipt = (await repo.pay(
            request,
          )).fold((f) => throw StateError(f.message), (d) => d);
          expect(receipt.outstanding, 30000);
          expect(receipt.paymentCount, 1);
          expect(receipt.payments.single.verified, true);
        }
      }
      await tester.pumpWidget(app(id: doc.id));
      await settle();
      expect(find.text('Pemasok Android Uji'), findsWidgets);
      debugPrint(
        'TRADE_ANDROID_UAT: manual AP 100000; partial payment 40000; outstanding 60000; AR transaction/opening and retry verified',
      );
    },
  );
}
