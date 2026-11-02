import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Reports device connectivity, not an unverified promise that the API is up.
class PosPaymentConnectionBadge extends StatefulWidget {
  const PosPaymentConnectionBadge({
    super.key,
    this.changes,
    this.readConnectivity,
  });
  final Stream<List<ConnectivityResult>>? changes;
  final Future<List<ConnectivityResult>> Function()? readConnectivity;

  @override
  State<PosPaymentConnectionBadge> createState() => _BadgeState();
}

class _BadgeState extends State<PosPaymentConnectionBadge> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  List<ConnectivityResult>? _results;
  bool _changeObserved = false;

  @override
  void initState() {
    super.initState();
    final connectivity = Connectivity();
    _subscription = (widget.changes ?? connectivity.onConnectivityChanged)
        .listen(
          (results) {
            _changeObserved = true;
            if (mounted) setState(() => _results = results);
          },
          onError: (Object _) {
            _changeObserved = true;
            if (mounted) setState(() => _results = null);
          },
        );
    _readInitial(widget.readConnectivity ?? connectivity.checkConnectivity);
  }

  Future<void> _readInitial(
    Future<List<ConnectivityResult>> Function() read,
  ) async {
    try {
      final results = await read();
      if (mounted && !_changeObserved) setState(() => _results = results);
    } catch (_) {
      // Keep an honest unknown state; a plugin failure does not mean online.
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final known = _results != null;
    final available =
        _results?.any((result) => result != ConnectivityResult.none) ?? false;
    final label = !known
        ? 'Memeriksa…'
        : available
        ? 'Terhubung'
        : 'Offline';
    final hint = !known
        ? 'Status koneksi perangkat belum diketahui.'
        : available
        ? 'Jaringan perangkat tersedia. Server diperiksa saat transaksi.'
        : 'Perangkat offline. Penjualan tunai disimpan lokal dan menunggu sinkronisasi.';
    return Tooltip(
      message: hint,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              !known
                  ? Icons.help_outline
                  : available
                  ? Icons.wifi
                  : Icons.wifi_off,
              size: 12,
              color: !known
                  ? Colors.blueGrey
                  : available
                  ? Colors.teal
                  : Colors.deepOrange,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
