import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_transfer_editor_page.dart';
import 'pos_transfer_editor_test.dart' show TransferFake;

void main() {
  testWidgets('unsupported landed cost cannot be selected in transfer editor', (tester) async {
    await tester.pumpWidget(MaterialApp(home:PosTransferEditorPage(
      existing:const {'_id':'doc'},repository:TransferFake())));
    await tester.pumpAndSettle();
    final mode=find.text('Beban langsung').last;
    await tester.scrollUntilVisible(mode,400,scrollable:find.byType(Scrollable).first,maxScrolls:40);
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
