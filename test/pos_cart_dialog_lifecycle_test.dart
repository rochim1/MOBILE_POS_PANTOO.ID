import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_cart_panel.dart';

class _Repo extends Fake implements PosRepository {}
class _Cart extends PosBloc {
  _Cart(PosProduct product) : super(posRepository: _Repo()) {
    emit(PosState(cart: {product: 1}, runtimeConfig: const {'allow_cashier_price_edit': true}));
  }
  final events = <PosEvent>[];
  @override
  void add(PosEvent event) => events.add(event);
}

void main() {
  const laundry = PosProduct(id: 'laundry', code: 'KG', name: 'Laundry QA',
    category: 'Jasa', price: 3000, stock: 0, productType: 'service',
    tracksStock: false, baseUnit: 'kg');
  for (final cancel in [false, true]) {
    testWidgets('quantity dialog survives keyboard metrics during ${cancel ? 'cancel' : 'apply'} exit', (tester) async {
      final bloc = _Cart(laundry);
      addTearDown(bloc.close);
      await tester.pumpWidget(BlocProvider<PosBloc>.value(value: bloc,
        child: MaterialApp(locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: PosCartPanel()))));
      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '3.5');
      await tester.tap(find.text(cancel ? 'Cancel' : 'Apply'));
      await tester.pump();
      // Native IME hiding can rebuild the still-mounted exiting dialog.
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(bloc.events.whereType<UpdateQuantity>().length, cancel ? 0 : 1);
    });
  }
}
