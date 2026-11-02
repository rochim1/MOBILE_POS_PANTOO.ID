import 'package:flutter/material.dart';

/// Keeps form state alive until the dialog's exit transition has finished.
/// The caller receives a value, never a controller owned by a departing route.
class PosForcedProfileChangeDialog extends StatefulWidget {
  const PosForcedProfileChangeDialog({super.key, required this.message});

  final String message;

  @override
  State<PosForcedProfileChangeDialog> createState() =>
      _PosForcedProfileChangeDialogState();
}

class _PosForcedProfileChangeDialogState
    extends State<PosForcedProfileChangeDialog> {
  String _reason = '';
  bool _acknowledged = false;
  String? _validation;

  void _confirm() {
    if (_reason.trim().length < 10 || !_acknowledged) {
      setState(() {
        _validation =
            'Isi alasan minimal 10 karakter dan centang pernyataan pemahaman.';
      });
      return;
    }
    Navigator.of(context).pop(_reason.trim());
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Profil masih digunakan operasional'),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.message),
            const SizedBox(height: 10),
            const Text(
              'Pesanan lama tetap memakai snapshot-nya. Profil baru berlaku untuk transaksi berikutnya. Periksa kembali fitur meja, layanan, pelanggan, dan tipe pemenuhan.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              maxLines: 3,
              onChanged: (value) => _reason = value,
              decoration: const InputDecoration(
                labelText: 'Alasan perubahan paksa',
                hintText: 'Minimal 10 karakter',
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _acknowledged,
              onChanged: (value) =>
                  setState(() => _acknowledged = value == true),
              title: const Text(
                'Saya memahami operasional aktif tidak ikut diubah.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_validation != null)
              Text(
                _validation!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Batal'),
      ),
      FilledButton(onPressed: _confirm, child: const Text('Paksa lanjutkan')),
    ],
  );
}
