import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/customer_display/pos_customer_display_service.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_receipt_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_keyboard_navigation_policy.dart';

class _FakePosRepository extends Fake implements PosRepository {}

class _FakeReceiptRepository extends Fake implements PosReceiptRepository {
  @override
  Future<Either<Failure, PosReceiptPrintData>>
  preloadReceiptPrintData() async =>
      const Left(ServerFailure('Tidak tersedia dalam tes'));
}

class _FakeDisplayService extends Fake implements PosCustomerDisplayService {
  @override
  final ValueNotifier<PosCustomerDisplayState> state = ValueNotifier(
    const PosCustomerDisplayState(),
  );
}

void main() {
  test('shortcut navigasi mengikuti izin dan fitur profil POS', () {
    final config = <String, dynamic>{
      'permissions': <String, dynamic>{
        'view_dashboard': true,
        'use_cashier': true,
        'view_products': false,
        'view_tables': true,
        'view_transactions': true,
        'view_inventory_purchases': true,
      },
      'features': <String, dynamic>{'use_tables': false, 'track_stock': false},
    };

    expect(canOpenPosKeyboardDestination(config, 0), isTrue);
    expect(canOpenPosKeyboardDestination(config, 1), isTrue);
    expect(canOpenPosKeyboardDestination(config, 2), isFalse);
    expect(canOpenPosKeyboardDestination(config, 5), isFalse);
    expect(canOpenPosKeyboardDestination(config, 7), isTrue);
    expect(canOpenPosKeyboardDestination(config, 3), isTrue);
    expect(canOpenPosKeyboardDestination(config, 14), isFalse);
  });

  testWidgets('F6 membuka keranjang dan F2 kembali fokus ke pencarian', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final display = _FakeDisplayService();
    final bloc = PosBloc(posRepository: _FakePosRepository());
    sl.registerSingleton<PosCustomerDisplayService>(display);
    sl.registerSingleton<PosReceiptRepository>(_FakeReceiptRepository());
    addTearDown(() async {
      await bloc.close();
      display.state.dispose();
      await sl.reset();
    });

    await tester.pumpWidget(
      BlocProvider<PosBloc>.value(
        value: bloc,
        child: const MaterialApp(home: PosPage()),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.f6);
    await tester.pumpAndSettle();
    expect(
      find.text('Silakan masukkan pesanan dari pelanggan'),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pumpAndSettle();
    final search = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Cari nama, kode, SKU, atau barcode...'),
    );
    expect(search.focusNode?.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
}
