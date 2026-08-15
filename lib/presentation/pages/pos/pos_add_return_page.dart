import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import '../../widgets/pos_ui.dart';
import '../../bloc/pos_return/pos_return_bloc.dart';
import '../../bloc/pos_return/pos_return_event.dart';
import '../../bloc/pos_return/pos_return_state.dart';
import '../../widgets/app_toast.dart';
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
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const PosAppBarTitle(
          title: 'Tambah Retur',
          subtitle: 'Pilih invoice dan item',
        ),
      ),
      bottomNavigationBar: BlocConsumer<PosReturnBloc, PosReturnState>(
        listener: (context, state) {
          if (state.status == PosReturnStatus.success &&
              state.searchResult == null) {
            AppToast.success(context, 'Retur berhasil disimpan sebagai draft');
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
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE7E7E7))),
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed:
                    (state.searchResult == null ||
                        !hasSelected ||
                        state.status == PosReturnStatus.loading)
                    ? null
                    : () {
                        context.read<PosReturnBloc>().add(
                          SubmitReturn(
                            alasan: _alasan,
                            metodeRefund: _metodeRefund,
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
                child:
                    state.status == PosReturnStatus.loading &&
                        state.searchResult != null
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Simpan Draft Retur',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                  const Text(
                    'Cari Invoice',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _invoiceController,
                          decoration: InputDecoration(
                            hintText: 'Masukkan No. Invoice...',
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
                        child: const Text('Cari'),
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
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Invoice: ${trx['invoice']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pelanggan: ${trx['pelanggan'] ?? 'Umum'}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          Text(
                            'Total: ${_formatCurrency(trx['total'] ?? 0)}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Item Selection
                    const Text(
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
                                    'Qty Asal: ${item['qty_original']} ${item['unit']}',
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
                                          const Text(
                                            'Qty Retur',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          TextFormField(
                                            initialValue: item['qty_returned']
                                                .toString(),
                                            keyboardType: TextInputType.number,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.all(8),
                                            ),
                                            onChanged: (val) {
                                              final qty =
                                                  double.tryParse(val) ?? 0;
                                              context.read<PosReturnBloc>().add(
                                                UpdateReturnItem(
                                                  inventarisId:
                                                      item['inventaris_id'],
                                                  qtyReturned: qty,
                                                  kondisi: item['kondisi'],
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
                                          const Text(
                                            'Kondisi',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          DropdownButtonFormField<String>(
                                            initialValue: item['kondisi'],
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              contentPadding: EdgeInsets.all(8),
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'baik',
                                                child: Text('Baik'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'rusak_ringan',
                                                child: Text('Rusak Ringan'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'rusak_berat',
                                                child: Text('Rusak Berat'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'tidak_layak',
                                                child: Text('Tidak Layak'),
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
                                      value: item['masuk_ke_stok'] == true,
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
                                                  kondisi: item['kondisi'],
                                                  masukKeStok: val ?? false,
                                                ),
                                              );
                                            },
                                    ),
                                    const Text('Kembalikan ke Stok'),
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
                          const Text(
                            'Detail Retur',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Alasan Retur'),
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
                                child: Text('Cacat Produksi'),
                              ),
                              DropdownMenuItem(
                                value: 'tidak_sesuai',
                                child: Text('Tidak Sesuai Pesanan'),
                              ),
                              DropdownMenuItem(
                                value: 'rusak_pengiriman',
                                child: Text('Rusak Pengiriman'),
                              ),
                              DropdownMenuItem(
                                value: 'batal_beli',
                                child: Text('Batal Beli'),
                              ),
                              DropdownMenuItem(
                                value: 'kualitas',
                                child: Text('Kualitas Buruk'),
                              ),
                              DropdownMenuItem(
                                value: 'lainnya',
                                child: Text('Lainnya'),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _alasan = val ?? 'cacat'),
                          ),
                          const SizedBox(height: 12),
                          const Text('Metode Refund'),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            initialValue: _metodeRefund,
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
                                value: 'tunai',
                                child: Text('Tunai'),
                              ),
                              DropdownMenuItem(
                                value: 'transfer',
                                child: Text('Transfer Bank'),
                              ),
                              DropdownMenuItem(
                                value: 'kredit_store',
                                child: Text('Kredit Toko (Voucher)'),
                              ),
                              DropdownMenuItem(
                                value: 'tidak_ada',
                                child: Text('Tanpa Refund (Tukar)'),
                              ),
                            ],
                            onChanged: (val) =>
                                setState(() => _metodeRefund = val ?? 'tunai'),
                          ),
                          const SizedBox(height: 12),
                          const Text('Catatan Tambahan'),
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
  }
}
