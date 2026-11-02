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
    title: const Text('Simpan pesanan'),
    content: TextFormField(
      autofocus: true,
      onChanged: (value) => _name = value,
      decoration: const InputDecoration(
        labelText: 'Nama pesanan',
        hintText: 'Contoh: Pesanan Pak Budi',
        helperText: 'Nama ini ditampilkan sebagai judul pesanan tersimpan.',
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Batal'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.of(context).pop(_name.trim()),
        child: const Text('Simpan'),
      ),
    ],
  );
}
