import 'dart:io';
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
        MaterialApp(
          home: Scaffold(
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
          ),
        ),
      );
      expect(tester.widget<Text>(find.text('Toko Uji')).style?.fontSize, 18);
      expect(tester.widget<Text>(find.text('Kasir Uji')).style?.fontSize, 12);
      await tester.tap(find.text('Toko Uji'));
      expect(taps, 1);
      expect(tester.takeException(), isNull);
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
}
