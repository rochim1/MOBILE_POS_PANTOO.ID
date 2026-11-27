import 'dart:io';
import 'dart:ui' as ui;
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_customer.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_business_report.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_shift/pos_shift_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_shift/pos_shift_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_shift/pos_shift_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_return/pos_return_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_return/pos_return_event.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_return_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_customer_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_business_report_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_active_shift_tab.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_metric_card.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_operational_toolbar.dart';
import 'pos_business_report_test.dart' show BusinessRepository;

const activeShift = {
  '_id': 'shift',
  'toko_id': 'store',
  'status': 'open',
  'kasir_user_id': 'qa',
  'opening_cash': 100000,
  'cash_in_total': 20000,
  'cash_out_total': 5000,
  'total_transaksi': 12,
  'toko': {'nama_toko': 'Toko QA'},
};

class _Customers extends Fake implements PosRepository {
  int writes = 0;
  @override
  Map<String, dynamic>? pendingReturnDraft() => null;
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getAllSalesReturns({
    String? search,
    String? status,
  }) async => const Right([
    {
      '_id': 'return',
      'no_retur': 'RET-QA',
      'sumber_no': 'INV-QA',
      'status': 'approved',
      'total_refund': 25000,
    },
  ]);
  @override
  Future<List<PosCustomer>> getCustomers() async => const [
    PosCustomer(
      id: 'budi',
      name: 'Budi QA',
      phone: '0811111111',
      priceLevel: 'retail',
    ),
    PosCustomer(
      id: 'ani',
      name: 'Ani QA',
      phone: '0822222222',
      priceLevel: 'grosir',
    ),
  ];
  @override
  Future<Map<String, dynamic>> getRuntimeConfig() async => {
    'price_level_options': ['retail', 'grosir'],
    'default_price_level': 'retail',
  };
  @override
  Future<Either<Failure, Map<String, dynamic>>> createCustomer(
    Map<String, dynamic> input,
  ) async {
    writes++;
    return Right({'_id': 'new-customer', ...input});
  }
}

