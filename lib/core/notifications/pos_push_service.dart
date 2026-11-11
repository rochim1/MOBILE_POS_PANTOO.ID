import 'dart:async';
import 'dart:ui' show Color;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'pos_push_repository.dart';

@pragma('vm:entry-point')
Future<void> pantooPosBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp();
  // FCM displays notification payloads in the background. Do not show a second copy.
}

enum PosPushStatus { unavailable, ready, denied, error }

class PosPushService with WidgetsBindingObserver {
  PosPushService({
    required this.repository,
    required this.prefs,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? notifications,
    this.firebaseReady,
    this.projectId,
    this.enabled,
    this.foregroundMessages,
    this.openedMessages,
  }) : _messaging = messaging,
       _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  final PosPushTokenRepository repository;
  final SharedPreferences prefs;
  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _notifications;
  final Future<void> Function()? firebaseReady;
  final String? projectId;
  final bool? enabled;
  final Stream<RemoteMessage>? foregroundMessages, openedMessages;
  final status = ValueNotifier(PosPushStatus.unavailable);
  void Function()? onOpen;
  StreamSubscription<RemoteMessage>? _foreground, _opened;
  StreamSubscription<String>? _refresh;
  Future<void> _writes = Future.value();
  Future<void>? _initializing;
  Future<void>? _activating;
  bool _initialized = false,
      _permissionGranted = false,
      _authenticated = false,
      _pendingOpen = false,
      _disposed = false;
  int _generation = 0;
  int _refreshVersion = 0;
  String? _scope, _savedToken, _attemptedToken;
  final _seenMessages = <String>{};

