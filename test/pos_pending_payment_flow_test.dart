import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/customer_display/pos_customer_display_service.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_customer.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_payment_page.dart';

class _Repo extends Fake implements PosRepository {
  final calls = <Map<String, Object?>>[];
  Completer<Either<Failure, Map<String, dynamic>>>? pending;
  Either<Failure, Map<String, dynamic>> response = const Left(
    ServerFailure('QA retryable failure'),
  );

  @override
  Future<Either<Failure, Map<String, dynamic>>> payPendingOrder({
    required String orderId,
    required String method,
    double? cashReceived,
    List<Map<String, dynamic>> splitPayments = const [],
    String? customerId,
  }) async {
    calls.add({'order': orderId, 'method': method, 'customer': customerId});
    return pending?.future ?? response;
  }
}

class _Display extends Fake implements PosCustomerDisplayService {
  int completed = 0;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #publishCart) {
      completed++;
      return null;
    }
    return super.noSuchMethod(invocation);
  }
}

class _Bloc extends PosBloc {
  _Bloc(_Repo repo, String method, {PosCustomer? customer})
    : super(posRepository: repo) {
    emit(
      PosState(
        status: PosStatus.success,
        cart: {product: 1},
        selectedCustomer: customer,
        stores: const [
          PosStore(
            id: 'store',
            name: 'QA',
            status: 'active',
            branchId: 'branch',
          ),
        ],
        activeShift: const {'_id': 'shift', 'toko_id': 'store'},
        runtimeConfig: {'default_payment_method': method},
      ),
    );
  }

  final events = <PosEvent>[];
  @override
  void add(PosEvent event) => events.add(event);
}

const product = PosProduct(
  id: 'p',
  code: 'P',
  name: 'QA item',
  price: 100,
  stock: 10,
  category: 'QA',
);
const customer = PosCustomer(
  id: 'customer-cart',
  name: 'Cart customer',
  phone: '',
  priceLevel: 'retail',
);

PosOrder order({String? customerId = 'customer-order'}) => PosOrder(
  id: 'pending-order',
  invoice: 'ORD-QA',
  date: '2026-11-25',
  customer: customerId == null ? 'Pelanggan umum' : 'Order customer',
  customerId: customerId,
  cashierName: 'QA',
  paymentMethod: '',
  total: 100,
  status: 'Baru',
  paymentStatus: 'belum_bayar',
  isInvoice: true,
);

