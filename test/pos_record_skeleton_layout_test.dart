import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_record_skeletons.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_content_skeletons.dart';

void main() {
  for (final size in [
    const Size(280, 480),
    const Size(360, 640),
    const Size(800, 600),
    const Size(1280, 800),
  ]) {
    final variants = <String, Widget>{
      for (final kind in PosRecordSkeletonKind.values)
        kind.name: PosRecordListSkeleton(kind: kind),
      'settings form': const PosDocumentFormSkeleton(
        fieldGroups: [3],
        showItems: false,
      ),
      'inventory purchase step': const PosDocumentFormSkeleton(
        fieldGroups: [3],
      ),
      'direct purchase form': const PosDocumentFormSkeleton(fieldGroups: [6]),
      'trade list': const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: PosTradeContentSkeleton(detail: false),
      ),
      'trade detail': const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: PosTradeContentSkeleton(detail: true),
      ),
      'embedded records': const SingleChildScrollView(
        child: PosRecordListSkeleton(
          kind: PosRecordSkeletonKind.purchaseAdvance,
          embedded: true,
        ),
      ),
      'notification slivers': CustomScrollView(
        slivers: [
          SliverList.builder(
            itemCount: 6,
            itemBuilder: (_, index) => const Padding(
              padding: EdgeInsets.all(16),
              child: PosRecordCardSkeleton(
                kind: PosRecordSkeletonKind.notification,
              ),
            ),
          ),
        ],
      ),
    };
    for (final entry in variants.entries) {
      testWidgets('${entry.key} loading fits $size with large text', (
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
                textScaler: const TextScaler.linear(1.6),
              ),
              child: Scaffold(body: entry.value),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -180));
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
