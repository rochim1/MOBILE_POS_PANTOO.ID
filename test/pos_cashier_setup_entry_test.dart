import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_cashier_entry_button.dart';

class _Repository extends Fake implements PosRepository {}

void main() {
  testWidgets(
    'setup shortcut receives descendant POS context and blocks double submit',
    (tester) async {
      final bloc = PosBloc(posRepository: _Repository());
      addTearDown(bloc.close);
      final pending = Completer<void>();
      var attempts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: Scaffold(
              floatingActionButton: PosCashierEntryButton(
                showSetupGuide: true,
                onContinueSetup: (context) {
                  expect(context.read<PosBloc>(), same(bloc));
                  attempts++;
                  return pending.future;
                },
                onOpenCashier: () => fail('Must not bypass readiness'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Buka kasir'));
      await tester.pump();
      expect(attempts, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester
            .widget<FloatingActionButton>(find.byType(FloatingActionButton))
            .onPressed,
        isNull,
      );
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('ready workspace opens cashier directly', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: PosCashierEntryButton(
            showSetupGuide: false,
            onContinueSetup: (_) async => fail('No setup needed'),
            onOpenCashier: () => opened = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Buka kasir'));
    expect(opened, isTrue);
  });
  testWidgets('failed readiness check shows recovery and releases loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          floatingActionButton: PosCashierEntryButton(
            showSetupGuide: true,
            onContinueSetup: (_) async => throw StateError('QA failure'),
            onOpenCashier: () => fail('No bypass'),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Buka kasir'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Kasir belum dapat dibuka'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
