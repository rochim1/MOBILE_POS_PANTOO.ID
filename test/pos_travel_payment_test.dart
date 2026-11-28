import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/core/network/pos_travel_intent_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_travel_repository.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_travel_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_travel_forms.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_travel_copy.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';

const shop = '000000000000000000000001';
const book = '000000000000000000000002';
Map<String, dynamic> booking([int paid = 0]) => {
  '__typename': 'POSTravelBooking',
  '_id': book,
  'toko_id': shop,
  'departure_id': 'trip',
  'customer_id': 'customer',
  'customer_name': 'QA Customer',
  'contact_phone': '08123456789',
  'pickup_point': 'Terminal',
  'number': 'TRV-QA-1',
  'status': 'confirmed',
  'version': paid == 0 ? 2 : 3,
  'seats': 1,
  'total_amount': 1000000,
  'currency': 'IDR',
  'paid_amount': paid,
  'refunded_amount': 0,
  'outstanding_amount': 1000000 - paid,
  'payment_status': paid == 0
      ? 'unpaid'
      : paid == 1000000
      ? 'paid'
      : 'partial',
  'expires_at': null,
  'completed_at': null,
  'departure_snapshot': {
    'code': 'TRIP',
    'starts_at': '2030-12-01T01:00:00Z',
    'booking_closes_at': '2030-11-30T01:00:00Z',
  },
  'package_snapshot': {
    'package_id': 'package',
    'code': 'TOUR',
    'name': 'Tour QA',
    'terms': 'Terms',
    'terms_version': 1,
    'hold_minutes': 15,
  },
  'participants': [
    {
      'name': 'Passenger',
      'category': 'adult',
      'uses_seat': true,
      'price': 1000000,
    },
  ],
  'payments': [],
  'history': [],
};
const options = {
  'can_pay': true,
  'can_refund': true,
  'can_complete': true,
  'accounts': [
    {
      '_id': 'bank',
      'name': 'QA Bank',
      'account_last4': '1234',
      'coa_code': '1002',
    },
  ],
};

class Provider extends Fake implements GraphQLClientProvider {
  @override
  late GraphQLClient client;
  @override
  late SharedPreferences sharedPreferences;
  @override
  String subscriptionScope = 'local|tenant|terminal|cashier';
  @override
  bool requiresOperatorVerification = false;
}

class WidgetRepo extends Fake implements PosTravelRepository {
  Map<String, dynamic> row = booking();
  final calls = <Map<String, dynamic>>[];
  bool writable = true;
  bool unresolved = false;
  @override
  String get scope => 'widget-owner';
  @override
  Map<String, dynamic>? pending() => unresolved
      ? {
          'operation': 'payment',
          'input': {'toko_id': shop, 'booking_id': book},
        }
      : null;
  @override
  Future<Map<String, dynamic>> read(
    String operation,
    Map<String, dynamic> variables,
  ) async {
    if (operation == 'TravelPaymentOptions') {
      return {
        ...options,
        'can_pay': writable,
        'can_refund': writable,
        'can_complete': writable,
      };
    }
    if (operation == 'TravelStores') {
      return {
        'business_profile': 'travel',
        'permissions': {'create_booking': true, 'manage_master': true},
        'selected': null,
        'items': [
          {'_id': shop, 'nama_toko': 'Travel QA', 'status': 'active'},
        ],
        'totalCount': 1,
      };
    }
    if (operation == 'TravelBookings') {
      return {
        'items': [row],
        'totalCount': 1,
      };
    }
    if (operation == 'TravelDepartures') {
      return {
        'items': [
          {
            '_id': 'trip',
            'code': 'TRIP-QA',
            'starts_at': '2030-12-01T01:00:00Z',
            'available_seats': 5,
          },
        ],
        'totalCount': 1,
      };
    }
    if (operation == 'TravelCustomers') {
      return {
        'items': [
          {'_id': 'customer', 'name': 'QA Customer'},
        ],
        'totalCount': 1,
      };
    }
    return row;
  }

  @override
  Future<Map<String, dynamic>> submit(
    String operation,
    Map<String, dynamic> input,
  ) async {
    calls.add({'operation': operation, ...input});
    if (operation == 'createBooking') return row;
    row = booking((row['paid_amount'] as int) + (input['amount'] as int));
    return row;
  }
}