void main() {
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
  tearDown(() => sl.reset());

  Future<(_Bloc, _Repo)> open(
    WidgetTester tester, {
    String method = 'tempo',
    PosOrder? pendingOrder,
    PosCustomer? selectedCustomer,
    bool pushed = false,
    Locale locale = const Locale('id'),
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _Repo();
    sl.registerSingleton<PosRepository>(repo);
    final bloc = _Bloc(repo, method, customer: selectedCustomer);
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider<PosBloc>.value(
        value: bloc,
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: pushed
              ? Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => BlocProvider<PosBloc>.value(
                            value: bloc,
                            child: PosPaymentPage(pendingOrder: pendingOrder),
                          ),
                        ),
                      ),
                      child: const Text('Open payment'),
                    ),
                  ),
                )
              : PosPaymentPage(pendingOrder: pendingOrder),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (pushed) {
      await tester.tap(find.text('Open payment'));
      await tester.pumpAndSettle();
    }
    return (bloc, repo);
  }

  VoidCallback submit(WidgetTester tester) => tester
      .widget<ElevatedButton>(find.byKey(const Key('payment_submit')))
      .onPressed!;
  Future<void> finish(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  testWidgets(
    'pending order tempo uses its linked customer without reselecting',
    (tester) async {
      final (_, repo) = await open(tester, pendingOrder: order());
      expect(find.byKey(const Key('payment_mobile_customer')), findsOneWidget);
      submit(tester)();
      await tester.pumpAndSettle();
      expect(repo.calls, hasLength(1));
      expect(repo.calls.single['customer'], 'customer-order');
      expect(repo.calls.single['method'], 'tempo');
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'pending order without customer cannot borrow an unrelated cart customer for credit',
    (tester) async {
      final (_, repo) = await open(
        tester,
        pendingOrder: order(customerId: null),
        selectedCustomer: customer,
      );
      submit(tester)();
      await tester.pumpAndSettle();
      expect(repo.calls, isEmpty);
      expect(
        find.text('Pilih pelanggan terlebih dahulu untuk penjualan tempo.'),
        findsOneWidget,
      );
      await finish(tester);
    },
  );

  testWidgets('new sale still accepts a valid selected customer for credit', (
    tester,
  ) async {
    final (bloc, repo) = await open(tester, selectedCustomer: customer);
    submit(tester)();
    await tester.pumpAndSettle();
    expect(repo.calls, isEmpty);
    expect(
      bloc.events.whereType<SubmitPayment>().single.paymentMethod,
      'tempo',
    );
    await finish(tester);
  });

  testWidgets('new credit sale blocks an empty customer id', (tester) async {
    final (bloc, _) = await open(
      tester,
      selectedCustomer: const PosCustomer(
        id: ' ',
        name: 'Invalid',
        phone: '',
        priceLevel: 'retail',
      ),
    );
    submit(tester)();
    await tester.pumpAndSettle();
    expect(bloc.events.whereType<SubmitPayment>(), isEmpty);
    await finish(tester);
  });

  testWidgets(
    'rapid pending-order payment taps submit once and permit retry after rejection',
    (tester) async {
      final (_, repo) = await open(
        tester,
        method: 'transfer',
        pendingOrder: order(),
      );
      final pending = Completer<Either<Failure, Map<String, dynamic>>>();
      repo.pending = pending;
      final press = submit(tester);
      press();
      press();
      await tester.pump();
      expect(repo.calls, hasLength(1));
      await tester.pump();
      expect(
        tester.widget<PopScope>(find.byType(PopScope).first).canPop,
        isFalse,
      );
      pending.complete(const Left(ServerFailure('QA rejected')));
      await tester.pumpAndSettle();
      repo.pending = null;
      expect(
        tester.widget<PopScope>(find.byType(PopScope).first).canPop,
        isTrue,
      );
      submit(tester)();
      await tester.pumpAndSettle();
      expect(repo.calls, hasLength(2));
      expect(
        repo.calls.every((call) => call['order'] == 'pending-order'),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );

  testWidgets(
    'successful pending payment exits to orders and keeps unrelated cashier cart',
    (tester) async {
      final display = _Display();
      sl.registerSingleton<PosCustomerDisplayService>(display);
      final (bloc, repo) = await open(
        tester,
        method: 'transfer',
        pendingOrder: order(),
        selectedCustomer: customer,
        pushed: true,
      );
      repo.response = const Right({'_id': 'pending-order'});
      submit(tester)();
      await tester.pumpAndSettle();
      expect(repo.calls, hasLength(1));
      expect(repo.calls.single['customer'], 'customer-order');
      expect(find.byType(PosPaymentPage), findsNothing);
      expect(find.text('Open payment'), findsOneWidget);
      expect(bloc.events.whereType<RefreshOrders>(), hasLength(1));
      expect(bloc.events.whereType<ClearCart>(), isEmpty);
      expect(bloc.state.cart[product], 1);
      expect(display.completed, 1);
      expect(tester.takeException(), isNull);
      await finish(tester);
    },
  );
  for (final locale in [const Locale('id'), const Locale('en')]) {
    testWidgets(
      'pending credit completion states receivable, not money received ${locale.languageCode}',
      (tester) async {
        sl.registerSingleton<PosCustomerDisplayService>(_Display());
        final (_, repo) = await open(
          tester,
          pendingOrder: order(),
          pushed: true,
          locale: locale,
        );
        repo.response = const Right({
          '_id': 'pending-order',
          'metode_pembayaran': 'tempo',
        });
        submit(tester)();
        await tester.pumpAndSettle();
        expect(repo.calls.single['method'], 'tempo');
        expect(
          find.text(
            locale.languageCode == 'id'
                ? 'Pesanan dicatat sebagai piutang. Pelunasan dapat dilanjutkan dari Piutang Pelanggan.'
                : 'Order recorded as a receivable. Continue collecting payment from Customer Receivables.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('berhasil dibayar'), findsNothing);
        expect(find.byType(PosPaymentPage), findsNothing);
        await finish(tester);
      },
    );
  }
  for (final tender in [
    (requested: 'transfer', committed: 'tempo'),
    (requested: 'tempo', committed: 'transfer'),
  ]) {
    testWidgets(
      'recovered payment displays committed ${tender.committed} instead of requested ${tender.requested}',
      (tester) async {
        sl.registerSingleton<PosCustomerDisplayService>(_Display());
        final (_, repo) = await open(
          tester,
          method: tender.requested,
          pendingOrder: order(),
          pushed: true,
        );
        repo.response = Right({
          '_id': 'pending-order',
          'metode_pembayaran': tender.committed,
        });
        submit(tester)();
        await tester.pumpAndSettle();
        expect(repo.calls.single['method'], tender.requested);
        expect(
          find.textContaining('piutang.'),
          tender.committed == 'tempo' ? findsOneWidget : findsNothing,
        );
        expect(
          find.textContaining('berhasil dibayar'),
          tender.committed == 'tempo' ? findsNothing : findsOneWidget,
        );
        expect(find.byType(PosPaymentPage), findsNothing);
        await finish(tester);
      },
    );
  }
}
