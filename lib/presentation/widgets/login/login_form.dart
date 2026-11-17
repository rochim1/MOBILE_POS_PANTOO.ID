import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:mobile_pos_pantoo/l10n/language_picker.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/themes/colors_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/flavor/flavor_config.dart';
import '../../../core/network/graphql_client_provider.dart';
import '../../pages/login/register_page.dart';
import 'legal_links.dart';
import 'google_account_button.dart';

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
  bool _googleBusy = false;

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
    if (status.canRetrySubscription) {
      context.read<AuthCubit>().retrySubscription();
      return;
    }
    if (status.isCheckingSession ||
        status.isAuthenticating ||
        status.isAuthenticated) {
      return;
    }
    if (_googleBusy || _formKey.currentState?.validate() != true) return;
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
          title: const PosText('Dev: Custom Endpoint'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: (GraphQLClientProvider.developmentEndpoint).tr(context),
              labelText: ('GraphQL Endpoint').tr(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const PosText('Batal'),
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
                      content: PosText(
                        'Endpoint tersimpan. Mohon restart aplikasi/hot restart.',
                      ),
                    ),
                  );
                }
              },
              child: const PosText('Simpan'),
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
            _googleBusy ||
            state.isCheckingSession ||
            state.isAuthenticating ||
            state.isAuthenticated;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: LanguagePicker(),
            ),
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
                      PosText(
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
                      tooltip: ('Set API Endpoint').tr(context),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            GoogleAccountButton(
              enabled:
                  !_googleBusy &&
                  !state.isCheckingSession &&
                  !state.isAuthenticating &&
                  !state.isAuthenticated,
              onBusyChanged: (value) => setState(() => _googleBusy = value),
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    errorBuilder: posValidationError,
                    controller: _usernameController,
                    readOnly: isLoading || state.canRetrySubscription,
                    decoration: InputDecoration(
                      labelText: ('Username').tr(context),
                    ),
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      if (context.read<AuthCubit>().state.captcha != null) {
                        _captchaController.clear();
                        context.read<AuthCubit>().clearCaptcha();
                      }
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return ('Username wajib diisi').tr(context);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    errorBuilder: posValidationError,
                    controller: _passwordController,
                    readOnly: isLoading || state.canRetrySubscription,
                    decoration: InputDecoration(
                      labelText: ('Password').tr(context),
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
                        return ('Password wajib diisi').tr(context);
                      }
                      return null;
                    },
                  ),
                  if (state.captcha != null) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PosText(
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
                      semanticLabel: ('Kode CAPTCHA enam karakter').tr(context),
                      errorBuilder: (_, __, ___) => const PosText(
                        'Gambar CAPTCHA tidak dapat ditampilkan. Coba login kembali.',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      errorBuilder: posValidationError,
                      controller: _captchaController,
                      focusNode: _captchaFocusNode,
                      decoration: InputDecoration(
                        labelText: ('Kode CAPTCHA').tr(context),
                        hintText: ('Ketik enam karakter pada gambar').tr(
                          context,
                        ),
                      ),
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onLoginTap(),
                      validator: (value) {
                        if (state.captcha == null) return null;
                        if ((value?.trim().length ?? 0) != 6) {
                          return ('Masukkan enam karakter CAPTCHA').tr(context);
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
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: PosText(
                                    state.isCheckingSubscription
                                        ? 'Memeriksa langganan…'
                                        : 'Memproses login…',
                                  ),
                                ),
                              ],
                            )
                          : PosText(
                              state.canRetrySubscription
                                  ? 'Coba lagi'
                                  : 'Masuk',
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (state.canRetrySubscription)
                    TextButton(
                      onPressed: () => context.read<AuthCubit>().logout(),
                      child: const PosText('Ganti akun'),
                    ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 2,
                    runSpacing: 0,
                    children: [
                      const PosText('Belum punya akun?'),
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: isLoading || state.canRetrySubscription
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const RegisterPage(),
                                ),
                              ),
                        child: const PosText('Daftar sekarang'),
                      ),
                    ],
                  ),
                  if (!state.isAuthenticated &&
                      state.isFailure &&
                      state.captcha == null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.error ?? ('Login gagal.').tr(context),
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
