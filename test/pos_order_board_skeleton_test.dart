import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/skeleton_loading.dart';

void main() {
  for (final height in <double>[305, 180]) {
    testWidgets(
      'skeleton papan pesanan tidak overflow pada tinggi ${height.toInt()} dp',
      (tester) async {
        tester.view.physicalSize = Size(320, height + 40);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 272,
                  height: height,
                  child: const PosOrderBoardSkeleton(),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(PosOrderTicketSkeleton), findsNWidgets(6));
        expect(tester.takeException(), isNull);
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -100),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
