import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_pos_pantoo/core/themes/colors_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/pos/pos_bloc.dart';
import '../../../bloc/pos/pos_event.dart';
import '../../../bloc/pos/pos_state.dart';
import '../../../widgets/app_toast.dart';
import '../../../../domain/models/pos_product.dart';

class PosCartPanel extends StatelessWidget {
  const PosCartPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        if (state.cart.isEmpty) {
          return const Center(
            child: Text(
              'Silakan masukkan pesanan dari pelanggan',
              style: TextStyle(color: Colors.black54),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: state.cart.length,
          separatorBuilder: (_, __) => const Divider(height: 24),
          itemBuilder: (context, index) {
            final product = state.cart.keys.elementAt(index);
            final qty = state.cart[product]!;
            return _buildCartItem(
              context,
              product,
              qty,
              state.unitPriceFor(product),
              allowPriceEdit:
                  state.runtimeConfig['allow_cashier_price_edit'] == true,
            );
          },
        );
      },
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    PosProduct product,
    double quantity,
    double unitPrice, {
    required bool allowPriceEdit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    product.code,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: AppColors.danger),
              onPressed: () {
                context.read<PosBloc>().add(RemoveCartItem(product));
                AppToast.info(
                  context,
                  '${product.name} dihapus dari keranjang',
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              height: 36,
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36),
                    icon: const Icon(
                      Icons.remove,
                      size: 18,
                      color: Colors.black87,
                    ),
                    onPressed: () => context.read<PosBloc>().add(
                      UpdateQuantity(product, -1.0),
                    ),
                  ),
                  Tooltip(
                    message: 'Ubah jumlah',
                    child: InkWell(
                      onTap: () => _editQuantity(context, product, quantity),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 40,
                        alignment: Alignment.center,
                        child: Text(
                          _quantityText(quantity),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36),
                    icon: const Icon(
                      Icons.add,
                      size: 18,
                      color: Colors.black87,
                    ),
                    onPressed: () => context.read<PosBloc>().add(
                      UpdateQuantity(product, 1.0),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: allowPriceEdit
                        ? () => _editUnitPrice(context, product, unitPrice)
                        : null,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '@ Rp ${unitPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: allowPriceEdit
                                    ? AppColors.primary
                                    : Colors.grey,
                                fontSize: 12,
                                fontWeight: allowPriceEdit
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (allowPriceEdit) ...[
                            const SizedBox(width: 3),
                            const Icon(Icons.edit_outlined, size: 14),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${(unitPrice * quantity).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _quantityText(double value) => value == value.truncateToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');

  Future<void> _editQuantity(
    BuildContext context,
    PosProduct product,
    double currentQuantity,
  ) async {
    final controller = TextEditingController(
      text: _quantityText(currentQuantity),
    );
    final quantity = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Jumlah ${product.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,3}')),
          ],
          decoration: InputDecoration(
            labelText: 'Jumlah (${product.baseUnit})',
            helperText: 'Bisa memakai pecahan, contoh 3,5 kg',
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) {
            final value = double.tryParse(
              controller.text.trim().replaceAll(',', '.'),
            );
            if (value != null && value > 0) {
              Navigator.pop(dialogContext, value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(
                controller.text.trim().replaceAll(',', '.'),
              );
              if (value != null && value > 0) {
                Navigator.pop(dialogContext, value);
              }
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (quantity == null || !context.mounted) return;
    context.read<PosBloc>().add(
      UpdateQuantity(product, quantity - currentQuantity),
    );
  }

  Future<void> _editUnitPrice(
    BuildContext context,
    PosProduct product,
    double currentPrice,
  ) async {
    final controller = TextEditingController(
      text: currentPrice.toStringAsFixed(0),
    );
    final price = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah harga satuan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
          ],
          decoration: InputDecoration(
            labelText: 'Harga ${product.name}',
            prefixText: 'Rp ',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(
                controller.text.replaceAll(',', '.'),
              );
              if (value == null || value <= 0) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (price == null || !context.mounted) return;
    context.read<PosBloc>().add(UpdateCartUnitPrice(product, price));
  }
}
