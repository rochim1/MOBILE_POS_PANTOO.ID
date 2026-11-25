import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';

class _Provider extends Fake implements GraphQLClientProvider {
  _Provider(this.client);
  @override
  final GraphQLClient client;
  @override
  String get endpointUrl => 'https://qa.invalid/graphql';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'instansi_id': 'tenant',
      'user_id': 'cashier',
    });
    prefs = await SharedPreferences.getInstance();
  });
  const acknowledged = <String, dynamic>{
    '_id': 'order',
    'order_no': 'ORD-QA',
    'status': 'completed',
    'status_pembayaran': 'lunas',
    'pos_transaction_invoice': 'INV-QA',
    'metode_pembayaran': 'tunai',
  };
  for (final scenario in [
    'empty',
    'wrong-order',
    'no-sale-proof',
    'unpaid-cash',
    'identity-changed',
    'cash',
    'credit',
    'credit-partial',
  ]) {
    test(
      'pending-order payment requires matching committed acknowledgement: $scenario',
      () async {
        var calls = 0;
        final data = {...acknowledged};
        if (scenario == 'empty') data.clear();
        if (scenario == 'wrong-order') data['_id'] = 'other';
        if (scenario == 'no-sale-proof') data['pos_transaction_invoice'] = null;
        if (scenario == 'unpaid-cash')
          data['status_pembayaran'] = 'belum_bayar';
        if (scenario.startsWith('credit')) {
          data['metode_pembayaran'] = 'tempo';
          data['status_pembayaran'] = scenario == 'credit'
              ? 'belum_bayar'
              : 'partial';
        }
        final client = GraphQLClient(
          cache: GraphQLCache(),
          defaultPolicies: DefaultPolicies(
            mutate: Policies(fetch: FetchPolicy.noCache),
          ),
          link: Link.function((request, [forward]) async* {
            calls++;
            if (scenario == 'identity-changed')
              await prefs.setString('instansi_id', 'other-tenant');
            yield Response(data: {'PayPOSOrder': data}, response: {});
          }),
        );
        final result = await PosRepository(
          _Provider(client),
          prefs,
        ).payPendingOrder(orderId: 'order', method: 'tunai', cashReceived: 100);
        expect(
          result.isRight(),
          ['cash', 'credit', 'credit-partial'].contains(scenario),
        );
        expect(calls, 1);
        if (scenario.startsWith('credit')) {
          expect(
            result.fold((_) => '', (paid) => paid['metode_pembayaran']),
            'tempo',
            reason:
                'Recovery must retain committed tender rather than the retry choice',
          );
        }
      },
    );
  }
}
