import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/pos_financial_request_store.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_trade.dart';
import 'pos_trade_workspace_test.dart' show TradeRepository, app;

void main() {
  setUpAll(() async => initializeDateFormatting());
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final kind in PosTradeKind.values) {
    for (final payment in [false,true]) {
      testWidgets('${kind.name} ${payment?'payment':'entry'} form has comfortable field gaps', (tester) async {
        tester.view.physicalSize=const Size(390,844);
        tester.view.devicePixelRatio=1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo=TradeRepository();
        final store=PosFinancialRequestStore(await SharedPreferences.getInstance(),'spacing');
        final captureKey=GlobalKey();
        await tester.pumpWidget(RepaintBoundary(key:captureKey,child:app(repo,store,kind:kind,id:payment?'doc':null)));
        await tester.pumpAndSettle();
        final action=find.text(payment?(kind==PosTradeKind.receivable?'Catat Penerimaan':'Catat Pembayaran'):'Catat Tagihan Manual');
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        final fields=find.descendant(of:find.byType(Form),matching:find.byType(InputDecorator));
        final rects=fields.evaluate().map((e)=>tester.getRect(find.byWidget(e.widget))).toList()..sort((a,b)=>a.top.compareTo(b.top));
        expect(rects.length,greaterThanOrEqualTo(3));
        final directory=Platform.environment['POS_TRADE_FORM_SCREENSHOTS'];
        if(directory!=null) {
          await tester.runAsync(() async {
            final boundary=captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
            final image=await boundary.toImage();
            final bytes=await image.toByteData(format:ui.ImageByteFormat.png);
            await Directory(directory).create(recursive:true);
            await File('$directory/${kind.name}-${payment?'payment':'entry'}.png').writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        for(var i=1;i<rects.length;i++) {
          expect(rects[i].top-rects[i-1].bottom,greaterThanOrEqualTo(12),reason:'Field $i must not touch the preceding input');
        }
        expect(repo.writes,isEmpty);
        expect(tester.takeException(),isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
