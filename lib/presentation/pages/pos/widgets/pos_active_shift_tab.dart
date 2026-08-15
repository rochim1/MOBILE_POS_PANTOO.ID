import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/_core.dart';
import '../../../bloc/pos/pos_bloc.dart';
import '../../../bloc/pos_shift/pos_shift_bloc.dart';
import '../../../bloc/pos_shift/pos_shift_event.dart';
import '../../../bloc/pos_shift/pos_shift_state.dart';
import 'package:intl/intl.dart';

class PosActiveShiftTab extends StatefulWidget {
  const PosActiveShiftTab({super.key});

  @override
  State<PosActiveShiftTab> createState() => _PosActiveShiftTabState();
}

class _ShiftSkeleton extends StatelessWidget {
  const _ShiftSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _button()),
            const SizedBox(width: 12),
            Expanded(child: _button()),
          ],
        ),
      ],
    );
  }

  Widget _button() => Container(
    height: 46,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

class _PosActiveShiftTabState extends State<PosActiveShiftTab> {
  String? selectedTokoId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stores = context.read<PosBloc>().state.stores;
      if (stores.isNotEmpty) {
        setState(() => selectedTokoId = stores.first.id);
        context.read<PosShiftBloc>().add(LoadShiftData(stores.first.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stores = context
        .watch<PosBloc>()
        .state
        .stores
        .where((s) => s.status.toLowerCase() == 'active')
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        if (selectedTokoId != null) {
          context.read<PosShiftBloc>().add(LoadShiftData(selectedTokoId!));
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStoreSelector(stores),
            const SizedBox(height: 16),
            BlocBuilder<PosShiftBloc, PosShiftState>(
              builder: (context, state) {
                if (state is PosShiftLoading) {
                  return const _ShiftSkeleton();
                }

                if (state is PosShiftLoaded) {
                  if (state.activeShift != null) {
                    return _buildActiveShiftInfo(context, state.activeShift!);
                  }
                  return _buildOpenShiftForm(context);
                }

                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreSelector(List<dynamic> stores) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.storefront_outlined,
              color: AppColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedTokoId,
                hint: const Text('Pilih toko kasir'),
                isExpanded: true,
                isDense: true,
                items: stores
                    .map(
                      (s) => DropdownMenuItem<String>(
                        value: s.id,
                        child: Text(s.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => selectedTokoId = val);
                    context.read<PosShiftBloc>().add(LoadShiftData(val));
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveShiftInfo(
    BuildContext context,
    Map<String, dynamic> shift,
  ) {
    final openedAt = DateTime.tryParse(shift['opened_at'] ?? '');
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF10B981), Color(0xFF047857)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF059669).withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock_open_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shift sedang berjalan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Kasir siap menerima transaksi',
                          style: TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                shift['toko']?['nama_toko'] ?? '-',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                openedAt != null
                    ? 'Dibuka ${DateFormat('dd MMM, HH:mm').format(openedAt)}'
                    : 'Waktu buka tidak tersedia',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildShiftMetric(
                      'Kas seharusnya',
                      formatCurrency.format(
                        shift['closing_cash_expected'] ?? 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildShiftMetric(
                      'Transaksi',
                      '${shift['total_transaksi'] ?? 0}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildShiftMetric(
                      'Kas awal',
                      formatCurrency.format(shift['opening_cash'] ?? 0),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildShiftMetric(
                      'Kas masuk / keluar',
                      '${formatCurrency.format(shift['petty_cash_in'] ?? 0)} / ${formatCurrency.format(shift['petty_cash_out'] ?? 0)}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _promptPettyCash(context, 'in', shift['_id']),
                icon: const Icon(Icons.download, color: Colors.green),
                label: const Text(
                  'Kas Masuk',
                  style: TextStyle(color: Colors.green),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _promptPettyCash(context, 'out', shift['_id']),
                icon: const Icon(Icons.upload, color: Colors.orange),
                label: const Text(
                  'Kas Keluar',
                  style: TextStyle(color: Colors.orange),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: () => _promptCloseShift(context, shift),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Tutup Shift',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildShiftMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpenShiftForm(BuildContext context) {
    double openingCash = 0;
    String notes = '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mulai shift kasir',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Catat modal awal sebelum bertransaksi',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            keyboardType: TextInputType.number,
            inputFormatters: const [RupiahInputFormatter()],
            decoration: InputDecoration(
              labelText: 'Kas Awal (Rp)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (val) => openingCash = parseRupiah(val),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              labelText: 'Catatan Buka Shift',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: 2,
            onChanged: (val) => notes = val,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: selectedTokoId == null
                ? null
                : () {
                    context.read<PosShiftBloc>().add(
                      OpenShiftEvent(
                        tokoId: selectedTokoId!,
                        amount: openingCash,
                        notes: notes,
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Buka Shift Sekarang',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _promptPettyCash(BuildContext context, String type, String shiftId) {
    double amount = 0;
    String notes = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              type == 'in'
                  ? 'Kas Masuk (Tambah Modal)'
                  : 'Kas Keluar (Ambil Kas)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: const [RupiahInputFormatter()],
              decoration: InputDecoration(
                labelText: 'Jumlah (Rp)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) => amount = parseRupiah(val),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Keterangan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
              onChanged: (val) => notes = val,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (amount <= 0) return;
                context.read<PosShiftBloc>().add(
                  AddPettyCashEvent(
                    shiftId: shiftId,
                    type: type,
                    amount: amount,
                    notes: notes,
                    tokoId: selectedTokoId!,
                  ),
                );
                Navigator.pop(bottomSheetContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Simpan'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _promptCloseShift(BuildContext context, Map<String, dynamic> shift) {
    double actualCash =
        double.tryParse(shift['closing_cash_expected']?.toString() ?? '0') ?? 0;
    String notes = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tutup Shift',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: formatRupiahInput(actualCash),
              keyboardType: TextInputType.number,
              inputFormatters: const [RupiahInputFormatter()],
              decoration: InputDecoration(
                labelText: 'Kas Fisik Aktual (Saat Tutup)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) => actualCash = parseRupiah(val),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Catatan Tutup Shift',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 2,
              onChanged: (val) => notes = val,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<PosShiftBloc>().add(
                  CloseShiftEvent(
                    shiftId: shift['_id'],
                    actualCash: actualCash,
                    notes: notes,
                    tokoId: selectedTokoId!,
                  ),
                );
                Navigator.pop(bottomSheetContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Konfirmasi Tutup Shift',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
