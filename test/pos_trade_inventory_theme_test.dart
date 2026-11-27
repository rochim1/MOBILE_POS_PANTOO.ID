import 'dart:io';
import 'dart:ui' as ui;
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/network/pos_financial_request_store.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_trade.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_trade_workspace_page.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_category_navigation.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_metric_card.dart';
import 'pos_trade_workspace_test.dart' show TradeRepository, document;

class _Repository extends TradeRepository {
  bool empty = false, detailFails = false, apOnly = false;
  final List<(PosTradeKind, String, bool)> reads = [];
  @override
  Future<Either<Failure, PosTradeOptions>> options() async {
    final original = (await super.options()).getOrElse(
      () => throw StateError('options'),
    );
    return Right(
      PosTradeOptions({
        ...original.data,
        'today': '2026-11-27',
        if (apOnly) 'view_ar': false,
      }),
    );
  }

  @override
  Future<Either<Failure, PosTradePage>> list(
    PosTradeKind kind, {
    String search = '',
    int page = 1,
    bool settled = false,
  }) async {
    reads.add((kind, search, settled));
    return Right(
      PosTradePage(
        empty ? [] : [document(kind: kind)],
        empty ? 0 : 1,
        empty ? 0 : 60000,
        1,
        20,
      ),
    );
  }

