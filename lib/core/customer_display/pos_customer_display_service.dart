import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../network/graphql_client_provider.dart';

enum PosCustomerDisplayConnection { disconnected, connecting, waiting, connected, error }

class PosCustomerDisplayState {
  final PosCustomerDisplayConnection connection;
  final String pairingUrl;
  final String message;

  const PosCustomerDisplayState({
    this.connection = PosCustomerDisplayConnection.disconnected,
    this.pairingUrl = '',
    this.message = '',
  });

  bool get isActive => connection == PosCustomerDisplayConnection.waiting ||
      connection == PosCustomerDisplayConnection.connected;
}

/// Relays the cashier cart to a paired, browser-only customer display.
/// Pairing tokens are short-lived in memory and never grant API access.
class PosCustomerDisplayService {
  PosCustomerDisplayService(this._network, this._secureStorage);

  final GraphQLClientProvider _network;
  final FlutterSecureStorage _secureStorage;
  final ValueNotifier<PosCustomerDisplayState> state =
      ValueNotifier(const PosCustomerDisplayState());

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  String _pairingToken = '';
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  Timer? _handshakeTimer;
  bool _manualDisconnect = false;
  int _reconnectAttempts = 0;

  Future<PosCustomerDisplayState> beginPairing() async {
    await disconnect();
    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null || token.trim().isEmpty) {
      return _terminalFailure('Sesi POS tidak tersedia. Login kembali terlebih dahulu.');
    }

