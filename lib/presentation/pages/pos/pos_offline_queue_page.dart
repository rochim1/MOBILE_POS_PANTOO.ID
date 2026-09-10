import 'dart:convert';
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import '../../widgets/pos_ui.dart';
import '../../widgets/app_toast.dart';
import 'package:mobile_pos_pantoo/core/network/sync_service.dart';
import 'package:mobile_pos_pantoo/injections.dart';

class PosOfflineQueuePage extends StatefulWidget {
  const PosOfflineQueuePage({super.key});

  @override
  State<PosOfflineQueuePage> createState() => _PosOfflineQueuePageState();
}

class _PosOfflineQueuePageState extends State<PosOfflineQueuePage> {
  final _syncService = sl<SyncService>();
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  String? _status;
  Map<String, dynamic> _summary = const {};
  bool _networkAvailable = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      if (!mounted) return;
      setState(
        () => _networkAvailable = !result.contains(ConnectivityResult.none),
      );
    });
    _load();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait<dynamic>([
      _syncService.getOfflineTransactions(status: _status),
      _syncService.getQueueSummary(),
      Connectivity().checkConnectivity(),
    ]);
    if (!mounted) return;
    setState(() {
      _transactions = results[0] as List<Map<String, dynamic>>;
      _summary = results[1] as Map<String, dynamic>;
      _networkAvailable = !(results[2] as List<ConnectivityResult>).contains(
        ConnectivityResult.none,
      );
      _loading = false;
    });
  }

  Future<void> _sync() async {
    setState(() => _loading = true);
    await _syncService.syncOfflineTransactions(force: true);
    await _load();
    if (mounted) {
      AppToast.success(context, 'Sinkronisasi antrean selesai diperiksa');
    }
  }

  Future<void> _retryAll() async {
    final count = await _syncService.retryAllRejected();
    if (count > 0) {
      await _syncService.syncOfflineTransactions(force: true);
    }
    await _load();
    if (mounted) {
      AppToast.info(
        context,
        '$count transaksi ditolak dimasukkan kembali ke antrean',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgPrimary,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _queueHealthCard(),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip(null, 'Semua'),
                      _filterChip('pending', 'Menunggu'),
                      _filterChip('syncing', 'Diproses'),
                      _filterChip('needs_review', 'Perlu ditinjau'),
                      _filterChip('rejected', 'Ditolak'),
                      _filterChip('synced', 'Terkirim'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _retryAll,
                        icon: const Icon(Icons.replay),
                        label: const Text('Coba ulang yang ditolak'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _loading ? null : _sync,
                        icon: const Icon(Icons.sync),
                        label: const Text('Sinkronkan sekarang'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const PosSkeletonList(count: 5)
                : _transactions.isEmpty
                ? PosEmptyState(
                    icon: Icons.cloud_done_outlined,
                    title: 'Antrean transaksi kosong',
                    message: _status == null
                        ? 'Semua transaksi lokal sudah selesai diproses.'
                        : 'Tidak ada transaksi dengan status yang dipilih.',
                    actionLabel: _status == null ? null : 'Lihat semua',
                    onAction: _status == null
                        ? null
                        : () {
                            setState(() => _status = null);
                            _load();
                          },
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, index) =>
                          _transactionCard(_transactions[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _queueHealthCard() {
    final unresolved = (_summary['unresolved'] as num?)?.toInt() ?? 0;
    final review = (_summary['needs_review'] as num?)?.toInt() ?? 0;
    final oldestRaw = _summary['oldest_pending_at']?.toString();
    final oldest = oldestRaw == null ? null : DateTime.tryParse(oldestRaw);
    final age = oldest == null ? null : DateTime.now().difference(oldest);
    final ageLabel = age == null
        ? null
        : age.inDays > 0
        ? '${age.inDays} hari'
        : age.inHours > 0
        ? '${age.inHours} jam'
        : '${age.inMinutes.clamp(1, 59)} menit';
    final color = !_networkAvailable
        ? AppColors.warning
        : review > 0
        ? Colors.deepOrange
        : unresolved > 0
        ? AppColors.info
        : AppColors.success;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .09),
        border: Border.all(color: color.withValues(alpha: .28)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _networkAvailable ? Icons.cloud_outlined : Icons.cloud_off_outlined,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _networkAvailable
                      ? 'Koneksi perangkat tersedia'
                      : 'Perangkat sedang offline',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  unresolved == 0
                      ? 'Tidak ada transaksi penjualan yang menunggu.'
                      : '$unresolved transaksi belum selesai${ageLabel == null ? '' : ' • tertua $ageLabel'}${review == 0 ? '' : ' • $review perlu ditinjau'}',
                  style: const TextStyle(fontSize: 12.5),
                ),
                if (_networkAvailable)
                  const Text(
                    'Ketersediaan server diperiksa saat sinkronisasi.',
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                const SizedBox(height: 4),
                const Text(
                  'Cakupan offline: penjualan tunai kasir. Pembayaran elektronik, shift, pelanggan, dan perubahan inventori wajib online.',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String? status, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _status == status,
        onSelected: (_) {
          setState(() => _status = status);
          _load();
        },
      ),
    );
  }

  Widget _transactionCard(Map<String, dynamic> transaction) {
    final status = transaction['status']?.toString() ?? 'pending';
    final payload = _decodePayload(transaction['payload']);
    final clientSnapshot = _decodePayload(transaction['client_snapshot']);
    final total = _findValue(clientSnapshot, const [
      'total',
      'grand_total',
      'total_bayar',
    ]);
    final reference = _findValue(payload, const [
      'nomor_invoice',
      'invoice_number',
      'client_transaction_id',
    ]);
    final rejectedByOperator =
        transaction['resolution']?.toString() == 'rejected_by_operator';
    final canRetry =
        status == 'pending' || (status == 'rejected' && !rejectedByOperator);
    final needsReview = status == 'needs_review';
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showDetails(transaction, payload, clientSnapshot),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reference?.toString() ??
                          'Transaksi lokal #${transaction['id']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 8),
              Text('Waktu: ${transaction['timestamp'] ?? '-'}'),
              if (total != null) Text('Total: Rp $total'),
              Text('Percobaan sinkron: ${transaction['attempts'] ?? 0}'),
              if ((transaction['next_retry_at']?.toString() ?? '').isNotEmpty &&
                  status == 'pending')
                Text('Retry otomatis: ${transaction['next_retry_at']}'),
              if ((transaction['error']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  transaction['error'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ],
              if (canRetry)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () async {
                      await _syncService.retryTransaction(
                        transaction['id'] as int,
                      );
                      await _load();
                    },
                    icon: const Icon(Icons.replay),
                    label: const Text('Coba ulang'),
                  ),
                ),
              if (needsReview)
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => _rejectAfterReview(transaction),
                        child: const Text('Tolak transaksi'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _retryAfterReview(transaction),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Tinjau & kirim ulang'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final (label, color) = switch (status) {
      'synced' => ('Terkirim', AppColors.success),
      'syncing' => ('Diproses', AppColors.info),
      'needs_review' => ('Perlu ditinjau', Colors.deepOrange),
      'rejected' => ('Ditolak', AppColors.danger),
      _ => ('Menunggu', AppColors.warning),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showDetails(
    Map<String, dynamic> transaction,
    dynamic payload,
    dynamic clientSnapshot,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Detail transaksi #${transaction['id']}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('Status: ${transaction['status']}'),
            Text('Outlet: ${transaction['toko_id'] ?? '-'}'),
            Text('Shift: ${transaction['shift_id'] ?? '-'}'),
            Text('Percobaan: ${transaction['attempts'] ?? 0}'),
            if ((transaction['resolution']?.toString() ?? '').isNotEmpty)
              Text('Keputusan: ${transaction['resolution']}'),
            if ((transaction['server_response']?.toString() ?? '').isNotEmpty)
              Text('Respons server: ${transaction['server_response']}'),
            if ((transaction['error']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Error',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.danger,
                ),
              ),
              SelectableText(transaction['error'].toString()),
            ],
            const SizedBox(height: 16),
            const Text(
              'Snapshot saat pembayaran',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SelectableText(
              const JsonEncoder.withIndent('  ').convert(clientSnapshot),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payload lokal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SelectableText(const JsonEncoder.withIndent('  ').convert(payload)),
          ],
        ),
      ),
    );
  }

  Future<void> _retryAfterReview(Map<String, dynamic> transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kirim ulang transaksi?'),
        content: const Text(
          'Pastikan harga, stok, promo, pelanggan, dan shift sudah diperbaiki. '
          'Server akan menghitung dan memvalidasi ulang transaksi ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Kirim ulang'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _syncService.retryTransaction(transaction['id'] as int);
    await _load();
  }

  Future<void> _rejectAfterReview(Map<String, dynamic> transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tolak transaksi lokal?'),
        content: const Text(
          'Transaksi tidak akan dikirim ke server, tetapi tetap disimpan sebagai '
          'jejak audit pada perangkat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _syncService.rejectTransaction(transaction['id'] as int);
    await _load();
  }

  dynamic _decodePayload(dynamic raw) {
    try {
      return jsonDecode(raw?.toString() ?? '{}');
    } catch (_) {
      return {'raw': raw?.toString()};
    }
  }

  dynamic _findValue(dynamic value, List<String> keys) {
    if (value is Map) {
      for (final key in keys) {
        if (value[key] != null) return value[key];
      }
      for (final nested in value.values) {
        final found = _findValue(nested, keys);
        if (found != null) return found;
      }
    } else if (value is List) {
      for (final nested in value) {
        final found = _findValue(nested, keys);
        if (found != null) return found;
      }
    }
    return null;
  }
}
