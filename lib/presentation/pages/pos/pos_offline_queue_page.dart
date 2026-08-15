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
    final count = await _syncService.retryAllFailed();
    if (count > 0) await _syncService.syncOfflineTransactions();
    await _load();
    if (mounted) {
      AppToast.info(
        context,
        '$count transaksi gagal dimasukkan kembali ke antrean',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const PosAppBarTitle(
          title: 'Antrean Offline',
          subtitle: 'Audit dan sinkronisasi transaksi',
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
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
                      _filterChip('failed_permanent', 'Gagal'),
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
                        label: const Text('Coba ulang semua gagal'),
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
    final total = _findValue(payload, const [
      'total',
      'grand_total',
      'total_bayar',
    ]);
    final reference = _findValue(payload, const [
      'nomor_invoice',
      'invoice_number',
      'client_transaction_id',
    ]);
    final canRetry = status != 'synced' && status != 'syncing';
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _showDetails(transaction, payload),
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
      'failed_permanent' => ('Gagal', Colors.red),
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

  void _showDetails(Map<String, dynamic> transaction, dynamic payload) {
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