    _manualDisconnect = false;
    _pairingToken = const Uuid().v4().replaceAll('-', '');
    final connected = await _connect(token, isInitialConnection: true);
    if (!connected) {
      return _terminalFailure('Tidak dapat menghubungkan layanan layar pelanggan.');
    }
    return state.value;
  }

  Future<bool> _connect(
    String token, {
    bool isInitialConnection = false,
  }) async {
    if (_pairingToken.isEmpty || _manualDisconnect) return false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    state.value = PosCustomerDisplayState(
      connection: PosCustomerDisplayConnection.connecting,
      pairingUrl: _pairingUrl(_pairingToken),
      message: isInitialConnection ? '' : 'Menghubungkan ulang layar pelanggan…',
    );

    try {
      await _disposeSocket();
      final endpoint = Uri.parse(_network.endpointUrl);
      final socketUri = endpoint.replace(
        scheme: endpoint.scheme == 'https' ? 'wss' : 'ws',
        path: '/notifications',
        query: null,
        fragment: null,
      );
      final channel = WebSocketChannel.connect(socketUri);
      _channel = channel;
      _subscription = channel.stream.listen(
        _onMessage,
        onError: (_) => _handleSocketLoss(channel),
        onDone: () => _handleSocketLoss(channel),
        cancelOnError: true,
      );
      await channel.ready;
      if (!identical(_channel, channel)) return false;
      _send(channel, {
        'type': 'auth',
        'token': token,
        'client_type': 'mobile',
      });
      _handshakeTimer?.cancel();
      _handshakeTimer = Timer(const Duration(seconds: 8), () {
        if (identical(_channel, channel) &&
            state.value.connection == PosCustomerDisplayConnection.connecting) {
          _handleSocketLoss(channel);
          unawaited(channel.sink.close());
        }
      });
      return true;
    } catch (_) {
      if (!isInitialConnection) _scheduleReconnect();
      return false;
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final message = Map<String, dynamic>.from(jsonDecode(raw.toString()) as Map);
      final type = message['type']?.toString();
      if (type == 'auth_success') {
        _send(_channel, {
          'type': 'customer_display_host',
          'pairing_token': _pairingToken,
        });
      } else if (type == 'customer_display_host_ready') {
        _handshakeTimer?.cancel();
        _handshakeTimer = null;
        _reconnectAttempts = 0;
        state.value = PosCustomerDisplayState(
          connection: PosCustomerDisplayConnection.waiting,
          pairingUrl: _pairingUrl(_pairingToken),
        );
        _startPing();
      } else if (type == 'customer_display_connected') {
        state.value = PosCustomerDisplayState(
          connection: PosCustomerDisplayConnection.connected,
          pairingUrl: _pairingUrl(_pairingToken),
        );
      } else if (type == 'customer_display_disconnected') {
        state.value = PosCustomerDisplayState(
          connection: PosCustomerDisplayConnection.waiting,
          pairingUrl: _pairingUrl(_pairingToken),
        );
      } else if (type == 'customer_display_error') {
        _terminalFailure(message['message']?.toString() ?? 'Pairing gagal.');
      }
    } catch (_) {
      // Other notification messages do not belong to the customer display.
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _send(_channel, const {'type': 'ping'});
    });
  }

  void _handleSocketLoss(WebSocketChannel source) {
    if (!identical(_channel, source) || _manualDisconnect || _pairingToken.isEmpty) {
      return;
    }
    _pingTimer?.cancel();
    _pingTimer = null;
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    _channel = null;
    _subscription = null;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || _pairingToken.isEmpty || _reconnectTimer != null) return;
    if (_reconnectAttempts >= 3) {
      _terminalFailure('Koneksi layar pelanggan terputus. Buat pairing baru untuk mencoba lagi.');
      return;
    }
    _reconnectAttempts += 1;
    state.value = PosCustomerDisplayState(
      connection: PosCustomerDisplayConnection.connecting,
      pairingUrl: _pairingUrl(_pairingToken),
      message: 'Koneksi terputus. Menghubungkan ulang ($_reconnectAttempts/3)…',
    );
    _reconnectTimer = Timer(const Duration(seconds: 3), () async {
      _reconnectTimer = null;
      final token = await _secureStorage.read(key: 'auth_token');
      if (token == null || token.trim().isEmpty) {
        _terminalFailure('Sesi POS berakhir. Login kembali untuk menghubungkan layar pelanggan.');
        return;
      }
      await _connect(token);
    });
  }

  void publishCart({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double total,
    required String storeName,
    String status = 'cart',
  }) {
    if (!state.value.isActive || _pairingToken.isEmpty) return;
    _send(_channel, {
      'type': 'customer_display_state',
      'pairing_token': _pairingToken,
      'data': {
        'items': items,
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'store_name': storeName,
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
    });
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    if (_pairingToken.isNotEmpty) {
      _send(_channel, {
        'type': 'customer_display_stop',
        'pairing_token': _pairingToken,
      });
    }
    _pairingToken = '';
    await _disposeSocket();
    state.value = const PosCustomerDisplayState();
  }

  Future<void> _disposeSocket() async {
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    final channel = _channel;
    _channel = null;
    try {
      await _subscription?.cancel().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Do not keep the POS UI waiting for a broken network subscription.
    }
    _subscription = null;
    try {
      await channel?.sink.close().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Socket close is best-effort. The server expiry guard cleans stale peers.
    }
  }

  PosCustomerDisplayState _terminalFailure(String message) {
    _manualDisconnect = true;
    _pingTimer?.cancel();
    _pingTimer = null;
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    if (_pairingToken.isNotEmpty) {
      _send(_channel, {
        'type': 'customer_display_stop',
        'pairing_token': _pairingToken,
      });
    }
    _pairingToken = '';
    unawaited(_disposeSocket());
    final failed = PosCustomerDisplayState(
      connection: PosCustomerDisplayConnection.error,
      message: message,
    );
    state.value = failed;
    return failed;
  }

  void _send(WebSocketChannel? channel, Map<String, dynamic> payload) {
    if (channel == null) return;
    try {
      channel.sink.add(jsonEncode(payload));
    } catch (_) {
      _handleSocketLoss(channel);
    }
  }

  String _pairingUrl(String token) {
    final endpoint = Uri.parse(_network.endpointUrl);
    final localHost = endpoint.host == 'localhost' || endpoint.host == '127.0.0.1';
    final origin = endpoint.host == 'graphql.pantoo.id'
        ? Uri.parse('https://app.pantoo.id')
        : localHost
            ? endpoint.replace(port: 5173, path: '/', query: null, fragment: null)
            : endpoint.replace(path: '/', query: null, fragment: null);
    return origin
        .replace(path: '/pos/customer-display', queryParameters: {'pair': token})
        .toString();
  }
}
