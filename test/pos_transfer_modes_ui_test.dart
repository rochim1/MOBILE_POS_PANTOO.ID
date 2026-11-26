import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_transfer_editor_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_transfer_location_fields.dart';
import 'pos_transfer_editor_test.dart' show TransferFake;

class ModeFake extends TransferFake {
  @override
  Future<List<Map<String, dynamic>>> warehouses() async => [
    {
      '_id': 'from',
      'nama_cabang': 'Gudang A',
      'warehouse_type': 'store',
      'linked_toko_id': 'A',
      'gedung': [
        {'kode_gedung': 'G1', 'nama_gedung': 'Gudang utama'},
      ],
    },
    {
      '_id': 'to',
      'nama_cabang': 'Gudang B',
      'warehouse_type': 'store',
      'linked_toko_id': 'B',
    },
    {
      '_id': 'display',
      'nama_cabang': 'Rak A',
      'warehouse_type': 'display',
      'linked_toko_id': 'A',
    },
  ];
}

void main() {
  testWidgets(
    'two modes filter destination and confirm before clearing existing items',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PosTransferEditorPage(
            existing: const {'_id': 'doc'},
            repository: ModeFake(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Antar toko / gudang'), findsOneWidget);
      expect(find.text('Mutasi internal'), findsOneWidget);
      await tester.tap(find.text('Mutasi internal'));
      await tester.pumpAndSettle();
      expect(find.text('Ganti jenis perpindahan?'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(PosTransferLocationFields).last,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<PosTransferLocationFields>(
              find.byType(PosTransferLocationFields).last,
            )
            .warehouses
            .map((w) => w['_id']),
        ['to'],
      );
      await tester.scrollUntilVisible(
        find.text('Mutasi internal'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mutasi internal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ganti jenis'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Lokasi perpindahan'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final source = tester.widget<PosTransferLocationFields>(
        find.byType(PosTransferLocationFields).first,
      );
      expect(source.value['cabang_id'], 'from');
      final target = tester.widget<PosTransferLocationFields>(
        find.byType(PosTransferLocationFields).last,
      );
      expect(target.value['cabang_id'], isNull);
      expect(target.warehouses.map((w) => w['_id']), ['from', 'display']);
      await tester.scrollUntilVisible(
        find.text('Tambah barang'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Barang transfer QA'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'replenishment opens internal automatically on phone without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: PosTransferEditorPage(
            initialSourceId: 'from',
            initialDestinationId: 'display',
            displayReplenishment: true,
            repository: ModeFake(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Pindah rak'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('profile mismatch is retained for review but cannot be saved', (
    tester,
  ) async {
    final repo = ModeFake();
    await tester.pumpWidget(
      MaterialApp(
        home: PosTransferEditorPage(
          existing: const {'_id': 'doc'},
          repository: repo,
          inventoryPolicy: const {'inventory_profile': 'advanced'},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('Pasangan lokasi tidak tersedia'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.textContaining('Pasangan lokasi tidak tersedia'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Simpan mutasi'),
      300,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 40,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Simpan mutasi'),
          )
          .onPressed,
      isNull,
    );
    expect(repo.requests, isEmpty);
  });
  testWidgets(
    'English phone labels and empty profile guidance remain readable',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PosTransferEditorPage(
            repository: ModeFake(),
            inventoryPolicy: const {'inventory_profile': 'simple'},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Between stores / warehouses'), findsOneWidget);
      expect(find.text('Internal movement'), findsOneWidget);
      expect(find.textContaining('No compatible locations'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
