import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_payment_connection_badge.dart';

void main() {
  testWidgets(
    'unknown -> offline -> available -> offline, and a late initial read cannot overwrite a change',
    (tester) async {
      final changes = StreamController<List<ConnectivityResult>>(sync: true);
      final initial = Completer<List<ConnectivityResult>>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosPaymentConnectionBadge(
              changes: changes.stream,
              readConnectivity: () => initial.future,
            ),
          ),
        ),
      );
      expect(find.text('Memeriksa…'), findsOneWidget);
      expect(find.text('Online'), findsNothing);
      changes.add([ConnectivityResult.none]);
      await tester.pump();
      expect(find.text('Offline'), findsOneWidget);
      initial.complete([ConnectivityResult.wifi]);
      await tester.pump();
      expect(find.text('Offline'), findsOneWidget);
      changes.add([ConnectivityResult.wifi]);
      await tester.pump();
      expect(find.text('Terhubung'), findsOneWidget);
      expect(
        find.byTooltip(
          'Jaringan perangkat tersedia. Server diperiksa saat transaksi.',
        ),
        findsOneWidget,
      );
      changes.add([ConnectivityResult.none]);
      await tester.pump();
      expect(find.text('Offline'), findsOneWidget);
      changes.addError(StateError('plugin'));
      await tester.pump();
      expect(find.text('Memeriksa…'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      unawaited(changes.close());
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'initial offline result and failed initial read never report online',
    (tester) async {
      final changes = StreamController<List<ConnectivityResult>>(sync: true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosPaymentConnectionBadge(
              changes: changes.stream,
              readConnectivity: () async => [ConnectivityResult.none],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Offline'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      unawaited(changes.close());
      final failed = StreamController<List<ConnectivityResult>>(sync: true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosPaymentConnectionBadge(
              changes: failed.stream,
              readConnectivity: () async => throw StateError('initial'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Memeriksa…'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      unawaited(failed.close());
      expect(tester.takeException(), isNull);
    },
  );
}
