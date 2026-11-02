import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/skeleton_loading.dart';

void main() {
  testWidgets('skeleton katalog tidak overflow pada kartu tablet sempit', (
    tester,
  ) async {
    for (final width in [150.0, 160.0, 180.0, 210.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                height: 224,
                child: const SkeletonProductCard(),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: 'Lebar kartu $width');
    }
  });

  test(
    'grid katalog tablet mengikuti lebar dan skeleton memakai ukuran sama',
    () {
      final source = File(
        'lib/presentation/pages/pos/pos_product_page.dart',
      ).readAsStringSync();

      expect(source, contains('SliverGridDelegateWithMaxCrossAxisExtent('));
      expect(source, contains('maxCrossAxisExtent: 210'));
      expect(source, contains('mainAxisExtent: 224'));
      expect(
        RegExp('gridDelegate: _catalogGridDelegate').allMatches(source).length,
        2,
      );
      expect(source, contains('if (!widget.isGridView || isMobile)'));
    },
  );
}
