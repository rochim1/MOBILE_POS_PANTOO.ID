import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_receivables_page.dart';

class _Provider extends Fake implements GraphQLClientProvider {
  _Provider(this.sharedPreferences, this.client);
  @override
  final SharedPreferences sharedPreferences;
  @override
  final GraphQLClient client;
  @override
  String get endpointUrl => 'https://qa.invalid/graphql';
}

void main() {
  testWidgets('legacy invoice ledger collapses list filters without replaying payments', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'instansi_id': 'qa'});
    final reads = <String>[];
    final client = GraphQLClient(cache: GraphQLCache(), link: Link.function((request, [forward]) {
      reads.add(request.operation.operationName!);
      return Stream.value(const Response(data: {'GetPOSReceivables': {
        'items': [], 'totalCount': 0, 'summary': {'outstanding_amount': 0},
      }}));
    }));
    sl.pushNewScope();
    addTearDown(sl.popScope);
    sl.registerSingleton<GraphQLClientProvider>(_Provider(await SharedPreferences.getInstance(), client));
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('id'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: PosReceivablesPage(canCollect: false, operatorId: 'qa')),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    final toggle = find.byKey(const Key('receivable_filter_toggle'));
    await tester.tap(toggle); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'INV-42');
    await tester.tap(toggle); await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await tester.tap(toggle); await tester.pumpAndSettle();
    expect(find.text('INV-42'), findsOneWidget);
    expect(reads, ['POSReceivables']);
    expect(find.byType(FilledButton), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    client.dispose();
  });
}
