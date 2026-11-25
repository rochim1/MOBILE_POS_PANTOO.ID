import 'package:dartz/dartz.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/customer_display/pos_customer_display_service.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_transaction_result.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_receipt_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_keyboard_navigation_policy.dart';

class _FakePosRepository extends Fake implements PosRepository {
  Map<String, dynamic>? pending;
  Completer<Either<Failure, PosTransactionResult>>? recovery;
  int recoveries = 0;
  @override
  Map<String, dynamic>? get pendingCheckout => pending;
  @override
  Future<Either<Failure, PosTransactionResult>> recoverPendingCheckout() {
    recoveries++;
    return recovery!.future;
  }
}

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
  testWidgets(
    'cashier offers explicit recovery after restart and shows progress without duplicate requests',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _FakePosRepository()
        ..pending = {
          'input': {'client_transaction_id': 'old'},
          'receipt': {'receipt_items': [], 'total': 100},
        }
        ..recovery = Completer();
      final display = _FakeDisplayService();
      final recoveryBusy = <bool>[];
      final bloc = PosBloc(posRepository: repository);
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
          child: MaterialApp(
            home: PosPage(onCheckoutRecoveryBusyChanged: recoveryBusy.add),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('recover_checkout')), findsOneWidget);
      expect(find.text('Katalog Produk'), findsNothing);
      await tester.tap(find.byKey(const Key('recover_checkout')));
      await tester.pump();
      expect(find.text('Memulihkan pembayaran...'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('recover_checkout')))
            .onPressed,
        isNull,
      );
      expect(repository.recoveries, 1);
      expect(recoveryBusy, [true]);
      repository.recovery!.complete(
        const Left(NetworkFailure('QA masih offline')),
      );
      await tester.pumpAndSettle();
      expect(find.text('QA masih offline'), findsOneWidget);
      expect(recoveryBusy, [true, false]);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('recover_checkout')))
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
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

    expect(canOpenPosKeyboardDestination(config, 0), isFalse);
    expect(canOpenPosKeyboardDestination(config, 1), isTrue);
    expect(canOpenPosKeyboardDestination(config, 2), isFalse);
    expect(canOpenPosKeyboardDestination(config, 5), isTrue);
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
