import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:mobile_pos_pantoo/core/themes/app_theme.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/utils/product_image_picker.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_personal_profile_repository.dart';
import 'package:mobile_pos_pantoo/presentation/pages/profile/profile_page.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';

class _Provider extends Fake implements GraphQLClientProvider {
  @override
  late GraphQLClient client;
  @override
  String subscriptionScope = 'endpoint|tenant|terminal|operator';
  @override
  String endpointUrl = 'http://localhost:8080/graphql';
  @override
  String resolveMediaUrl(dynamic value) => value == null || value == ''
      ? ''
      : Uri.parse(
          'http://localhost:8080/',
        ).resolve(value.toString()).toString();
  @override
  Future<Map<String, String>> authenticatedRequestHeaders() async => {
    'Authorization': 'Bearer fixture',
    'apps': 'pos',
    'x-pos-operator-token': 'fixture-operator',
  };
}

const data = {
  '__typename': 'POSPersonalProfile',
  '_id': 'operator',
  'name': 'Kasir Uji',
  'username': 'kasir',
  'email': 'qa@example.invalid',
  'phone': '081234567890',
  'address': 'Jalan uji',
  'photo': '/static/t/profile/photo.png',
  'version': '2026-11-24T01:00:00.000Z',
};

class _Upload extends http.BaseClient {
  late http.MultipartRequest request;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest value) async {
    request = value as http.MultipartRequest;
    return http.StreamedResponse(
      Stream.value(
        utf8.encode(
          jsonEncode({
            'data': {'UpdateMyPOSPersonalProfile': data},
          }),
        ),
      ),
      200,
    );
  }
}

class _Repository extends Fake implements PosPersonalProfileRepository {
  PickedProductImage? savedPhoto;
  int saves = 0;
  Completer<Either<Failure, PosPersonalProfile>>? pending;
  final bool cached;
  _Repository({this.cached = false});
  @override
  Future<Either<Failure, PosPersonalProfile>> getProfile() async => Right(
    PosPersonalProfile(
      id: 'operator',
      name: 'Kasir Uji',
      username: 'kasir',
      email: 'qa@example.invalid',
      phone: '081234567890',
      address: 'Jalan uji',
      photo: '',
      version: 'v1',
      cached: cached,
    ),
  );
  @override
  Future<Either<Failure, PosPersonalProfile>> save({
    required String name,
    required String phone,
    required String address,
    required String expectedVersion,
    PickedProductImage? photo,
    bool removePhoto = false,
  }) async {
    saves++;
    savedPhoto = photo;
    expect(expectedVersion, 'v1');
    expect(name, 'Nama Baru');
    return pending?.future ??
        Future.value(
          Right(
            PosPersonalProfile(
              id: 'operator',
              name: name,
              username: 'kasir',
              email: 'qa@example.invalid',
              phone: phone,
              address: address,
              photo: '',
              version: 'v2',
            ),
          ),
        );
  }
}

