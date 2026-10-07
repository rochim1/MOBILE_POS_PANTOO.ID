import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/themes/colors_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/flavor/flavor_config.dart';
import '../../pages/login/register_page.dart';
import 'legal_links.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();
  final _captchaFocusNode = FocusNode();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (GetIt.I<FlavorConfig>().environment == FlavorEnvironment.development) {
      _usernameController.text = 'putrabangsacendikia';
      _passwordController.text = 'kuitansiku3';
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    _captchaFocusNode.dispose();
    super.dispose();
  }

  void _onLoginTap() {
    final status = context.read<AuthCubit>().state;
    if (status.isCheckingSession ||
        status.isAuthenticating ||
        status.isAuthenticated) {
      return;
    }
    if (_formKey.currentState?.validate() != true) return;
    context.read<AuthCubit>().login(
      _usernameController.text.trim(),
      _passwordController.text,
      captchaAnswer: status.captcha == null
          ? null
          : _captchaController.text.trim(),
    );
  }

  void _showEndpointDialog() async {
    final prefs = GetIt.I<SharedPreferences>();
    final currentEndpoint = prefs.getString('custom_endpoint') ?? '';
    final controller = TextEditingController(text: currentEndpoint);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dev: Custom Endpoint'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'http://10.0.2.2:4000/graphql',
              labelText: 'GraphQL Endpoint',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                final val = controller.text.trim();
                if (val.isEmpty) {
                  await prefs.remove('custom_endpoint');
                } else {
                  await prefs.setString('custom_endpoint', val);
                }
                if (context.mounted) Navigator.pop(context);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Endpoint tersimpan. Mohon restart aplikasi/hot restart.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state.isFailure) _captchaController.clear();
      },
      builder: (context, state) {
        final isLoading =
            state.isCheckingSession ||
            state.isAuthenticating ||
            state.isAuthenticated;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 80,
                        child: Image.asset(
                          'assets/images/pantoo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Masuk ke POS Mobile',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                if (GetIt.I<FlavorConfig>().environment ==
                    FlavorEnvironment.development)
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.settings_ethernet,
                        color: Colors.grey,
                      ),
                      onPressed: _showEndpointDialog,
                      tooltip: 'Set API Endpoint',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (context.read<AuthCubit>().state.captcha != null) {
                        _captchaController.clear();
                        context.read<AuthCubit>().clearCaptcha();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Username wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (state.captcha != null) {
                        _captchaFocusNode.requestFocus();
                      } else {
                        _onLoginTap();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password wajib diisi';
                      }
                      return null;
                    },
                  ),
                  if (state.captcha != null) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Verifikasi CAPTCHA',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Image.memory(
                      base64Decode(state.captcha!.image.split(',').last),
                      width: 190,
                      height: 55,
                      fit: BoxFit.contain,
                      semanticLabel: 'Kode CAPTCHA enam karakter',
                      errorBuilder: (_, __, ___) => const Text(
                        'Gambar CAPTCHA tidak dapat ditampilkan. Coba login kembali.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _captchaController,
                      focusNode: _captchaFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Kode CAPTCHA',
                        hintText: 'Ketik enam karakter pada gambar',
                      ),
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onLoginTap(),
                      validator: (value) {
                        if (state.captcha == null) return null;
                        if ((value?.trim().length ?? 0) != 6) {
                          return 'Masukkan enam karakter CAPTCHA';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _onLoginTap,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Masuk'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 2,
                    runSpacing: 0,
                    children: [
                      const Text('Belum punya akun?'),
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const RegisterPage(),
                                ),
                              ),
                        child: const Text('Daftar sekarang'),
                      ),
                    ],
                  ),
                  if (!state.isAuthenticated &&
                      state.isFailure &&
                      state.captcha == null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.error ?? 'Login gagal.',
                      style: const TextStyle(color: AppColors.danger),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  const PantooLegalLinks(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
