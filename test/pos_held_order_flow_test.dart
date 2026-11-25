import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_held_order_flow.dart';
import 'pos_held_order_safety_test.dart'
    show HeldRepo, HeldBloc, held, product, customer;

void main() {
  for (final language in ['id', 'en']) {
    for (final approve in [false, true]) {
      testWidgets(
        'restoring from occupied cart keeps both orders $language approve=$approve',
        (tester) async {
          final repo = HeldRepo()..pending = Completer<void>();
          final draft = held();
          final bloc = HeldBloc(repo, drafts: [draft]);
          addTearDown(bloc.close);
          bool? result;
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Builder(
                builder: (context) => Scaffold(
                  body: FilledButton(
                    onPressed: () async =>
                        result = await restorePosHeldCart(context, bloc, draft),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          expect(repo.saved, isNull);
          expect(repo.deletes, 0);
          if (!approve) {
            await tester.tap(find.text(language == 'en' ? 'Cancel' : 'Batal'));
            await tester.pumpAndSettle();
            expect(result, isFalse);
            expect(bloc.state.cart[product], 1);
            expect(bloc.state.heldOrders, [draft]);
            return;
          }
          await tester.tap(
            find.text(language == 'en' ? 'Save and open' : 'Simpan dan buka'),
          );
          await tester.pump(const Duration(milliseconds: 250));
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(repo.saved?.customer?.id, customer.id);
          expect(
            repo.deletes,
            0,
            reason:
                'Do not consume the saved order before current cart is durable',
          );
          expect(bloc.state.cart[product], 1);
          repo.pending!.complete();
          await tester.pumpAndSettle();
          expect(result, isTrue);
          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(bloc.state.cart[product], 2);
          expect(bloc.state.selectedCustomer, isNull);
          expect(bloc.state.heldOrders.single.customer?.id, customer.id);
          expect(repo.deletes, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  for (final failSave in [true, false]) {
    testWidgets(
      'local ${failSave ? 'save' : 'restore'} failure dismisses progress and keeps recoverable data',
      (tester) async {
        final repo = HeldRepo()
          ..rejectSave = failSave
          ..rejectDelete = !failSave;
        final draft = held();
        final bloc = HeldBloc(repo, cart: failSave, drafts: [draft]);
        addTearDown(bloc.close);
        bool? result;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: FilledButton(
                  onPressed: () async =>
                      result = await restorePosHeldCart(context, bloc, draft),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        if (failSave) {
          await tester.tap(find.text('Simpan dan buka'));
          await tester.pumpAndSettle();
        }
        expect(result, isFalse);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(bloc.state.heldOrders, [draft]);
        expect(bloc.state.cart.isNotEmpty, failSave);
        expect(bloc.errors, isEmpty);
        expect(tester.takeException(), isNull);
      // Let the real recoverable-error toast finish its four-second lifetime.
      await tester.pump(const Duration(seconds: 5));
      },
    );
  }
}