  bool get supported =>
      enabled ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);
  String get _session =>
      '${prefs.getString('user_id') ?? ''}:${prefs.getString('instansi_id') ?? ''}';
  String get _installation => prefs.getString('pos_push_installation_id')!;

  Future<void> initialize() async {
    if (!supported || _disposed || _initialized) return;
    if (_initializing != null) return _initializing;
    _initializing = _initialize();
    try {
      await _initializing;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initialize() async {
    try {
      if (firebaseReady != null) {
        await firebaseReady!();
      } else {
        await Firebase.initializeApp();
      }
      if (_disposed) return;
      _messaging ??= FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(pantooPosBackgroundMessage);
      if (prefs.getString('pos_push_installation_id') == null) {
        await prefs.setString('pos_push_installation_id', const Uuid().v4());
      }
      await _notifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notif'),
        ),
        onDidReceiveNotificationResponse: (_) => _open(),
      );
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              'pantoo_pos',
              'Pantoo POS',
              importance: Importance.high,
            ),
          );
      _foreground = (foregroundMessages ?? FirebaseMessaging.onMessage).listen(
        _show,
        onError: (Object _) => status.value = PosPushStatus.error,
      );
      _opened = (openedMessages ?? FirebaseMessaging.onMessageOpenedApp).listen(
        (_) => _open(),
      );
      _refresh = _messaging!.onTokenRefresh.listen((token) {
        _refreshVersion++;
        if (_authenticated && _permissionGranted) unawaited(_register(token));
      }, onError: (Object _) => status.value = PosPushStatus.error);
      _initialized = true;
      WidgetsBinding.instance.addObserver(this);
      final localLaunch = await _notifications
          .getNotificationAppLaunchDetails();
      if (localLaunch?.didNotificationLaunchApp == true) _pendingOpen = true;
      if (await _messaging!.getInitialMessage() != null) _pendingOpen = true;
    } catch (_) {
      status.value = PosPushStatus.error;
    }
  }

  /// Called only after authentication, organization selection and login navigation.
  Future<void> activate() {
    final previous = _activating ?? Future<void>.value();
    late final Future<void> task;
    task = previous
        .catchError((Object _) {})
        .then((_) => _activate())
        .whenComplete(() {
          if (identical(_activating, task)) _activating = null;
        });
    _activating = task;
    return task;
  }

  Future<void> _activate() async {
    if (!supported || _disposed) return;
    if (_authenticated && _scope != null && _scope != _session) {
      await deactivate();
    }
    if ((prefs.getString('user_id') ?? '').isEmpty ||
        (prefs.getString('instansi_id') ?? '').isEmpty)
      return;
    final expectedSession = _session;
    final startGeneration = _generation;
    await initialize();
    if (!_initialized ||
        _disposed ||
        expectedSession != _session ||
        startGeneration != _generation)
      return;
    if (_scope != _session) {
      _generation++;
      _savedToken = null;
      _seenMessages.clear();
    }
    _scope = _session;
    _authenticated = true;
    final generation = _generation;
    try {
      final permission = await _messaging!.requestPermission();
      if (!_authenticated || generation != _generation) return;
      if (permission.authorizationStatus != AuthorizationStatus.authorized &&
          permission.authorizationStatus != AuthorizationStatus.provisional) {
        _permissionGranted = false;
        status.value = PosPushStatus.denied;
        return;
      }
      _permissionGranted = true;
      final version = _refreshVersion;
      final token = await _messaging!.getToken();
      if (token != null &&
          generation == _generation &&
          version == _refreshVersion)
        await _register(token);
      else if (version != _refreshVersion)
        await _writes;
      if (_pendingOpen && _authenticated && generation == _generation) {
        _pendingOpen = false;
        onOpen?.call();
      }
    } catch (_) {
      status.value = PosPushStatus.error;
    }
  }

  Future<void> _register(String token) {
    final generation = _generation;
    _writes = _writes.then((_) async {
      if (!_authenticated ||
          _disposed ||
          generation != _generation ||
          _scope != _session ||
          token.isEmpty)
        return;
      if (_savedToken == token) return;
      try {
        _attemptedToken = token;
        await repository.register(
          token: token,
          projectId: projectId ?? Firebase.app().options.projectId,
          installationId: _installation,
        );
        if (_authenticated && generation == _generation) {
          _savedToken = token;
          await prefs.setString('pos_push_token', token);
          status.value = PosPushStatus.ready;
        }
      } catch (_) {
        if (generation == _generation) status.value = PosPushStatus.error;
      }
    });
    return _writes;
  }

  Future<void> _show(RemoteMessage message) async {
    if (!_authenticated ||
        !_permissionGranted ||
        _scope != _session ||
        _disposed)
      return;
    final notification = message.notification;
    if (notification == null) return;
    final id = message.messageId;
    if (id != null && !_seenMessages.add(id)) return;
    if (_seenMessages.length > 100) _seenMessages.remove(_seenMessages.first);
    try {
      await _notifications.show(
        id:
            (id ?? '${message.sentTime}:${notification.title}').hashCode &
            0x7fffffff,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'pantoo_pos',
            'Pantoo POS',
            icon: 'ic_notif',
            color: Color(0xFF087F75),
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: 'pos_notifications',
      );
    } catch (_) {
      status.value = PosPushStatus.error;
    }
  }

  void _open() {
    if (_disposed) return;
    if (_authenticated && _scope == _session && onOpen != null) {
      onOpen!();
    } else {
      _pendingOpen = true;
    }
  }

  Future<void> deactivate() async {
    if (!supported) return;
    _generation++;
    if (!_authenticated) return;
    _authenticated = false;
    _permissionGranted = false;
    _pendingOpen = false;
    final token =
        _attemptedToken ?? _savedToken ?? prefs.getString('pos_push_token');
    _savedToken = null;
    try {
      await _writes.timeout(const Duration(seconds: 3));
    } catch (_) {}
    if (token != null) {
      try {
        await repository
            .unregister(token: token, installationId: _installation)
            .timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
    try {
      await _messaging?.deleteToken().timeout(const Duration(seconds: 3));
    } catch (_) {}
    try {
      await _notifications.cancelAll();
    } catch (_) {}
    await prefs.remove('pos_push_token');
    status.value = PosPushStatus.unavailable;
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _disposed = true;
    _authenticated = false;
    _generation++;
    await _foreground?.cancel();
    await _opened?.cancel();
    await _refresh?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _authenticated && !_disposed) {
      unawaited(activate());
    }
  }
}
