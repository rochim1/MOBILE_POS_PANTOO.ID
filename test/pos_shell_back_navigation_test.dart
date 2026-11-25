import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/customer_display/pos_customer_display_service.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/core/network/sync_service.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_customer.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/auth_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_notification_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_receipt_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/auth_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_shell_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_customer_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_more_menu_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_cashier_entry_button.dart';

class _Repo extends Fake implements PosRepository {
  @override
  Map<String, dynamic>? get pendingCheckout => null;
  @override
  Future<void> syncPendingFavoriteProductIds() async {}
  @override
  Future<List<PosCustomer>> getCustomers() async => [];
}

class _Sync extends Fake implements SyncService {
  @override
  Future<void> syncOfflineTransactions({bool force = false}) async {}
  @override
  Future<Map<String, dynamic>> getQueueSummary() async => {'unresolved': 0};
}

class _Notifications extends Fake implements PosNotificationRepository {
  @override
  Future<Either<Failure, PosNotificationResult>> getOperationalNotifications({
    int limit = 50,
  }) async => const Right(
    PosNotificationResult(items: [], unreadCount: 0, pageCount: 0),
  );
}

class _Receipts extends Fake implements PosReceiptRepository {
  @override
  Future<Either<Failure, PosReceiptPrintData>>
  preloadReceiptPrintData() async => const Left(ServerFailure('fixture'));
}

class _Display extends Fake implements PosCustomerDisplayService {
  @override
  final state = ValueNotifier(const PosCustomerDisplayState());
}

class _Provider extends Fake implements GraphQLClientProvider {
  @override
  String get subscriptionScope => 'fixture';
}

class _AuthRepo extends Fake implements AuthRepository {}

class _Lock extends AppLockCubit {
  void locked() => emit(state.copyWith(status: AppLockStatus.locked));
}

class _Pos extends PosBloc {
  _Pos(PosRepository repository) : super(posRepository: repository);
  static const ready = PosState(
    status: PosStatus.success,
    stores: [PosStore(id: 'shop', name: 'Fixture', status: 'active')],
    activeShift: {'toko_id': 'shop'},
    runtimeConfig: {
      'features': {'track_stock': false},
      'permissions': {
        'use_cashier': true,
        'view_shifts': true,
        'view_customers': true,
      },
    },
  );
  @override
  void add(PosEvent event) {
    if (event is LoadPosData) {
      scheduleMicrotask(() {
        if (!isClosed) emit(ready);
      });
    }
  }

  void busy(bool value) => emit(state.copyWith(paymentInProgress: value));
  void revokeCustomers() => emit(
    state.copyWith(
      runtimeConfig: {
        'permissions': {'use_cashier': true},
      },
    ),
  );
}

void main() {
  testWidgets(
    'real shell arrow and Android back follow visits, stay open, and honor busy/lock',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({
        'pos_operational_setup_completed_v2:unknown-instansi': true,
      });
      sl.pushNewScope();
      final repo = _Repo();
      final pos = _Pos(repo);
      final lock = _Lock();
      final auth = AuthCubit(authRepository: _AuthRepo());
      final display = _Display();
      sl.registerSingleton<SharedPreferences>(
        await SharedPreferences.getInstance(),
      );
      sl.registerSingleton<PosRepository>(repo);
      sl.registerSingleton<PosBloc>(pos);
      sl.registerSingleton<SyncService>(_Sync());
      sl.registerSingleton<PosNotificationRepository>(_Notifications());
      sl.registerSingleton<PosReceiptRepository>(_Receipts());
      sl.registerSingleton<PosCustomerDisplayService>(display);
      sl.registerSingleton<GraphQLClientProvider>(_Provider());
      const connectivity = MethodChannel(
        'dev.fluttercommunity.plus/connectivity_status',
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        connectivity,
        (_) async => null,
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await lock.close();
        await auth.close();
        display.state.dispose();
        await sl.popScope();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          connectivity,
          null,
        );
      });
      final platformCalls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          platformCalls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AppLockCubit>.value(value: lock),
            BlocProvider<AuthCubit>.value(value: auth),
          ],
          child: MaterialApp(
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const PosShellPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PosPage), findsOneWidget);
      await tester.tap(find.text('Lainnya').last);
      await tester.pumpAndSettle();
      expect(find.byType(PosMoreMenuPage), findsOneWidget);
      await tester.ensureVisible(find.text('Pelanggan'));
      await tester.tap(find.text('Pelanggan'));
      await tester.pumpAndSettle();
      expect(find.byType(PosCustomerPage), findsOneWidget);
      await tester.tap(find.byType(PosCashierEntryButton));
      await tester.pumpAndSettle();
      expect(find.byType(PosPage), findsOneWidget);
      pos.busy(true);
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(PosPage), findsOneWidget);
      pos.busy(false);
      await tester.pump();
      tester
          .widget<PosPage>(find.byType(PosPage))
          .onCheckoutRecoveryBusyChanged
          ?.call(true);
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(PosPage), findsOneWidget);
      tester
          .widget<PosPage>(find.byType(PosPage))
          .onCheckoutRecoveryBusyChanged
          ?.call(false);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PosCustomerPage), findsOneWidget);
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      expect(find.byType(PosMoreMenuPage), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PosPage), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PosPage), findsOneWidget);
      await tester.tap(find.text('Lainnya').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Pelanggan'));
      await tester.tap(find.text('Pelanggan'));
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PosCustomerPage), findsOneWidget);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(PosCashierEntryButton));
      await tester.pumpAndSettle();
      pos.revokeCustomers();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PosMoreMenuPage), findsOneWidget);
      lock.locked();
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PosMoreMenuPage), findsOneWidget);
      expect(platformCalls, isNot(contains('SystemNavigator.pop')));
      expect(tester.takeException(), isNull);
    },
  );
}
