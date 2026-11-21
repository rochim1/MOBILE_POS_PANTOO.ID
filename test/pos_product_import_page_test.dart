import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_product_import_repository.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_product_import_page.dart';

class _Repo extends Fake implements PosProductImportRepository {
  int previews = 0, writes = 0;
  bool failPreview = false, failWrite = false;
  Map<String, dynamic>? unresolved;
  Completer<void>? gate;
  @override
  Map<String, dynamic>? get pending => unresolved;
  PosProductImportResult result({bool preview = false}) =>
      PosProductImportResult.fromJson({
        'importedCount': 1,
        'failedCount': 1,
        'skippedCount': 0,
        'totalProcessed': 2,
        'stockItemIds': ['stock-id'],
        'errors': [
          {'row': 3, 'field': 'harga', 'message': 'Invalid price'},
        ],
        'warnings': [
          {'row': 2, 'field': 'stok', 'message': 'Isi melalui Stok Awal'},
        ],
        'previewRows': preview
            ? [
                {'row': 2, 'name': 'Produk uji', 'unit': 'pcs', 'price': 5000},
              ]
            : [],
      });
  @override
  Future<PosProductImportResult> upload({
    required Uint8List bytes,
    required String filename,
    required bool preview,
  }) async {
    if (preview) {
      previews++;
      if (failPreview) throw StateError('File salah');
      return result(preview: true);
    }
    writes++;
    unresolved = {'filename': filename};
    if (gate != null) await gate!.future;
    if (failWrite) throw StateError('Koneksi terputus');
    unresolved = null;
    return result();
  }
}

void main() {
  Future<void> open(
    WidgetTester tester,
    _Repo repo, {
    bool allowed = true,
    bool offline = false,
    bool cancel = false,
    ValueChanged<PosProductImportResult?>? done,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final result = await Navigator.of(context)
                    .push<PosProductImportResult>(
                      MaterialPageRoute(
                        builder: (_) => PosProductImportPage(
                          repository: repo,
                          canImport: allowed,
                          offline: offline,
                          pickFile: () async => cancel
                              ? null
                              : PosImportFile(
                                  'products.csv',
                                  Uint8List.fromList([1, 2]),
                                ),
                          saveTemplate: () async {},
                        ),
                      ),
                    );
                done?.call(result);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'pick preview import and finish hand off stock IDs with no overflow',
    (tester) async {
      final repo = _Repo();
      PosProductImportResult? done;
      await open(tester, repo, done: (r) => done = r);
      await tester.tap(find.text('Pilih file Excel / CSV'));
      await tester.pumpAndSettle();
      expect(find.text('Produk uji'), findsOneWidget);
      expect(find.textContaining('Invalid price'), findsOneWidget);
      final import = find.text('Import produk yang valid');
      await tester.ensureVisible(import);
      await tester.tap(import);
      await tester.pumpAndSettle();
      expect(repo.writes, 1);
      expect(find.text('Hasil import'), findsOneWidget);
      final finish = find.text('Selesai & lanjutkan');
      await tester.ensureVisible(finish);
      await tester.tap(finish);
      await tester.pumpAndSettle();
      expect(done?.stockItemIds, ['stock-id']);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'loading blocks repeated submit and back until response returns',
    (tester) async {
      final repo = _Repo()..gate = Completer<void>();
      await open(tester, repo);
      await tester.tap(find.text('Pilih file Excel / CSV'));
      await tester.pumpAndSettle();
      final button = find.text('Import produk yang valid');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(find.text('Memproses file…'), findsOneWidget);
      expect(repo.writes, 1);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Import produk'), findsOneWidget);
      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('Hasil import'), findsOneWidget);
    },
  );
  testWidgets('lost response keeps a usable confirmation button', (
    tester,
  ) async {
    final repo = _Repo()..failWrite = true;
    await open(tester, repo);
    await tester.tap(find.text('Pilih file Excel / CSV'));
    await tester.pumpAndSettle();
    final button = find.text('Import produk yang valid');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.textContaining('Koneksi terputus'), findsOneWidget);
    repo.failWrite = false;
    final retry = find.text('Periksa hasil import');
    await tester.ensureVisible(retry);
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(repo.writes, 2);
    expect(find.text('Hasil import'), findsOneWidget);
  });
  testWidgets('preview failure and cancelled picker allow selecting again', (
    tester,
  ) async {
    final repo = _Repo()..failPreview = true;
    await open(tester, repo);
    await tester.tap(find.text('Pilih file Excel / CSV'));
    await tester.pumpAndSettle();
    expect(find.textContaining('File salah'), findsOneWidget);
    repo.failPreview = false;
    await tester.tap(find.text('products.csv'));
    await tester.pumpAndSettle();
    expect(find.text('Produk uji'), findsOneWidget);
    expect(repo.writes, 0);
  });
  testWidgets('offline and denied permission cannot pick or post', (
    tester,
  ) async {
    for (final offline in [false, true]) {
      final repo = _Repo();
      await open(tester, repo, allowed: offline, offline: offline);
      final pick = find.widgetWithText(
        OutlinedButton,
        'Pilih file Excel / CSV',
      );
      expect(tester.widget<OutlinedButton>(pick).onPressed, isNull);
      expect(repo.writes, 0);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
    }
  });
  testWidgets('system back after success returns confirmed import result', (
    tester,
  ) async {
    final repo = _Repo();
    PosProductImportResult? done;
    await open(tester, repo, done: (r) => done = r);
    await tester.tap(find.text('Pilih file Excel / CSV'));
    await tester.pumpAndSettle();
    final button = find.text('Import produk yang valid');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(done?.importedCount, 1);
  });
}
