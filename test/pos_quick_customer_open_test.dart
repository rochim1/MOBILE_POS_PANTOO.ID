import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_quick_customer_dialog.dart';

class _Repository implements PosRepository {
  int configCalls = 0;
  int saves = 0;
  final configs = <Completer<Map<String, dynamic>>>[];
  Map<String, dynamic>? input;
  @override
  Future<Map<String, dynamic>> getRuntimeConfig() {
    configCalls++;
    final request = Completer<Map<String, dynamic>>();
    configs.add(request);
    return request.future;
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> createCustomer(
    Map<String, dynamic> value,
  ) async {
    saves++;
    input = value;
    return Right({'_id': 'customer-test', ...value});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Repository repository;
  setUp(() async {
    await sl.reset();
    repository = _Repository();
    sl.registerSingleton<PosRepository>(repository);
  });
  tearDown(() => sl.reset());

  Future<void> open(
    WidgetTester tester, {
    Map<String, dynamic>? config,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showPosQuickCustomerDialog(context, runtimeConfig: config),
              child: const Text('Open customer'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open customer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
  }

  testWidgets('cashier snapshot opens editable form without another request', (
    tester,
  ) async {
    await open(
      tester,
      config: {
        'price_level_options': ['retail', 'grosir'],
        'default_price_level': 'grosir',
      },
    );
    expect(repository.configCalls, 0);
    expect(find.text('Tambah Pelanggan'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Budi');
    await tester.ensureVisible(find.text('Simpan & Pilih'));
    await tester.tap(find.text('Simpan & Pilih'));
    await tester.pumpAndSettle();
    expect(repository.saves, 1);
    expect(repository.input?['name'], 'Budi');
    expect(repository.input?['price_level'], 'grosir');
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing config immediately shows cancellable loading dialog', (
    tester,
  ) async {
    await open(tester);
    expect(repository.configCalls, 1);
    expect(find.text('Tambah Pelanggan'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    repository.configs.single.complete({
      'price_level_options': ['retail'],
    });
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNothing);
    expect(repository.saves, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet dialog also opens without network and closes cleanly', (
    tester,
  ) async {
    await open(
      tester,
      config: {
        'price_level_options': ['retail'],
      },
      size: const Size(1024, 768),
    );
    expect(repository.configCalls, 0);
    expect(find.byType(TextFormField), findsNWidgets(5));
    await tester.enterText(find.byType(TextFormField).first, 'Tablet customer');
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(repository.saves, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed config can retry and never silently assumes a price level',
    (tester) async {
      await open(tester);
      repository.configs.single.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Coba lagi'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
      await tester.tap(find.text('Coba lagi'));
      await tester.pump();
      expect(repository.configCalls, 2);
      repository.configs.last.complete({
        'price_level_options': ['retail'],
      });
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsWidgets);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
