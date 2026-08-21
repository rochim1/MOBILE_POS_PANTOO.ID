import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _syncService.getOfflineTransactions(status: _status);
    if (!mounted) return;
    setState(() {
      _transactions = items;
      _loading = false;
    });
  }

  Future<void> _sync() async {
    setState(() => _loading = true);
    await _syncService.syncOfflineTransactions();
    await _load();
    if (mounted) {
      AppToast.success(context, 'Sinkronisasi antrean selesai diperiksa');
    }
  }

  Future<void> _retryAll() async {
    final count = await _syncService.retryAllRejected();
    if (count > 0) await _syncService.syncOfflineTransactions();
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
              if ((transaction['error']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  transaction['error'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.red),
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
      'synced' => ('Terkirim', Colors.green),
      'syncing' => ('Diproses', Colors.blue),
      'needs_review' => ('Perlu ditinjau', Colors.deepOrange),
      'rejected' => ('Ditolak', Colors.red),
      _ => ('Menunggu', Colors.orange),
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
                  color: Colors.red,
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