  @override
  Future<Either<Failure, PosTradeDocument>> detail(
    PosTradeKind kind,
    String id,
  ) async => detailFails
      ? const Left(NetworkFailure('Gagal memuat detail QA'))
      : Right(document(kind: kind));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    final font = FontLoader('Roboto')
      ..addFont(
        Future.value(
          ByteData.sublistView(
            await File('assets/fonts/roboto-regular.ttf').readAsBytes(),
          ),
        ),
      );
    await font.load();
    final sdkRoot = Platform.environment['FLUTTER_ROOT'];
    if (sdkRoot != null) {
      final iconFile = File(
        '$sdkRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      if (await iconFile.exists()) {
        final icons = FontLoader('MaterialIcons')
          ..addFont(
            Future.value(ByteData.sublistView(await iconFile.readAsBytes())),
          );
        await icons.load();
      }
    }
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<GlobalKey> mount(
    WidgetTester tester,
    _Repository repo, {
    double width = 390,
    String locale = 'id',
    double scale = 1,
    String? id,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = PosFinancialRequestStore(
      await SharedPreferences.getInstance(),
      'ui',
    );
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(fontFamily: 'Roboto'),
          debugShowCheckedModeBanner: false,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              viewPadding: const EdgeInsets.only(bottom: 24),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: PosTradeWorkspacePage(
              operatorId: 'qa',
              repository: repo,
              requestStore: store,
              initialKind: PosTradeKind.payable,
              initialDocumentId: id,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return key;
  }

  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    final directory = Platform.environment['POS_TRADE_UI_SCREENSHOTS'];
    if (directory == null) return;
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(directory).create(recursive: true);
      await File(
        '$directory/$name.png',
      ).writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final width in [320.0, 390.0, 768.0, 1280.0]) {
    for (final locale in ['id', 'en']) {
      for (final scale in [1.0, 1.4]) {
        testWidgets('inventory theme $width $locale text $scale', (
          tester,
        ) async {
          final repo = _Repository();
          final key = await mount(
            tester,
            repo,
            width: width,
            locale: locale,
            scale: scale,
          );
          expect(
            find.byType(PosCategorySidebar<PosTradeKind>),
            width >= 760 ? findsOneWidget : findsNothing,
          );
          expect(
            find.byType(PosCategoryDropdown<PosTradeKind>),
            width < 760 ? findsOneWidget : findsNothing,
          );
          expect(find.byKey(const Key('trade_search')), findsOneWidget);
          expect(find.byType(SwitchListTile), findsNothing);
          expect(
            tester
                .widgetList<PosMetricCard>(find.byType(PosMetricCard))
                .every((c) => c.compact),
            true,
          );
          if (scale == 1 && [390.0, 1280.0].contains(width)) {
            await capture(tester, key, 'overview-${width.toInt()}-$locale');
          }
          await tester.scrollUntilVisible(
            find.text('Pemasok QA'),
            200,
            scrollable: find.byType(Scrollable).last,
          );
          expect(
            find.text(locale == 'en' ? 'Overdue' : 'Lewat jatuh tempo'),
            findsOneWidget,
          );
          expect(repo.writes, isEmpty);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  testWidgets(
    'category and settled filters query the chosen ledger without writes',
    (tester) async {
      final repo = _Repository();
      await mount(tester, repo);
      await tester.tap(find.byType(DropdownButtonFormField<PosTradeKind>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Piutang Pelanggan').last);
      await tester.pumpAndSettle();
      expect(repo.reads.last.$1, PosTradeKind.receivable);
      await tester.tap(find.byKey(const Key('trade_filter_toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(repo.reads.last.$3, true);
      await tester.enterText(find.byKey(const Key('trade_search')), 'INV-QA');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(repo.reads.last.$2, 'INV-QA');
      expect(repo.writes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'empty list stays useful and reset filter restores request state',
    (tester) async {
      final repo = _Repository()..empty = true;
      final key = await mount(tester, repo);
      await capture(tester, key, 'empty-390-id');
      await tester.enterText(
        find.byKey(const Key('trade_search')),
        'tidak ada',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      final reset = find.text('Atur ulang filter');
      await tester.ensureVisible(reset);
      await tester.tap(reset);
      await tester.pumpAndSettle();
      expect(repo.reads.last.$2, '');
      expect(repo.reads.last.$3, false);
      expect(repo.writes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed detail returns visible list controls rather than a dead end',
    (tester) async {
      final repo = _Repository()..detailFails = true;
      await mount(tester, repo);
      final row = find.text('Pemasok QA');
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.text('Gagal memuat detail QA'), findsOneWidget);
      expect(find.byKey(const Key('trade_search')), findsOneWidget);
      expect(find.byType(PosCategoryDropdown<PosTradeKind>), findsOneWidget);
      expect(repo.writes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('detail preserves clear payment action and back to list', (
    tester,
  ) async {
    final repo = _Repository();
    final key = await mount(tester, repo, id: 'doc');
    await capture(tester, key, 'detail-390-id');
    expect(find.byKey(const Key('trade_back_to_list')), findsOneWidget);
    expect(find.text('Pemasok QA'), findsOneWidget);
    expect(find.text('Sudah dibayar'), findsOneWidget);
    expect(find.text('Belum ada pembayaran'), findsNothing);
    final action = find.text('Catat Pembayaran');
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    await capture(tester, key, 'payment-390-id');
    expect(find.byType(Form), findsOneWidget);
    final formFields = find.descendant(
      of: find.byType(Form),
      matching: find.byType(TextField),
    );
    expect(
      tester
          .widgetList<TextField>(formFields)
          .every((f) => f.decoration?.labelText?.isNotEmpty == true),
      true,
    );
    await tester.tap(find.byTooltip('Tutup'));
    await tester.pumpAndSettle();
    final back = find.byKey(const Key('trade_back_to_list'));
    await tester.ensureVisible(back);
    await tester.tap(back);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('trade_search')), findsOneWidget);
    expect(repo.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets('navigation exposes only permitted ledger', (tester) async {
    final repo = _Repository()
      ..apOnly = true
      ..createAllowed = false;
    await mount(tester, repo, width: 1280);
    final sidebar = tester.widget<PosCategorySidebar<PosTradeKind>>(
      find.byType(PosCategorySidebar<PosTradeKind>),
    );
    expect(sidebar.items.map((i) => i.value), [PosTradeKind.payable]);
    expect(find.byKey(const Key('trade_create')), findsNothing);
    expect(repo.writes, isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'manual bill submit stays reachable above keyboard and system navigation',
    (tester) async {
      final repo = _Repository();
      await mount(tester, repo);
      await tester.tap(find.byKey(const Key('trade_create')));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final save = find.text('Simpan Tagihan');
      await tester.scrollUntilVisible(
        save,
        240,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(844 - 300 - 24));
      expect(repo.writes, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
