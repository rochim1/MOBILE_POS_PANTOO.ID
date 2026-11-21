import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/core/subscription/pos_subscription_link.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_product_import_repository.dart';

class _Provider extends Fake implements GraphQLClientProvider {
  final SharedPreferences prefs;
  String scope='endpoint|tenant|owner|operator';
  SubscriptionMutationGuard? guard;
  bool switchOnHeaders=false;
  _Provider(this.prefs);
  @override String get subscriptionScope=>scope;
  @override SharedPreferences get sharedPreferences=>prefs;
  @override String get endpointUrl=>'http://localhost/graphql';
  @override bool get requiresOperatorVerification=>false;
  @override SubscriptionMutationGuard? get subscriptionGuard=>guard;
  @override Future<Map<String,String>> authenticatedRequestHeaders() async { if(switchOnHeaders) scope='different'; return {'apps':'pos','x-pos-operator-token':'synthetic'}; }
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Provider provider;
  final bytes=Uint8List.fromList(utf8.encode('nama_inventaris\nTest\n'));
  final result={'importedCount':1,'failedCount':0,'skippedCount':0,'totalProcessed':1,'stockItemIds':['stock'],'errors':[],'warnings':[],'previewRows':[]};
  setUp(() async { SharedPreferences.setMockInitialValues({}); provider=_Provider(await SharedPreferences.getInstance()); });
  http.Response response(Map data)=>http.Response(jsonEncode({'data':{'ImportInventarisUmum':data}}),200);
  test('preview multipart is authenticated and has no pending write',() async {
    late http.Request sent;
    final repo=PosProductImportRepository(provider,client:MockClient((r)async { sent=r;return response(result); }));
    final r=await repo.upload(bytes:bytes,filename:'test.csv',preview:true);
    expect(r.importedCount,1); expect(repo.pending,isNull);
    expect(sent.headers['x-pos-operator-token'],'synthetic'); expect(sent.body,contains('"preview":true'));
    expect(sent.body,contains('variables.file')); expect(sent.body,contains(PosProductImportRepository.requestId(bytes)));
  });
  test('lost response survives reopen; wrong file blocked; exact retry clears pending',() async {
    var fail=true,calls=0;
    final client=MockClient((r) async { calls++; if(fail) throw StateError('lost'); return response(result); });
    final repo=PosProductImportRepository(provider,client:client);
    await expectLater(repo.upload(bytes:bytes,filename:'test.csv',preview:false),throwsA(anything));
    final pending=repo.pending;
    final reloaded=PosProductImportRepository(provider,client:client);
    expect(reloaded.pending,pending);
    await expectLater(reloaded.upload(bytes:Uint8List.fromList([1]),filename:'other.csv',preview:false),throwsStateError);
    expect(calls,1); fail=false;
    await reloaded.upload(bytes:bytes,filename:'test.csv',preview:false);
    expect(reloaded.pending,isNull); expect(calls,2);
  });
  test('double submit shares one request and pending exists before network result',() async {
    final gate=Completer<http.Response>(); var calls=0;
    final repo=PosProductImportRepository(provider,client:MockClient((r) { calls++;return gate.future; }));
    final a=repo.upload(bytes:bytes,filename:'test.csv',preview:false);
    final b=repo.upload(bytes:bytes,filename:'test.csv',preview:false);
    expect(identical(a,b),isTrue); await Future<void>.delayed(Duration.zero);
    expect(repo.pending,isNotNull); gate.complete(response(result));
    await a; expect(calls,1); expect(repo.pending,isNull);
  });
  test('operator switch before upload never sends the file',() async {
    provider.switchOnHeaders=true;var calls=0;
    final repo=PosProductImportRepository(provider,client:MockClient((r)async {calls++;return response(result);}));
    await expectLater(repo.upload(bytes:bytes,filename:'test.csv',preview:false),throwsStateError);
    expect(calls,0);expect(repo.pending,isNull);
  });
  test('invalid server response cannot discard unresolved import',() async {
    final repo=PosProductImportRepository(provider,client:MockClient((r)async=>response({})));
    await expectLater(repo.upload(bytes:bytes,filename:'test.csv',preview:false),throwsStateError);
    expect(repo.pending,isNotNull);
  });
  test('invalid file extension and empty file never reach transport',() async {
    var calls=0;final repo=PosProductImportRepository(provider,client:MockClient((r)async {calls++;return response(result);}));
    await expectLater(repo.upload(bytes:bytes,filename:'test.exe',preview:true),throwsStateError);
    await expectLater(repo.upload(bytes:Uint8List(0),filename:'test.csv',preview:true),throwsStateError);
    expect(calls,0);
  });
}
