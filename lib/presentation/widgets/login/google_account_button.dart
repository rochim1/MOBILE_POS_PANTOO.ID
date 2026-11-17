import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/error/failures.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../../core/auth/google_identity_service.dart';
import 'google_registration_details.dart';
import 'google_button_stub.dart'
    if (dart.library.js_interop) 'google_button_web.dart'
    as web;

class GoogleAccountButton extends StatefulWidget {
  const GoogleAccountButton({
    super.key,
    this.enabled = true,
    this.onBusyChanged,
    this.prepareEndpoint,
  });
  final bool enabled;
  final ValueChanged<bool>? onBusyChanged;
  final Future<void> Function()? prepareEndpoint;

  @override
  State<GoogleAccountButton> createState() => _GoogleAccountButtonState();
}

class _GoogleAccountButtonState extends State<GoogleAccountButton> {
  bool get _supported =>
      kIsWeb ||
      const [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      ].contains(defaultTargetPlatform);
  StreamSubscription<GoogleSignInAuthenticationEvent>? _events;
  bool _ready = false;
  bool _busy = false;
  String _progress = 'Menyiapkan login Google…';
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_supported) _initialize();
  }

  Future<void> _initialize() async {
    if (mounted) {
      setState(() {
        _ready = false;
        _error = null;
      });
    }
    try {
      await widget.prepareEndpoint?.call().timeout(const Duration(seconds: 15));
      await GoogleIdentityService.initialize(
        GetIt.I<AuthRepository>(),
      ).timeout(const Duration(seconds: 20));
      if (!mounted) return;
      if (kIsWeb) {
        _events = GoogleSignIn.instance.authenticationEvents.listen(
          (event) {
            // The login page can remain mounted below the registration route.
            if (event is GoogleSignInAuthenticationEventSignIn &&
                mounted &&
                (ModalRoute.of(context)?.isCurrent ?? true)) {
              unawaited(_submitAccount(event.user));
            }
          },
          onError: (Object error) {
            if (error is GoogleSignInException &&
                error.code == GoogleSignInExceptionCode.canceled) {
              return;
            }
            if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) {
              _showError('Google belum dapat dihubungkan. Silakan coba lagi.');
            }
          },
        );
      }
      setState(() {
        _ready = true;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Google belum tersedia. Anda tetap bisa masuk atau daftar dengan email.',
        );
      }
    }
  }

  void _setBusy(bool value) {
    if (!mounted) return;
    setState(() {
      _busy = value;
      if (value) {
        _error = null;
        _progress = 'Menyiapkan login Google…';
      }
    });
    widget.onBusyChanged?.call(value);
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: PosText(message)));
  }

  Future<void> _authenticate() async {
    if (_busy || !widget.enabled) return;
    _setBusy(true);
    try {
      final cubit = context.read<AuthCubit>();
      if (cubit.state.canRetrySubscription) {
        await cubit.retrySubscription();
        return;
      }
      await widget.prepareEndpoint?.call().timeout(const Duration(seconds: 15));
      await GoogleIdentityService.initialize(
        GetIt.I<AuthRepository>(),
      ).timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() => _progress = 'Menunggu pilihan akun Google…');
      final account = await GoogleSignIn.instance.authenticate().timeout(
        const Duration(seconds: 90),
      );
      if (mounted) await _login(account);
    } on GoogleSignInException catch (error) {
      if (mounted && error.code != GoogleSignInExceptionCode.canceled) {
        _showError(
          'Login Google belum berhasil. Coba lagi atau gunakan email dan password.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showError('Google belum dapat dihubungkan. Silakan coba lagi.');
      }
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _submitAccount(GoogleSignInAccount account) async {
    if (_busy || !widget.enabled) return;
    _setBusy(true);
    try {
      await widget.prepareEndpoint?.call().timeout(const Duration(seconds: 15));
      if (!mounted) return;
      await _login(account);
    } catch (_) {
      if (mounted) {
        _showError('Login Google belum berhasil. Silakan coba lagi.');
      }
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _login(GoogleSignInAccount account) async {
    setState(() => _progress = 'Memverifikasi akun ke Pantoo POS…');
    final token = account.authentication.idToken;
    if (token == null || token.isEmpty) {
      _showError('Google belum memberikan verifikasi akun. Silakan coba lagi.');
      return;
    }
    final cubit = context.read<AuthCubit>();
    if (cubit.state.isAuthenticating || cubit.state.isAuthenticated) {
      return;
    }
    final failure = await cubit.loginGoogle(token);
    if (!mounted || cubit.isClosed) return;
    if (failure is! GoogleRegistrationRequiredFailure) {
      if (failure != null) _showError(failure.message);
      return;
    }
    setState(() => _progress = 'Lengkapi informasi akun untuk melanjutkan.');
    final phone = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const GoogleRegistrationDetails(),
    );
    if (!mounted || cubit.isClosed || phone == null) return;
    setState(() => _progress = 'Menyelesaikan pendaftaran…');
    final registrationFailure = await cubit.loginGoogle(
      token,
      phone: phone,
      consent: true,
    );
    if (mounted && registrationFailure != null) {
      _showError(registrationFailure.message);
    }
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => !_supported
      ? const SizedBox.shrink()
      : BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_ready && kIsWeb && !state.canRetrySubscription)
                IgnorePointer(
                  ignoring:
                      _busy ||
                      !widget.enabled ||
                      state.isAuthenticating ||
                      state.isAuthenticated,
                  child: LayoutBuilder(
                    builder: (_, constraints) => Center(
                      child: web.googleWebButton(constraints.maxWidth),
                    ),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed:
                      !widget.enabled ||
                          _busy ||
                          state.isAuthenticating ||
                          state.isAuthenticated
                      ? null
                      : state.canRetrySubscription || _ready
                      ? _authenticate
                      : _error == null
                      ? null
                      : _initialize,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.g_mobiledata),
                  label: Text(
                    state.canRetrySubscription
                        ? ('Coba lagi').tr(context)
                        : state.isCheckingSubscription
                        ? ('Memeriksa langganan…').tr(context)
                        : _error == null
                        ? ('Lanjutkan dengan Google').tr(context)
                        : ('Coba hubungkan Google').tr(context),
                  ),
                ),
              if (_busy ||
                  state.isCheckingSubscription ||
                  (!_ready && _error == null))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(
                    liveRegion: true,
                    child: Column(
                      children: [
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          state.isCheckingSubscription
                              ? ('Memeriksa langganan…').tr(context)
                              : _busy
                              ? _progress
                              : ('Menyiapkan login Google…').tr(context),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              if (_error != null || state.canRetrySubscription)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: PosText(
                    state.canRetrySubscription ? state.error! : _error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: PosText('atau dengan email'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
}
