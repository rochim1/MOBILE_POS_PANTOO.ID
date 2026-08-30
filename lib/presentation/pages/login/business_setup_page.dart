import 'package:flutter/material.dart';
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
    if (!_formKey.currentState!.validate() || _saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    final result = await sl<AuthRepository>().createWorkspace(
      businessName: _businessName.text,
      phone: _phone.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failure.message),
          backgroundColor: Colors.red.shade700,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0f8177),
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
                        Text(
                          'Siapkan Profil Usaha',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Profil ini menjadi workspace utama untuk toko, produk, kasir, laporan, dan trial Pantoo Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _businessName,
                          autofocus: true,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nama usaha',
                            hintText: 'Contoh: Toko Pantoo Jaya',
                            prefixIcon: Icon(Icons.storefront_outlined),
                          ),
                          validator: (value) => (value?.trim().length ?? 0) < 3
                              ? 'Nama usaha minimal 3 karakter'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          maxLength: 15,
                          decoration: const InputDecoration(
                            labelText: 'Nomor telepon usaha',
                            hintText: '08xxxxxxxxxx',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          onFieldSubmitted: (_) => _create(),
                          validator: (value) {
                            final length = value?.length ?? 0;
                            return length < 8 || length > 15
                                ? 'Nomor telepon harus 8–15 digit'
                                : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xffe8f5f3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.workspace_premium_outlined,
                                color: Color(0xff0f8177),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
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
                                : const Text('Buat Profil & Lanjutkan'),
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
