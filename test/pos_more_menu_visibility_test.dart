import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_more_menu_page.dart';

class _FakePosRepository extends Fake implements PosRepository {}

class _ConfiguredPosBloc extends PosBloc {
  _ConfiguredPosBloc(Map<String, dynamic> config)
    : super(posRepository: _FakePosRepository()) {
    emit(state.copyWith(runtimeConfig: config));
  }
}

void main() {
  test('menu tambahan hanya memuat tujuan di luar navbar bawah', () {
    final sections = PosMoreMenuPage.visibleSections({
      'features': {'use_tables': true, 'use_kitchen_flow': true},
      'permissions': {
        'view_tables': true,
        'view_shifts': true,
        'view_stock': true,
        'view_promos': true,
        'view_customers': true,
        'view_stores': true,
        'view_returns': true,
        'view_purchase_returns': true,
        'view_reports': true,
        'view_settings': true,
        'view_receipt': true,
      },
    });

    expect(sections['Operasional'], [5, 18, 11, 15]);
    expect(sections['Kelola Bisnis'], [7, 8, 9, 10, 13, 16]);
    expect(sections['Laporan'], [12]);
    expect(sections['Pengaturan'], [17, 14]);
    expect(
      sections.values.expand((items) => items),
      isNot(contains(anyOf(0, 1, 2, 3, 4))),
    );
  });

  test('fitur meja dan dapur mengikuti profil serta izin akun', () {
    final noTables = PosMoreMenuPage.visibleSections({
      'features': {'use_tables': false, 'use_kitchen_flow': true},
      'permissions': {'view_tables': true},
    });
    expect(noTables['Operasional'], [5, 18, 15]);

    final manageOnly = PosMoreMenuPage.visibleSections({
      'features': {'use_tables': true, 'use_kitchen_flow': true},
      'permissions': {'manage_tables': true},
    });
    expect(manageOnly['Operasional'], [5, 15]);

    final noPermission = PosMoreMenuPage.visibleSections({});
    expect(noPermission['Operasional'], [15]);
    expect(noPermission['Kelola Bisnis'], isEmpty);
    expect(noPermission['Laporan'], isEmpty);
    expect(noPermission['Pengaturan'], isEmpty);
  });

  test('inventori terlihat untuk izin pembelian meski stok tidak dilacak', () {
    final sections = PosMoreMenuPage.visibleSections({
      'features': {'track_stock': false},
      'permissions': {'view_stock': true, 'view_inventory_purchases': true},
    });
    expect(sections['Kelola Bisnis'], [7]);
  });

  testWidgets('profil tanpa meja menamai menu hanya Pesanan Aktif', (
    tester,
  ) async {
    final bloc = _ConfiguredPosBloc({
      'features': {'use_tables': false},
      'permissions': {'view_tables': true},
    });
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider<PosBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: PosMoreMenuPage(onNavigate: (_) {}, onLogout: () {}),
        ),
      ),
    );
    expect(find.text('Pesanan Aktif'), findsOneWidget);
    expect(find.text('Pesanan Aktif & Meja'), findsNothing);
  });

  for (final width in <double>[320, 360]) {
    testWidgets('Lainnya tetap bisa diakses pada lebar ${width.toInt()} dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final bloc = PosBloc(posRepository: _FakePosRepository());
      addTearDown(bloc.close);
      int? destination;
      var logoutPressed = false;
      await tester.pumpWidget(
        BlocProvider<PosBloc>.value(
          value: bloc,
          child: MaterialApp(
            home: PosMoreMenuPage(
              onNavigate: (index) => destination = index,
              onLogout: () => logoutPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Antrean Transaksi Offline'));
      expect(destination, 15);
      await tester.ensureVisible(find.text('Keluar'));
      await tester.tap(find.text('Keluar'));
      expect(logoutPressed, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('tujuan yang dipindahkan dari drawer dapat dibuka dari Lainnya', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = _ConfiguredPosBloc({
      'features': {'use_tables': true, 'use_kitchen_flow': true},
      'permissions': {
        'view_tables': true,
        'view_promos': true,
        'view_reports': true,
        'view_settings': true,
      },
    });
    addTearDown(bloc.close);
    int? destination;
    await tester.pumpWidget(
      BlocProvider<PosBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: PosMoreMenuPage(
            onNavigate: (index) => destination = index,
            onLogout: () {},
          ),
        ),
      ),
    );

    for (final (label, index) in <(String, int)>[
      ('Pesanan Aktif & Meja', 5),
      ('Tampilan Dapur', 18),
      ('Promo & Voucher', 8),
      ('Laporan Penjualan', 12),
      ('Pengaturan POS', 17),
    ]) {
      await tester.scrollUntilVisible(find.text(label), 100);
      await tester.tap(find.text(label));
      expect(destination, index);
    }
    expect(tester.takeException(), isNull);
  });
}
