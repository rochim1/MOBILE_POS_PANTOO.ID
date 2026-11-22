import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'pos_subscription.dart';
import 'pos_trusted_clock.dart';

const posSubscriptionQuery = r'''query GetSubscriptionStatus {
  GetSubscriptionStatus {
    subscription_status access_level effective_state is_owner package_name
    days_remaining server_now expires_at operational_until read_only_until
    offline_valid_until
  }
}''';

/// One state source for startup, lifecycle, banners, checkout and offline queue.
/// A secure, tenant/operator-specific cache is bounded by the server's deadline.
class PosSubscriptionService extends ChangeNotifier {
  PosSubscriptionService({
    required this.fetch,
    required this.readScope,
    required this.storage,
    DateTime Function()? clock,
    Future<PosTrustedClockStamp?> Function()? trustedClock,
  }) : clock = clock ?? DateTime.now,
       trustedClock = trustedClock ?? PosTrustedClockStamp.read;
  final Future<PosTrustedClockStamp?> Function() trustedClock;
  PosTrustedClockStamp? _trustedAnchor;
  final Future<Map<String, dynamic>> Function() fetch;
  final String Function() readScope;
  final FlutterSecureStorage storage;
  final DateTime Function() clock;
  String _scope = '';
  PosSubscription? _snapshot;
  DateTime? _anchor;
  DateTime? _checkedDeviceAt;
  Stopwatch? _elapsed;
  Future<void>? _inFlight;
  Future<void>? _activation;
  int _revision = 0;
  bool _disposed = false;
  bool initialized = false, checking = false, offline = false;
  String? error;
  Timer? _deadline;
  final ValueNotifier<int> recovered = ValueNotifier(0);

  PosSubscription? get snapshot => _scope == readScope() ? _snapshot : null;
  bool get required => readScope().isNotEmpty;
  DateTime get serverNow =>
      (_anchor ?? clock().toUtc()).add(_elapsed?.elapsed ?? Duration.zero);
  String get accessLevel => snapshot?.levelAt(serverNow) ?? 'unknown';
  bool get canSell =>
      !required ||
      (accessLevel == 'full' &&
          snapshot != null &&
          serverNow.isBefore(snapshot!.offlineValidUntil));
  bool get canRead => accessLevel == 'full' || accessLevel == 'read_only';
  bool get recoveryOnly => !canRead && accessLevel != 'unknown';
  bool get isOwner => snapshot?.isOwner == true;
  bool get showWarning =>
      required &&
      (offline ||
          error != null ||
          snapshot?.warningAt(serverNow) == true ||
          !canSell);
  DateTime? get lastCheckedAt => _checkedDeviceAt;
  String get denialMessage => accessLevel == 'unknown' || accessLevel == 'full'
      ? posSubscriptionUnverifiedMessage
      : posSubscriptionBlockedMessage;
  String get _cacheKey => 'pos_subscription:${Uri.encodeComponent(_scope)}';

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void _tick() {
    _deadline?.cancel();
    _deadline = Timer(const Duration(seconds: 30), () {
      _emit();
      _tick();
    });
  }

  Future<void> activate() {
    if (_scope == readScope() && _activation != null) return _activation!;
    late final Future<void> future;
    future = _activateScope().whenComplete(() {
      if (identical(_activation, future)) _activation = null;
    });
    _activation = future;
    return future;
  }

  /// Known restrictions may open billing/recovery. An unknown status must not
  /// be mistaken for expiry or expose the private workspace on first login.
  Future<bool> prepareLogin() async {
    if (!required) return true;
    await activate();
    return canSell || accessLevel == 'read_only' || recoveryOnly;
  }

