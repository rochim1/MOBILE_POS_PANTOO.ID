import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:mobile_pos_pantoo/l10n/language_picker.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import '../../../core/utils/product_image_picker.dart';
import '../../../domain/repositories/pos_personal_profile_repository.dart';
import '../../widgets/pos_employee_avatar.dart';

/// Edits only the PIN-verified operator; login/security settings stay separate.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.repository,
    this.onUpdated,
    this.imagePicker,
  });
  final PosPersonalProfileRepository? repository;
  final ValueChanged<PosPersonalProfile>? onUpdated;
  final Future<PickedProductImage?> Function()? imagePicker;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  late final PosPersonalProfileRepository _repository;
  PosPersonalProfile? _profile;
  PickedProductImage? _photo;
  bool _loading = true, _saving = false, _picking = false, _removePhoto = false;
  String? _error;
  bool get _busy => _saving || _picking;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? sl<PosPersonalProfileRepository>();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _setProfile(PosPersonalProfile value) {
    _profile = value;
    _name.text = value.name;
    _phone.text = value.phone;
    _address.text = value.address;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getProfile();
    if (!mounted) return;
    setState(() {
      _loading = false;
      result.fold((failure) => _error = failure.message, _setProfile);
    });
  }

  Future<void> _pickPhoto() async {
    if (_busy || _profile?.cached != false) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final value = await (widget.imagePicker ?? pickProductImage)();
      if (!mounted || value == null) return;
      final validation = personalPhotoValidation(value);
      setState(() {
        _error = validation;
        if (validation == null) {
          _photo = value;
          _removePhoto = false;
        }
      });
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Foto belum dapat dipilih. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    final profile = _profile;
    if (_busy ||
        profile == null ||
        profile.cached ||
        !_form.currentState!.validate())
      return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await _repository.save(
      name: _name.text,
      phone: _phone.text,
      address: _address.text,
      expectedVersion: profile.version,
      photo: _photo,
      removePhoto: _removePhoto,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      result.fold((failure) => _error = failure.message, (value) {
        _setProfile(value);
        _photo = null;
        _removePhoto = false;
      });
    });
    result.fold((_) {}, (value) {
      widget.onUpdated?.call(value);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: PosText('Profil berhasil diperbarui')));
    });
  }

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label.tr(context),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    border: const OutlineInputBorder(),
  );

  Widget _content(PosPersonalProfile profile) {
    final editable = !_busy && !profile.cached;
    final preview = _removePhoto
        ? ''
        : _photo != null
        ? 'data:image/png;base64,' + base64Encode(_photo!.bytes)
        : profile.photo;
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PosText(
                    'Profil kasir aktif',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const PosText(
                    'Data pribadi kasir yang sudah diverifikasi dengan PIN. Hak akses, outlet, dan PIN tidak berubah.',
                  ),
                  const SizedBox(height: 20),
                  if (profile.cached) ...[
                    const PosText(
                      'Menampilkan data terakhir. Sambungkan internet untuk mengubah profil.',
                    ),
                    const SizedBox(height: 16),
                  ],
                  Center(
                    child: PosEmployeeAvatar(
                      employee: {'name': _name.text, 'photo_url': preview},
                      radius: 44,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: editable ? _pickPhoto : null,
                        icon: _picking
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_a_photo_outlined),
                        label: const PosText('Ubah foto profil'),
                      ),
                      if (preview.isNotEmpty)
                        TextButton.icon(
                          onPressed: editable
                              ? () => setState(() {
                                  _photo = null;
                                  _removePhoto = true;
                                })
                              : null,
                          icon: const Icon(Icons.delete_outline),
                          label: const PosText('Hapus foto'),
                        ),
                    ],
                  ),
                  const Center(
                    child: PosText('JPG, PNG, atau WebP. Maksimal 5 MB.'),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const ValueKey('profile_name'),
                    controller: _name,
                    enabled: editable,
                    maxLength: 160,
                    decoration: _decoration('Nama lengkap'),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nama wajib diisi'.tr(context)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('profile_phone'),
                    controller: _phone,
                    enabled: editable,
                    keyboardType: TextInputType.phone,
                    maxLength: 16,
                    decoration: _decoration('Nomor telepon'),
                    validator: (value) =>
                        value != null &&
                            value.trim().isNotEmpty &&
                            !RegExp(r'^\+?\d{8,15}$').hasMatch(value.trim())
                        ? 'Nomor telepon tidak valid'.tr(context)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('profile_address'),
                    controller: _address,
                    enabled: editable,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 1000,
                    decoration: _decoration('Alamat'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const ValueKey('profile_email'),
                    initialValue: profile.email,
                    enabled: false,
                    decoration: _decoration('Email'),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: const ValueKey('profile_username'),
                    initialValue: profile.username,
                    enabled: false,
                    decoration: _decoration('Username'),
                  ),
                  const SizedBox(height: 8),
                  const PosText(
                    'Identitas login hanya dapat diubah melalui pengaturan keamanan akun.',
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) ...[
                    PosText(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  FilledButton.icon(
                    key: const ValueKey('profile_save'),
                    onPressed: editable ? _save : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: PosText(_saving ? 'Menyimpan...' : 'Simpan profil'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: const PosText('Profil Pengguna'),
        actions: const [LanguagePicker(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _profile != null
            ? _content(_profile!)
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PosText(_error ?? 'Profil belum dapat dimuat'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _load,
                        child: const PosText('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    ),
  );
}
