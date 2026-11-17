import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/core/utils/product_image_picker.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_settings.dart';
import 'package:mobile_pos_pantoo/domain/repositories/auth_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_business_profile_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_settings_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/pages/login/business_setup_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_onboarding_page.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_business_logo_picker.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_business_profile_form.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_remote_profile_catalog.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_settings/pos_settings_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_settings_page.dart';

PickedProductImage image() => PickedProductImage(
  name: 'logo.png',
  bytes: base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a2ioAAAAASUVORK5CYII=',
  ),
);

class _Profiles extends Fake implements PosBusinessProfileRepository {
  PosBusinessProfile current = const PosBusinessProfile(
    id: 'tenant',
    name: 'Usaha Uji',
    phone: '081234567890',
  );
  bool failSave = false, failLoad = false;
  int saves = 0;
  bool? removed;
  PickedProductImage? uploaded;
  Completer<Either<Failure, PosBusinessProfile>>? pending;
  @override
  Future<Either<Failure, PosBusinessProfile>> getProfile() async =>
      failLoad ? const Left(NetworkFailure('Koneksi gagal')) : Right(current);
  @override
  Future<Either<Failure, PosBusinessProfile>> save({
    required String name,
    required String phone,
    String? address,
    PickedProductImage? logo,
    bool removeLogo = false,
  }) async {
    saves++;
    removed = removeLogo;
    uploaded = logo;
    if (pending != null) return pending!.future;
    if (failSave) return const Left(NetworkFailure('Koneksi gagal'));
    current = PosBusinessProfile(
      id: current.id,
      name: name,
      phone: phone,
      address: address ?? '',
      logo: removeLogo
          ? ''
          : logo != null
          ? 'http://localhost/updated.png'
          : current.logo,
    );
    return Right(current);
  }
}

class _Auth extends Fake implements AuthRepository {
  int creates = 0;
  @override
  Future<Either<Failure, String>> createWorkspace({
    required String businessName,
    required String phone,
  }) async {
    creates++;
    return const Right('tenant');
  }
}

class _Lock extends AppLockCubit {
  int locks = 0;
  @override
  Future<void> lock() async {
    locks++;
  }
}

class _PendingSettings extends Fake implements PosSettingsRepository {
  @override
  Future<Either<Failure, PosSettings>> getSettings() =>
      Completer<Either<Failure, PosSettings>>().future;
}

class _Settings extends Fake implements PosSettingsRepository {
  @override
  Future<PosRemoteProfileCatalog> getProfileCatalog() async =>
      PosRemoteProfileCatalog.bundled();
  @override
  Future<Either<Failure, PosSettings>> getSettings() async =>
      const Right(PosSettings());
}

class _Pos extends Fake implements PosRepository {}

class _ReadyPos extends PosBloc {
  _ReadyPos() : super(posRepository: _Pos()) {
    emit(
      state.copyWith(
        status: PosStatus.success,
        runtimeConfig: {
          'permissions': {'manage_settings': true},
        },
      ),
    );
  }
}

