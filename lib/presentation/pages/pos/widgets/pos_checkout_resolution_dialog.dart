import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';

class PosCheckoutResolutionDialog extends StatefulWidget {
  const PosCheckoutResolutionDialog({super.key});
  @override
  State<PosCheckoutResolutionDialog> createState() => _ResolutionState();
}

class _ResolutionState extends State<PosCheckoutResolutionDialog> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  final _username = TextEditingController();
  final _pin = TextEditingController();
  String _resolution = 'not_received';
  bool _visible = false;
  @override
  void dispose() {
    _note.dispose();
    _username.dispose();
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const PosText('Selesaikan pembayaran'),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PosText(
              'Periksa invoice dan uang terlebih dahulu. Server tidak akan membatalkan transaksi yang sudah tercatat.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _resolution,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Hasil pemeriksaan uang'.tr(context),
              ),
              items: [
                DropdownMenuItem(
                  value: 'not_received',
                  child: PosText('Uang belum diterima'),
                ),
                DropdownMenuItem(
                  value: 'reconciled',
                  child: PosText('Dana sudah dikembalikan / direkonsiliasi'),
                ),
              ],
              onChanged: (value) => setState(() => _resolution = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('checkout_resolution_note'),
              controller: _note,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Catatan pemeriksaan'.tr(context),
              ),
              validator: (value) => (value?.trim().length ?? 0) < 5
                  ? 'Catatan minimal 5 karakter'.tr(context)
                  : null,
            ),
            if (_resolution == 'reconciled') ...[
              const PosText(
                'Dana yang sudah diterima memerlukan persetujuan supervisor. Jangan lanjut jika dana belum dikembalikan atau direkonsiliasi.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _username,
                decoration: InputDecoration(
                  labelText: 'Username supervisor'.tr(context),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pin,
                obscureText: !_visible,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'PIN supervisor'.tr(context),
                  suffixIcon: IconButton(
                    tooltip: (_visible ? 'Sembunyikan PIN' : 'Tampilkan PIN')
                        .tr(context),
                    onPressed: () => setState(() => _visible = !_visible),
                    icon: Icon(
                      _visible ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const PosText('Batal'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, {
              'resolution': _resolution,
              'note': _note.text.trim(),
              'username': _username.text.trim(),
              'pin': _pin.text,
            });
          }
        },
        child: const PosText('Selesaikan percobaan'),
      ),
    ],
  );
}
