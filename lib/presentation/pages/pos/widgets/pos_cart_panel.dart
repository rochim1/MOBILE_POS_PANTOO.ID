import 'package:flutter/material.dart';
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
            );
          },
        );
      },
    );
  }

  Widget _buildCartItem(
    BuildContext context,
    PosProduct product,
    int quantity,
    double unitPrice,
  ) {
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
              icon: const Icon(Icons.close, color: Colors.red),
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
                      UpdateQuantity(product, -1),
                    ),
                  ),
                  Container(
                    width: 32,
                    alignment: Alignment.center,
                    child: Text(
                      '$quantity',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
                    onPressed: () =>
                        context.read<PosBloc>().add(UpdateQuantity(product, 1)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '@ Rp ${unitPrice.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
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
}