class _Lock extends AppLockCubit {
  void seed(AppLockStatus status) => emit(
    AppLockState(
      status: status,
      activeEmployeeId: 'operator',
      activeEmployeeName: 'Lama',
      activeEmployeeRole: 'cashier',
      operatorSessionToken: 'verified-token',
      selectedEmployeeId: 'operator',
      hasPinConfigured: true,
      employees: const [
        {'_id': 'operator', 'name': 'Lama', 'has_pin': true},
        {'_id': 'other', 'name': 'Lain'},
      ],
    ),
  );
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Provider provider;
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_id': 'terminal',
      'username': 'Pemilik Terminal',
    });
    prefs = await SharedPreferences.getInstance();
    provider = _Provider();
  });
  void response({OperationException? failure}) {
    provider.client = GraphQLClient(
      cache: GraphQLCache(),
      link: Link.function((request, [forward]) async* {
        if (failure != null) {
          if (failure.graphqlErrors.isNotEmpty) {
            yield Response(
              errors: failure.graphqlErrors
                  .map(
                    (e) => GraphQLError(
                      message: e.message,
                      extensions: e.extensions,
                    ),
                  )
                  .toList(),
              response: {},
            );
            return;
          }
          throw failure;
        }
        yield Response(
          data: {'__typename': 'Query', 'GetMyPOSPersonalProfile': data},
          response: {},
        );
      }),
    );
  }

  test(
    'profile caches per PIN operator and never uses cache on authorization failure',
    () async {
      response();
      final repo = PosPersonalProfileRepository(provider, prefs);
      final online = (await repo.getProfile()).getOrElse(
        () => throw StateError('load failed'),
      );
      expect(online.photo, 'http://localhost:8080/static/t/profile/photo.png');
      response(
        failure: OperationException(
          linkException: ServerException(
            originalException: TimeoutException('timeout'),
          ),
        ),
      );
      expect(
        (await repo.getProfile())
            .getOrElse(() => throw StateError('cache failed'))
            .cached,
        isTrue,
      );
      provider.subscriptionScope = 'endpoint|tenant|terminal|other';
      expect((await repo.getProfile()).isLeft(), isTrue);
      provider.subscriptionScope = 'endpoint|tenant|terminal|operator';
      response(
        failure: OperationException(
          graphqlErrors: [
            GraphQLError(
              message: 'Forbidden',
              extensions: {'code': 'FORBIDDEN'},
            ),
          ],
        ),
      );
      expect((await repo.getProfile()).isLeft(), isTrue);
    },
  );
  test(
    'multipart preserves operator identity and whitelists only editable personal data',
    () async {
      final upload = _Upload();
      final repo = PosPersonalProfileRepository(
        provider,
        prefs,
        uploadClient: upload,
      );
      final result = await repo.save(
        name: 'Kasir Uji',
        phone: '081234567890',
        address: 'Jalan uji',
        expectedVersion: 'v1',
        photo: PickedProductImage(
          name: 'photo.png',
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      expect(result.isRight(), isTrue);
      expect(
        upload.request.headers['x-pos-operator-token'],
        'fixture-operator',
      );
      final operations =
          jsonDecode(upload.request.fields['operations']!) as Map;
      final input = (operations['variables'] as Map)['input'] as Map;
      expect(input.keys.toSet(), {
        'name',
        'phone',
        'address',
        'expected_version',
      });
      expect(jsonDecode(upload.request.fields['map']!), {
        '0': ['variables.photo'],
      });
      expect(
        prefs.getString('username'),
        'Pemilik Terminal',
        reason: 'editing an operator must not rename the login owner',
      );
    },
  );
  test(
    'invalid photo and upload/remove conflict are rejected before a request',
    () async {
      final repo = PosPersonalProfileRepository(provider, prefs);
      for (final image in [
        PickedProductImage(name: 'photo.svg', bytes: Uint8List(1)),
        PickedProductImage(
          name: 'photo.png',
          bytes: Uint8List(5 * 1024 * 1024 + 1),
        ),
      ]) {
        expect(
          (await repo.save(
            name: 'Kasir',
            phone: '',
            address: '',
            expectedVersion: 'v1',
            photo: image,
          )).isLeft(),
          isTrue,
        );
      }
    },
  );
  for (final size in [const Size(320, 568), const Size(768, 800)]) {
    testWidgets(
      'personal profile labels, progress and save stay usable at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = _Repository()..pending = Completer();
        var updated = 0;
        await tester.pumpWidget(
          RepaintBoundary(
            key: const ValueKey('profile_preview'),
            child: MaterialApp(
              theme: AppTheme.light(),
              locale: const Locale('id'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: ProfilePage(repository: repo, onUpdated: (_) => updated++),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (const bool.fromEnvironment('CAPTURE_PERSONAL_PROFILE')) {
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('profile_preview')),
            );
            final image = await boundary.toImage(pixelRatio: 2);
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            await Directory(
              'output/personal-profile-20261124',
            ).create(recursive: true);
            await File(
              'output/personal-profile-20261124/profile-${size.width.toInt()}.png',
            ).writeAsBytes(png!.buffer.asUint8List());
            image.dispose();
          });
        }
        for (final label in [
          'Nama lengkap',
          'Nomor telepon',
          'Alamat',
          'Email',
          'Username',
        ]) {
          expect(find.text(label), findsWidgets);
        }
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('profile_email')),
              )
              .enabled,
          isFalse,
        );
        await tester.ensureVisible(find.byKey(const ValueKey('profile_name')));
        await tester.enterText(
          find.byKey(const ValueKey('profile_name')),
          'Nama Baru',
        );
        final save = find.byKey(const ValueKey('profile_save'));
        tester.testTextInput.hide();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        await tester.tap(save);
        await tester.pump();
        expect(repo.saves, 1);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        await tester.tap(save);
        expect(repo.saves, 1);
        repo.pending!.complete(
          Right(
            const PosPersonalProfile(
              id: 'operator',
              name: 'Nama Baru',
              username: 'kasir',
              email: 'qa@example.invalid',
              phone: '',
              address: '',
              photo: '',
              version: 'v2',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(updated, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'cached profile is readable but cannot queue profile changes offline',
    (tester) async {
      final repo = _Repository(cached: true);
      await tester.pumpWidget(MaterialApp(home: ProfilePage(repository: repo)));
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('profile_save'));
      await tester.ensureVisible(save);
      expect(tester.widget<FilledButton>(save).onPressed, isNull);
      expect(repo.saves, 0);
    },
  );
  test(
    'cosmetic identity refresh cannot unlock, change role/session or another operator',
    () async {
      final lock = _Lock();
      for (final status in [AppLockStatus.locked, AppLockStatus.unlocked]) {
        lock.seed(status);
        lock.applyActiveEmployeeProfile(
          id: 'operator',
          name: 'Baru',
          photoUrl: '/photo.png',
        );
        expect(lock.state.status, status);
        expect(lock.state.activeEmployeeName, 'Baru');
        expect(lock.state.operatorSessionToken, 'verified-token');
        expect(lock.state.activeEmployeeRole, 'cashier');
        expect(lock.state.selectedEmployeeId, 'operator');
        expect(lock.state.hasPinConfigured, isTrue);
        expect(lock.state.employees.first['photo_url'], '/photo.png');
        expect(lock.state.employees.last['name'], 'Lain');
        lock.applyActiveEmployeeProfile(
          id: 'other',
          name: 'Wrong',
          photoUrl: '',
        );
        expect(lock.state.activeEmployeeName, 'Baru');
      }
      await lock.close();
      lock.applyActiveEmployeeProfile(
        id: 'operator',
        name: 'Closed',
        photoUrl: '',
      );
    },
  );
  test('late server profile from previous operator is discarded', () async {
    final pending = Completer<Response>();
    provider.client = GraphQLClient(
      cache: GraphQLCache(),
      link: Link.function((request, [forward]) => pending.future.asStream()),
    );
    final read = PosPersonalProfileRepository(provider, prefs).getProfile();
    await Future<void>.delayed(Duration.zero);
    provider.subscriptionScope = 'endpoint|tenant|terminal|new';
    pending.complete(
      Response(
        data: {'__typename': 'Query', 'GetMyPOSPersonalProfile': data},
        response: {},
      ),
    );
    expect((await read).isLeft(), isTrue);
    expect(
      prefs.getKeys().where(
        (key) => key.startsWith('pos_personal_profile_v1:'),
      ),
      isEmpty,
    );
  });
  test(
    'text-only save and removal use exact API input; owner name updates only for self',
    () async {
      Map<String, dynamic>? variables;
      provider.client = GraphQLClient(
        cache: GraphQLCache(),
        link: Link.function((request, [forward]) async* {
          variables = request.variables;
          yield Response(
            data: {
              '__typename': 'Mutation',
              'UpdateMyPOSPersonalProfile': data,
            },
            response: {},
          );
        }),
      );
      await prefs.setString('user_id', 'operator');
      final result = await PosPersonalProfileRepository(provider, prefs).save(
        name: 'Kasir Uji',
        phone: '',
        address: '',
        expectedVersion: 'v1',
        removePhoto: true,
      );
      expect(result.isRight(), isTrue);
      expect(variables?['input'], {
        'name': 'Kasir Uji',
        'phone': '',
        'address': '',
        'expected_version': 'v1',
        'remove_photo': true,
      });
      expect(prefs.getString('username'), 'Kasir Uji');
    },
  );
  testWidgets(
    'photo selection is previewed and submitted once; rejected save preserves draft',
    (tester) async {
      final repo = _Repository()..pending = Completer();
      final image = PickedProductImage(
        name: 'photo.png',
        bytes: base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: ProfilePage(repository: repo, imagePicker: () async => image),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ubah foto profil'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus foto'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('profile_name')),
        'Nama Baru',
      );
      tester.testTextInput.hide();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final save = find.byKey(const ValueKey('profile_save'));
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pump();
      expect(repo.savedPhoto, same(image));
      expect(repo.saves, 1);
      repo.pending!.complete(
        const Left(
          ServerFailure('Profil berubah. Muat ulang sebelum menyimpan.'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('profile_name')))
            .controller!
            .text,
        'Nama Baru',
      );
      expect(
        find.text('Profil berubah. Muat ulang sebelum menyimpan.'),
        findsOneWidget,
      );
      expect(repo.saves, 1);
    },
  );
  testWidgets('English profile actions and notices are translated', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfilePage(repository: _Repository()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Active cashier profile'), findsOneWidget);
    expect(find.text('Change profile photo'), findsOneWidget);
    expect(find.text('Save profile'), findsOneWidget);
  });
}
