import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_settings.dart';
import 'package:mobile_pos_pantoo/domain/repositories/auth_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_settings_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/pages/login/business_setup_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_onboarding_page.dart';

class _Auth extends Fake implements AuthRepository {
  final pending = Completer<Either<Failure, String>>();
  int creates = 0;
  @override
  Future<Either<Failure, String>> createWorkspace({
    required String businessName,
    required String phone,
    String businessProfile = 'retail',
  }) {
    creates++;
    return pending.future;
  }
}

class _Settings extends Fake implements PosSettingsRepository {
  final pending = Completer<Either<Failure, PosSettings>>();
  @override
  Future<Either<Failure, PosSettings>> getSettings() => pending.future;
}

class _Lock extends AppLockCubit {
  final pending = Completer<void>();
  int locks = 0;
  @override
  Future<void> lock() {
    locks++;
    return pending.future;
  }
}

void main() {
  Future<({_Auth auth, _Settings settings, _Lock lock})> mount(
    WidgetTester tester, {
    VoidCallback? onCompleted,
    double width = 390,
  }) async {
    SharedPreferences.setMockInitialValues({
      'instansi_id': 'tenant',
      'user_id': 'user',
    });
    sl.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
    final auth = _Auth(), settings = _Settings(), lock = _Lock();
    sl.registerSingleton<AuthRepository>(auth);
    sl.registerSingleton<PosSettingsRepository>(settings);
    await tester.binding.setSurfaceSize(Size(width, 1200));
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      if (!auth.pending.isCompleted)
        auth.pending.complete(const Left(NetworkFailure('offline')));
      if (!settings.pending.isCompleted)
        settings.pending.complete(const Left(NetworkFailure('offline')));
      if (!lock.pending.isCompleted) lock.pending.complete();
      await tester.pump();
      await lock.close();
      await sl.reset();
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      BlocProvider<AppLockCubit>.value(
        value: lock,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: BusinessSetupPage(onCompleted: onCompleted),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Usaha Uji');
    await tester.enterText(find.byType(TextFormField).at(1), '081234567890');
    await tester.ensureVisible(find.text('Buat Profil & Lanjutkan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buat Profil & Lanjutkan'));
    await tester.pump();
    return (auth: auth, settings: settings, lock: lock);
  }

  testWidgets(
    'submit displays readable loading inside the button and blocks repeated submit',
    (tester) async {
      final h = await mount(tester);
      expect(find.text('Menyimpan…'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(h.auth.creates, 1);
      expect(find.byType(BusinessSetupPage), findsOneWidget);
    },
  );
  testWidgets(
    'after creation access preparation remains on the same form and button, not a full-page loader',
    (tester) async {
      final h = await mount(tester);
      h.auth.pending.complete(const Right('tenant'));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(BusinessSetupPage), findsOneWidget);
      expect(find.byType(PosOnboardingGate), findsNothing);
      expect(find.text('Menyiapkan Pantoo POS…'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(h.auth.creates, 1);
      await tester.pumpWidget(const SizedBox());
      h.settings.pending.complete(const Left(NetworkFailure('offline')));
      h.lock.pending.complete();
      await tester.pump();
    },
  );
  testWidgets('failed creation restores the button and keeps entered values', (
    tester,
  ) async {
    final h = await mount(tester);
    h.auth.pending.complete(const Left(NetworkFailure('Koneksi gagal')));
    await tester.pumpAndSettle();
    expect(find.text('Koneksi gagal'), findsOneWidget);
    expect(find.text('Usaha Uji'), findsOneWidget);
    expect(find.text('081234567890'), findsOneWidget);
    expect(find.text('Buat Profil & Lanjutkan'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets(
    'completion waits for settings and PIN context; narrow button never overflows',
    (tester) async {
      var completed = 0;
      final h = await mount(tester, width: 320, onCompleted: () => completed++);
      h.auth.pending.complete(const Right('tenant'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(completed, 0);
      expect(h.lock.locks, 0);
      h.settings.pending.complete(const Right(PosSettings()));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(h.lock.locks, 1);
      expect(completed, 0);
      expect(find.text('Menyiapkan Pantoo POS…'), findsOneWidget);
      expect(find.byType(PosOnboardingGate), findsNothing);
      expect(tester.takeException(), isNull);
      h.lock.pending.complete();
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(completed, 1);
      expect(h.auth.creates, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'unexpected creation failure releases loading instead of hanging',
    (tester) async {
      final h = await mount(tester);
      h.auth.pending.completeError(StateError('simulated transport failure'));
      await tester.pumpAndSettle();
      expect(
        find.text('Konfigurasi POS belum dapat dimuat. Coba lagi.'),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'retry after PIN preparation failure never creates a second workspace',
    (tester) async {
      final h = await mount(tester);
      h.auth.pending.complete(const Right('tenant'));
      h.settings.pending.complete(const Right(PosSettings()));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      h.lock.pending.completeError(
        StateError('simulated PIN preparation failure'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lanjutkan'), findsOneWidget);
      await tester.ensureVisible(find.text('Lanjutkan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjutkan'));
      await tester.pumpAndSettle();
      expect(h.auth.creates, 1);
      expect(h.lock.locks, 2);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
