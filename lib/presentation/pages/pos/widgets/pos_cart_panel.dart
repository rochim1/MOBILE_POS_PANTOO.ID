import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:mobile_pos_pantoo/core/utils/rupiah_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_pos_pantoo/core/themes/colors_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/pos/pos_bloc.dart';
import '../../../bloc/pos/pos_event.dart';
import '../../../bloc/pos/pos_state.dart';
import '../../../widgets/app_toast.dart';
import '../../../../domain/models/pos_product.dart';
import 'pos_service_price_dialog.dart';

class PosCartPanel extends StatelessWidget {
  const PosCartPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        if (state.cart.isEmpty) {
          return const Center(
            child: PosText(
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
              selectedUnit: state.unitFor(product),
              allowPriceEdit:
                  product.isFlexibleService ||
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
    required String selectedUnit,
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
                    message: ('Ubah jumlah').tr(context),
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
            SizedBox(
              width: 76,
              height: 36,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedUnit,
                      isExpanded: true,
                      isDense: true,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                      items: product.saleUnits
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(
                                unit,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (unit) {
                        if (unit != null) {
                          context.read<PosBloc>().add(
                            UpdateCartUnit(product, unit),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
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
                              posLocale(context).pos5e6481728b57(
                                (formatRupiahAmount(unitPrice)).toString(),
                              ),
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
                    posLocale(context).pos70272f418def(
                      (formatRupiahAmount((unitPrice * quantity))).toString(),
                    ),
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
        title: Text(
          posLocale(dialogContext).posfed87456b577((product.name).toString()),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,3}')),
          ],
          decoration: InputDecoration(
            labelText: posLocale(
              dialogContext,
            ).pos8109832b1b60((product.baseUnit).toString()),
            helperText: ('Bisa memakai pecahan, contoh 3,5 kg').tr(
              dialogContext,
            ),
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
            child: const PosText('Batal'),
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
            child: const PosText('Terapkan'),
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
    if (product.isFlexibleService) {
      final price = await showServicePriceDialog(
        context,
        product,
        currentPrice: currentPrice,
        unit: context.read<PosBloc>().state.unitFor(product),
      );
      if (price != null && context.mounted) {
        context.read<PosBloc>().add(UpdateCartUnitPrice(product, price));
      }
      return;
    }
    final controller = TextEditingController(
      text: formatRupiahAmount(currentPrice),
    );
    final price = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const PosText('Ubah harga satuan'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [RupiahInputFormatter(decimalDigits: 2)],
          decoration: InputDecoration(
            labelText: posLocale(
              dialogContext,
            ).posba0f270a2974((product.name).toString()),
            prefixText: 'Rp ',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const PosText('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final value = parseRupiahAmount(controller.text);
              if (!value.isFinite || value <= 0 || value < product.priceFloor) {
                return;
              }
              Navigator.pop(dialogContext, value);
            },
            child: const PosText('Terapkan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (price == null || !context.mounted) return;
    context.read<PosBloc>().add(UpdateCartUnitPrice(product, price));
  }
}
