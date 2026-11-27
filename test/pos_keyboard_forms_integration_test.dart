import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_transfer_editor_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_inventory_editor_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_quick_customer_dialog.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_service_intake_fields.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_table_qr_print_settings_dialog.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_table_qr_print_settings.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_keyboard_stable_sheet.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_keyboard_visibility.dart';
import 'pos_keyboard_visibility_test.dart' show settleKeyboard;
import 'pos_service_intake_fields_test.dart' show work;
import 'pos_transfer_editor_test.dart' show TransferFake;
import 'pos_opname_parity_test.dart' show QaOpnameRepository;

class _NoWrites extends Fake implements PosRepository {}

void main() {
  setUp(() => sl.pushNewScope());
  tearDown(() => sl.popScope());

  Future<void> open(WidgetTester tester, Widget page, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.view.resetViewInsets();
    });
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        scrollBehavior: const PosKeyboardScrollBehavior(),
        builder: (context, child) => PosKeyboardVisibility(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(size.width == 320 ? 1.4 : 1),
            ),
            child: child!,
          ),
        ),
        home: page,
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(844, 480),
  ]) {
    for (final form in ['customer', 'service', 'qr']) {
      testWidgets(
        'real $form modal reveals its field and stays stable at $size',
        (tester) async {
          sl.registerSingleton<PosRepository>(_NoWrites());
          await open(
            tester,
            Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () {
                    switch (form) {
                      case 'customer':
                        showPosQuickCustomerDialog(
                          context,
                          runtimeConfig: const {
                            'price_level_options': ['retail'],
                          },
                        );
                      case 'service':
                        showPosServiceIntakeDialog(
                          context,
                          cart: {work: 1},
                          profile: 'jasa',
                          features: const {
                            'use_vehicle_data': true,
                            'use_technicians': true,
                          },
                        );
                      case 'qr':
                        showDialog<void>(
                          context: context,
                          builder: (_) => const PosTableQrPrintSettingsDialog(
                            initial: PosTableQrPrintSettings(),
                          ),
                        );
                    }
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
            size,
          );
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
          final outer = find.byType(Dialog).evaluate().isNotEmpty
              ? find.byType(Dialog)
              : find.byType(PosKeyboardStableSheet);
          final before = tester.getRect(outer);
          final target = form == 'customer'
              ? find.byType(TextFormField).at(4)
              : find.byType(TextField).last;
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          await tester.tap(target);
          await settleKeyboard(tester, size.height < 500 ? 180 : 320);
          expect(tester.getRect(outer), before);
          final visibleBottom = size.height - (size.height < 500 ? 180 : 320);
          if (form == 'qr' && size.width == 320) {
            // Its two-line field plus label/counter is taller than the tiny
            // viewport under the scaled dialog title. Keep the caret visible.
            final editable = tester.state<EditableTextState>(
              find.descendant(of: target, matching: find.byType(EditableText)),
            );
            final render = editable.renderEditable;
            final caret = render.localToGlobal(
              render
                  .getLocalRectForCaret(
                    editable.textEditingValue.selection.extent,
                  )
                  .bottomLeft,
            );
            expect(caret.dy, lessThanOrEqualTo(visibleBottom));
          } else {
            expect(
              tester.getRect(target).bottom,
              lessThanOrEqualTo(visibleBottom + 1),
            );
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        },
      );
    }
  }

  testWidgets(
    'real multi-rack opname quantity is reachable without saving or changing the other rack',
    (tester) async {
      final repo = QaOpnameRepository();
      sl.registerSingleton<PosInventoryRepository>(repo);
      await open(
        tester,
        const PosInventoryEditorPage(
          type: PosInventoryDocumentType.opname,
          existing: {'_id': 'doc'},
        ),
        const Size(390, 844),
      );
      final quantity = find.widgetWithText(TextFormField, 'Jumlah fisik').last;
      await tester.ensureVisible(quantity);
      await tester.pumpAndSettle();
      expect(quantity.hitTestable(), findsOneWidget);
      await tester.tap(quantity);
      await settleKeyboard(tester, 320);
      expect(tester.getRect(quantity).bottom, lessThanOrEqualTo(524));
      await tester.enterText(quantity, '0');
      expect(repo.calls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'real transfer item note remains visible and is not submitted by scrolling',
    (tester) async {
      final repo = TransferFake();
      await open(
        tester,
        PosTransferEditorPage(existing: const {'_id': 'doc'}, repository: repo),
        const Size(390, 844),
      );
      final note = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Catatan barang',
      );
      await tester.scrollUntilVisible(
        note,
        400,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 35,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(note);
      await tester.pumpAndSettle();
      expect(note.hitTestable(), findsOneWidget);
      await tester.tap(note);
      expect(FocusManager.instance.primaryFocus?.hasFocus, true);
      await settleKeyboard(tester, 320);
      expect(tester.getRect(note).bottom, lessThanOrEqualTo(524));
      await tester.enterText(note, 'Catatan QA tetap utuh');
      expect(find.text('Catatan QA tetap utuh'), findsOneWidget);
      expect(repo.requests, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
