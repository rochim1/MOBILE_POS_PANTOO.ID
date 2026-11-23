import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_cart_panel.dart';

class _Repository extends Fake implements PosRepository {}

class _Cart extends PosBloc {
  _Cart() : super(posRepository: _Repository()) {
    emit(PosState(cart: {product: 1}));
  }

  final events = <PosEvent>[];
  @override
  void add(PosEvent event) => events.add(event);
}

const product = PosProduct(
  id: 'melon',
  code: 'MRC-0002',
  name: 'pop ice melon',
  category: 'Minuman',
  price: 5000,
  stock: 100,
  unitConversions: [
    {'unit': 'unit', 'factor': 1.0},
    {'unit': 'box', 'factor': 12.0},
  ],
);

Future<_Cart> _pumpCart(WidgetTester tester, double width, double scale) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final bloc = _Cart();
  addTearDown(bloc.close);
  await tester.pumpWidget(
    BlocProvider<PosBloc>.value(
      value: bloc,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const RepaintBoundary(
          key: ValueKey('cart-control-preview'),
          child: Scaffold(body: PosCartPanel()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return bloc;
}

void main() {
  setUpAll(() async {
    await (FontLoader(
      'Roboto',
    )..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final (width, scale) in [
    (320.0, 1.0),
    (360.0, 1.0),
    (600.0, 1.0),
    (320.0, 1.5),
  ]) {
    testWidgets('cart controls align at $width dp with text scale $scale', (
      tester,
    ) async {
      await _pumpCart(tester, width, scale);
      final unit = find.byWidgetPredicate(
        (widget) =>
            widget is InputDecorator && widget.decoration.labelText == 'Satuan',
      );
      // Both the previous outlined container and the labelled replacement
      // represent the quantity control, so RED measures the actual mismatch.
      final quantity = find
          .ancestor(
            of: find.byIcon(Icons.remove),
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is InputDecorator ||
                  (widget is Container &&
                      widget.decoration is BoxDecoration &&
                      (widget.decoration! as BoxDecoration).border != null),
            ),
          )
          .first;
      final unitRect = tester.getRect(unit);
      final quantityRect = tester.getRect(quantity);
      expect(quantityRect.height, closeTo(unitRect.height, 0.1));
      expect(quantityRect.top, closeTo(unitRect.top, 0.1));
      expect(quantityRect.bottom, closeTo(unitRect.bottom, 0.1));

      const preview = String.fromEnvironment('CART_BORDER_PREVIEW');
      if (width == 360 && scale == 1 && ['before', 'after'].contains(preview)) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('cart-control-preview')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('output/cart-visible-border-$preview.png').writeAsBytes(
            bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
          image.dispose();
        });
      }

      // InputDecorator's outer 48 dp can hide an intrinsically shorter border.
      // Check the actual painted container, not only its SizedBox allocation.
      final unitBorder = InputDecorator.containerOf(
        tester.element(find.byType(DropdownButton<String>)),
      )!;
      final quantityBorder = InputDecorator.containerOf(
        tester.element(find.byIcon(Icons.remove)),
      )!;
      final unitBorderRect =
          unitBorder.localToGlobal(Offset.zero) & unitBorder.size;
      final quantityBorderRect =
          quantityBorder.localToGlobal(Offset.zero) & quantityBorder.size;
      expect(quantityBorderRect.height, closeTo(unitBorderRect.height, 0.1));
      expect(quantityBorderRect.top, closeTo(unitBorderRect.top, 0.1));
      expect(quantityBorderRect.bottom, closeTo(unitBorderRect.bottom, 0.1));
      for (final control in [
        find.text('1'),
        find.byIcon(Icons.remove),
        find.byIcon(Icons.add),
      ]) {
        final contentRect = tester.getRect(control.first);
        expect(
          contentRect.height,
          greaterThanOrEqualTo(14),
          reason: 'Quantity content must have visible height: $contentRect',
        );
        expect(
          quantityBorderRect.contains(contentRect.center),
          true,
          reason:
              'Quantity content $contentRect must remain visible inside $quantityBorderRect',
        );
      }
      expect(find.text('Jumlah'), findsOneWidget);
      final unitText = tester.widget<Text>(find.text('unit').first);
      final quantityText = tester.widget<Text>(find.text('1').first);
      final dropdown = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(
        unitText.style?.fontSize ?? dropdown.style?.fontSize,
        quantityText.style?.fontSize,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('aligned controls preserve quantity and unit selection actions', (
    tester,
  ) async {
    final bloc = await _pumpCart(tester, 320, 1);
    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.remove));
    expect(bloc.events.whereType<UpdateQuantity>().length, 2);
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('box').last);
    await tester.pumpAndSettle();
    expect(bloc.events.whereType<UpdateCartUnit>().length, 1);
    expect(tester.takeException(), isNull);
  });
}