void main() {
  testWidgets(
    'Travel participant and payment labels follow Indonesian and English',
    (tester) async {
      for (final language in ['id', 'en']) {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Builder(
              builder: (context) => Column(
                children: [
                  Text(travelCategory(context, 'adult')),
                  Text(travelMethod(context, 'tunai')),
                  Text(travelMethod(context, 'transfer')),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(language == 'id' ? 'Dewasa' : 'Adult'),
          findsOneWidget,
        );
        expect(find.text(language == 'id' ? 'Tunai' : 'Cash'), findsOneWidget);
        expect(
          find.text(
            language == 'id' ? 'Transfer manual' : 'Manual bank transfer',
          ),
          findsOneWidget,
        );
      }
    },
  );
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late Provider provider;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    provider = Provider()..sharedPreferences = prefs;
  });
  void wire(Stream<Response> Function(Request) handler) {
    provider.client = GraphQLClient(
      cache: GraphQLCache(),
      link: Link.function((request, [forward]) => handler(request)),
    );
  }

  test(
    'durable intent is copied, isolates owners and refuses duplicate creation or corruption',
    () async {
      final store = PosTravelIntentStore(prefs, provider.subscriptionScope),
          input = {
            'toko_id': shop,
            'booking_id': book,
            'operator_session_token': 'never-store',
            'amount': 200000,
          };
      final first = await store.prepare('payment', input);
      input['amount'] = 1;
      expect(store.load()!['input']['amount'], 200000);
      expect(
        store.load()!['input'].containsKey('operator_session_token'),
        false,
      );
      expect(PosTravelIntentStore(prefs, 'other').load(), null);
      await expectLater(store.prepare('payment', input), throwsStateError);
      await expectLater(store.acknowledge('wrong'), throwsStateError);
      await store.acknowledge(first['input']['request_id']);
      expect(store.load(), null);
      await prefs.setString(store.key, '{}');
      expect(store.load, throwsStateError);
    },
  );
  test(
    'lost ACK then repository restart retries exactly the same payment and clears only verified evidence',
    () async {
      final calls = <Map<String, dynamic>>[];
      wire((request) async* {
        calls.add(
          jsonDecode(jsonEncode(request.variables)) as Map<String, dynamic>,
        );
        if (calls.length == 1) throw StateError('lost response');
        yield Response(
          data: {
            '__typename': 'Mutation',
            'RecordPOSTravelPayment': booking(200000),
          },
          response: {},
        );
      });
      final repo = PosTravelRepository(provider);
      await expectLater(
        repo.submit('payment', {
          'toko_id': shop,
          'booking_id': book,
          'expected_version': 2,
          'amount': 200000,
          'method': 'tunai',
          'reference': 'Cash QA',
        }),
        throwsStateError,
      );
      expect(repo.pending()!['attempts'], 1);
      await expectLater(
        repo.submit('payment', {'toko_id': shop}),
        throwsStateError,
      );
      final recovered = await PosTravelRepository(provider).recover();
      expect(calls.length, 2);
      expect(calls[1], calls[0]);
      expect(recovered['paid_amount'], 200000);
      expect(repo.pending(), null);
    },
  );
  test(
    'first explicit rejection clears intent but ambiguity followed by rejection does not',
    () async {
      wire((request) async* {
        yield Response(
          errors: [
            GraphQLError(
              message: 'Shift closed',
              extensions: {'code': 'SHIFT_REQUIRED'},
            ),
          ],
          response: {},
        );
      });
      final repo = PosTravelRepository(provider);
      await expectLater(
        repo.submit('payment', {'toko_id': shop}),
        throwsStateError,
      );
      expect(repo.pending(), null);
      wire((request) async* {
        throw StateError('offline');
      });
      await expectLater(
        repo.submit('payment', {'toko_id': shop}),
        throwsStateError,
      );
      wire((request) async* {
        yield Response(
          errors: [
            GraphQLError(message: 'Revoked', extensions: {'code': 'FORBIDDEN'}),
          ],
          response: {},
        );
      });
      await expectLater(repo.recover(), throwsStateError);
      expect(repo.pending()!['attempts'], 2);
    },
  );
  test(
    'scope/PIN expiry and malformed payment response cannot acknowledge old evidence',
    () async {
      wire((request) async* {
        yield Response(
          data: {
            'RecordPOSTravelPayment': {
              ...booking(200000),
              '_id': 'other-booking',
            },
          },
          response: {},
        );
      });
      final repo = PosTravelRepository(provider);
      await expectLater(
        repo.submit('payment', {'toko_id': shop, 'booking_id': book}),
        throwsStateError,
      );
      expect(repo.pending(), isNotNull);
      provider.requiresOperatorVerification = true;
      expect(() => repo.recover(), throwsStateError);
      provider.requiresOperatorVerification = false;
      provider.subscriptionScope = 'another-owner';
      expect(repo.pending(), null);
    },
  );
  test(
    'two taps share one in-flight retry and authoritative resolution never invents payment success',
    () async {
      final completer = Completer<Response>();
      int calls = 0;
      wire((request) {
        calls++;
        return completer.future.asStream();
      });
      final repo = PosTravelRepository(provider),
          f = repo.submit('payment', {'toko_id': shop, 'booking_id': book});
      await Future<void>.delayed(Duration.zero);
      final retry = repo.recover();
      expect(() => repo.submit('payment', {'toko_id': shop}), throwsStateError);
      completer.complete(
        Response(
          data: {'RecordPOSTravelPayment': booking(200000)},
          response: {},
        ),
      );
      await Future.wait([f, retry]);
      expect(calls, 1);
      await repo.store.prepare('payment', {
        'toko_id': shop,
        'booking_id': book,
      });
      wire((request) async* {
        yield Response(
          data: {
            'ResolvePOSTravelRequest': {
              'status': 'cancelled',
              'operation': 'cancel_pending',
              'entity_id': null,
            },
          },
          response: {},
        );
      });
      expect((await repo.resolve())['status'], 'cancelled');
      expect(repo.pending(), null);
    },
  );
  test('read uses named field even with root typename present', () async {
    wire((request) async* {
      yield Response(
        data: {'__typename': 'Query', 'GetPOSTravelBooking': booking(200000)},
        response: {},
      );
    });
    expect(
      (await PosTravelRepository(provider).read('TravelBooking', {
        'toko_id': shop,
        'booking_id': book,
      }))['paid_amount'],
      200000,
    );
  });
  testWidgets(
    'mobile DP then settlement uses same booking and current version without asking schedule again',
    (tester) async {
      final repo = WidgetRepo();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: PosTravelBookingPage(
            repository: repo,
            storeId: shop,
            bookingId: book,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(const Key('travel-pay')), 400);
      await tester.tap(find.byKey(const Key('travel-pay')));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(PosTravelMoneyDialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(fields.at(0), '200000');
      await tester.enterText(fields.at(1), 'Cash QA');
      await tester.tap(
        find.descendant(
          of: find.byType(PosTravelMoneyDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.row['paid_amount'], 200000);
      expect(repo.calls.single['booking_id'], book);
      expect(repo.calls.single['expected_version'], 2);
      await tester.ensureVisible(find.byKey(const Key('travel-pay')));
      await tester.tap(find.byKey(const Key('travel-pay')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find
            .descendant(
              of: find.byType(PosTravelMoneyDialog),
              matching: find.byType(TextFormField),
            )
            .at(1),
        'Settle QA',
      );
      await tester.tap(
        find.descendant(
          of: find.byType(PosTravelMoneyDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.row['outstanding_amount'], 0);
      expect(repo.calls.length, 2);
      expect(repo.calls.last['booking_id'], book);
      expect(repo.calls.last['amount'], 800000);
      expect(repo.calls.last['expected_version'], 3);
      expect(find.byKey(const Key('travel-pay')), findsNothing);
      expect(tester.takeException(), null);
    },
  );
  testWidgets(
    'read-only operators cannot see money or booking mutation buttons',
    (tester) async {
      final repo = WidgetRepo()..writable = false;
      await tester.pumpWidget(
        MaterialApp(
          home: PosTravelBookingPage(
            repository: repo,
            storeId: shop,
            bookingId: book,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('travel-pay')), findsNothing);
      expect(find.text('Cancel booking'), findsNothing);
      expect(tester.takeException(), null);
    },
  );
  testWidgets(
    'compact travel list fits portrait and landscape without RenderFlex overflow',
    (tester) async {
      for (final size in [const Size(320, 568), const Size(740, 320)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PosTravelPage(
                key: UniqueKey(),
                repository: WidgetRepo()..unresolved = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), null);
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    },
  );
  testWidgets(
    'mobile new booking selects one departure, contact and passenger with no repeated schedule',
    (tester) async {
      final repo = WidgetRepo();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        PosTravelDraftPage(repository: repo, storeId: shop),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose departure'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TRIP-QA'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose customer'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(PosTravelReferencePicker),
          matching: find.byType(TextField),
        ),
        'QA',
      );
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.tap(find.text('QA Customer'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '08123456789');
      await tester.enterText(fields.at(2), 'Passenger QA');
      final save = find.widgetWithText(FilledButton, 'Create booking');
      await tester.scrollUntilVisible(
        save,
        300,
        scrollable: find
            .descendant(
              of: find.byType(PosTravelDraftPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(repo.calls.length, 1);
      expect(repo.calls.single['departure_id'], 'trip');
      expect(repo.calls.single['contact_phone'], '08123456789');
      expect(repo.calls.single['participants'], [
        {'name': 'Passenger QA', 'category': 'adult'},
      ]);
      expect(find.text('Open'), findsOneWidget);
      expect(tester.takeException(), null);
    },
  );
  test(
    'resolution of package creation never mistakes the package for a booking',
    () async {
      final repo = PosTravelRepository(provider);
      await repo.store.prepare('createPackage', {
        'toko_id': shop,
        'name': 'Tour',
      });
      wire((request) async* {
        yield Response(
          data: {
            'ResolvePOSTravelRequest': {
              'status': 'committed',
              'operation': 'createPackage',
              'entity_id': 'package',
            },
          },
          response: {},
        );
      });
      expect((await repo.resolve())['booking_id'], null);
      expect(repo.pending(), null);
    },
  );
}