  Future<void> _activateScope() async {
    final next = readScope();
    if (_scope != next) {
      _revision++;
      _scope = next;
      _snapshot = null;
      _trustedAnchor = null;
      _anchor = null;
      _elapsed = null;
      _checkedDeviceAt = null;
      initialized = false;
      checking = false;
      offline = false;
      error = null;
      _inFlight = null;
      _deadline?.cancel();
      _emit();
      if (next.isEmpty) {
        initialized = true;
        return;
      }
      final revision = _revision;
      try {
        final raw = await storage.read(key: _cacheKey);
        if (revision != _revision || _scope != readScope() || _disposed) return;
        if (raw != null) {
          final saved = jsonDecode(raw) as Map;
          final stamp = await trustedClock();
          if (revision != _revision || _scope != readScope() || _disposed) {
            return;
          }
          final previousMs = saved['elapsed_ms'];
          final validClock =
              stamp != null &&
              previousMs is int &&
              saved['boot'] == stamp.boot &&
              stamp.elapsedMs >= previousMs;
          final elapsed = Duration(
            milliseconds: validClock ? stamp.elapsedMs - previousMs : -1,
          );
          if (validClock && elapsed <= const Duration(hours: 24)) {
            _snapshot = PosSubscription.fromJson(
              Map<String, dynamic>.from(saved['status'] as Map),
            );
            _anchor = _snapshot!.serverNow.add(elapsed);
            _elapsed = Stopwatch()..start();
            _trustedAnchor = PosTrustedClockStamp(stamp.boot, previousMs);
            _checkedDeviceAt = clock().toUtc().subtract(elapsed);
            offline = true;
            if (!canSell) {
              _snapshot = null;
              await storage.delete(key: _cacheKey);
            }
          } else {
            await storage.delete(key: _cacheKey);
          }
        }
      } catch (_) {
        /* No cache is safer than trusting a damaged snapshot. */
      }
    }
    if (next.isNotEmpty && !_disposed) {
      _tick();
      await _startRefresh();
    }
  }

  void pause() {
    _deadline?.cancel();
  }

  void deactivate() {
    _revision++;
    _scope = '';
    _snapshot = null;
    _trustedAnchor = null;
    _anchor = null;
    _elapsed = null;
    _checkedDeviceAt = null;
    _inFlight = null;
    _activation = null;
    _deadline?.cancel();
    initialized = false;
    checking = false;
    offline = false;
    error = null;
    _emit();
  }

  Future<void> refresh() {
    if (_disposed || readScope().isEmpty) return Future.value();
    if (_scope != readScope()) return activate();
    if (!initialized && _activation != null) return _activation!;
    return _startRefresh();
  }

  /// Start a nearly-stale access check while the cashier is choosing payment.
  /// This is only a warm-up: mutation/offline guards still authorize the write.
  Future<void> prepareCheckout() async {
    if (_disposed || !required) return;
    if (!initialized || _scope != readScope()) {
      await activate();
      return;
    }
    final revision = _revision;
    await _advanceTrustedTime(revision);
    if (_disposed || revision != _revision || _scope != readScope()) return;
    if (offline ||
        error != null ||
        _checkedDeviceAt == null ||
        clock().toUtc().difference(_checkedDeviceAt!) >=
            const Duration(seconds: 45)) {
      await refresh();
    }
  }

  Future<void> _startRefresh() {
    final revision = _revision;
    return _inFlight ??= _refresh(revision).whenComplete(() {
      if (!_disposed && revision == _revision && _scope == readScope()) {
        _inFlight = null;
      }
    });
  }

  Future<void> _refresh(int revision) async {
    final wasRestricted = initialized && !canSell;
    checking = true;
    _emit();
    await _advanceTrustedTime(revision);
    try {
      final json = await fetch().timeout(const Duration(seconds: 12));
      final stamp = await trustedClock();
      if (_disposed || revision != _revision || _scope != readScope()) return;
      final value = PosSubscription.fromJson(json);
      _snapshot = value;
      _trustedAnchor = stamp;
      _anchor = value.serverNow;
      _elapsed = Stopwatch()..start();
      _checkedDeviceAt = clock().toUtc();
      offline = false;
      error = null;
      // A persisted grant contains no credentials and is isolated by identity.
      try {
        await storage.write(
          key: _cacheKey,
          value: jsonEncode({
            'saved_at': _checkedDeviceAt!.toIso8601String(),
            'boot': stamp?.boot,
            'elapsed_ms': stamp?.elapsedMs,
            'status': json,
          }),
        );
      } catch (_) {
        /* The online result remains usable without persistence. */
      }
      if (_disposed || revision != _revision || _scope != readScope()) return;
      initialized = true;
      if (wasRestricted && canSell) recovered.value++;
    } catch (_) {
      if (_disposed || revision != _revision || _scope != readScope()) return;
      offline = true;
      error = posSubscriptionUnverifiedMessage;
    } finally {
      if (!_disposed && revision == _revision && _scope == readScope()) {
        checking = false;
        initialized = true;
        _emit();
      }
    }
  }

