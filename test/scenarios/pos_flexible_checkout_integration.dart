// Specialized cross-client scenario (outside default *_test.dart collection).
// Run through backend npm run test:pos-flexible-checkout-clients.
// Real HTTP/schema/database; fixture context replaces login only.
import 'dart:convert';
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/core/network/sync_service.dart';
import 'package:mobile_pos_pantoo/data/datasources/local/pos_local_database.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_customer.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order_detail.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';

class _LiveHttp extends HttpOverrides {}

class _Provider extends Fake implements GraphQLClientProvider {
  _Provider(this.client, this.sharedPreferences);
  @override
  final GraphQLClient client;
  @override
  final SharedPreferences sharedPreferences;
  @override
  Future<String?> checkOfflineSubscription() async => null;
  @override
  String resolveMediaUrl(dynamic value) => '';
}

class _CheckoutBloc extends PosBloc {
  _CheckoutBloc(PosRepository repository, PosState seed)
    : super(posRepository: repository) {
    emit(seed);
  }
}

T right<T>(Either<Failure, T> result) =>
    result.fold((error) => throw StateError(error.message), (value) => value);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final origin = Platform.environment['QA_FLEX_CHECKOUT_ORIGIN'];
  // Ordinary flutter test runs must not silently mark this cross-server suite
  // passed. An explicit harness is mandatory for the specialized group.
  if (origin == null) {
    test('cross-client integration requires its isolated backend harness', () {
      fail(
        'Run npm run test:pos-flexible-checkout-clients from backend with QA_FLUTTER_BIN set',
      );
    });
    return;
  }
  assert(Uri.parse(origin).host == '127.0.0.1');
  late Database db;
  late Map<String, dynamic> fixture;
  late SharedPreferences prefs;
  late PosRepository repository;
  late _Provider provider;
  late PosProduct product;
  late PosBloc bloc;
  var offline = false;
  final networkRequests = <Map<String, dynamic>>[];
  Future<Map<String, dynamic>> jsonRequest(
    String route, [
    Map<String, dynamic>? body,
  ]) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(
        body == null ? 'GET' : 'POST',
        Uri.parse('$origin$route'),
      );
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      final value =
          jsonDecode(await utf8.decoder.bind(response).join())
              as Map<String, dynamic>;
      expect(response.statusCode, 200, reason: value.toString());
      return value;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> settle(bool Function() condition) async {
    for (var i = 0; i < 500 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(condition(), true, reason: bloc.state.errorMessage);
  }

  Future<Map<String, dynamic>> summary() =>
      jsonRequest('/summary/${fixture['tenant']}');
  void checkReceivable(Map<String, dynamic> saved) {
    final invoice = (saved['invoices'] as List).single as Map;
    expect(invoice['outstanding_amount'], 350);
    expect(invoice['paid_amount'], 0);
    expect(invoice['lines'][0]['unit_price'], 175);
    expect(invoice['lines'][0]['quantity'], 2);
    final journal =
        (saved['journals'] as List).singleWhere(
              (value) => value['_id'] == invoice['journal_id'],
            )
            as Map;
    expect(journal['status'], 'posted');
    expect(journal['total_debit'], 350);
    expect(journal['total_credit'], 350);
    final ar = (journal['lines'] as List).where(
      (line) => line['account_code'] == invoice['ar_account_code'],
    );
    expect(
      ar.fold<num>(
        0,
        (sum, line) => sum + (line['debit'] as num) - (line['credit'] as num),
      ),
      350,
    );
  }

  Future<void> changeMaster() =>
      jsonRequest('/master/${fixture['tenant']}', {'price': 999});
  setUpAll(() async {
    HttpOverrides.global = _LiveHttp();
    sqfliteFfiInit();
    final directory = await Directory.systemTemp.createTemp(
      'pantoo-flex-checkout-',
    );
    await databaseFactoryFfi.setDatabasesPath(directory.path);
    db = await PosLocalDatabase.instance.database;
  });
  tearDownAll(() async {
    await PosLocalDatabase.instance.close();
    HttpOverrides.global = null;
  });
  setUp(() async {
    offline = false;
    networkRequests.clear();
    fixture = await jsonRequest('/fixture');
    SharedPreferences.setMockInitialValues({
      'instansi_id': fixture['tenant'],
      'user_id': fixture['actor'],
    });
    prefs = await SharedPreferences.getInstance();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (_) async => offline ? ['none'] : ['wifi'],
        );
    final network = HttpLink(fixture['endpoint'] as String);
    final gate = Link.function((request, [forward]) async* {
      networkRequests.add(Map<String, dynamic>.from(request.variables));
      if (offline) {
        throw const ServerException(
          originalException: SocketException('Network is unreachable'),
        );
      }
      yield* forward!(request);
    });
    final client = GraphQLClient(
      cache: GraphQLCache(),
      link: gate.concat(network),
    );
    provider = _Provider(client, prefs);
    repository = PosRepository(provider, prefs);
    // Populate actual store/catalog caches before testing offline submission.
    final stores = await repository.getStores();
    final products = await repository.getProducts(
      branchId: fixture['branch'] as String,
    );
    product = products.firstWhere((value) => value.id == fixture['product']);
    expect(product.isFlexibleService, true);
    expect(product.price, 100);
    bloc = _CheckoutBloc(
      repository,
      PosState(
        stores: stores,
        products: [product],
        cart: {product: 2},
        manualUnitPrices: {product.id: 150},
        selectedCustomer: PosCustomer(
          id: fixture['customer'] as String,
          name: 'QA',
          phone: '',
          priceLevel: 'retail',
        ),
        runtimeConfig: const {
          'allow_cashier_price_edit': false,
          'allow_out_of_shift': true,
        },
      ),
    );
    bloc.add(UpdateCartUnitPrice(product, 175));
    await settle(
      () => bloc.state.pricingPreview != null && bloc.state.grandTotal == 350,
    );
    expect(bloc.state.unitPriceFor(product), 175);
  });
  tearDown(() async {
    await bloc.close();
    await provider.client.link.dispose();
  });

  for (final method in ['tunai', 'tempo']) {
    test(
      'mobile edited tariff → $method → receipt and persisted Finance',
      () async {
        bloc.add(
          SubmitPayment(
            paymentMethod: method,
            cashReceived: method == 'tunai' ? 350 : 0,
          ),
        );
        await settle(
          () =>
              bloc.state.status == PosStatus.paymentSuccess ||
              bloc.state.status == PosStatus.failure,
        );
        expect(
          bloc.state.status,
          PosStatus.paymentSuccess,
          reason: bloc.state.errorMessage,
        );
        expect(bloc.state.lastTransaction!.total, 350);
        expect(bloc.state.lastTransaction!.items.single['harga_jual'], 175);
        final saved = await summary();
        final sale = (saved['sales'] as List).single;
        expect(sale['items'][0]['harga_jual'], 175);
        expect(sale['total'], 350);
        expect(saved['master']['harga_jual'], 100);
        if (method == 'tempo') {
          checkReceivable(saved);
        }
      },
    );
  }
  for (final disconnected in [false, true]) {
    for (final method in ['tunai', 'tempo']) {
      test(
        'mobile edited tariff → unpaid ${disconnected ? 'offline/reopen/replay' : 'online'} → $method',
        () async {
          final state = bloc.state;
          offline = disconnected;
          final result = right(
            await repository.createUnpaidInvoice(
              clientRequestId: 'edited-unpaid-${fixture['tenant']}',
              cart: state.cart,
              itemPrices: {product.id: state.unitPriceFor(product)},
              selectedUnits: state.selectedUnits,
              tokoId: fixture['store'] as String,
              shiftId: '',
              orderType: 'take_away',
              customerId: fixture['customer'] as String,
              expectedTotal: state.grandTotal,
            ),
          );
          Map<String, dynamic> order;
          if (disconnected) {
            expect(result['offline_queued'], true);
            var rows = await db.query(
              'offline_transactions',
              where: 'instansi_id = ?',
              whereArgs: [fixture['tenant']],
            );
            expect(rows, hasLength(1));
            final payload = jsonDecode(rows.single['payload'] as String);
            expect(payload['items'][0]['harga_satuan'], 175);
            await PosLocalDatabase.instance.close();
            db = await PosLocalDatabase.instance.database;
            offline = false;
            final sync = SyncService(provider);
            await sync.syncOfflineTransactions(force: true);
            rows = await db.query(
              'offline_transactions',
              where: 'instansi_id = ?',
              whereArgs: [fixture['tenant']],
            );
            expect(
              rows.single['status'],
              'synced',
              reason: rows.single.toString(),
            );
            await sync.syncOfflineTransactions(force: true);
            order = Map<String, dynamic>.from(
              (await summary())['orders'].single as Map,
            );
          } else {
            order = result;
          }
          final before = await summary();
          expect(before['sales'], isEmpty);
          expect(before['invoices'], isEmpty);
          expect(order['items'][0]['harga_satuan'], 175);
          expect(order['grand_total'], 350);
          bloc.add(EditActiveOrder(PosOrderDetail.fromJson(order)));
          await settle(
            () =>
                bloc.state.editingOrderId == order['_id'] &&
                bloc.state.pricingPreview != null,
          );
          expect(bloc.state.unitPriceFor(product), 175);
          expect(bloc.state.grandTotal, 350);
          expect(bloc.state.orderType, 'take_away');
          await changeMaster();
          final paid = right(
            await repository.payPendingOrder(
              orderId: order['_id'] as String,
              method: method,
              cashReceived: method == 'tunai' ? 350 : null,
              customerId: fixture['customer'] as String,
            ),
          );
          expect(paid['_id'], order['_id']);
          final saved = await summary();
          expect(saved['orders'], hasLength(1));
          expect(saved['sales'], hasLength(1));
          expect(saved['sales'][0]['items'][0]['harga_jual'], 175);
          expect(saved['sales'][0]['total'], 350);
          if (method == 'tempo') {
            checkReceivable(saved);
          }
        },
      );
    }
  }
  test(
    'mobile edited tariff → offline cash → SQLite reopen → exact replay',
    () async {
      offline = true;
      bloc.add(const SubmitPayment(paymentMethod: 'tunai', cashReceived: 350));
      await settle(
        () =>
            bloc.state.status == PosStatus.paymentSuccess ||
            bloc.state.status == PosStatus.failure,
      );
      expect(
        bloc.state.status,
        PosStatus.paymentSuccess,
        reason: bloc.state.errorMessage,
      );
      expect(bloc.state.lastTransaction!.pendingSync, true);
      expect(bloc.state.lastTransaction!.items.single['harga_jual'], 175);
      var rows = await db.query(
        'offline_transactions',
        where: 'instansi_id = ?',
        whereArgs: [fixture['tenant']],
      );
      expect(rows, hasLength(1));
      final payload = jsonDecode(rows.single['payload'] as String);
      expect(payload['items'][0]['harga_jual'], 175);
      expect(payload.containsKey('operator_session_token'), false);
      await PosLocalDatabase.instance.close();
      db = await PosLocalDatabase.instance.database;
      offline = false;
      await changeMaster();
      final sync = SyncService(provider);
      await sync.syncOfflineTransactions(force: true);
      await sync.syncOfflineTransactions(force: true);
      rows = await db.query(
        'offline_transactions',
        where: 'instansi_id = ?',
        whereArgs: [fixture['tenant']],
      );
      expect(rows.single['status'], 'synced', reason: rows.single.toString());
      final saved = await summary();
      expect(saved['sales'], hasLength(1));
      expect(saved['sales'][0]['items'][0]['harga_jual'], 175);
      expect(saved['sales'][0]['total'], 350);
    },
  );
  test(
    'mobile offline credit rejected, edited cart retained and no false AR',
    () async {
      offline = true;
      bloc.add(const SubmitPayment(paymentMethod: 'tempo'));
      await settle(() => bloc.state.status == PosStatus.failure);
      expect(bloc.state.unitPriceFor(product), 175);
      expect(bloc.state.grandTotal, 350);
      expect(
        await db.query(
          'offline_transactions',
          where: 'instansi_id = ?',
          whereArgs: [fixture['tenant']],
        ),
        isEmpty,
      );
      final saved = await summary();
      expect(saved['invoices'], isEmpty);
      expect(saved['sales'], isEmpty);
    },
  );
}
