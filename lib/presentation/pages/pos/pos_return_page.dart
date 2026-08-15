import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import '../../../../injections.dart';
import '../../bloc/pos_return/pos_return_bloc.dart';
import '../../bloc/pos_return/pos_return_event.dart';
import '../../bloc/pos_return/pos_return_state.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_ui.dart';
import 'pos_add_return_page.dart';
import 'package:intl/intl.dart';

class PosReturnPage extends StatelessWidget {
  const PosReturnPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PosReturnBloc>()..add(const LoadReturns()),
      child: const PosReturnView(),
    );
  }
}

class PosReturnView extends StatefulWidget {
  const PosReturnView({super.key});

  @override
  State<PosReturnView> createState() => _PosReturnViewState();
}

class _PosReturnViewState extends State<PosReturnView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = '';

  String _formatCurrency(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(value);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey.shade600;
      case 'approved':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const PosAppBarTitle(
          title: 'Retur Penjualan',
          subtitle: 'Pengembalian dan refund',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_return_fab',
        onPressed: () async {
          final bloc = context.read<PosReturnBloc>();
          bloc.add(ClearReturnForm());
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: bloc,
                child: const PosAddReturnPage(),
              ),
            ),
          );
          if (result == true) {
            bloc.add(const LoadReturns());
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Retur',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari No. Retur / Invoice...',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (val) {
                      context.read<PosReturnBloc>().add(
                        LoadReturns(search: val, status: _selectedStatus),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatus,
                      items: const [
                        DropdownMenuItem(value: '', child: Text('Semua')),
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                        DropdownMenuItem(
                          value: 'approved',
                          child: Text('Approved'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedStatus = val ?? '');
                        context.read<PosReturnBloc>().add(
                          LoadReturns(
                            search: _searchController.text,
                            status: _selectedStatus,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: BlocConsumer<PosReturnBloc, PosReturnState>(
              listener: (context, state) {
                if (state.status == PosReturnStatus.failure &&
                    state.errorMessage.isNotEmpty) {
                  AppToast.error(context, state.errorMessage);
                }
              },
              builder: (context, state) {
                if (state.status == PosReturnStatus.loading &&
                    state.returns.isEmpty) {
                  return const PosSkeletonList();
                }

                if (state.returns.isEmpty) {
                  return const PosEmptyState(
                    icon: Icons.assignment_return_outlined,
                    title: 'Belum ada retur',
                    message:
                        'Retur dan refund penjualan yang diajukan akan tampil di halaman ini.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.returns.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = state.returns[index];
                    final status = item['status'] ?? 'draft';
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['no_retur'] ?? '-',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      status,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Invoice Asal',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(item['sumber_no'] ?? '-'),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      'Total Refund',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(
                                        item['total_refund'] ?? 0,
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (status == 'draft' || status == 'approved') ...[
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (status == 'draft')
                                    TextButton(
                                      onPressed: () => context
                                          .read<PosReturnBloc>()
                                          .add(ApproveReturn(item['_id'])),
                                      child: const Text(
                                        'Approve',
                                        style: TextStyle(color: Colors.blue),
                                      ),
                                    ),
                                  if (status == 'draft')
                                    const SizedBox(width: 8),
                                  if (status == 'draft')
                                    TextButton(
                                      onPressed: () => context
                                          .read<PosReturnBloc>()
                                          .add(DeleteReturn(item['_id'])),
                                      child: const Text(
                                        'Hapus',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  if (status == 'approved')
                                    ElevatedButton(
                                      onPressed: () => context
                                          .read<PosReturnBloc>()
                                          .add(ProcessReturn(item['_id'])),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Proses',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
