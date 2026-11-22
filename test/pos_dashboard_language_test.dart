import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_remote_profile_catalog.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_settings.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_settings_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/app_language_controller.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/l10n/language_picker.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_settings/pos_settings_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_more_menu_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_settings_page.dart';

class _Runtime extends Fake implements PosRepository {}
class _Settings extends Fake implements PosSettingsRepository {
  final pending = Completer<Either<Failure, PosSettings>>();
  int saves = 0;
  @override
  Future<Either<Failure, PosSettings>> getSettings() => pending.future;
  @override
  Future<PosRemoteProfileCatalog> getProfileCatalog() async => PosRemoteProfileCatalog.bundled();
  @override
  Future<Either<Failure, PosSettings>> updateSettings(Map<String, dynamic> input) async {
    saves++;
    return Right(PosSettings.fromJson(input));
  }
}
class _Pos extends PosBloc {
  _Pos() : super(posRepository: _Runtime()) {
    emit(PosState(cart: {_product: 2}, runtimeConfig: const {'permissions': {}}));
  }
}
const _product = PosProduct(id: 'cart', code: 'KEEP', name: 'Produk tetap', category: 'QA', price: 5000, stock: 10);

Future<void> _open(WidgetTester tester, Widget page, _Pos bloc, {Size size = const Size(390, 844)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(BlocProvider<PosBloc>.value(value: bloc,
    child: ValueListenableBuilder<Locale?>(valueListenable: AppLanguageController.instance,
      child: page,
      builder: (_, locale, child) => MaterialApp(locale: locale,
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child)))));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
Future<void> _choose(WidgetTester tester, String label) async {
  final picker = find.byType(LanguagePicker);
  expect(picker, findsOneWidget);
  await tester.ensureVisible(picker);
  await tester.tap(picker);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.tap(find.text(label).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'token': 'keep-session', 'shift_id': 'keep-shift'});
    await AppLanguageController.instance.select('id');
  });
  tearDown(() async { await sl.reset(); });

  testWidgets('More menu lets a cashier change language without settings permission or navigation', (tester) async {
    final bloc = _Pos(); addTearDown(bloc.close);
    var navigations = 0;
    var logouts = 0;
    await _open(tester, PosMoreMenuPage(onNavigate: (_) => navigations++, onLogout: () => logouts++), bloc);
    expect(find.text('Pengaturan POS'), findsNothing);
    await _choose(tester, 'English');
    expect(find.text('Language'), findsOneWidget);
    expect(bloc.state.cart[_product], 2);
    expect(navigations, 0); expect(logouts, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('token'), 'keep-session');
    expect(prefs.getString('shift_id'), 'keep-shift');
    final restored = AppLanguageController(); addTearDown(restored.dispose);
    await restored.load(); expect(restored.value, const Locale('en'));
    await _choose(tester, 'Bahasa Indonesia');
    expect(find.text('Bahasa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Settings language remains available during loading and offline failure', (tester) async {
    final repo = _Settings(); final bloc = _Pos(); addTearDown(bloc.close);
    sl.registerFactory<PosSettingsBloc>(() => PosSettingsBloc(repository: repo));
    await _open(tester, const PosSettingsPage(), bloc);
    await _choose(tester, 'English');
    repo.pending.complete(const Left(NetworkFailure('Koneksi terputus')));
    await tester.pump(); await tester.pump(const Duration(milliseconds: 300));
    await _choose(tester, 'Bahasa Indonesia');
    expect(repo.saves, 0);
    expect(tester.takeException(), isNull);
  });
  for (final size in [const Size(320, 568), const Size(844, 390), const Size(1024, 768)]) {
    testWidgets('Settings language is visible and usable in read-only mode at $size', (tester) async {
      final repo = _Settings(); final bloc = _Pos(); addTearDown(bloc.close);
      repo.pending.complete(const Right(PosSettings(businessProfile: 'retail')));
      sl.registerFactory<PosSettingsBloc>(() => PosSettingsBloc(repository: repo));
      await _open(tester, const PosSettingsPage(), bloc, size: size);
      final picker = find.byType(LanguagePicker);
      expect(picker, findsOneWidget);
      expect(tester.getRect(picker).top, lessThan(120));
      await _choose(tester, 'English');
      await _choose(tester, 'Use device language');
      expect(AppLanguageController.instance.value, isNull);
      expect(repo.saves, 0);
      expect(bloc.state.cart[_product], 2);
      expect(tester.takeException(), isNull);
    });
  }
}
