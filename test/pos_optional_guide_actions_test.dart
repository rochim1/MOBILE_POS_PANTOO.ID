import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_setup_guide_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_onboarding_page.dart';

class _Repo extends Fake implements PosRepository {}
class _Inventory extends Fake implements PosInventoryRepository {
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getWarehouses({String search = ''}) async => const Right([]);
}
class _Bloc extends PosBloc {
  _Bloc(bool canSell) : super(posRepository: _Repo()) {
    emit(state.copyWith(runtimeConfig: {'permissions': {'use_cashier': canSell}}));
  }
}
void main() {
  tearDown(() async => sl.reset());
  for (final canSell in [true, false]) {
    testWidgets('incomplete guide can close; cashier action respects permission $canSell', (tester) async {
      SharedPreferences.setMockInitialValues({'instansi_id': 'a', 'user_id': 'u'});
      final prefs = await SharedPreferences.getInstance();
      sl.registerSingleton<SharedPreferences>(prefs);
      sl.registerSingleton<PosInventoryRepository>(_Inventory());
      final bloc = _Bloc(canSell), lock = AppLockCubit();
      addTearDown(bloc.close); addTearDown(lock.close);
      var closed = 0, opened = 0;
      await tester.pumpWidget(MaterialApp(home: MultiBlocProvider(providers: [
        BlocProvider<PosBloc>.value(value: bloc), BlocProvider<AppLockCubit>.value(value: lock),
      ], child: Scaffold(body: PosSetupGuidePage(
        onNavigate: (_, _) {}, onStartCashier: () => fail('No automatic tour or completion'),
        onStartWalkthrough: (_, _, _, _, _) async {},
        onClose: () => closed++, onOpenCashier: () => opened++,
      )))));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tutup panduan')); expect(closed, 1);
      if (canSell) {
        await tester.ensureVisible(find.widgetWithText(FilledButton, 'Buka kasir'));
        await tester.tap(find.widgetWithText(FilledButton, 'Buka kasir'));
        expect(opened, 1);
      } else {
        expect(find.widgetWithText(FilledButton, 'Buka kasir'), findsNothing);
      }
      expect(PosOnboardingPage.isOperationalSetupCompleted(prefs), false);
      expect(tester.takeException(), isNull);
    });
  }
}
