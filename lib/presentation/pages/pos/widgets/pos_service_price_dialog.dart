import 'package:flutter/material.dart';
import '../../../../domain/models/pos_product.dart';
import '../../../../core/utils/rupiah_input_formatter.dart';

Future<double?> showServicePriceDialog(
  BuildContext context,
  PosProduct product, {
  double? currentPrice,
  String? unit,
}) => showDialog<double>(
  context: context,
  builder: (_) => _ServicePriceDialog(
    product: product,
    initialPrice: currentPrice ?? product.price,
    unit: unit ?? product.saleUnit,
  ),
);

class _ServicePriceDialog extends StatefulWidget {
  const _ServicePriceDialog({
    required this.product,
    required this.initialPrice,
    required this.unit,
  });
  final PosProduct product;
  final double initialPrice;
  final String unit;
  @override
  State<_ServicePriceDialog> createState() => _ServicePriceDialogState();
}

class _ServicePriceDialogState extends State<_ServicePriceDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialPrice > 0
          ? formatRupiahAmount(widget.initialPrice)
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Tarif layanan'),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [RupiahInputFormatter(decimalDigits: 2)],
          decoration: InputDecoration(
            labelText: widget.product.name,
            prefixText: 'Rp ',
            helperText:
                'Per ${widget.unit} • minimum Rp ${formatRupiahAmount(widget.product.priceFloor)}',
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final price = parseRupiahAmount(value ?? '');
            return !price.isFinite ||
                    price <= 0 ||
                    price < widget.product.priceFloor
                ? 'Tarif wajib lebih dari nol dan memenuhi minimum'
                : null;
          },
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState?.validate() == true) {
            Navigator.pop(context, parseRupiahAmount(_controller.text));
          }
        },
        child: const Text('Terapkan'),
      ),
    ],
  );
}