class _Pos extends Cubit<PosState> implements PosBloc {
  _Pos()
    : super(
        const PosState(
          status: PosStatus.success,
          stores: [
            PosStore(
              id: 'store',
              name: 'Toko QA',
              status: 'active',
              shiftMode: 'per_operator',
            ),
          ],
          activeShift: activeShift,
        ),
      );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Shifts extends PosShiftBloc {
  _Shifts() : super(posRepository: _Customers()) {
    emit(const PosShiftLoaded(activeShift: activeShift));
  }
  final events = <PosShiftEvent>[];
  @override
  void add(PosShiftEvent event) => events.add(event);
}

class _Operator extends AppLockCubit {
  _Operator() {
    emit(
      state.copyWith(
        status: AppLockStatus.unlocked,
        activeEmployeeId: 'qa',
        activeEmployeeName: 'Kasir QA',
      ),
    );
  }
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
    final root = Platform.environment['FLUTTER_ROOT'];
    if (root != null) {
      final file = File(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      );
      if (await file.exists()) {
        final icons = FontLoader('MaterialIcons')
          ..addFont(
            Future.value(ByteData.sublistView(await file.readAsBytes())),
          );
        await icons.load();
      }
    }
  });
  setUp(() async {
    sl.pushNewScope();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => sl.popScope());

  Future<GlobalKey> mount(
    WidgetTester tester,
    Widget page, {
    double width = 390,
    String locale = 'id',
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF087F75),
            ),
          ),
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              viewPadding: const EdgeInsets.only(bottom: 24),
            ),
            child: child!,
          ),
          home: Scaffold(backgroundColor: const Color(0xFFF7F8FA), body: page),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return key;
  }

  Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
    final directory = Platform.environment['POS_OPERATIONAL_UI_SCREENSHOTS'];
    if (directory == null) return;
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(directory).create(recursive: true);
      await File(
        '$directory/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final page in ['customer', 'shift', 'return', 'report']) {
    for (final width in [320.0, 390.0, 800.0]) {
      for (final locale in ['id', 'en']) {
        for (final scale in [1.0, 1.4]) {
          testWidgets('$page inventory theme $width $locale scale $scale', (
            tester,
          ) async {
            final customers = _Customers();
            sl.registerSingleton<PosRepository>(customers);
            final pos = _Pos(), shifts = _Shifts(), operator = _Operator();
            final returns = PosReturnBloc(posRepository: customers)
              ..add(const LoadReturns());
            addTearDown(returns.close);
            addTearDown(pos.close);
            addTearDown(shifts.close);
            addTearDown(operator.close);
            final child = switch (page) {
              'customer' => const PosCustomerPage(),
              'shift' => MultiBlocProvider(
                providers: [
                  BlocProvider<PosBloc>.value(value: pos),
                  BlocProvider<PosShiftBloc>.value(value: shifts),
                  BlocProvider<AppLockCubit>.value(value: operator),
                ],
                child: const PosActiveShiftTab(),
              ),
              'return' => BlocProvider<PosReturnBloc>.value(
                value: returns,
                child: const PosReturnView(permissions: {}),
              ),
              _ => PosBusinessReportPage(
                repository: BusinessRepository(),
                initialKind: PosBusinessReportKind.inventory,
              ),
            };
            final key = await mount(
              tester,
              child,
              width: width,
              locale: locale,
              scale: scale,
            );
            if (page == 'customer') {
              expect(find.byType(TextField), findsOneWidget);
              expect(
                tester.getSize(find.byType(TextField)).width,
                greaterThan(200),
              );
              expect(find.text('Budi QA'), findsOneWidget);
            } else if (page == 'return') {
              expect(find.byType(TextField), findsOneWidget);
              expect(find.text('RET-QA'), findsOneWidget);
            } else {
              final metrics = tester
                  .widgetList<PosMetricCard>(find.byType(PosMetricCard))
                  .toList();
              expect(metrics, isNotEmpty);
              expect(metrics.every((m) => m.compact), true);
              if (page == 'shift') {
                expect(shifts.events.every((e) => e is LoadShiftData), true);
              }
            }
            if (scale == 1 && locale == 'id' && width != 320) {
              await capture(tester, key, '$page-${width.toInt()}-id');
            }
            expect(customers.writes, 0);
            expect(tester.takeException(), isNull);
          });
        }
      }
    }
  }
  testWidgets('customer search, price filter and create remain usable', (
    tester,
  ) async {
    final repo = _Customers();
    sl.registerSingleton<PosRepository>(repo);
    final key = await mount(tester, const PosCustomerPage());
    await tester.enterText(find.byType(TextField), '081111');
    await tester.pumpAndSettle();
    expect(find.text('Budi QA'), findsOneWidget);
    expect(find.text('Ani QA'), findsNothing);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filter pelanggan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('grosir').last);
    await tester.pumpAndSettle();
    expect(find.text('Ani QA'), findsOneWidget);
    expect(find.text('Budi QA'), findsNothing);
    expect(repo.writes, 0);
    await tester.tap(find.text('Tambah'));
    await tester.pumpAndSettle();
    await capture(tester, key, 'customer-create-390-id');
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Pelanggan Baru QA');
    await tester.enterText(fields.at(1), '08123456789');
    await tester.tap(find.text('Simpan Pelanggan'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(repo.writes, 1);
    expect(find.text('Pelanggan Baru QA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'toolbar preserves search when secondary filters toggle without writes',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var actions = 0;
      await mount(
        tester,
        Padding(
          padding: const EdgeInsets.all(12),
          child: PosOperationalToolbar(
            search: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Cari'),
            ),
            filters: const Text('Status'),
            filterToggleKey: const Key('filters'),
            primaryAction: FilledButton(
              onPressed: () => actions++,
              child: const Text('Tambah'),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), 'QA');
      await tester.tap(find.byKey(const Key('filters')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filters')));
      await tester.pumpAndSettle();
      expect(find.text('QA'), findsOneWidget);
      expect(actions, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'compact loading metrics match compact cards rather than taking 180px',
    (tester) async {
      await mount(
        tester,
        const Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 160,
            child: PosMetricCardSkeleton(compact: true),
          ),
        ),
      );
      expect(tester.getSize(find.byType(PosMetricCardSkeleton)).height, 92);
      expect(tester.takeException(), isNull);
    },
  );
}
