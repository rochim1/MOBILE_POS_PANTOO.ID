import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_order.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_order_page.dart';

class _Repo extends Fake implements PosRepository {}

class _Bloc extends PosBloc {
  _Bloc() : super(posRepository: _Repo()) {
    final today = DateTime.now().toIso8601String();
    emit(PosState(status: PosStatus.success, orders: [
      PosOrder(id: 'a', invoice: 'INV-A', date: today, customer: 'QA A', cashierName: 'QA A', paymentMethod: 'tunai', total: 100, status: 'Selesai'),
      PosOrder(id: 'b', invoice: 'INV-B', date: today, customer: 'QA B', cashierName: 'QA B', paymentMethod: 'tunai', total: 200, status: 'Batal'),
    ]));
  }
  final events = <PosEvent>[];
  @override
  void add(PosEvent event) => events.add(event);
}

const _toggle = Key('transaction_filter_toggle');

void main() {
  Future<_Bloc> open(WidgetTester tester, {Size size = const Size(390, 844), String language = 'id', double textScale = 1}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final bloc = _Bloc();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.runAsync(bloc.close);
    });
    await tester.pumpWidget(BlocProvider<PosBloc>.value(value: bloc, child: MaterialApp(
      locale: Locale(language), localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)), child: child!),
      home: const Scaffold(body: PosOrderPage()),
    )));
    await tester.pumpAndSettle();
    return bloc;
  }

  for (final language in ['id', 'en']) {
    for (final size in [const Size(360, 568), const Size(390, 844), const Size(760, 800), const Size(1280, 900)]) {
      testWidgets('responsive transaction filters $language $size', (tester) async {
        await open(tester, size: size, language: language);
        if (size.width < 760) {
          expect(find.byKey(_toggle), findsOneWidget);
          expect(find.byType(TextField), findsNothing);
          expect(tester.getTopLeft(find.text('INV-A')).dy, lessThan(230));
        } else {
          expect(find.byKey(_toggle), findsNothing);
          expect(find.byType(TextField), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('search remains applied and visible after collapse and reopen without refetch', (tester) async {
    final bloc = await open(tester);
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'INV-B');
    await tester.pumpAndSettle();
    expect(find.text('INV-A'), findsNothing);
    expect(find.text('INV-B'), findsOneWidget);
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('INV-B'), findsOneWidget);
    expect(find.descendant(of: find.byKey(_toggle), matching: find.text('1')), findsOneWidget);
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, 'INV-B');
    expect(bloc.events.whereType<RefreshOrders>(), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('status cashier and period remain applied when collapsed', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    for (final choice in [('Semua Status', 'Batal'), ('Semua Kasir', 'QA B'), ('Semua Waktu', 'Hari Ini')]) {
      final dropdown = find.widgetWithText(DropdownButtonFormField<String>, choice.$1);
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text(choice.$2).last);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.byKey(_toggle));
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    expect(find.text('INV-A'), findsNothing);
    expect(find.text('INV-B'), findsOneWidget);
    expect(find.descendant(of: find.byKey(_toggle), matching: find.text('3')), findsOneWidget);
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    final values = tester.widgetList<DropdownButtonFormField<String>>(find.byType(DropdownButtonFormField<String>)).map((widget) => widget.initialValue);
    expect(values, containsAll(['Batal', 'QA B', 'Hari Ini']));
    expect(tester.takeException(), isNull);
  });

  testWidgets('short phone with large text can open and scroll filters without overflow', (tester) async {
    await open(tester, size: const Size(360, 420), textScale: 1.4);
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(DropdownButtonFormField<String>, 'Semua Kasir'));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resize preserves search and keeps desktop filters visible', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'INV-B');
    await tester.tap(find.byKey(_toggle));
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpAndSettle();
    expect(find.byKey(_toggle), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, 'INV-B');
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byKey(_toggle), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('INV-B'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
