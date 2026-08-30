import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../injections.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../bloc/auth/register_cubit.dart';
import '../../bloc/auth/register_state.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RegisterCubit>(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  Timer? _usernameDebounce;
  Timer? _emailDebounce;
  bool _hidePassword = true;
  bool _hideConfirmation = true;

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _emailDebounce?.cancel();
    _name.dispose();
    _username.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _checkUsername(String raw) {
    final cubit = context.read<RegisterCubit>();
    final value = cubit.sanitizeUsername(raw);
    if (value != raw) {
      _username.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
    _usernameDebounce?.cancel();
    _usernameDebounce = Timer(
      const Duration(milliseconds: 500),
      () => cubit.checkUsername(value),
    );
  }

  void _checkEmail(String value) {
    _emailDebounce?.cancel();
    _emailDebounce = Timer(
      const Duration(milliseconds: 500),
      () => context.read<RegisterCubit>().checkEmail(value),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    TextInput.finishAutofillContext(shouldSave: true);
    await context.read<RegisterCubit>().register(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      username: _username.text,
      email: _email.text,
      password: _password.text,
    );
  }

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xfff7f8fa),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Widget _availability({
    required bool checking,
    required bool? available,
    required String noun,
  }) {
    if (checking) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 7),
            Text('Memeriksa...', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }
    if (available == null) return const SizedBox.shrink();
    final color = available ? Colors.green.shade700 : Colors.red.shade700;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            available ? '$noun tersedia' : '$noun sudah digunakan',
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterCubit, RegisterState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) async {
        if (state.status == RegisterStatus.success) {
          var resending = false;
          await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => StatefulBuilder(
              builder: (dialogContext, setDialogState) => AlertDialog(
                icon: const Icon(Icons.mark_email_read_outlined, size: 48),
                title: const Text('Pendaftaran Berhasil'),
                content: Text(
                  'Email verifikasi telah dikirim ke ${_email.text.trim()}. '
                  'Verifikasi akun terlebih dahulu, lalu masuk untuk menyiapkan POS Anda.',
                ),
                actions: [
                  TextButton(
                    onPressed: resending
                        ? null
                        : () async {
                            setDialogState(() => resending = true);
                            final result = await sl<AuthRepository>()
                                .resendActivationEmail(_email.text);
                            if (!dialogContext.mounted) return;
                            setDialogState(() => resending = false);
                            final message = result.fold(
                              (failure) => failure.message,
                              (success) => success,
                            );
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                    child: Text(
                      resending ? 'Mengirim...' : 'Kirim Ulang Email',
                    ),
                  ),
                  FilledButton(
                    onPressed: resending
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Kembali ke Login'),
                  ),
                ],
              ),
            ),
          );
          if (context.mounted) Navigator.pop(context);
        } else if (state.status == RegisterStatus.failure &&
            state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/geometric_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: AutofillGroup(
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Image.asset(
                                      'assets/images/pantoo.png',
                                      height: 58,
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'Daftar POS Mobile',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Mulai trial Pantoo Unlimited dan siapkan toko Anda dalam beberapa langkah.',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Colors.grey.shade700,
                                          ),
                                    ),
                                    const SizedBox(height: 24),
                                    TextFormField(
                                      controller: _name,
                                      decoration: _decoration(
                                        'Nama lengkap',
                                        Icons.person_outline,
                                      ),
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [AutofillHints.name],
                                      validator: (value) =>
                                          (value?.trim().length ?? 0) < 3
                                          ? 'Nama minimal 3 karakter'
                                          : null,
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _username,
                                      decoration: _decoration(
                                        'Username',
                                        Icons.alternate_email,
                                      ),
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.newUsername,
                                      ],
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[a-zA-Z0-9._-]'),
                                        ),
                                      ],
                                      onChanged: _checkUsername,
                                      validator: (value) {
                                        if ((value?.trim().length ?? 0) < 3) {
                                          return 'Username minimal 3 karakter';
                                        }
                                        if (!RegExp(
                                          r'^[a-zA-Z0-9._-]+$',
                                        ).hasMatch(value ?? '')) {
                                          return 'Gunakan huruf, angka, titik, _ atau -';
                                        }
                                        if (state.usernameAvailable == false) {
                                          return 'Username sudah digunakan';
                                        }
                                        return null;
                                      },
                                    ),
                                    _availability(
                                      checking: state.checkingUsername,
                                      available: state.usernameAvailable,
                                      noun: 'Username',
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _email,
                                      decoration: _decoration(
                                        'Email',
                                        Icons.email_outlined,
                                      ),
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      onChanged: _checkEmail,
                                      validator: (value) {
                                        final valid = RegExp(
                                          r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                        ).hasMatch(value?.trim() ?? '');
                                        if (!valid) {
                                          return 'Masukkan email yang valid';
                                        }
                                        if (state.emailAvailable == false) {
                                          return 'Email sudah digunakan';
                                        }
                                        return null;
                                      },
                                    ),
                                    _availability(
                                      checking: state.checkingEmail,
                                      available: state.emailAvailable,
                                      noun: 'Email',
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _phone,
                                      decoration: _decoration(
                                        'Nomor telepon',
                                        Icons.phone_outlined,
                                      ),
                                      keyboardType: TextInputType.phone,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.telephoneNumber,
                                      ],
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      maxLength: 15,
                                      validator: (value) {
                                        final length = value?.length ?? 0;
                                        return length < 8 || length > 15
                                            ? 'Nomor telepon harus 8–15 digit'
                                            : null;
                                      },
                                    ),
                                    const SizedBox(height: 4),
                                    TextFormField(
                                      controller: _password,
                                      decoration: _decoration(
                                        'Password',
                                        Icons.lock_outline,
                                        suffix: IconButton(
                                          onPressed: () => setState(
                                            () =>
                                                _hidePassword = !_hidePassword,
                                          ),
                                          icon: Icon(
                                            _hidePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                        ),
                                      ),
                                      obscureText: _hidePassword,
                                      textInputAction: TextInputAction.next,
                                      autofillHints: const [
                                        AutofillHints.newPassword,
                                      ],
                                      validator: (value) =>
                                          (value?.length ?? 0) < 8
                                          ? 'Password minimal 8 karakter'
                                          : null,
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _confirmation,
                                      decoration: _decoration(
                                        'Konfirmasi password',
                                        Icons.lock_reset_outlined,
                                        suffix: IconButton(
                                          onPressed: () => setState(
                                            () => _hideConfirmation =
                                                !_hideConfirmation,
                                          ),
                                          icon: Icon(
                                            _hideConfirmation
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                        ),
                                      ),
                                      obscureText: _hideConfirmation,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.newPassword,
                                      ],
                                      onFieldSubmitted: (_) => _submit(),
                                      validator: (value) =>
                                          value != _password.text
                                          ? 'Konfirmasi password tidak sama'
                                          : null,
                                    ),
                                    const SizedBox(height: 22),
                                    SizedBox(
                                      height: 50,
                                      child: FilledButton(
                                        onPressed: state.isSubmitting
                                            ? null
                                            : _submit,
                                        child: state.isSubmitting
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Text(
                                                'Daftar & Mulai Trial',
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text.rich(
                                      TextSpan(
                                        text: 'Sudah punya akun? ',
                                        children: [
                                          TextSpan(
                                            text: 'Masuk',
                                            style: const TextStyle(
                                              color: Color(0xff0f8177),
                                              fontWeight: FontWeight.w700,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () =>
                                                  Navigator.pop(context),
                                          ),
                                        ],
                                      ),
                                      textAlign: TextAlign.center,
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
                ),
                Positioned(
                  top: 8,
                  left: 12,
                  child: SafeArea(
                    child: Material(
                      color: Colors.white,
                      elevation: 3,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Kembali ke login',
                        onPressed: state.isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
