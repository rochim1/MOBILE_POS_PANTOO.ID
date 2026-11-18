import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_content_skeletons.dart';
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
      expect(source, contains('PosCatalogContentSkeleton('));
    },
  );

  testWidgets('catalog skeleton uses table, mobile list or tablet grid', (
    tester,
  ) async {
    const delegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 210,
      mainAxisExtent: 224,
    );
    for (final mode in [(true, false), (true, true), (false, true)]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosCatalogContentSkeleton(
              isMobile: mode.$1,
              isGridView: mode.$2,
              gridDelegate: delegate,
            ),
          ),
        ),
      );
      await tester.pump();
      if (!mode.$2) {
        expect(find.byType(PosDataTableSkeleton), findsOneWidget);
      } else if (mode.$1) {
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(GridView), findsNothing);
      } else {
        expect(find.byType(GridView), findsOneWidget);
        expect(
          tester.widget<GridView>(find.byType(GridView)).gridDelegate,
          same(delegate),
        );
      }
      expect(tester.takeException(), isNull);
    }
  });
}
