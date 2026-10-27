import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../core/error/failures.dart';
import '../../bloc/auth/auth_cubit.dart';
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
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_supported) _initialize();
  }

  Future<void> _initialize() async {
    if (mounted) setState(() => _error = null);
    try {
      await widget.prepareEndpoint?.call();
      await GoogleIdentityService.initialize(GetIt.I<AuthRepository>());
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
    setState(() => _busy = value);
    widget.onBusyChanged?.call(value);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _authenticate() async {
    if (_busy || !widget.enabled) return;
    _setBusy(true);
    try {
      await widget.prepareEndpoint?.call();
      await GoogleIdentityService.initialize(GetIt.I<AuthRepository>());
      if (!mounted) return;
      final account = await GoogleSignIn.instance.authenticate();
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
      await widget.prepareEndpoint?.call();
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
    final phone = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const GoogleRegistrationDetails(),
    );
    if (!mounted || cubit.isClosed || phone == null) return;
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
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_ready && kIsWeb)
              IgnorePointer(
                ignoring: _busy || !widget.enabled,
                child: LayoutBuilder(
                  builder: (_, constraints) =>
                      Center(child: web.googleWebButton(constraints.maxWidth)),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: !widget.enabled || _busy
                    ? null
                    : _ready
                    ? _authenticate
                    : _error == null
                    ? null
                    : _initialize,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.g_mobiledata),
                label: Text(
                  _error == null
                      ? 'Lanjutkan dengan Google'
                      : 'Coba hubungkan Google',
                ),
              ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
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
                  child: Text('atau dengan email'),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
          ],
        );
}
