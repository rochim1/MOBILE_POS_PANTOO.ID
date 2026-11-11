import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:flutter/material.dart';

/// Owns input through the whole dialog route, including its exit animation.
class PosHeldOrderNameDialog extends StatefulWidget {
  const PosHeldOrderNameDialog({super.key});

  @override
  State<PosHeldOrderNameDialog> createState() => _PosHeldOrderNameDialogState();
}

class _PosHeldOrderNameDialogState extends State<PosHeldOrderNameDialog> {
  String _name = '';

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const PosText('Simpan pesanan'),
    content: TextFormField(
      autofocus: true,
      onChanged: (value) => _name = value,
      decoration:  InputDecoration(
        labelText: ('Nama pesanan').tr(context),
        hintText: ('Contoh: Pesanan Pak Budi').tr(context),
        helperText: ('Nama ini ditampilkan sebagai judul pesanan tersimpan.').tr(context),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const PosText('Batal'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.of(context).pop(_name.trim()),
        child: const PosText('Simpan'),
      ),
    ],
  );
}
