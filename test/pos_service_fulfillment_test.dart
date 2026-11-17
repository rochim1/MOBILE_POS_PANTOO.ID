import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_customer.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_remote_profile_catalog.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_payment_page.dart';

class _Repo extends Fake implements PosRepository {}
class _Bloc extends PosBloc {
  _Bloc(String type, String method) : super(posRepository: _Repo()) {
    emit(PosState(orderType: type, cart: {service: 1}, manualUnitPrices: const {'service': 175000},
      selectedCustomer: customer, runtimeConfig: {'business_profile': 'jasa', 'default_payment_method': method,
        'features': {'use_service_order': true, 'use_appointments': true, 'require_customer': true}}));
  }
  final submitted = <SubmitPayment>[];
  @override
  void add(PosEvent event) {
    if (event is SubmitPayment) { submitted.add(event); } else { super.add(event); }
  }
}
const service = PosProduct(id: 'service', code: 'J', name: 'Transport', category: 'Jasa', price: 1000,
  stock: 0, tracksStock: false, productType: 'service', servicePriceMode: 'flexible');
const customer = PosCustomer(id: 'customer', name: 'Pelanggan QA', phone: '', priceLevel: 'retail');

Future<_Bloc> open(WidgetTester tester, String type, {String method = 'transfer'}) async {
  tester.view.physicalSize = const Size(800, 1000); tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
  final bloc = _Bloc(type, method); addTearDown(bloc.close);
  await tester.pumpWidget(BlocProvider<PosBloc>.value(value: bloc, child: MaterialApp(locale: const Locale('id'),
    localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
    home: const PosPaymentPage())));
  await tester.pumpAndSettle();
  return bloc;
}
Future<void> saveIntake(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'Transport');
  await tester.tap(find.text('Simpan').last); await tester.pumpAndSettle();
}
void main() {
  test('bundled and legacy remote jasa labels are direct service while retail remains takeaway', () {
    final catalog = PosRemoteProfileCatalog.bundled();
    expect(catalog.fulfillmentOptions('jasa', {'use_appointments': true}).map((e) => e['label']),
      ['Layanan Langsung', 'Reservasi']);
    final remote = PosRemoteProfileCatalog.fromJson(catalog.toJson());
    expect(remote.fulfillmentOptions('jasa', {}).single['label'], 'Layanan Langsung');
    expect(remote.fulfillmentOptions('retail', {}).single['label'], 'Bawa Pulang');
  });
  for (final method in ['transfer', 'tempo']) {
    testWidgets('direct service $method has no schedule prompt and preserves agreed tariff', (tester) async {
      final bloc = await open(tester, 'take_away', method: method);
      await tester.tap(find.text('Proses Bayar')); await tester.pumpAndSettle();
      expect(find.text('Detail layanan'), findsOneWidget);
      expect(find.text('Pilih jadwal layanan'), findsNothing);
      await saveIntake(tester);
      expect(bloc.submitted, hasLength(1));
      expect(bloc.submitted.single.paymentMethod, method);
      expect(bloc.submitted.single.serviceOrder?['appointment_at'], isNull);
      expect(bloc.state.unitPriceFor(service), 175000);
      expect(find.text('Detail reservasi'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('reservation asks schedule once, after intake, and missing start cannot continue', (tester) async {
    final bloc = await open(tester, 'reservation');
    await tester.tap(find.text('Proses Bayar')); await tester.pumpAndSettle();
    expect(find.text('Detail layanan'), findsOneWidget);
    expect(find.text('Pilih jadwal layanan'), findsNothing);
    await saveIntake(tester);
    expect(find.text('Detail reservasi'), findsOneWidget);
    await tester.tap(find.text('Simpan')); await tester.pumpAndSettle();
    expect(find.text('Detail reservasi'), findsOneWidget);
    expect(bloc.submitted, isEmpty);
    await tester.tap(find.text('Batal')); await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  test('saved reservation is reused on payment retry, not asked again', () {
    final code = File('lib/presentation/pages/pos/pos_payment_page.dart').readAsStringSync();
    final reservation = code.split('Future<bool> _ensureReservationDetails(PosState state) async {').last.split('Future<void> _createInvoice(').first;
    expect(reservation, contains('if (_reservationStartAt != null && _reservationEndAt != null) return true;'));
    expect(reservation, contains('await reservationDialogRoute?.completed'));
  });
}
