import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/pos/pos_bloc.dart';
import '../../../bloc/pos/pos_state.dart';
import '../../../../injections.dart';
import '../../../../domain/repositories/pos_repository.dart';
import '../../../bloc/pos/pos_event.dart';

class ShiftManagementPanel extends StatefulWidget {
  const ShiftManagementPanel({super.key});

  @override
  State<ShiftManagementPanel> createState() => _ShiftManagementPanelState();
}

class _ShiftManagementPanelState extends State<ShiftManagementPanel> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _openShift(BuildContext context, String tokoId) async {
    final amount = parseRupiah(_amountController.text);
    setState(() => _isLoading = true);

    final repo = sl<PosRepository>();
    final result = await repo.openShift(tokoId, amount);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
      (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Shift berhasil dibuka')));
        context.read<PosBloc>().add(LoadPosData());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        final tokoId = state.stores.isNotEmpty ? state.stores.first.id : '';

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Container(
                    width: 400,
                    margin: const EdgeInsets.symmetric(vertical: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.storefront,
                          size: 64,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Buka Shift Kasir',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Anda belum memiliki shift aktif di toko ini. Silakan masukkan uang modal awal untuk membuka shift.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [RupiahInputFormatter()],
                          decoration: InputDecoration(
                            labelText: 'Uang Modal Awal (Rp)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.payments),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _openShift(context, tokoId),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: AppColors.primary,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Buka Shift'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
