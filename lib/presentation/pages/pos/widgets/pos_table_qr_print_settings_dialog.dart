import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_keyboard_stable_dialog.dart';

import '../utils/pos_table_qr_print_settings.dart';

class PosTableQrPrintSettingsDialog extends StatefulWidget {
  const PosTableQrPrintSettingsDialog({super.key, required this.initial});

  final PosTableQrPrintSettings initial;

  @override
  State<PosTableQrPrintSettingsDialog> createState() =>
      _PosTableQrPrintSettingsDialogState();
}

class _PosTableQrPrintSettingsDialogState
    extends State<PosTableQrPrintSettingsDialog> {
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late bool _useLogo;
  late String _orientation;
  late String _theme;
  bool _titleRequired = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initial.title);
    _subtitle = TextEditingController(text: widget.initial.subtitle);
    _useLogo = widget.initial.useLogo;
    _orientation = widget.initial.orientation;
    _theme = widget.initial.theme;
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _titleRequired = true);
      return;
    }
    Navigator.pop(
      context,
      PosTableQrPrintSettings(
        title: title,
        subtitle: _subtitle.text.trim(),
        useLogo: _useLogo,
        orientation: _orientation,
        theme: _theme,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PosKeyboardStableFormDialog(
    width: 390,
    height: 580,
    title: const Text('Pengaturan Cetak QR Code'),
    content: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            maxLength: 60,
            onChanged: (_) {
              if (_titleRequired) setState(() => _titleRequired = false);
            },
            decoration: const InputDecoration(
              labelText: 'Judul Utama',
              border: OutlineInputBorder(),
            ).copyWith(errorText: _titleRequired ? 'Judul wajib diisi' : null),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _subtitle,
            maxLength: 120,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Sub-Judul',
              border: OutlineInputBorder(),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _useLogo,
            title: const Text('Tampilkan Logo Instansi'),
            onChanged: (value) => setState(() => _useLogo = value ?? false),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _orientation,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Orientasi',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'portrait', child: Text('Potret')),
              DropdownMenuItem(value: 'landscape', child: Text('Lanskap')),
            ],
            onChanged: (value) =>
                setState(() => _orientation = value ?? 'portrait'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _theme,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Warna Tema',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'light', child: Text('Terang')),
              DropdownMenuItem(value: 'dark', child: Text('Gelap')),
              DropdownMenuItem(value: 'primary', child: Text('Aksen Pantoo')),
            ],
            onChanged: (value) => setState(() => _theme = value ?? 'light'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton(onPressed: _save, child: const Text('Simpan')),
    ],
  );
}
