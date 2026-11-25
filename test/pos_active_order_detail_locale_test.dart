import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order_detail.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_order_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/app_language_controller.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_order_management/pos_order_management_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_table_order_page.dart';

class _Repo extends Fake implements PosRepository {}
class _Storage extends Fake implements FlutterSecureStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #read) return Future<String?>.value(null);
    return super.noSuchMethod(invocation);
  }
}
class _Orders extends Fake implements PosOrderRepository {
  _Orders(this.order);
  final PosOrderDetail order;
  @override
  Future<(int, int)?> getSlaThresholds() async => (15, 25);
  @override
  Future<Either<Failure, PosActiveOrderPage>> getActiveOrders({required String storeId, String search = '', String status = '', String fulfillment = '', String dateFrom = '', String dateTo = '', String sort = 'oldest', int page = 0}) async => Right(PosActiveOrderPage([order], 1, const {'Baru': 1}));
}
class _Bloc extends PosBloc {
  _Bloc() : super(posRepository: _Repo()) {
    emit(const PosState(status: PosStatus.success,
      stores: [PosStore(id: 'store', name: 'QA', status: 'active', branchId: 'branch')],
      activeShift: {'_id': 'shift', 'toko_id': 'store'},
      runtimeConfig: {'business_profile': 'jasa', 'features': {'use_service_order': true}, 'permissions': {'view_tables': true}},
    ));
  }
  @override
  void add(PosEvent event) {}
}

void main() {
  for (final locale in [const Locale('en'), const Locale('id')]) {
    testWidgets('order detail translates fallback, elapsed time and service status ${locale.languageCode}', (tester) async {
      tester.view.physicalSize = const Size(430, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final previous = AppLanguageController.instance.value;
      AppLanguageController.instance.value = locale;
      final orders = _Orders(PosOrderDetail(
        id: 'order', orderNumber: 'QA-DETAIL', customerName: 'QA customer',
        orderType: 'take_away', status: 'Baru', totalAmount: 5000,
        createdAt: DateTime.now().subtract(const Duration(minutes: 1, seconds: 5)).toIso8601String(),
        items: const [PosOrderItem(productId: 'service', productName: 'QA Service', quantity: 1, price: 5000)],
        serviceOrder: const {'service_type': 'jasa', 'service_mode': 'direct', 'service_lines': [
          {'line_id': 'line', 'name': 'QA Service', 'quantity': 1, 'unit': 'trip', 'subtotal': 5000, 'status': 'diterima'},
        ]},
      ));
      sl.registerSingleton<PosOrderRepository>(orders);
      sl.registerSingleton<FlutterSecureStorage>(_Storage());
      sl.registerFactory<PosOrderManagementBloc>(() => PosOrderManagementBloc(repository: orders));
      final bloc = _Bloc();
      try {
        await tester.pumpWidget(BlocProvider<PosBloc>.value(value: bloc, child: MaterialApp(
          locale: locale, localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales, home: const Scaffold(body: PosTableOrderPage()),
        )));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('QA-DETAIL').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text(locale.languageCode == 'en' ? 'QA customer · No table' : 'QA customer · Tanpa meja'), findsOneWidget);
        expect(find.textContaining(RegExp(locale.languageCode == 'en' ? r'Ordered .* · \d+ minutes' : r'Dipesan .* · \d+ menit')), findsOneWidget);
        expect(find.textContaining(locale.languageCode == 'en' ? 'Status: Accepted · Rp 5.000' : 'Status: Diterima · Rp 5.000'), findsOneWidget);
        expect(find.text('QA Service'), findsWidgets);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        await tester.runAsync(bloc.close);
        await sl.reset();
        AppLanguageController.instance.value = previous;
      }
    });
  }
}
