import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/core/network/pos_financial_request_store.dart';
import 'package:mobile_pos_pantoo/data/graphql/pos_receivable_queries.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_receivables_page.dart';

class _Provider extends Fake implements GraphQLClientProvider {
  _Provider(this.sharedPreferences);
  @override
  final SharedPreferences sharedPreferences;
  @override
  late GraphQLClient client;
  @override
  String get endpointUrl => 'https://qa.invalid/graphql';
}

void main() {
  for (final scenario in [
    'confirmed',
    'foreign',
    'tenant-change',
    'client-change',
  ]) {
    testWidgets(
      'receivable replay preserves proof unless matching current-session ACK: $scenario',
      (tester) async {
        SharedPreferences.setMockInitialValues({'instansi_id': 'tenant'});
        final prefs = await SharedPreferences.getInstance();
        final store = PosFinancialRequestStore(
          prefs,
          'https://qa.invalid/graphql:tenant:actor',
        );
        final proof = await store.begin('inv-1', {
          'invoice_id': 'inv-1',
          'amount': 1000,
          'payment_method': 'cash',
          'cash_account_code': '1001',
          'reference': 'QA',
        });
        final provider = _Provider(prefs);
        var writes = 0;
        final invoice = <String, dynamic>{
          '__typename': 'SalesInvoice',
          'invoice_date': null,
          'due_date': null,
          'source_context': null,
          '_id': 'inv-1',
          'invoice_number': 'INV-QA',
          'customer_name': 'QA Customer',
          'status': 'partial',
          'total_amount': 2000,
          'paid_amount': 1000,
          'credited_amount': 0,
          'outstanding_amount': 1000,
          'payments': <dynamic>[],
        };
        provider.client = GraphQLClient(
          cache: GraphQLCache(),
          defaultPolicies: DefaultPolicies(
            mutate: Policies(fetch: FetchPolicy.noCache),
          ),
          link: Link.function((request, [forward]) async* {
            if (request.operation.document ==
                gql(PosReceivableQueries.payment)) {
              writes++;
              expect(
                (request.variables['input'] as Map)['request_id'],
                proof['request_id'],
              );
              if (scenario == 'tenant-change')
                await prefs.setString('instansi_id', 'other');
              if (scenario == 'client-change')
                provider.client = GraphQLClient(
                  cache: GraphQLCache(),
                  link: Link.function(
                    (r, [f]) => const Stream<Response>.empty(),
                  ),
                );
              yield Response(
                data: {
                  'RecordPOSReceivablePayment': {
                    ...invoice,
                    '_id': scenario == 'foreign' ? 'inv-2' : 'inv-1',
                    'outstanding_amount': 0,
                  },
                },
                response: {},
              );
            } else {
              yield Response(
                data:
                    request.operation.document ==
                        gql(PosReceivableQueries.detail)
                    ? {'__typename': 'Query', 'GetPOSReceivable': invoice}
                    : {
                        '__typename': 'Query',
                        'GetSalesInvoiceOptions': {
                          '__typename': 'SalesInvoiceOptions',
                          'cash_accounts': [
                            {
                              '__typename': 'COAOption',
                              'code': '1001',
                              'name': 'Kas QA',
                            },
                          ],
                          'banks': <dynamic>[],
                        },
                      },
                response: {},
              );
            }
          }),
        );
        sl.pushNewScope();
        addTearDown(sl.popScope);
        sl.registerSingleton<GraphQLClientProvider>(provider);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: PosReceivablesPage(
                canCollect: true,
                operatorId: 'actor',
                initialInvoiceId: 'inv-1',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final send = find.widgetWithText(
          FilledButton,
          'Kirim ulang bukti yang sama',
        );
        await tester.ensureVisible(send);
        await tester.tap(send);
        await tester.pumpAndSettle();
        expect(writes, 1);
        expect(store.load('inv-1') == null, scenario == 'confirmed');
        if (scenario != 'confirmed') {
          expect(store.load('inv-1')?['request_id'], proof['request_id']);
          expect(
            find.text('Penerimaan tercatat di Finance. Stok tidak berubah.'),
            findsNothing,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
