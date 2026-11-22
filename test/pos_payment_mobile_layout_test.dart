import 'dart:io';
import 'dart:async';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/core/subscription/pos_subscription_service.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_payment_page.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';

class _Repository extends Fake implements PosRepository {}

class _PreparingAccess extends ChangeNotifier
    implements PosSubscriptionService {
  final ready = Completer<void>();
  int preparations = 0;
  @override
  bool get required => false;
  @override
  bool get canSell => true;
  @override
  Future<void> prepareCheckout() {
    preparations++;
    return ready.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PaymentBloc extends PosBloc {
  _PaymentBloc(PosState initial) : super(posRepository: _Repository()) {
    emit(initial);
  }
  final submitted = <PosEvent>[];
  @override
  void add(PosEvent event) {
    submitted.add(event);
  }
}

const product = PosProduct(
  id: 'payment-product',
  code: 'QA-PAY',
  name: 'Kopi susu dan paket sarapan untuk pelanggan',
  category: 'Minuman',
  price: 134000,
  stock: 50,
);
PosState initial({
  PosStatus status = PosStatus.success,
  Map<String, double> prices = const {},
}) => PosState(
  status: status,
  cart: {product: 1},
  manualUnitPrices: prices,
  stores: const [
    PosStore(
      id: 'store',
      name: 'Toko Uji Pembayaran',
      status: 'active',
      branchId: 'branch',
    ),
  ],
);
Widget _app(
  _PaymentBloc bloc, {
  double scale = 1,
  Locale locale = const Locale('id'),
  PosOrder? pendingOrder,
}) => BlocProvider<PosBloc>.value(
  value: bloc,
  child: MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    theme: AppTheme.light().copyWith(
      textTheme: AppTheme.light().textTheme.apply(fontFamily: 'Roboto'),
      chipTheme: AppTheme.light().chipTheme.copyWith(
        labelStyle: const TextStyle(fontFamily: 'Roboto'),
        secondaryLabelStyle: const TextStyle(fontFamily: 'Roboto'),
      ),
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: RepaintBoundary(
      key: const Key('payment_preview'),
      child: PosPaymentPage(pendingOrder: pendingOrder),
    ),
  ),
);
Future<void> size(WidgetTester tester, Size dimensions) async {
  tester.view.physicalSize = dimensions;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> show(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

ElevatedButton submit(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.byKey(const Key('payment_submit')));
Future<void> cash(
  WidgetTester tester,
  String amount, {
  bool keyboard = false,
}) async {
  await show(tester, find.byKey(const Key('payment_mobile_cash_input')));
  await tester.tap(find.byKey(const Key('payment_mobile_cash_input')));
  await tester.pumpAndSettle();
  if (keyboard) {
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
  }
  await tester.enterText(
    find.byKey(const Key('payment_custom_cash_value')),
    amount,
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  await tester.tap(find.text('Gunakan'));
  await tester.pumpAndSettle();
  if (keyboard) {
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
  }
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (_) async => ['wifi'],
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
          (_) async => null,
        );
  });
  testWidgets(
    'checkout access warms once without blocking form or submitting payment',
    (tester) async {
      final access = _PreparingAccess();
      sl.registerSingleton<PosSubscriptionService>(access);
      final bloc = _PaymentBloc(initial());
      addTearDown(() async {
        await sl.unregister<PosSubscriptionService>();
        access.dispose();
        await bloc.close();
      });
      await size(tester, const Size(360, 800));
      await tester.pumpWidget(_app(bloc));
      await tester.pumpAndSettle();
      expect(access.preparations, 1);
      expect(find.byKey(const Key('payment_mobile_layout')), findsOneWidget);
      expect(bloc.submitted.whereType<SubmitPayment>(), isEmpty);
      await cash(tester, '150000');
      expect(submit(tester).onPressed, isNotNull);
      expect(access.preparations, 1);
      access.ready.complete();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('payment_submit')));
      await tester.pumpAndSettle();
      expect(
        bloc.submitted.whereType<SubmitPayment>().single.cashReceived,
        150000,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final entry in [
    (const Size(320, 568), 1.5, const Locale('id')),
    (const Size(360, 800), 1.0, const Locale('id')),
    (const Size(844, 390), 1.3, const Locale('en')),
  ]) {
    testWidgets(
      'payment stays scrollable with visible pay action at ${entry.$1} scale ${entry.$2}',
      (tester) async {
        await size(tester, entry.$1);
        final bloc = _PaymentBloc(initial());
        addTearDown(bloc.close);
        await tester.pumpWidget(_app(bloc, scale: entry.$2, locale: entry.$3));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('payment_mobile_layout')), findsOneWidget);
        expect(submit(tester).onPressed, isNull);
        final rect = tester.getRect(find.byKey(const Key('payment_submit')));
        expect(rect.bottom, lessThanOrEqualTo(entry.$1.height));
        expect(rect.top, greaterThan(0));
        if (entry.$1.width == 360) {
          final preview = Platform.environment['PANTOO_PAYMENT_MOBILE_PREVIEW'];
          if (preview != null) {
            await tester.runAsync(() async {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('payment_preview')),
              );
              final image = await boundary.toImage(pixelRatio: 2);
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                preview.replaceFirst('.png', '-top.png'),
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
        }
        await show(tester, find.byKey(const Key('payment_mobile_cash_input')));
        expect(tester.takeException(), isNull);
        if (entry.$1.width == 360) {
          final path = Platform.environment['PANTOO_PAYMENT_MOBILE_PREVIEW'];
          if (path != null) {
            await tester.runAsync(() async {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('payment_preview')),
              );
              final img = await boundary.toImage(pixelRatio: 2);
              final bytes = await img.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(path).writeAsBytes(bytes!.buffer.asUint8List());
              img.dispose();
            });
          }
        }
      },
    );
  }
  testWidgets(
    'custom cash accepts keyboard, blocks short payment and submits the correct amount',
    (tester) async {
      await size(tester, const Size(320, 568));
      addTearDown(tester.view.resetViewInsets);
      final bloc = _PaymentBloc(initial());
      addTearDown(bloc.close);
      await tester.pumpWidget(_app(bloc));
      await tester.pumpAndSettle();
      await cash(tester, '50000', keyboard: true);
      expect(submit(tester).onPressed, isNull);
      expect(find.text('Rp 84.000'), findsOneWidget);
      await cash(tester, '150000');
      expect(submit(tester).onPressed, isNotNull);
      expect(find.text('Rp 16.000'), findsOneWidget);
      await tester.tap(find.byKey(const Key('payment_submit')));
      await tester.pumpAndSettle();
      final event = bloc.submitted.whereType<SubmitPayment>().single;
      expect(event.paymentMethod, 'tunai');
      expect(event.cashReceived, 150000);
      expect(event.payments, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'English QRIS selection keeps its business key and enables the same submit flow',
    (tester) async {
      await size(tester, const Size(360, 800));
      final bloc = _PaymentBloc(initial());
      addTearDown(bloc.close);
      await tester.pumpWidget(_app(bloc, locale: const Locale('en')));
      await tester.pumpAndSettle();
      final method = find.byKey(const ValueKey('payment_mobile_method:QRIS'));
      await show(tester, method);
      await tester.tap(method);
      await tester.pumpAndSettle();
      expect(submit(tester).onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('payment_submit')));
      await tester.pumpAndSettle();
      expect(
        bloc.submitted.whereType<SubmitPayment>().single.paymentMethod,
        'qris',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'order detail displays the edited price instead of the catalogue price',
    (tester) async {
      await size(tester, const Size(360, 800));
      final bloc = _PaymentBloc(initial(prices: {product.id: 120000}));
      addTearDown(bloc.close);
      await tester.pumpWidget(_app(bloc));
      await tester.pumpAndSettle();
      await show(tester, find.byKey(const Key('payment_mobile_summary')));
      await tester.tap(find.text('Ringkasan pesanan'));
      await tester.pumpAndSettle();
      expect(find.text('Rp 120.000'), findsNWidgets(4));
      expect(find.text('Rp 134.000'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'split payment form fits a narrow phone and changing to cash clears allocations',
    (tester) async {
      await size(tester, const Size(320, 568));
      final bloc = _PaymentBloc(initial());
      addTearDown(bloc.close);
      await tester.pumpWidget(_app(bloc, scale: 1.2));
      await tester.pumpAndSettle();
      await show(tester, find.byKey(const Key('payment_mobile_split')));
      await tester.tap(find.byKey(const Key('payment_mobile_split')));
      await tester.pumpAndSettle();
      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(2));
      await tester.enterText(fields.at(0), '50000');
      await tester.enterText(fields.at(1), '84000');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Gunakan'));
      await tester.pumpAndSettle();
      expect(submit(tester).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
      final method = find.byKey(const ValueKey('payment_mobile_method:Tunai'));
      await show(tester, method);
      await tester.tap(method);
      await tester.pumpAndSettle();
      expect(submit(tester).onPressed, isNull);
      await cash(tester, '134000');
      await tester.tap(find.byKey(const Key('payment_submit')));
      await tester.pumpAndSettle();
      expect(
        bloc.submitted.whereType<SubmitPayment>().single.payments,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('desktop retains its two-panel payment layout', (tester) async {
    await size(tester, const Size(1200, 800));
    final bloc = _PaymentBloc(initial());
    addTearDown(bloc.close);
    await tester.pumpWidget(_app(bloc));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('payment_desktop_layout')), findsOneWidget);
    expect(find.byKey(const Key('payment_mobile_layout')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('note remains usable with the phone keyboard and closes safely', (
    tester,
  ) async {
    await size(tester, const Size(320, 568));
    addTearDown(tester.view.resetViewInsets);
    final bloc = _PaymentBloc(initial());
    addTearDown(bloc.close);
    await tester.pumpWidget(_app(bloc, scale: 1.3));
    await tester.pumpAndSettle();
    await show(tester, find.text('Catatan'));
    await tester.tap(find.text('Catatan'));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('payment_note_value')),
      'Catatan pembayaran uji',
    );
    await tester.tap(find.text('Simpan'));
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.text('Catatan pembayaran uji'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'removing a focused split amount and cancelling keeps form lifecycle safe',
    (tester) async {
      await size(tester, const Size(320, 568));
      final bloc = _PaymentBloc(initial());
      addTearDown(bloc.close);
      await tester.pumpWidget(_app(bloc));
      await tester.pumpAndSettle();
      await show(tester, find.byKey(const Key('payment_mobile_split')));
      await tester.tap(find.byKey(const Key('payment_mobile_split')));
      await tester.pumpAndSettle();
      await show(tester, find.text('Tambah metode pembayaran'));
      await tester.tap(find.text('Tambah metode pembayaran'));
      await tester.pumpAndSettle();
      final last = find.byType(TextField).last;
      await show(tester, last);
      await tester.enterText(last, '20000');
      await tester.pumpAndSettle();
      await show(tester, find.byTooltip('Hapus metode').last);
      await tester.tap(find.byTooltip('Hapus metode').last);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'cash minimum is still enforced and loading cannot submit noncash payment',
    (tester) async {
      await size(tester, const Size(320, 568));
      final bloc = _PaymentBloc(
        initial().copyWith(runtimeConfig: {'minimum_cash_transaction': 200000}),
      );
      addTearDown(bloc.close);
      await tester.pumpWidget(_app(bloc));
      await tester.pumpAndSettle();
      await cash(tester, '134000');
      expect(submit(tester).onPressed, isNull);
      final qris = find.byKey(const ValueKey('payment_mobile_method:QRIS'));
      await show(tester, qris);
      await tester.tap(qris);
      await tester.pumpAndSettle();
      expect(submit(tester).onPressed, isNotNull);
      await tester.pumpWidget(const SizedBox());
      final loading = _PaymentBloc(
        initial(
          status: PosStatus.loading,
        ).copyWith(runtimeConfig: {'default_payment_method': 'qris'}),
      );
      addTearDown(loading.close);
      await tester.pumpWidget(_app(loading));
      await tester.pump();
      expect(submit(tester).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(loading.submitted.whereType<SubmitPayment>(), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'payment remains locked when background refresh changes general status',
    (tester) async {
      await size(tester, const Size(360, 800));
      final bloc = _PaymentBloc(initial().copyWith(paymentInProgress: true));
      addTearDown(bloc.close);
      await tester.pumpWidget(_app(bloc));
      await tester.pump();
      expect(
        tester.widget<PopScope>(find.byType(PopScope).first).canPop,
        false,
      );
      expect(submit(tester).onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.arrow_back),
            )
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets('pending invoice displays its own items and total on mobile', (
    tester,
  ) async {
    await size(tester, const Size(360, 800));
    final bloc = _PaymentBloc(initial());
    addTearDown(bloc.close);
    const invoice = PosOrder(
      id: 'invoice-qa',
      invoice: 'INV-QA-0042',
      date: '2026-11-14',
      customer: 'Pelanggan Invoice Uji',
      cashierName: 'Kasir Uji',
      paymentMethod: 'tempo',
      total: 42000,
      subtotal: 40000,
      taxAmount: 2000,
      status: 'pending',
      items: [
        {
          'qty': 2,
          'nama': 'Produk Invoice Uji',
          'harga_satuan': 20000,
          'subtotal': 40000,
        },
      ],
    );
    await tester.pumpWidget(_app(bloc, pendingOrder: invoice));
    await tester.pumpAndSettle();
    expect(find.text('Rp 42.000'), findsNWidgets(2));
    await show(tester, find.byKey(const Key('payment_mobile_summary')));
    await tester.tap(find.text('Ringkasan pesanan'));
    await tester.pumpAndSettle();
    expect(find.text('Produk Invoice Uji'), findsOneWidget);
    expect(find.text(product.name), findsNothing);
    expect(find.text('Rp 2.000'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
