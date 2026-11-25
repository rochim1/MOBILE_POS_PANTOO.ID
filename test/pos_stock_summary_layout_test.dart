import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_stock.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_stock_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_stock/pos_stock_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_stock/pos_stock_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_stock/pos_stock_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_stock_page.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_metric_card.dart';

class _Repo extends Fake implements PosRepository {}

class _StockRepo extends Fake implements PosStockRepository {}

class _Pos extends PosBloc {
  _Pos({bool canView = true}) : super(posRepository: _Repo()) {
    emit(
      state.copyWith(
        runtimeConfig: {
          'features': {'track_stock': true},
          'permissions': {'view_stock': canView},
        },
      ),
    );
  }
}

class _Stock extends PosStockBloc {
  _Stock(bool loading) : super(repository: _StockRepo()) {
    emit(
      PosStockState(
        status: loading ? PosStockStatus.loading : PosStockStatus.success,
        statistics: loading
            ? null
            : const PosStockStatistics(
                totalInventaris: 29,
                totalNilaiInventaris: 442735900,
                lowStockCount: 2,
                outOfStockCount: 0,
              ),
      ),
    );
  }
  @override
  void add(PosStockEvent event) {}
}

Future<void> _mount(
  WidgetTester tester,
  double width,
  double scale, {
  bool loading = false,
  bool canView = true,
}) async {
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final pos = _Pos(canView: canView);
  addTearDown(pos.close);
  sl.registerFactory<PosStockBloc>(() => _Stock(loading));
  await tester.pumpWidget(
    BlocProvider<PosBloc>.value(
      value: pos,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const RepaintBoundary(
          key: ValueKey('stock-summary-preview'),
          child: Scaffold(body: PosStockPage()),
        ),
      ),
    ),
  );
  if (loading) {
    await tester.pump(const Duration(milliseconds: 100));
  } else {
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('phone stock filters collapse without hiding history', (tester) async {
    await _mount(tester, 390, 1);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Riwayat Shift'), findsOneWidget);
    final toggle = find.byKey(const Key('stock_filter_toggle'));
    await tester.tap(toggle); await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'QA stock');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(toggle); await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await tester.tap(toggle); await tester.pumpAndSettle();
    expect(find.text('QA stock'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  setUpAll(() async {
    await initializeDateFormatting('id_ID');
    await (FontLoader(
      'Roboto',
    )..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() => sl.pushNewScope());
  tearDown(() => sl.popScope());

  for (final (width, scale, loading) in [
    (320.0, 1.0, false),
    (360.0, 1.0, false),
    (700.0, 1.0, false),
    (958.0, 1.0, false),
    (320.0, 1.5, false),
    (958.0, 1.5, false),
    (320.0, 1.0, true),
    (958.0, 1.0, true),
  ]) {
    testWidgets(
      'stock summaries are compact at $width dp scale $scale loading $loading',
      (tester) async {
        await _mount(tester, width, scale, loading: loading);
        final cards = find.byType(PosMetricCard);
        expect(cards, findsNWidgets(4));
        const phase = String.fromEnvironment('STOCK_SUMMARY_PREVIEW');
        if (width == 958 &&
            scale == 1 &&
            !loading &&
            ['before', 'after'].contains(phase)) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('stock-summary-preview')),
          );
          await tester.runAsync(() async {
            final snapshot = await boundary.toImage(pixelRatio: 1);
            final bytes = await snapshot.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              'output/stock-summary-$phase.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            snapshot.dispose();
          });
        }
        final rects = [
          for (var index = 0; index < 4; index++)
            tester.getRect(cards.at(index)),
        ];
        for (final rect in rects) {
          expect(rect.height, lessThanOrEqualTo(scale == 1 ? 120 : 160));
        }
        expect(rects[1].top, closeTo(rects.first.top, 0.1));
        if (width >= 958) {
          expect(rects.last.top, closeTo(rects.first.top, 0.1));
        } else {
          expect(rects[2].top, greaterThan(rects.first.top));
        }
        if (!loading) expect(find.text('Rp 442.735.900'), findsOneWidget);
        if (loading) expect(find.text('Rp 442.735.900'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'compact inventory page still denies a user without stock permission',
    (tester) async {
      await _mount(tester, 360, 1, canView: false);
      expect(find.byType(PosMetricCard), findsNothing);
      expect(find.text('Akses stok tidak tersedia'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
