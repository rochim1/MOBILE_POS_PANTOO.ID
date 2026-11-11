import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import '../../widgets/pos_ui.dart';
import '../../bloc/pos_return/pos_return_bloc.dart';
import '../../bloc/pos_return/pos_return_event.dart';
import '../../bloc/pos_return/pos_return_state.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_return_draft_recovery.dart';
import 'package:intl/intl.dart';

class PosAddReturnPage extends StatefulWidget {
  const PosAddReturnPage({super.key});

  @override
  State<PosAddReturnPage> createState() => _PosAddReturnPageState();
}

class _PosAddReturnPageState extends State<PosAddReturnPage> {
  final TextEditingController _invoiceController = TextEditingController();
  String _alasan = 'cacat';
  String _metodeRefund = 'tunai';
  final TextEditingController _catatanController = TextEditingController();
  bool _completionHandled = false;

  @override
  void dispose() {
    _invoiceController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  String _formatCurrency(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title:  PosAppBarTitle(
          title: ('Tambah Retur').tr(context),
          subtitle: ('Pilih invoice dan item').tr(context),
        ),
      ),
      bottomNavigationBar: BlocConsumer<PosReturnBloc, PosReturnState>(
        listener: (context, state) {
          if (state.status == PosReturnStatus.success &&
              state.searchResult == null &&
              !_completionHandled) {
            // ReloadReturns can succeed before this dialog's exit animation
            // finishes. Never pop the underlying POS route a second time.
            _completionHandled = true;
            AppToast.success(
              context,
              'Retur terkonfirmasi. Periksa status pada daftar; pengajuan dan refund tetap terpisah.',
            );
            Navigator.pop(context, true);
          } else if (state.status == PosReturnStatus.failure &&
              state.errorMessage.isNotEmpty) {
            AppToast.error(context, state.errorMessage);
          }
        },
        builder: (context, state) {
          final hasSelected = state.returnItems.any(
            (i) => i['selected'] == true && i['qty_returned'] > 0,
          );
          final pending = state.pendingDraft != null;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE8EBEE))),
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed:
                    ((!pending &&
                            (state.searchResult == null || !hasSelected)) ||
                        state.pendingDraftError.isNotEmpty ||
                        state.status == PosReturnStatus.loading)
                    ? null
                    : () {
                        if (pending) {
                          context.read<PosReturnBloc>().add(
                            const RecoverReturnDraft(),
                          );
                          return;
                        }
                        context.read<PosReturnBloc>().add(
                          SubmitReturn(
                            alasan: _alasan,
                            metodeRefund:
                                _metodeRefund == 'kredit_store' &&
                                    state.searchResult?['sales_invoice_id'] ==
                                        null
                                ? 'tunai'
                                : _metodeRefund,
                            catatan: _catatanController.text,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: state.status == PosReturnStatus.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        pending ? ('Pulihkan draft retur').tr(context) : ('Simpan Draft Retur').tr(context),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
      body: BlocBuilder<PosReturnBloc, PosReturnState>(
        builder: (context, state) {
          if (state.pendingDraft != null ||
              state.pendingDraftError.isNotEmpty) {
            return const SingleChildScrollView(child: PosReturnDraftRecovery());
          }
          return AbsorbPointer(
            absorbing: state.status == PosReturnStatus.loading,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Pencarian Invoice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PosText(
                          'Cari Invoice',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _invoiceController,
                                decoration: InputDecoration(
                                  hintText: ('Masukkan No. Invoice...').tr(context),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                if (_invoiceController.text.isNotEmpty) {
                                  context.read<PosReturnBloc>().add(
                                    SearchInvoice(_invoiceController.text),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const PosText('Cari'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  BlocBuilder<PosReturnBloc, PosReturnState>(
                    builder: (context, state) {
                      if (state.status == PosReturnStatus.loading &&
                          state.searchResult == null) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (state.searchResult == null) {
                        return const SizedBox.shrink();
                      }

                      final trx = state.searchResult!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Detail Invoice
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.infoBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  posLocale(context).posee94ad7e244c((trx['invoice']).toString()),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  posLocale(context).pose8576d8afa6c((trx['pelanggan'] ?? 'Umum').toString()),
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                Text(
                                  posLocale(context).pos596318639b9f((_formatCurrency(trx['total'] ?? 0)).toString()),
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Item Selection
                          const PosText(
                            'Pilih Item Diretur:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...state.returnItems.map((item) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: item['selected'] == true,
                                          onChanged: (val) {
                                            context.read<PosReturnBloc>().add(
                                              SelectReturnItem(
                                                item['inventaris_id'],
                                                val ?? false,
                                              ),
                                            );
                                          },
                                        ),
                                        Expanded(
                                          child: Text(
                                            item['nama_inventaris'] ?? '-',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          posLocale(context).posbc47f5da0ae0((item['qty_original']).toString(), (item['unit']).toString()),
                                        ),
                                      ],
                                    ),
                                    if (item['selected'] == true) ...[
                                      const Divider(),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const PosText(
                                                  'Qty Retur',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                TextFormField(
                                                  initialValue:
                                                      item['qty_returned']
                                                          .toString(),
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration:
                                                      const InputDecoration(
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.all(8),
                                                      ),
                                                  onChanged: (val) {
                                                    final qty =
                                                        double.tryParse(val) ??
                                                        0;
                                                    context.read<PosReturnBloc>().add(
                                                      UpdateReturnItem(
                                                        inventarisId:
                                                            item['inventaris_id'],
                                                        qtyReturned: qty,
                                                        kondisi:
                                                            item['kondisi'],
                                                        masukKeStok:
                                                            item['masuk_ke_stok'],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const PosText(
                                                  'Kondisi',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                DropdownButtonFormField<String>(
                                                  initialValue: item['kondisi'],
                                                  decoration:
                                                      const InputDecoration(
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.all(8),
                                                      ),
                                                  items: const [
                                                    DropdownMenuItem(
                                                      value: 'baik',
                                                      child: PosText('Baik'),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'rusak_ringan',
                                                      child: PosText(
                                                        'Rusak Ringan',
                                                      ),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'rusak_berat',
                                                      child: PosText(
                                                        'Rusak Berat',
                                                      ),
                                                    ),
                                                    DropdownMenuItem(
                                                      value: 'tidak_layak',
                                                      child: PosText(
                                                        'Tidak Layak',
                                                      ),
                                                    ),
                                                  ],
                                                  onChanged: (val) {
                                                    context.read<PosReturnBloc>().add(
                                                      UpdateReturnItem(
                                                        inventarisId:
                                                            item['inventaris_id'],
                                                        qtyReturned:
                                                            item['qty_returned'],
                                                        kondisi: val ?? 'baik',
                                                        masukKeStok:
                                                            item['masuk_ke_stok'],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Checkbox(
                                            value:
                                                item['masuk_ke_stok'] == true,
                                            onChanged:
                                                item['kondisi'] == 'tidak_layak'
                                                ? null
                                                : (val) {
                                                    context.read<PosReturnBloc>().add(
                                                      UpdateReturnItem(
                                                        inventarisId:
                                                            item['inventaris_id'],
                                                        qtyReturned:
                                                            item['qty_returned'],
                                                        kondisi:
                                                            item['kondisi'],
                                                        masukKeStok:
                                                            val ?? false,
                                                      ),
                                                    );
                                                  },
                                          ),
                                          const PosText('Kembalikan ke Stok'),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const PosText(
                                  'Detail Retur',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const PosText('Alasan Retur'),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  initialValue: _alasan,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'cacat',
                                      child: PosText('Cacat Produksi'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'tidak_sesuai',
                                      child: PosText('Tidak Sesuai Pesanan'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'rusak_pengiriman',
                                      child: PosText('Rusak Pengiriman'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'batal_beli',
                                      child: PosText('Batal Beli'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'kualitas',
                                      child: PosText('Kualitas Buruk'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'lainnya',
                                      child: PosText('Lainnya'),
                                    ),
                                  ],
                                  onChanged: (val) =>
                                      setState(() => _alasan = val ?? 'cacat'),
                                ),
                                const SizedBox(height: 12),
                                const PosText(
                                  'Metode untuk bagian yang sudah dibayar',
                                ),
                                const PosText(
                                  'Retur mengurangi piutang terlebih dahulu. Hanya selisih yang sudah dibayar dikembalikan. Tunai memakai akun kas 1001; transfer akun bank 1002 di Finance.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                DropdownButtonFormField<String>(
                                  key: ValueKey(state.searchResult?['_id']),
                                  initialValue:
                                      _metodeRefund == 'kredit_store' &&
                                          state.searchResult?['sales_invoice_id'] ==
                                              null
                                      ? 'tunai'
                                      : _metodeRefund,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: 'tunai',
                                      child: PosText('Tunai'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'transfer',
                                      child: PosText('Transfer Bank'),
                                    ),
                                    if (state
                                            .searchResult?['sales_invoice_id'] !=
                                        null)
                                      const DropdownMenuItem(
                                        value: 'kredit_store',
                                        child: PosText('Saldo Kredit Pelanggan'),
                                      ),
                                  ],
                                  onChanged: (val) => setState(
                                    () => _metodeRefund = val ?? 'tunai',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const PosText('Catatan Tambahan'),
                                const SizedBox(height: 4),
                                TextField(
                                  controller: _catatanController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
