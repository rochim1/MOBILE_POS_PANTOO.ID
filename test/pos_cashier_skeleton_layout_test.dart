import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/skeleton_loading.dart';

void main() {
  for (final size in [const Size(320, 480), const Size(360, 800), const Size(800, 600), const Size(1280, 800)]) {
    for (final grid in [true, false]) {
      testWidgets('cashier loading fits $size grid=$grid including large text', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: const TextScaler.linear(1.5)),
          child: Scaffold(body: PosPageSkeleton(isGridView: grid)),
        )));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        expect(find.byType(SkeletonSummaryCard), findsNothing);
        expect(find.byType(SliverGrid), grid ? findsOneWidget : findsNothing);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -150));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
