import 'package:flutter/material.dart';
import '../../../../domain/models/pos_opname.dart';

class PosOpnameBatchFields extends StatelessWidget {
  final Map<String, dynamic> item;
  final ValueChanged<Map<String, dynamic>> onChanged;
  const PosOpnameBatchFields({
    super.key,
    required this.item,
    required this.onChanged,
  });

  String number(dynamic value) {
    final n = opnameNumber(value);
    return !n.isFinite
        ? ''
        : n == n.truncateToDouble()
        ? n.toInt().toString()
        : n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final batches = (item['batch_counts'] as List? ?? [])
        .whereType<Map>()
        .toList();
    void update(int? index, String text) {
      final next = {
        ...item,
        'batch_counts': batches
            .map((b) => Map<String, dynamic>.from(b))
            .toList(),
      };
      final qty = double.tryParse(text.replaceAll(',', '.')) ?? double.nan;
      if (index == null) {
        next['qty_unbatched_fisik'] = qty;
      } else {
        (next['batch_counts'] as List)[index]['qty_fisik'] = qty;
      }
      next['input_qty'] = opnamePhysicalTotal(next);
      onChanged(next);
    }

    Widget field(
      String label,
      dynamic qty,
      ValueChanged<String> change,
      String key,
      String helper,
    ) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        key: ValueKey(key),
        initialValue: number(qty),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          border: const OutlineInputBorder(),
        ),
        validator: (text) {
          final n = double.tryParse((text ?? '').replaceAll(',', '.'));
          return n == null || !n.isFinite || n < 0
              ? 'Isi angka nol atau lebih'
              : null;
        },
        onChanged: change,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, batch) in batches.indexed)
          field(
            'Fisik batch ${batch['no_batch']} · ${batch['tanggal_kadaluarsa'] == null || batch['tanggal_kadaluarsa'] == '' ? 'tanpa kedaluwarsa' : batch['tanggal_kadaluarsa']}',
            batch['qty_fisik'],
            (text) => update(index, text),
            '${opnameRowKey(item, 0)}:${batch['batch_id'] ?? '${batch['no_batch']}:${batch['tanggal_kadaluarsa']}'}',
            'Sistem ${number(batch['qty_system'])} ${item['unit'] ?? ''}',
          ),
        if (opnameNumber(item['qty_unbatched_system'] ?? 0) > 0)
          field(
            'Fisik tanpa batch',
            item['qty_unbatched_fisik'],
            (text) => update(null, text),
            '${opnameRowKey(item, 0)}:unbatched',
            'Sistem ${number(item['qty_unbatched_system'])}; dihitung terpisah.',
          ),
        Text(
          'Total fisik: ${number(item['input_qty'])} ${item['unit'] ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
