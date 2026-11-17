import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'dart:async';
import '../../../core/notifications/pos_push_service.dart';
import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/themes/colors_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../injections.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../bloc/lock/lock_cubit.dart';
import '../pos/pos_onboarding_page.dart';

class BusinessSetupPage extends StatefulWidget {
  const BusinessSetupPage({super.key});

  @override
  State<BusinessSetupPage> createState() => _BusinessSetupPageState();
}

class _BusinessSetupPageState extends State<BusinessSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _businessName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving || !(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final result = await sl<AuthRepository>().createWorkspace(
      businessName: _businessName.text.trim(),
      phone: _phone.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: PosText(failure.message),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      ),
      (_) {
        // The workspace now exists, so PIN setup/verification can safely load
        // its operator list. After unlock the user continues to POS onboarding.
        context.read<AppLockCubit>().lock();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const PosOnboardingGate()),
          (route) => false,
        );
        if (sl.isRegistered<PosPushService>()) {
          unawaited(sl<PosPushService>().activate());
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF087F75),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        PosText(
                          'Profil ini menjadi workspace utama untuk toko atau organisasi, produk, kasir, laporan, dan trial Pantoo Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          errorBuilder: posValidationError,
                          controller: _businessName,
                          autofocus: true,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            labelText: ('Nama Usaha/Organisasi').tr(context),
                            hintText:
                                ('Contoh: Toko Pantoo Jaya atau Koperasi Maju')
                                    .tr(context),
                            prefixIcon: Icon(Icons.storefront_outlined),
                          ),
                          validator: (value) => (value?.trim().length ?? 0) < 3
                              ? ('Nama usaha atau organisasi minimal 3 karakter')
                                    .tr(context)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          errorBuilder: posValidationError,
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          maxLength: 15,
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            labelText: ('Nomor Telepon Usaha/Organisasi').tr(
                              context,
                            ),
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
                                : ('Gunakan nomor aktif yang diawali 0 atau 62')
                                      .tr(context);
                          },
                        ),
                        const SizedBox(height: 12),
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
                        SizedBox(
                          height: 50,
                          child: FilledButton(
                            onPressed: _saving ? null : _create,
                            child: _saving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const PosText('Buat Profil & Lanjutkan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
