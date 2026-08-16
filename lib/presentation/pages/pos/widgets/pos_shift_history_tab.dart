import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/pos_shift/pos_shift_bloc.dart';
import '../../../bloc/pos_shift/pos_shift_event.dart';
import '../../../bloc/pos_shift/pos_shift_state.dart';
import 'package:intl/intl.dart';

class PosShiftHistoryTab extends StatefulWidget {
  const PosShiftHistoryTab({super.key});

  @override
  State<PosShiftHistoryTab> createState() => _PosShiftHistoryTabState();
}

class _PosShiftHistoryTabState extends State<PosShiftHistoryTab> {
  String _search = '';
  String _status = 'all';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosShiftBloc, PosShiftState>(
      builder: (context, state) {
        if (state is PosShiftLoading ||
            (state is PosShiftLoaded && state.isLoadingHistory)) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, __) => const _HistorySkeleton(),
          );
        }

        if (state is PosShiftLoaded) {
          final shifts = state.shiftHistory.where((shift) {
            final query = _search.trim().toLowerCase();
            final store = shift['toko']?['nama_toko']?.toString() ?? '';
            final cashier =
                shift['user']?['name']?.toString() ??
                shift['kasir']?['nama']?.toString() ??
                '';
            final matchesSearch =
                query.isEmpty ||
                store.toLowerCase().contains(query) ||
                cashier.toLowerCase().contains(query);
            final rawStatus = shift['status']?.toString().toLowerCase() ?? '';
            final matchesStatus = _status == 'all' || rawStatus == _status;
            return matchesSearch && matchesStatus;
          }).toList();
          if (state.shiftHistory.isEmpty) {
            return _buildEmptyState(context);
          }
          return RefreshIndicator(
            onRefresh: () async {
              context.read<PosShiftBloc>().add(ReloadShiftHistory());
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: shifts.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) return _buildFilterToolbar();
                return _buildHistoryCard(shifts[index - 1]);
              },
            ),
          );
        }

        return _buildEmptyState(context);
      },
    );
  }

  Widget _buildFilterToolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final search = SizedBox(
          height: 48,
          child: TextField(
            onChanged: (value) => setState(() => _search = value),
            decoration: InputDecoration(
              hintText: 'Cari toko atau kasir...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        );
        final filter = SizedBox(
          height: 48,
          child: DropdownButtonFormField<String>(
            initialValue: _status,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.filter_list_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Semua Status')),
              DropdownMenuItem(value: 'open', child: Text('Buka')),
              DropdownMenuItem(value: 'closed', child: Text('Tutup')),
            ],
            onChanged: (value) => setState(() => _status = value ?? 'all'),
          ),
        );
        if (constraints.maxWidth >= 680) {
          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 10),
              SizedBox(width: 190, child: filter),
            ],
          );
        }
        return Column(children: [search, const SizedBox(height: 8), filter]);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Belum ada riwayat shift',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () =>
                context.read<PosShiftBloc>().add(ReloadShiftHistory()),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> shift) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final openedAt = DateTime.tryParse(shift['opened_at'] ?? '');
    final closedAt = shift['closed_at'] != null
        ? DateTime.tryParse(shift['closed_at'])
        : null;

    final isDiffZero = (shift['cash_difference'] ?? 0) == 0;
    final diffColor = isDiffZero ? Colors.green : Colors.red;

    final isOpen = shift['status'] == 'open';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (isOpen ? Colors.green : Colors.blueGrey).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.point_of_sale_rounded,
                  color: isOpen ? Colors.green.shade700 : Colors.blueGrey,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  shift['toko']?['nama_toko'] ?? '-',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isOpen
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isOpen ? 'Buka' : 'Tutup',
                  style: TextStyle(
                    color: isOpen
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(child: _buildTimeColumn('Waktu Buka', openedAt)),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTimeColumn(
                  'Waktu Tutup',
                  closedAt,
                  alignment: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Kas Awal',
            formatCurrency.format(shift['opening_cash'] ?? 0),
          ),
          _buildInfoRow(
            'Kas Expected',
            formatCurrency.format(shift['closing_cash_expected'] ?? 0),
          ),
          if (!isOpen) ...[
            _buildInfoRow(
              'Kas Aktual',
              formatCurrency.format(shift['closing_cash_actual'] ?? 0),
            ),
            _buildInfoRow(
              'Selisih',
              formatCurrency.format(shift['cash_difference'] ?? 0),
              textColor: diffColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeColumn(
    String label,
    DateTime? time, {
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          time != null ? DateFormat('dd MMM yyyy, HH:mm').format(time) : '-',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: textColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _block(42, 42, 12),
              const SizedBox(width: 11),
              Expanded(child: _block(double.infinity, 16, 5)),
              const SizedBox(width: 12),
              _block(52, 24, 8),
            ],
          ),
          const SizedBox(height: 18),
          _block(double.infinity, 1, 0),
          const SizedBox(height: 18),
          _block(double.infinity, 13, 5),
          const SizedBox(height: 12),
          _block(double.infinity, 13, 5),
          const SizedBox(height: 12),
          _block(double.infinity, 13, 5),
        ],
      ),
    );
  }

  Widget _block(double width, double height, double radius) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