void main() {
  tearDown(() async => sl.reset());

  Future<void> mountForm(
    WidgetTester tester,
    _Profiles repository, {
    bool canEdit = true,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: PosBusinessProfileForm(
            repository: repository,
            canEdit: canEdit,
            pickLogo: () async => image(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    final button = find.widgetWithText(FilledButton, 'Simpan profil usaha');
    await tester.ensureVisible(button);
    await tester.tap(button);
  }

  testWidgets(
    'settings can choose, preview and save a logo with a nonduplicating loading button',
    (tester) async {
      final repository = _Profiles();
      await mountForm(tester, repository);
      await tester.tap(find.byTooltip('Pilih logo usaha'));
      await tester.pumpAndSettle();
      expect(find.text('Ganti logo'), findsOneWidget);
      repository.pending = Completer<Either<Failure, PosBusinessProfile>>();
      await save(tester);
      await tester.pump();
      expect(find.text('Menyimpan…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(repository.saves, 1);
      expect(repository.uploaded?.name, 'logo.png');
      repository.pending!.complete(
        const Right(
          PosBusinessProfile(
            id: 'tenant',
            name: 'Usaha Uji',
            phone: '081234567890',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Profil usaha berhasil disimpan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('settings remove is explicit and failed save remains retryable', (
    tester,
  ) async {
    final repository = _Profiles()
      ..current = const PosBusinessProfile(
        id: 'tenant',
        name: 'Usaha Uji',
        phone: '081234567890',
        logo: 'http://localhost/logo.png',
      )
      ..failSave = true;
    await mountForm(tester, repository);
    await tester.tap(find.text('Hapus logo'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih logo'), findsOneWidget);
    await save(tester);
    await tester.pumpAndSettle();
    expect(repository.removed, true);
    expect(find.text('Koneksi gagal'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    repository.failSave = false;
    await save(tester);
    await tester.pumpAndSettle();
    expect(repository.current.logo, '');
    expect(repository.saves, 2);
  });

  testWidgets(
    'cashier without settings permission cannot edit, choose or save logo',
    (tester) async {
      final repository = _Profiles();
      await mountForm(tester, repository, canEdit: false);
      expect(find.byType(FilledButton), findsNothing);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      for (final field in tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      )) {
        expect(field.enabled, true);
      }
      for (final field in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(field.readOnly, true);
      }
      expect(repository.saves, 0);
    },
  );

  testWidgets('settings has recovery for a failed initial read', (
    tester,
  ) async {
    final repository = _Profiles()..failLoad = true;
    await mountForm(tester, repository);
    expect(find.text('Koneksi gagal'), findsOneWidget);
    repository.failLoad = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(3));
  });

  testWidgets(
    'business profile is reachable through the actual mobile settings category',
    (tester) async {
      final repository = _Profiles();
      sl.registerSingleton<PosBusinessProfileRepository>(repository);
      sl.registerFactory<PosSettingsBloc>(
        () => PosSettingsBloc(repository: _Settings()),
      );
      final bloc = _ReadyPos();
      addTearDown(bloc.close);
      await tester.binding.setSurfaceSize(const Size(390, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        BlocProvider<PosBloc>.value(
          value: bloc,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const Scaffold(body: PosSettingsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transaksi & Penjualan').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Profil Usaha').last);
      await tester.pumpAndSettle();
      expect(find.byType(PosBusinessProfileForm), findsOneWidget);
      expect(find.text('Simpan profil usaha'), findsOneWidget);
      expect(find.text('Usaha Uji'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'invalid image and picker cancellation leave previous selection unchanged',
    (tester) async {
      PickedProductImage? selected;
      final invalid = PickedProductImage(
        name: 'logo.html',
        bytes: image().bytes,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosBusinessLogoPicker(
              onChanged: (value) => selected = value,
              onRemove: () {},
              pickImage: () async => invalid,
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Pilih logo usaha'));
      await tester.pumpAndSettle();
      expect(find.text('Logo harus JPG, PNG, atau WebP'), findsOneWidget);
      expect(selected, isNull);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosBusinessLogoPicker(
              key: const ValueKey('cancel'),
              onChanged: (value) => selected = value,
              onRemove: () {},
              pickImage: () async => null,
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Pilih logo usaha'));
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'failed setup logo retries without creating a second workspace and can continue safely',
    (tester) async {
      final auth = _Auth(), profiles = _Profiles()..failSave = true;
      final lock = _Lock();
      addTearDown(lock.close);
      SharedPreferences.setMockInitialValues({'instansi_id': 'tenant'});
      sl.registerSingleton<SharedPreferences>(
        await SharedPreferences.getInstance(),
      );
      sl.registerSingleton<AuthRepository>(auth);
      sl.registerSingleton<PosBusinessProfileRepository>(profiles);
      sl.registerSingleton<PosSettingsRepository>(_PendingSettings());
      await tester.binding.setSurfaceSize(const Size(390, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        BlocProvider<AppLockCubit>.value(
          value: lock,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: BusinessSetupPage(pickLogo: () async => image()),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Pilih logo usaha'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Usaha Uji');
      await tester.enterText(find.byType(TextFormField).at(1), '081234567890');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Restoran / Cafe').last);
      await tester.pumpAndSettle();
      final submit = find.text('Buat Profil & Lanjutkan');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(auth.creates, 1);
      expect(profiles.saves, 1);
      expect(
        sl<SharedPreferences>().getString(
          PosOnboardingPage.pendingProfileKey(sl<SharedPreferences>()),
        ),
        'restoran',
      );
      expect(
        find.textContaining('Profil usaha sudah dibuat, tetapi logo belum'),
        findsOneWidget,
      );
      final retry = find.text('Coba unggah logo lagi');
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(auth.creates, 1);
      expect(profiles.saves, 2);
      final skip = find.text('Lanjutkan tanpa logo');
      await tester.ensureVisible(skip);
      await tester.tap(skip);
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(PosOnboardingGate), findsOneWidget);
      expect(lock.locks, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
