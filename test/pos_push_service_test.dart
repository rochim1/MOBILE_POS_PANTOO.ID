import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/notifications/pos_push_repository.dart';
import 'package:mobile_pos_pantoo/core/notifications/pos_push_service.dart';

class _Settings extends Fake implements NotificationSettings {
  _Settings(this.authorizationStatus);
  @override
  final AuthorizationStatus authorizationStatus;
}

class _Messaging extends Fake implements FirebaseMessaging {
  final refresh = StreamController<String>.broadcast();
  AuthorizationStatus permission = AuthorizationStatus.authorized;
  RemoteMessage? initial;
  Completer<String?>? pending;
  int deletes = 0;
  @override
  Stream<String> get onTokenRefresh => refresh.stream;
  @override
  Future<String?> getToken({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) async => pending == null ? 'initial-token' : await pending!.future;
  @override
  Future<void> deleteToken() async {
    deletes++;
  }

  @override
  Future<RemoteMessage?> getInitialMessage() async => initial;
  @override
  Future<NotificationSettings> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
    bool providesAppNotificationSettings = false,
  }) async => _Settings(permission);
}

class _Repository implements PosPushTokenRepository {
  final tokens = <String>[];
  final removed = <String>[];
  bool fail = false;
  Completer<void>? pending;
  @override
  Future<void> register({
    required String token,
    required String projectId,
    required String installationId,
  }) async {
    expect(projectId, 'pantoo-511802');
    expect(installationId, isNotEmpty);
    tokens.add(token);
    await pending?.future;
    if (fail) throw StateError('offline');
  }

  @override
  Future<void> unregister({
    required String token,
    required String installationId,
  }) async {
    removed.add(token);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const platform = MethodChannel('dexterous.com/flutter/local_notifications');
  const firebaseChannel = MethodChannel(
    'plugins.flutter.io/firebase_messaging',
  );
  late _Messaging messaging;
  late _Repository repository;
  late SharedPreferences prefs;
  late PosPushService service;
  Completer<void>? firebaseInitialization;
  late StreamController<RemoteMessage> foreground, opened;
  final calls = <MethodCall>[];
  var opens = 0;
  Future<void> flush() async {
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    SharedPreferences.setMockInitialValues({
      'user_id': 'user',
      'instansi_id': 'tenant',
    });
    prefs = await SharedPreferences.getInstance();
    messaging = _Messaging();
    firebaseInitialization = null;
    repository = _Repository();
    foreground = StreamController.broadcast();
    opened = StreamController.broadcast();
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseChannel, (_) async => null);
    opens = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform, (call) async {
          calls.add(call);
          if (call.method == 'initialize') return true;
          if (call.method == 'getNotificationAppLaunchDetails')
            return {'notificationLaunchedApp': false};
          return null;
        });
    service =
        PosPushService(
            repository: repository,
            prefs: prefs,
            messaging: messaging,
            firebaseReady: () async {
              await firebaseInitialization?.future;
            },
            projectId: 'pantoo-511802',
            enabled: true,
            foregroundMessages: foreground.stream,
            openedMessages: opened.stream,
          )
          ..onOpen = () {
            opens++;
          };
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(firebaseChannel, null);
    await service.dispose();
    await foreground.close();
    await opened.close();
    await messaging.refresh.close();
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(platform, null);
  });

  test(
    'registers initial token, refreshes replacements and deduplicates successful tokens',
    () async {
      await service.activate();
      messaging.refresh.add('replacement');
      await flush();
      messaging.refresh.add('replacement');
      await flush();
      expect(repository.tokens, ['initial-token', 'replacement']);
      expect(service.status.value, PosPushStatus.ready);
    },
  );
  test(
    'foreground shows one Pantoo notification and does not navigate until tapped',
    () async {
      await service.activate();
      const message = RemoteMessage(
        messageId: 'same',
        notification: RemoteNotification(title: 'POS', body: 'Test'),
      );
      foreground.add(message);
      foreground.add(message);
      await flush();
      final shown = calls.where((call) => call.method == 'show').toList();
      expect(shown, hasLength(1));
      expect(
        (shown.single.arguments['platformSpecifics'] as Map)['icon'],
        'ic_notif',
      );
      expect(
        (shown.single.arguments['platformSpecifics'] as Map)['channelId'],
        'pantoo_pos',
      );
      expect(opens, 0);
      opened.add(message);
      await flush();
      expect(opens, 1);
    },
  );
  test(
    'cold-start tap waits until authentication and organization are ready',
    () async {
      messaging.initial = const RemoteMessage(messageId: 'cold');
      await service.initialize();
      expect(opens, 0);
      await service.activate();
      expect(opens, 1);
      await service.activate();
      expect(opens, 1);
    },
  );
  test('permission denied does not register a token', () async {
    messaging.permission = AuthorizationStatus.denied;
    await service.activate();
    messaging.refresh.add('denied-refresh');
    await flush();
    expect(repository.tokens, isEmpty);
    expect(service.status.value, PosPushStatus.denied);
  });
  test('failed registration retries on activation', () async {
    repository.fail = true;
    await service.activate();
    expect(service.status.value, PosPushStatus.error);
    repository.fail = false;
    await service.activate();
    expect(repository.tokens, ['initial-token', 'initial-token']);
    expect(service.status.value, PosPushStatus.ready);
  });
  test(
    'logout removes server token, invalidates FCM token and suppresses foreground messages',
    () async {
      await service.activate();
      await service.deactivate();
      foreground.add(
        const RemoteMessage(notification: RemoteNotification(title: 'Private')),
      );
      messaging.refresh.add('after-logout');
      await flush();
      expect(repository.removed, ['initial-token']);
      expect(messaging.deletes, 1);
      expect(calls.where((call) => call.method == 'show'), isEmpty);
      expect(repository.tokens, ['initial-token']);
    },
  );
  test(
    'an organization change prevents stale-session foreground delivery',
    () async {
      await service.activate();
      await prefs.setString('instansi_id', 'other-tenant');
      foreground.add(
        const RemoteMessage(notification: RemoteNotification(title: 'Private')),
      );
      await flush();
      expect(calls.where((call) => call.method == 'show'), isEmpty);
      await service.activate();
      expect(repository.tokens, ['initial-token', 'initial-token']);
    },
  );
  test('refresh during initial token read wins over stale token', () async {
    messaging.pending = Completer<String?>();
    final activation = service.activate();
    await flush();
    messaging.refresh.add('fresh');
    await flush();
    messaging.pending!.complete('stale');
    await activation;
    expect(repository.tokens, ['fresh']);
  });

  test('logout during registration removes the attempted token', () async {
    repository.pending = Completer<void>();
    final activation = service.activate();
    await flush();
    expect(repository.tokens, ['initial-token']);
    final logout = service.deactivate();
    repository.pending!.complete();
    await Future.wait([activation, logout]);
    expect(repository.removed, ['initial-token']);
    expect(service.status.value, PosPushStatus.unavailable);
  });

  test(
    'logout while Firebase initializes cannot reactivate the old session',
    () async {
      firebaseInitialization = Completer<void>();
      final activation = service.activate();
      await flush();
      await service.deactivate();
      firebaseInitialization!.complete();
      await activation;
      messaging.refresh.add('after-logout');
      await flush();
      expect(repository.tokens, isEmpty);
    },
  );
}
