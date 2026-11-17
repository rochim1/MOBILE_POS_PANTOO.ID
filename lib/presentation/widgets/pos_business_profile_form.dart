import 'package:flutter/material.dart';
import '../../core/utils/product_image_picker.dart';
import '../../domain/repositories/pos_business_profile_repository.dart';
import '../../l10n/pos_localization.dart';
import 'pos_business_logo_picker.dart';

class PosBusinessProfileForm extends StatefulWidget {
  const PosBusinessProfileForm({
    super.key,
    required this.repository,
    required this.canEdit,
    this.onSaved,
    this.pickLogo,
  });
  final PosBusinessProfileRepository repository;
  final bool canEdit;
  final VoidCallback? onSaved;
  final Future<PickedProductImage?> Function()? pickLogo;
  @override
  State<PosBusinessProfileForm> createState() => _PosBusinessProfileFormState();
}

class _PosBusinessProfileFormState extends State<PosBusinessProfileForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _phone = TextEditingController(),
      _address = TextEditingController();
  PosBusinessProfile? _profile;
  PickedProductImage? _logo;
  bool _loading = true, _saving = false, _removeLogo = false;
  String? _error, _success;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _apply(PosBusinessProfile value) {
    _profile = value;
    _name.text = value.name;
    _phone.text = value.phone;
    _address.text = value.address;
    _logo = null;
    _removeLogo = false;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.repository.getProfile();
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold((f) => _error = f.message, _apply);
    });
  }

  Future<void> _save() async {
    if (_saving ||
        !widget.canEdit ||
        !(_form.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    final result = await widget.repository.save(
      name: _name.text,
      phone: _phone.text,
      address: _address.text,
      logo: _logo,
      removeLogo: _removeLogo,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      result.fold((f) => _error = f.message, (value) {
        _apply(value);
        _success = 'Profil usaha berhasil disimpan';
      });
    });
    if (result.isRight()) widget.onSaved?.call();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_profile == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PosText(_error ?? 'Profil usaha belum dapat dimuat'),
              TextButton(onPressed: _load, child: const PosText('Coba lagi')),
            ],
          ),
        ),
      );
    }
    final enabled = widget.canEdit && !_saving;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PosText(
                  'Profil Usaha',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const PosText(
                  'Nama, kontak, alamat, dan logo ini tersimpan pada profil usaha yang sama.',
                ),
                const SizedBox(height: 20),
                PosBusinessLogoPicker(
                  value: _logo,
                  imageUrl: _removeLogo ? '' : _profile!.logo,
                  enabled: enabled,
                  pickImage: widget.pickLogo,
                  onChanged: (image) => setState(() {
                    _logo = image;
                    _removeLogo = false;
                    _success = null;
                  }),
                  onRemove: () => setState(() {
                    _logo = null;
                    _removeLogo = true;
                    _success = null;
                  }),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _name,
                  readOnly: !enabled,
                  maxLength: 160,
                  onChanged: (_) => setState(() => _success = null),
                  decoration: const InputDecoration(
                    labelText: 'Nama Usaha/Organisasi',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  validator: (v) => (v?.trim().length ?? 0) < 3
                      ? 'Nama minimal 3 karakter'
                      : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _phone,
                  readOnly: !enabled,
                  onChanged: (_) => setState(() => _success = null),
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon Usaha/Organisasi',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  validator: (v) =>
                      !RegExp(r'^\d{8,15}$').hasMatch(v?.trim() ?? '')
                      ? 'Nomor telepon harus 8–15 digit'
                      : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _address,
                  readOnly: !enabled,
                  onChanged: (_) => setState(() => _success = null),
                  maxLines: 3,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Alamat usaha (opsional)',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
                const SizedBox(height: 16),
                if (_profile!.cached)
                  const PosText(
                    'Menampilkan data tersimpan. Penyimpanan perubahan memerlukan koneksi internet.',
                  ),
                if (!widget.canEdit)
                  const PosText(
                    'Anda tidak memiliki izin mengubah pengaturan usaha.',
                  ),
                if (_error != null)
                  PosText(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_success != null) PosText(_success!),
                if (widget.canEdit)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: FilledButton.icon(
                      onPressed: enabled ? _save : null,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: PosText(
                        _saving ? 'Menyimpan…' : 'Simpan profil usaha',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
