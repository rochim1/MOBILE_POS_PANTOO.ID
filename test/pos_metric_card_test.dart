import 'package:mobile_pos_pantoo/presentation/widgets/pos_ui.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/skeleton_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_metric_card.dart';

void main() {
  Widget card({double? growth, double scale = 1}) => MaterialApp(
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: SizedBox(
          width: 164,
          child: PosMetricCard(
            title: 'Total Penjualan',
            value: 'Rp 12.345.678.900',
            icon: Icons.payments_outlined,
            description: 'Dibanding periode sebelumnya',
            growth: growth,
          ),
        ),
      ),
    ),
  );

  testWidgets('phone cards keep long amounts and comparison readable', (
    tester,
  ) async {
    await tester.pumpWidget(card(growth: 2133.3, scale: 1.5));
    expect(find.text('Rp 12.345.678.900'), findsOneWidget);
    expect(find.text('+2,133.3%'), findsOneWidget);
    expect(find.text('Dibanding periode sebelumnya'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('direction distinguishes growth, decline and unchanged values', (
    tester,
  ) async {
    await tester.pumpWidget(card(growth: 12.5));
    expect(find.byIcon(Icons.north_east_rounded), findsOneWidget);
    await tester.pumpWidget(card(growth: -12.5));
    expect(find.text('-12.5%'), findsOneWidget);
    expect(find.byIcon(Icons.south_east_rounded), findsOneWidget);
    await tester.pumpWidget(card(growth: 0));
    expect(find.text('0%'), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing or invalid growth never appears as a real percentage', (
    tester,
  ) async {
    for (final value in [null, double.nan, double.infinity]) {
      await tester.pumpWidget(card(growth: value));
      expect(find.textContaining('%'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'shared grid adapts from phone to desktop without losing values',
    (tester) async {
      for (final width in [320.0, 390.0, 1100.0]) {
        await tester.binding.setSurfaceSize(Size(width, 900));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: PosMetricGrid(
                    children: List.generate(
                      4,
                      (index) => PosMetricCard(
                        title: 'Statistik $index',
                        value: 'Rp 123.456.789',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final first = tester.getTopLeft(find.byType(PosMetricCard).at(0));
        final second = tester.getTopLeft(find.byType(PosMetricCard).at(1));
        if (width == 320) {
          expect(second.dy, greaterThan(first.dy));
        } else {
          expect(second.dy, first.dy);
          expect(second.dx, greaterThan(first.dx));
        }
        expect(find.text('Rp 123.456.789'), findsNWidgets(4));
        expect(tester.takeException(), isNull);
      }
      addTearDown(() => tester.binding.setSurfaceSize(null));
    },
  );

  testWidgets('loading stock values do not appear as zero or stale amounts', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 164,
            child: PosMetricCard(
              title: 'Nilai Stok',
              value: 'Rp 999.000',
              icon: Icons.inventory_2_outlined,
              isLoading: true,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Nilai Stok'), findsOneWidget);
    expect(find.text('Rp 999.000'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy summary cards render through the shared design', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 164,
            child: PosStatCard(
              label: 'Penerimaan Tunai',
              value: 'Rp 123.456.789',
              icon: Icons.payments_outlined,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(PosMetricCard), findsOneWidget);
    expect(find.text('Rp 123.456.789'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'POS loading catalog fits a small phone without obsolete summary cards',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: PosPageSkeleton())),
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(PosMetricCardSkeleton), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shared summary loading card fits a small phone', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: SkeletonSummaryCard()),
        ),
      ),
    );
    expect(find.byType(PosMetricCardSkeleton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
