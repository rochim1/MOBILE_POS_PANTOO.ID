import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'legal_links.dart';

class GoogleRegistrationDetails extends StatefulWidget {
  const GoogleRegistrationDetails({super.key});

  @override
  State<GoogleRegistrationDetails> createState() =>
      _GoogleRegistrationDetailsState();
}

class _GoogleRegistrationDetailsState extends State<GoogleRegistrationDetails> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _consent = false;
  bool _showConsentError = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PosText(
              'Lengkapi akun Pantoo',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const PosText(
              'Nama dan email menggunakan akun Google Anda. Tambahkan nomor telepon untuk melanjutkan.',
            ),
            const SizedBox(height: 20),
            TextFormField(
errorBuilder: posValidationError,
              controller: _phone,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumberNational],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(15),
              ],
              decoration:  InputDecoration(
                labelText: ('Nomor telepon').tr(context),
                hintText: ('08xxxxxxxxxx').tr(context),
              ),
              validator: (value) =>
                  RegExp(r'^\d{8,15}$').hasMatch(value?.trim() ?? '')
                  ? null
                  : ('Masukkan nomor telepon 8–15 digit.').tr(context),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _consent,
              title: const PosText(
                'Saya menyetujui Kebijakan Privasi dan Ketentuan Layanan Pantoo.',
              ),
              onChanged: (value) => setState(() {
                _consent = value ?? false;
                _showConsentError = false;
              }),
            ),
            Wrap(
              children: [
                TextButton(
                  onPressed: () =>
                      openPantooLegalUrl(context, pantooPrivacyUrl),
                  child: const PosText('Kebijakan Privasi'),
                ),
                TextButton(
                  onPressed: () => openPantooLegalUrl(context, pantooTermsUrl),
                  child: const PosText('Ketentuan Layanan'),
                ),
              ],
            ),
            if (_showConsentError)
              PosText(
                'Persetujuan diperlukan untuk membuat akun.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final valid = _form.currentState!.validate();
                setState(() => _showConsentError = !_consent);
                if (valid && _consent) {
                  Navigator.pop(context, _phone.text.trim());
                }
              },
              child: const PosText('Buat akun dan lanjutkan'),
            ),
          ],
        ),
      ),
    ),
  );
}
