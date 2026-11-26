import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/data/graphql/pos_transfer_queries.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_transfer_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_stock_repository.dart';

class TransferProvider extends Fake implements GraphQLClientProvider {
  String scope = 'endpoint|tenant|owner|operator';
  final SharedPreferences prefs;
  final GraphQLClient graph;
  TransferProvider(this.prefs, Stream<Response> Function(Request) run)
    : graph = GraphQLClient(link: Link.function((r, [f]) => run(r)), cache: GraphQLCache());
  @override String get subscriptionScope => scope;
  @override SharedPreferences get sharedPreferences => prefs;
  @override GraphQLClient get client => graph;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const root = 'CreateInventoryTransfer';
  final variables = {'request_id': 'first-request', 'input': {
    'dari': {'cabang_id':'from'}, 'ke': {'cabang_id':'to'},
    'items': [{'inventaris_id':'product','qty':1}],
  }};
  test('lost create response survives repository recreation and exact recovery clears proof', () async {
    var fail = true;
    final sent = <Map<String,dynamic>>[];
    final p = TransferProvider(await SharedPreferences.getInstance(), (r) async* {
      sent.add(r.variables);
      if (fail) throw StateError('response lost');
      yield const Response(response:{},data:{root:{'_id':'doc','status':'draft'}});
    });
    final repo = PosTransferRepository(p);
    await expectLater(repo.execute(PosTransferQueries.create, variables, root), throwsA(anything));
    final reopened = PosTransferRepository(p);
    expect(reopened.pendingIntent()?['variables'], variables);
    fail = false;
    expect((await reopened.recoverPending())['_id'], 'doc');
    expect(sent[1], sent[0]);
    expect(reopened.pendingIntent(), isNull);
  });
  test('pending receipt blocks changed payload and survives account switch', () async {
    var calls = 0;
    final p = TransferProvider(await SharedPreferences.getInstance(), (r) async* {
      calls++; throw StateError('lost');
    });
    final repo = PosTransferRepository(p);
    final payload = {'id':'doc','request_id':'receipt-1','items':[{'item_id':'line','qty':1}]};
    await expectLater(repo.execute(PosTransferQueries.receive,payload,'ReceiveInventoryTransfer'), throwsA(anything));
    await expectLater(repo.execute(PosTransferQueries.receive,{...payload,'items':[{'item_id':'line','qty':2}]},'ReceiveInventoryTransfer'), throwsA(anything));
    expect(calls,1);
    p.scope = 'endpoint|tenant|owner|other';
    expect(repo.pendingIntent(documentId:'doc'),isNull);
    p.scope = 'endpoint|tenant|owner|operator';
    expect(repo.pendingIntent(documentId:'doc'),isNotNull);
  });
  test('double submit across repository instances shares one request', () async {
    final gate = Completer<void>(); var calls=0;
    final p=TransferProvider(await SharedPreferences.getInstance(),(r) async* {
      calls++; await gate.future;
      yield const Response(response:{},data:{root:{'_id':'doc'}});
    });
    final a=PosTransferRepository(p).execute(PosTransferQueries.create,variables,root);
    final b=PosTransferRepository(p).execute(PosTransferQueries.create,variables,root);
    await Future<void>.delayed(const Duration(milliseconds:20));
    gate.complete(); await Future.wait([a,b]); expect(calls,1);
  });
  test('fresh validation rejection unlocks editing, replay rejection retains proof', () async {
    var lost=false;
    final p=TransferProvider(await SharedPreferences.getInstance(),(r) async* {
      if(lost)throw StateError('lost');
      yield const Response(response:{},errors:[GraphQLError(message:'invalid',extensions:{'code':'BAD_REQUEST'})]);
    });
    final repo=PosTransferRepository(p);
    await expectLater(repo.execute(PosTransferQueries.create,variables,root),throwsA(anything));
    expect(repo.pendingIntent(),isNull);
    lost=true;
    await expectLater(repo.execute(PosTransferQueries.create,variables,root),throwsA(anything));
    lost=false;
    await expectLater(repo.recoverPending(),throwsA(anything));
    expect(repo.pendingIntent(),isNotNull);
  });
  test('stock locations and rack balances continue past 200 rows', () async {
    final pages=<String>[];
    final p=TransferProvider(await SharedPreferences.getInstance(),(r) async* {
      final balances=r.variables.containsKey('inventoryId');
      final page=r.variables['page'] as int? ?? 0;
      pages.add('${balances ? 'balance':'warehouse'}:$page');
      final rows=List.generate(page==0?200:1,(i)=>{'_id':'$page-$i','qty':1});
      yield Response(response:const {},data:balances
        ? {'GetInventoryLocationBalances':{'items':rows}}
        : {'getAllCabangs':{'cabang':rows}});
    });
    final repo=PosStockRepository(p);
    final locations=await repo.getStockLocations();
    final balances=await repo.getLocationBalances(inventoryId:'product');
    expect(locations.getOrElse(()=>[]).length,201);
    expect(balances.getOrElse(()=>[]).length,201);
    expect(pages,['warehouse:0','warehouse:1','balance:0','balance:1']);
  });
}
