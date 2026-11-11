import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:mobile_pos_pantoo/l10n/pos_translation_lookup.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/l10n/app_language_controller.dart';
import 'package:mobile_pos_pantoo/core/receipt/pos_receipt_document_builder.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_receipt_template.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'English receipt translates order type and preserves names and money',
    () async {
      SharedPreferences.setMockInitialValues({});
      final language = AppLanguageController.instance;
      await language.select('en');
      try {
        final text = PosReceiptDocumentBuilder.buildThermalText(
          data: const PosReceiptDocumentData(
            invoice: 'POS-1',
            dateLabel: '10/11/2026',
            paymentMethod: 'cash',
            orderType: 'dine_in',
            subtotal: 24000,
            total: 24000,
            cashierName: 'Simpan',
            customerName: 'Bayar',
            items: [
              {
                'name': 'Periksa',
                'qty': 2,
                'unit_price': 12000,
                'subtotal': 24000,
              },
            ],
          ),
          template: const PosReceiptTemplate(
            showOrderType: true,
            showKasir: true,
            showPelanggan: true,
          ),
          company: const {},
        );
        expect(text, contains('Dine In'));
        expect(text, isNot(contains('Makan di Tempat')));
        expect(text, contains('Simpan'));
        expect(text, contains('Bayar'));
        expect(text, contains('Periksa'));
        expect(text, contains('Rp 24.000'));
      } finally {
        await language.select('id');
      }
    },
  );
  test('every reviewed supplemental label has an English translation', () {
    final copy =
        jsonDecode(File('lib/l10n/supplemental_ui.json').readAsStringSync())
            as Map;
    final en = lookupAppLocalizations(const Locale('en'));
    for (final entry in copy.entries) {
      expect(
        translatePosText(entry.key as String, en),
        entry.value,
        reason: entry.key as String,
      );
    }
  });

  testWidgets('shared headings and actions translate on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          appBar: AppBar(
            title: const PosAppBarTitle(title: 'Pembayaran', subtitle: 'Bayar'),
          ),
          body: PosEmptyState(
            icon: Icons.receipt,
            title: 'Ringkasan',
            message: 'Belum ada transaksi',
            actionLabel: 'Terapkan',
            onAction: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Bayar'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('display status translates without changing the source code', (
    tester,
  ) async {
    const status = 'draft';
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Text(posStatusLabel(status, context)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Draft'), findsOneWidget);
    expect(status, 'draft');
  });
}
