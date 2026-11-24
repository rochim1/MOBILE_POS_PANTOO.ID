import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_mobile_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_navbar_identity.dart';

void main() {
  for (final width in [320.0, 360.0, 768.0]) {
    testWidgets('navbar identity remains readable at $width', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var taps = 0;
      await tester.pumpWidget(
          RepaintBoundary(key: const ValueKey('navbar_preview'), child: MaterialApp(
            theme: AppTheme.light(),
          home: Scaffold(
              bottomNavigationBar: PosMobileBottomBar(reports: const Icon(Icons.home_outlined),catalog: const Icon(Icons.inventory_2_outlined),transactions:const Icon(Icons.receipt_long_outlined),more:const Icon(Icons.menu),onOpenCashier:(){}),
            appBar: AppBar(
              toolbarHeight: 64,
              titleSpacing: 0,
              title: PosNavbarIdentity(
                title: 'Toko Uji',
                subtitle: 'Kasir Uji',
                employee: const {'name': 'Kasir Uji'},
                compact: true,
                onTap: () => taps++,
              ),
              actions: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
              ],
            ),
          )),
        ),
      );
      expect(tester.widget<Text>(find.text('Toko Uji')).style?.fontSize, 18);
      expect(tester.widget<Text>(find.text('Kasir Uji')).style?.fontSize, 12);
      await tester.tap(find.text('Toko Uji'));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('CAPTURE_PERSONAL_PROFILE')) {
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final boundary=tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('navbar_preview')));
            final image=await boundary.toImage(pixelRatio:2);final png=await image.toByteData(format:ui.ImageByteFormat.png);
            await Directory('output/personal-profile-20261124').create(recursive:true);
            await File('output/personal-profile-20261124/navbar-'+width.toInt().toString()+'.png').writeAsBytes(png!.buffer.asUint8List());image.dispose();
          });
        }
    });
  }
  test(
    'real shell uses readable identity and refreshes only the active operator profile',
    () {
      final source = File(
        'lib/presentation/pages/pos/pos_shell_page.dart',
      ).readAsStringSync();
      expect(source, contains('PosNavbarIdentity('));
      expect(source, contains('applyActiveEmployeeProfile'));
    },
  );
  testWidgets('large system font keeps both identity lines visible', (tester) async {
    tester.view.physicalSize=const Size(320,640);tester.view.devicePixelRatio=1;
    addTearDown(tester.view.resetPhysicalSize);addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:const TextScaler.linear(2)),child:child!),
      home:Builder(builder:(context)=>Scaffold(appBar:AppBar(toolbarHeight:PosNavbarIdentity.toolbarHeight(context),titleSpacing:0,
        title:PosNavbarIdentity(title:'Toko dengan nama panjang',subtitle:'Kasir dengan nama panjang',employee:const {'name':'Kasir'},compact:true,onTap:(){}))))));
    expect(tester.takeException(),isNull);expect(tester.getSize(find.byType(AppBar)).height,greaterThan(64));
  });
}
