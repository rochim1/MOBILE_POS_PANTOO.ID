import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/customer_display/pos_customer_display_service.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_order_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_receipt_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_payment_page.dart';

class _Repo extends Fake implements PosRepository {
  int creates = 0;
  @override
  Map<String, dynamic>? get pendingCheckout => null;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #createUnpaidInvoice) {
      creates++;
      return Future<Either<Failure, Map<String, dynamic>>>.value(
        const Right({'order_no': 'NEW'}),
      );
    }
    return super.noSuchMethod(invocation);
  }
}

class _OrderRepo extends Fake implements PosOrderRepository {
  final updates = <(String, List<Map<String, dynamic>>)>[];
  @override
  Future<Either<Failure, bool>> updateOrderItems(
    String orderId,
    List<Map<String, dynamic>> items,
  ) async {
    updates.add((orderId, items));
    return const Right(true);
  }
}

class _ReceiptRepo extends Fake implements PosReceiptRepository {
  @override
  Future<Either<Failure, PosReceiptPrintData>>
  preloadReceiptPrintData() async => const Left(ServerFailure('QA no printer'));
}

class _Display extends Fake implements PosCustomerDisplayService {
  @override
  final state = ValueNotifier(const PosCustomerDisplayState());
}

const product = PosProduct(
  id: 'p',
  code: 'P',
  name: 'QA item',
  category: 'QA',
  price: 100,
  stock: 10,
);

class _Bloc extends PosBloc {
  _Bloc(
    _Repo repo, {
    required String type,
    required String profile,
    required bool editing,
  }) : super(posRepository: repo) {
    emit(
      PosState(
        status: PosStatus.success,
        products: const [product],
        cart: {product: 2},
        orderType: type,
        editingOrderId: editing ? 'original-order' : null,
        editingOrderNumber: editing ? 'ORD-ORIGINAL' : null,
        activeShift: const {'_id': 'shift', 'toko_id': 'store'},
        stores: const [
          PosStore(
            id: 'store',
            name: 'QA',
            status: 'active',
            branchId: 'branch',
          ),
        ],
        runtimeConfig: {'business_profile': profile},
      ),
    );
  }
  final events = <PosEvent>[];
  @override
  void add(PosEvent event) => events.add(event);
}

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

  Future<(_Bloc, _OrderRepo, _Repo)> open(
    WidgetTester tester, {
    String type = 'take_away',
    String profile = 'retail',
    bool editing = true,
  }) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _Repo();
    final orders = _OrderRepo();
    final display = _Display();
    sl.registerSingleton<PosRepository>(repo);
    sl.registerSingleton<PosOrderRepository>(orders);
    sl.registerSingleton<PosReceiptRepository>(_ReceiptRepo());
    sl.registerSingleton<PosCustomerDisplayService>(display);
    final bloc = _Bloc(repo, type: type, profile: profile, editing: editing);
    addTearDown(() async {
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await bloc.close();
      display.state.dispose();
      await sl.reset();
    });
    await tester.pumpWidget(
      BlocProvider<PosBloc>.value(
        value: bloc,
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PosPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (bloc, orders, repo);
  }

  Future<void> act(WidgetTester tester, bool keyboard) async {
    if (keyboard) {
      await tester.sendKeyEvent(LogicalKeyboardKey.f4);
    } else {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan Perubahan'));
    }
    await tester.pumpAndSettle();
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  for (final keyboard in [true, false]) {
    for (final context in [
      (profile: 'retail', type: 'take_away'),
      (profile: 'jasa', type: 'take_away'),
      (profile: 'restoran', type: 'dine_in'),
    ]) {
      testWidgets(
        '${keyboard ? 'F4' : 'CTA'} updates existing ${context.profile}/${context.type} order without creating a payment',
        (tester) async {
          final (bloc, orders, repo) = await open(
            tester,
            type: context.type,
            profile: context.profile,
          );
          try {
            expect(find.text('Simpan Perubahan'), findsOneWidget);
            await act(tester, keyboard);
            expect(orders.updates, hasLength(1));
            expect(orders.updates.single.$1, 'original-order');
            expect(orders.updates.single.$2.single['qty'], 2);
            expect(orders.updates.single.$2.single['harga_satuan'], 100);
            expect(repo.creates, 0);
            expect(find.byType(PosPaymentPage), findsNothing);
            expect(bloc.events.whereType<ClearCart>(), hasLength(1));
            expect(bloc.events.whereType<RefreshOrders>(), hasLength(1));
            expect(tester.takeException(), isNull);
          } finally {
            await finish(tester);
          }
        },
      );
    }
  }

  testWidgets('F4 keeps new dine-in order blocked until a table is selected', (
    tester,
  ) async {
    final (_, orders, repo) = await open(
      tester,
      type: 'dine_in',
      profile: 'restoran',
      editing: false,
    );
    try {
      await act(tester, true);
      expect(orders.updates, isEmpty);
      expect(repo.creates, 0);
      expect(find.byType(PosPaymentPage), findsNothing);
      expect(
        find.text('Pilih meja dari menu tipe pemenuhan terlebih dahulu.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    } finally {
      await finish(tester);
    }
  });

  testWidgets('F4 opens payment for a new ordinary sale', (tester) async {
    final (_, orders, repo) = await open(tester, editing: false);
    try {
      await act(tester, true);
      expect(orders.updates, isEmpty);
      expect(repo.creates, 0);
      expect(find.byType(PosPaymentPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await finish(tester);
    }
  });
}