  void handleRequired(Map<String, dynamic> extensions, {String? requestScope}) {
    if (_disposed ||
        !required ||
        _scope != readScope() ||
        (requestScope != null && requestScope != _scope)) {
      return;
    }
    final level = extensions['access_level']?.toString();
    if (checking && accessLevel == level) return;
    _revision++;
    _inFlight = null;
    _activation = null;
    unawaited(storage.delete(key: _cacheKey));
    if (const ['read_only', 'billing_only', 'blocked'].contains(level)) {
      final current = snapshot;
      _snapshot = PosSubscription(
        accessLevel: level!,
        effectiveState: extensions['effective_state']?.toString() ?? 'recovery',
        serverNow: serverNow,
        offlineValidUntil: serverNow,
        isOwner: current?.isOwner ?? false,
        packageName: current?.packageName ?? '',
        expiresAt: current?.expiresAt,
        operationalUntil: DateTime.tryParse(
          extensions['operational_until']?.toString() ?? '',
        ),
        readOnlyUntil: DateTime.tryParse(
          extensions['read_only_until']?.toString() ?? '',
        ),
      );
      _anchor = _snapshot!.serverNow;
      _elapsed = Stopwatch()..start();
      initialized = true;
      error = null;
      _emit();
    }
    unawaited(refresh());
  }

  Future<GraphQLError?> guardMutation(Set<String> fields) async {
    if (!required || fields.every(posSubscriptionRecoveryMutations.contains)) {
      return null;
    }
    if (!initialized || _scope != readScope()) await activate();
    await _advanceTrustedTime(_revision);
    // Refresh stale state before an online write, without rechecking every keystroke.
    if (_checkedDeviceAt == null ||
        clock().toUtc().difference(_checkedDeviceAt!) >
            const Duration(minutes: 1)) {
      await refresh();
    }
    if (canSell) return null;
    return GraphQLError(
      message: denialMessage,
      extensions: {
        'code': 'SUBSCRIPTION_REQUIRED',
        'access_level': accessLevel,
      },
    );
  }

  Future<String?> guardOfflineWrite() async {
    if (!required) return null;
    if (!initialized || _scope != readScope()) await activate();
    await _advanceTrustedTime(_revision);
    return canSell && _trustedAnchor != null ? null : denialMessage;
  }

  Future<void> _advanceTrustedTime(int revision) async {
    final anchor = _trustedAnchor;
    if (anchor == null || snapshot == null) return;
    final stamp = await trustedClock();
    if (_disposed || revision != _revision || _scope != readScope()) return;
    if (stamp == null ||
        stamp.boot != anchor.boot ||
        stamp.elapsedMs < anchor.elapsedMs) {
      _snapshot = null;
      _trustedAnchor = null;
      await storage.delete(key: _cacheKey);
      return;
    }
    final monotonicNow = _snapshot!.serverNow.add(
      Duration(milliseconds: stamp.elapsedMs - anchor.elapsedMs),
    );
    // Never move backwards when switching from the process stopwatch.
    if (monotonicNow.isAfter(serverNow)) {
      _anchor = monotonicNow;
      _elapsed = Stopwatch()..start();
    }
    if (!canSell) await storage.delete(key: _cacheKey);
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    _deadline?.cancel();
    _elapsed?.stop();
    recovered.dispose();
    super.dispose();
  }
}
