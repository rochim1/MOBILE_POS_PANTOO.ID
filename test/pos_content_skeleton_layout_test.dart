import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_content_skeletons.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/skeleton_loading.dart';

void main() {
  const grid = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 210,
    mainAxisExtent: 224,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  );
  for (final size in [
    const Size(280, 480),
    const Size(360, 640),
    const Size(800, 600),
    const Size(1280, 800),
  ]) {
    final variants = <String, Widget>{
      'transfer editor': const PosDocumentFormSkeleton(),
      'transfer operation': const PosDocumentFormSkeleton(fieldGroups: [3]),
      'catalog cards': PosCatalogContentSkeleton(
        isMobile: size.width < 900,
        isGridView: true,
        gridDelegate: grid,
      ),
      'catalog table': PosCatalogContentSkeleton(
        isMobile: size.width < 900,
        isGridView: false,
        gridDelegate: grid,
      ),
      'table grid': const PosTableContentSkeleton(isGridView: true),
      'table list': const PosTableContentSkeleton(isGridView: false),
      'report rows': const SingleChildScrollView(
        child: PosReportRowsSkeleton(),
      ),
    };
    for (final entry in variants.entries) {
      testWidgets('${entry.key} loading fits $size with enlarged text', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(1.5),
              ),
              child: Scaffold(body: entry.value),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        expect(find.byType(PosPageSkeleton), findsNothing);
        if (entry.key == 'catalog table') {
          await tester.drag(
            find.byType(SingleChildScrollView).last,
            const Offset(-250, 0),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
