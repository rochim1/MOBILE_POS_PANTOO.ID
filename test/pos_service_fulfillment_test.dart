import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_customer.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_remote_profile_catalog.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_payment_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_product_panel.dart';

class _Repo extends Fake implements PosRepository {}

class _Bloc extends PosBloc {
  _Bloc(String type, String method) : super(posRepository: _Repo()) {
    emit(
      PosState(
        orderType: type,
        cart: {service: 1},
        manualUnitPrices: const {'service': 175000},
        stores: const [
          PosStore(
            id: 'store',
            name: 'QA',
            status: 'active',
            branchId: 'stock',
          ),
        ],
        activeShift: const {'_id': 'shift', 'toko_id': 'store'},
        selectedCustomer: customer,
        runtimeConfig: {
          'business_profile': 'jasa',
          'default_payment_method': method,
          'features': {
            'use_service_order': true,
            'use_appointments': true,
            'require_customer': true,
          },
        },
      ),
    );
  }
  final submitted = <SubmitPayment>[];
  @override
  void add(PosEvent event) {
    if (event is SubmitPayment) {
      submitted.add(event);
    } else {
      super.add(event);
    }
  }
}

const service = PosProduct(
  id: 'service',
  code: 'J',
  name: 'Transport',
  category: 'Jasa',
  price: 1000,
  stock: 0,
  tracksStock: false,
  productType: 'service',
  servicePriceMode: 'flexible',
);
const customer = PosCustomer(
  id: 'customer',
  name: 'Pelanggan QA',
  phone: '',
  priceLevel: 'retail',
);

Future<_Bloc> _open(
  WidgetTester tester,
  String type, {
  String method = 'transfer',
  double width = 800,
}) async {
  tester.view.physicalSize = Size(width, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final bloc = _Bloc(type, method);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    BlocProvider<PosBloc>.value(
      value: bloc,
      child: MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PosPaymentPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return bloc;
}

Future<void> saveIntake(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'Transport');
  await tester.tap(find.text('Simpan').last);
  await tester.pumpAndSettle();
}

void main() {
  test(
    'bundled and legacy remote jasa labels are direct service while retail remains takeaway',
    () {
      final catalog = PosRemoteProfileCatalog.bundled();
      expect(
        catalog
            .fulfillmentOptions('jasa', {'use_appointments': true})
            .map((e) => e['label']),
        ['Layanan Langsung', 'Reservasi'],
      );
      final legacy =
          jsonDecode(jsonEncode(catalog.toJson())) as Map<String, dynamic>;
      final jasa = (legacy['profiles'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((p) => p['value'] == 'jasa');
      final direct = (jasa['fulfillment_options'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((o) => o['value'] == 'take_away');
      direct['label'] = 'Bawa Pulang';
      final remote = PosRemoteProfileCatalog.fromJson(legacy);
      expect(
        remote.fulfillmentOptions('jasa', {}).single['label'],
        'Layanan Langsung',
      );
      expect(
        remote.fulfillmentOptions('retail', {}).single['label'],
        'Bawa Pulang',
      );
    },
  );
  for (final method in ['tunai', 'transfer', 'tempo']) {
    testWidgets(
      'direct service $method has no schedule prompt and preserves agreed tariff',
      (tester) async {
        final bloc = await _open(
          tester,
          'take_away',
          method: method,
          width: method == 'tunai' ? 390 : 800,
        );
        if (method == 'tunai') {
          await tester.tap(find.text('Uang Pas'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Proses Bayar'));
        await tester.pumpAndSettle();
        expect(find.text('Detail layanan'), findsOneWidget);
        expect(find.text('Pilih jadwal layanan'), findsNothing);
        await saveIntake(tester);
        expect(bloc.submitted, hasLength(1));
        expect(bloc.submitted.single.paymentMethod, method);
        expect(bloc.submitted.single.serviceOrder?['appointment_at'], isNull);
        expect(bloc.state.unitPriceFor(service), 175000);
        expect(find.text('Detail reservasi'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'reservation asks schedule once, after intake, and missing start cannot continue',
    (tester) async {
      final bloc = await _open(tester, 'reservation');
      await tester.tap(find.text('Proses Bayar'));
      await tester.pumpAndSettle();
      expect(find.text('Detail layanan'), findsOneWidget);
      expect(find.text('Pilih jadwal layanan'), findsNothing);
      await saveIntake(tester);
      expect(find.text('Detail reservasi'), findsOneWidget);
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Detail reservasi'), findsOneWidget);
      expect(bloc.submitted, isEmpty);
      // Confirm date and time once. End is filled automatically; no second picker.
      await tester.tap(find.text('Mulai reservasi *'));
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(DatePickerDialog),
              matching: find.byType(TextButton),
            )
            .last,
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(TimePickerDialog),
              matching: find.byType(TextButton),
            )
            .last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Simpan reservasi & lanjut bayar?'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Proses Bayar'));
      await tester.pumpAndSettle();
      expect(find.text('Simpan reservasi & lanjut bayar?'), findsOneWidget);
      expect(find.text('Detail reservasi'), findsNothing);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('cashier menu exposes direct service and reservation for jasa', (
    tester,
  ) async {
    final bloc = _Bloc('take_away', 'tunai');
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider<PosBloc>.value(
        value: bloc,
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PosProductPanel(
              isMobile: true,
              selectedCategory: 'Semua Kategori',
              categories: const ['Semua Kategori'],
              onCategorySelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.room_service_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Layanan Langsung'), findsOneWidget);
    expect(find.text('Reservasi'), findsOneWidget);
    expect(find.text('Bawa Pulang'), findsNothing);
    await tester.tap(find.text('Reservasi'));
    await tester.pumpAndSettle();
    expect(bloc.state.orderType, 'reservation');
    expect(tester.takeException(), isNull);
  });

  for (final scale in [0.85, 0.98]) {
    testWidgets('reservation time text entry survives compact scale $scale', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _open(tester, 'reservation', width: 411);
      await tester.tap(find.text('Proses Bayar'));
      await tester.pumpAndSettle();
      await saveIntake(tester);
      await tester.tap(find.text('Mulai reservasi *'));
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(DatePickerDialog),
              matching: find.byType(TextButton),
            )
            .last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(TimePickerDialog), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });
  }
  test('saved reservation is reused on payment retry, not asked again', () {
    final code = File(
      'lib/presentation/pages/pos/pos_payment_page.dart',
    ).readAsStringSync();
    final reservation = code
        .split('Future<bool> _ensureReservationDetails(PosState state) async {')
        .last
        .split('Future<void> _createInvoice(')
        .first;
    expect(
      reservation,
      contains(
        'if (_reservationStartAt != null && _reservationEndAt != null) return true;',
      ),
    );
    expect(reservation, contains('await reservationDialogRoute?.completed'));
  });
}
