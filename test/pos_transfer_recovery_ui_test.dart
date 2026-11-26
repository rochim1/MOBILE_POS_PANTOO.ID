import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_transfer_repository.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_transfer_operation_page.dart';
import 'pos_transfer_recovery_test.dart' show TransferProvider;
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_transfer_editor_page.dart';
import 'pos_transfer_editor_test.dart' show TransferFake;

void main() {
  setUp(()=>SharedPreferences.setMockInitialValues({}));
  for(final receiving in [false,true]) {
    testWidgets('${receiving?'receipt':'create'} lost response reopens recovery and replays exact intent once', (tester) async {
      final seen=<String>{};final sent=<Map<String,dynamic>>[];
      var lose=true,reads=0,received=0;
      Map<String,dynamic> doc()=>{'_id':'doc','status':'in_transit','updatedAt':'revision-$received',
        'tanggal_transfer':'2026-01-01','ke':{'cabang_id':'to'},'no_transfer':'QA-RECOVER',
        'items':[{'_id':'line','nama_inventaris':'QA product','unit':'pcs','qty':5.0,'received_qty':received.toDouble()}]};
      final provider=TransferProvider(await SharedPreferences.getInstance(),(r) async* {
        final op=(r.operation.document.definitions.first as dynamic).name?.value as String? ?? '';
        if(op=='MobileTransferCreate'||op=='MobileTransferReceive') {
          sent.add(r.variables);if(seen.add(r.variables['request_id'] as String))received++;
          if(lose)throw StateError('response lost after commit');
          yield Response(response:const {},data:{receiving?'ReceiveInventoryTransfer':'CreateInventoryTransfer':doc()});
        } else if(op=='MobileTransferWarehouses') {
          reads++;yield const Response(response:{},data:{'getAllCabangs':{'cabang':[
            {'_id':'from','nama_cabang':'Asal'},{'_id':'to','nama_cabang':'Tujuan'}]}});
        } else if(op=='MobileTransferAvailable') {
          yield const Response(response:{},data:{'GetInventarisAvailableInLocation':[
            {'inventaris_id':'product','nama_inventaris':'QA product','unit':'pcs','qty':10.0}]});
        } else {
          yield Response(response:const {},data:{'GetOneInventoryTransfer':doc()});
        }
      });
      Widget page()=>MaterialApp(key:UniqueKey(),home: receiving
        ? PosTransferOperationPage(transfer:const {'_id':'doc'},mode:'receive',repository:PosTransferRepository(provider))
        : PosTransferEditorPage(initialSourceId:'from',initialDestinationId:'to',initialInventoryId:'product',
            repository:PosTransferRepository(provider)));
      await tester.pumpWidget(page());await tester.pumpAndSettle();
      if(receiving) {await tester.enterText(find.byType(TextFormField).at(2),'1');await tester.pump();}
      final save=find.text(receiving?'Terima jumlah ini':'Simpan mutasi');
      await tester.scrollUntilVisible(save,350,scrollable:find.byType(Scrollable).first,maxScrolls:40);
      await tester.tap(save);await tester.pumpAndSettle();await tester.pump(const Duration(seconds:4));
      expect(received,1);final readsBefore=reads;
      await tester.pumpWidget(page());await tester.pumpAndSettle();
      expect(reads,readsBefore,reason:'Recovery does not depend on master-data loading');
      expect(find.text('Periksa transfer sebelumnya'),findsNWidgets(2));
      expect(find.text(receiving?'Terima jumlah ini':'Simpan mutasi'),findsNothing);
      lose=false;await tester.tap(find.text('Periksa transfer sebelumnya').last);
      await tester.pumpAndSettle();
      expect(sent.length,2);expect(sent[1],sent[0]);expect(received,1);
      expect(PosTransferRepository(provider).pendingIntent(documentId:receiving?'doc':null),isNull);
      expect(tester.takeException(),isNull);
    });
  }
  testWidgets('unsupported landed cost cannot be selected in transfer editor', (tester) async {
    await tester.pumpWidget(MaterialApp(home:PosTransferEditorPage(
      existing:const {'_id':'doc'},repository:TransferFake())));
    await tester.pumpAndSettle();
    final mode=find.text('Beban langsung');
    await tester.scrollUntilVisible(mode,400,scrollable:find.byType(Scrollable).first,maxScrolls:40);
    await tester.pumpAndSettle();await tester.ensureVisible(mode);await tester.pumpAndSettle();
    await tester.tap(mode);await tester.pumpAndSettle();
    expect(find.text('Tambahkan ke nilai persediaan'),findsNothing);
  });
  testWidgets('system back cannot abandon transfer while saving', (tester) async {
    final repo=TransferFake()..pending=Completer<Map<String,dynamic>>();
    await tester.pumpWidget(MaterialApp(home:Builder(builder:(context)=>Scaffold(body:
      TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>
        PosTransferEditorPage(existing:const {'_id':'doc'},repository:repo))),child:const Text('Open'))))));
    await tester.tap(find.text('Open'));await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Simpan mutasi'),450,scrollable:find.byType(Scrollable).first,maxScrolls:40);
    await tester.tap(find.text('Simpan mutasi'));await tester.pump();
    await tester.binding.handlePopRoute();await tester.pump(const Duration(milliseconds:400));
    expect(find.byType(PosTransferEditorPage),findsOneWidget);
    repo.pending!.complete({'_id':'doc','status':'draft'});
    await tester.pumpAndSettle();await tester.pump(const Duration(seconds:4));
  });
}
