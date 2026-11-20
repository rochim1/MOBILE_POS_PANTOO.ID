import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'dart:async';
import '../../../core/notifications/pos_push_service.dart';
import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/themes/colors_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../injections.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/repositories/pos_business_profile_repository.dart';
import '../../../core/utils/product_image_picker.dart';
import '../../widgets/pos_business_logo_picker.dart';
import '../../widgets/pos_business_profile_selector.dart';
import '../../widgets/pos_setup_scaffold.dart';
import '../../../domain/models/pos_remote_profile_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../bloc/lock/lock_cubit.dart';
import '../pos/pos_onboarding_page.dart';
import '../pos/pos_shell_page.dart';

class BusinessSetupPage extends StatefulWidget {
  const BusinessSetupPage({super.key, this.pickLogo, this.onCompleted});
  final Future<PickedProductImage?> Function()? pickLogo;

  /// An embedding host may own navigation after all preparation has completed.
  final VoidCallback? onCompleted;

  @override
  State<BusinessSetupPage> createState() => _BusinessSetupPageState();
}

class _BusinessSetupPageState extends State<BusinessSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;
  bool _navigating = false;
  String _savingLabel = 'Menyimpan…';
  bool _workspaceCreated = false;
  PickedProductImage? _logo;
  String? _logoError;
  String _profile = 'retail';
  final _profileCatalog = PosRemoteProfileCatalog.bundled();

  @override
  void dispose() {
    _businessName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _savingLabel = 'Menyimpan…';
    });
    try {
      if (!_workspaceCreated) {
        final result = await sl<AuthRepository>().createWorkspace(
          businessName: _businessName.text.trim(),
          phone: _phone.text.trim(),
          businessProfile: _profile,
        );
        if (!mounted) return;
        if (result.isLeft()) {
          result.fold(
            (failure) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: PosText(failure.message),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            ),
            (_) {},
          );
          return;
        }
        _workspaceCreated = true;
      }
      // Persist the selection before optional logo upload, so a restart can
      // finish configuring this workspace instead of asking to create another.
      await _rememberProfile();
      if (!mounted) return;
      if (_logo != null) {
        final result = await sl<PosBusinessProfileRepository>().save(
          name: _businessName.text.trim(),
          phone: _phone.text.trim(),
          logo: _logo,
        );
        if (!mounted) return;
        if (result.isLeft()) {
          setState(() {
            result.fold(
              (failure) => _logoError =
                  'Profil usaha sudah dibuat, tetapi logo belum tersimpan. ${failure.message}',
              (_) {},
            );
          });
          return;
        }
      }
      if (mounted) await _finishSetup();
    } catch (_) {
      _navigating = false;
      if (mounted) _showPreparationError();
    } finally {
      if (mounted && !_navigating) setState(() => _saving = false);
    }
  }

  Future<void> _rememberProfile() => sl<SharedPreferences>().setString(
    PosOnboardingPage.pendingProfileKey(sl<SharedPreferences>()),
    _profile,
  );

  Future<void> _continue() async {
    if (_saving || !_workspaceCreated) return;
    setState(() {
      _saving = true;
      _savingLabel = 'Menyiapkan Pantoo POS…';
    });
    try {
      await _finishSetup();
    } catch (_) {
      _navigating = false;
      if (mounted) _showPreparationError();
    } finally {
      if (mounted && !_navigating) setState(() => _saving = false);
    }
  }

  void _showPreparationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const PosText(
          'Konfigurasi POS belum dapat dimuat. Coba lagi.',
        ),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  Future<void> _finishSetup() async {
    setState(() => _savingLabel = 'Menyiapkan Pantoo POS…');
    await _rememberProfile();
    if (!mounted) return;
    await preparePosWorkspace(
      sl<SharedPreferences>(),
      isCurrent: () => mounted,
    );
    if (!mounted) return;
    // Keep the form/button visible while loading the PIN/operator context too.
    await context.read<AppLockCubit>().lock();
    if (!mounted) return;
    _navigating = true;
    if (widget.onCompleted case final onCompleted?) {
      onCompleted();
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const PosShellPage()),
      (route) => false,
    );
    if (sl.isRegistered<PosPushService>()) {
      unawaited(sl<PosPushService>().activate());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PosSetupScaffold(
      backgroundColor: const Color(0xFF087F75),
      body: PosSetupScrollBody(
        child: Card(
          elevation: 7,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/pantoo.png', height: 60),
                  const SizedBox(height: 18),
                  PosText(
                    'Siapkan Profil Usaha',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PosText(
                    'Profil ini menjadi workspace utama untuk toko atau organisasi, produk, kasir, laporan, dan trial Pantoo Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 24),
                  const PosText(
                    'Toko dan lokasi stok awal dibuat otomatis. Setelah ini cukup tambahkan produk atau layanan. Pengaturan lain bisa menyusul.',
                  ),
                  const SizedBox(height: 16),
                  PosBusinessLogoPicker(
                    value: _logo,
                    enabled: !_saving,
                    pickImage: widget.pickLogo,
                    onChanged: (image) => setState(() {
                      _logo = image;
                      _logoError = null;
                    }),
                    onRemove: () => setState(() {
                      _logo = null;
                      _logoError = null;
                    }),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    errorBuilder: posValidationError,
                    controller: _businessName,
                    readOnly: _saving || _workspaceCreated,
                    maxLength: 160,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelText: ('Nama Usaha/Organisasi').tr(context),
                      hintText: ('Contoh: Toko Pantoo Jaya atau Koperasi Maju')
                          .tr(context),
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                    validator: (value) => (value?.trim().length ?? 0) < 3
                        ? ('Nama usaha atau organisasi minimal 3 karakter').tr(
                            context,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    errorBuilder: posValidationError,
                    controller: _phone,
                    readOnly: _saving || _workspaceCreated,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 15,
                    decoration: InputDecoration(
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      labelText: ('Nomor Telepon Usaha/Organisasi').tr(context),
                      hintText: ('08xxxxxxxxxx').tr(context),
                      helperText:
                          ('Boleh memakai nomor penanggung jawab sementara.')
                              .tr(context),
                      helperMaxLines: 2,
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    onFieldSubmitted: (_) => _create(),
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      return RegExp(
                            r'^(?:0[0-9]{8,13}|62[0-9]{8,13})$',
                          ).hasMatch(phone)
                          ? null
                          : ('Gunakan nomor aktif yang diawali 0 atau 62').tr(
                              context,
                            );
                    },
                  ),
                  const SizedBox(height: 12),
                  PosBusinessProfileSelector(
                    value: _profile,
                    catalog: _profileCatalog,
                    onChanged: _saving
                        ? null
                        : (profile) => setState(() => _profile = profile),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.workspace_premium_outlined,
                          color: Color(0xFF087F75),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: PosText(
                            'Paket trial akan aktif otomatis setelah profil usaha berhasil dibuat.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_logoError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PosText(
                        _logoError!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                  if (_workspaceCreated && !_saving)
                    TextButton(
                      onPressed: _continue,
                      child: const PosText('Lanjutkan tanpa logo'),
                    ),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: _saving ? null : _create,
                      style: FilledButton.styleFrom(
                        disabledBackgroundColor: AppColors.primary,
                        disabledForegroundColor: Colors.white,
                      ),
                      child: _saving
                          ? Semantics(
                              liveRegion: true,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: PosText(
                                      _savingLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : PosText(
                              _workspaceCreated
                                  ? (_logo == null
                                        ? 'Lanjutkan'
                                        : 'Coba unggah logo lagi')
                                  : 'Buat Profil & Lanjutkan',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
