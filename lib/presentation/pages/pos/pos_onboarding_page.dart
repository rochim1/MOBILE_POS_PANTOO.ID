import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'dart:convert';
import '../../../../domain/models/pos_remote_profile_catalog.dart';
import '../../../../domain/models/pos_settings.dart';
import '../../../../domain/repositories/pos_repository.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/_core.dart';
import '../../../../domain/repositories/pos_settings_repository.dart';
import '../../../../injections.dart';
import 'pos_shell_page.dart';
import '../login/business_setup_page.dart';
import '../../widgets/pos_business_profile_selector.dart';
import '../../widgets/pos_setup_scaffold.dart';

class PosOnboardingPage extends StatefulWidget {
  const PosOnboardingPage({super.key, this.onCompleted});

  /// An embedding host may own navigation after the confirmed setup is saved.
  final VoidCallback? onCompleted;

  static String pendingProfileKey(SharedPreferences prefs) =>
      'pos_initial_business_profile_v1:${prefs.getString('instansi_id') ?? 'unknown-instansi'}:${prefs.getString('user_id') ?? 'unknown-user'}';

  static String preferenceKey(SharedPreferences prefs) {
    final userId = prefs.getString('user_id') ?? 'unknown-user';
    final instansiId = prefs.getString('instansi_id') ?? 'unknown-instansi';
    return 'pos_onboarding_completed_v2:$instansiId:$userId';
  }

  static bool isCompleted(SharedPreferences prefs) =>
      prefs.getBool(preferenceKey(prefs)) ?? false;

  static bool? canManageSettings(SharedPreferences prefs) {
    final raw = prefs.getString('pos_runtime_config');
    if (raw == null || raw.isEmpty) return null;
    try {
      final runtime = jsonDecode(raw);
      final permissions = runtime is Map ? runtime['permissions'] : null;
      if (permissions is! Map || !permissions.containsKey('manage_settings')) {
        return null;
      }
      return permissions['manage_settings'] == true;
    } catch (_) {
      return null;
    }
  }

  static String setupPreferenceKey(SharedPreferences prefs) {
    final userId = prefs.getString('user_id') ?? 'unknown-user';
    final instansiId = prefs.getString('instansi_id') ?? 'unknown-instansi';
    return 'pos_operational_setup_completed_v1:$instansiId:$userId';
  }

  static String tenantSetupPreferenceKey(SharedPreferences prefs) {
    final instansiId = prefs.getString('instansi_id') ?? 'unknown-instansi';
    return 'pos_operational_setup_completed_v2:$instansiId';
  }

  static String cashierTourPreferenceKey(SharedPreferences prefs) {
    final userId = prefs.getString('user_id') ?? 'unknown-user';
    final instansiId = prefs.getString('instansi_id') ?? 'unknown-instansi';
    return 'pos_cashier_tour_v1:$instansiId:$userId';
  }

  static bool isOperationalSetupCompleted(SharedPreferences prefs) {
    if (prefs.getBool(tenantSetupPreferenceKey(prefs)) ?? false) return true;
    if (prefs.getBool(setupPreferenceKey(prefs)) ?? false) return true;
    if (prefs.getBool(cashierTourPreferenceKey(prefs)) ?? false) return true;

    // Migrasi instalasi lama: setup operasional adalah kesiapan instansi,
    // bukan milik satu akun login. Terima flag user lama dari instansi yang
    // sama agar pergantian admin/operator tidak mengulang ringkasan setup.
    final instansiId = prefs.getString('instansi_id') ?? 'unknown-instansi';
    final legacySetupPrefix = 'pos_operational_setup_completed_v1:$instansiId:';
    final legacyTourPrefix = 'pos_cashier_tour_v1:$instansiId:';
    return prefs.getKeys().any(
      (key) =>
          (key.startsWith(legacySetupPrefix) ||
              key.startsWith(legacyTourPrefix)) &&
          (prefs.getBool(key) ?? false),
    );
  }

  static Future<void> markOperationalSetupCompleted(
    SharedPreferences prefs,
  ) async {
    // Simpan kedua flag secara atomik dari sudut pandang flow aplikasi.
    // Flag tour dipertahankan untuk kompatibilitas dengan instalasi lama.
    await prefs.setBool(cashierTourPreferenceKey(prefs), true);
    await prefs.setBool(setupPreferenceKey(prefs), true);
    await prefs.setBool(tenantSetupPreferenceKey(prefs), true);
    try {
      await sl<PosSettingsRepository>().markOperationalSetupCompleted();
    } catch (_) {
      // Cache lokal tetap menjaga flow kasir saat backend sedang offline.
    }
  }

  static Future<void> clearOperationalSetupCompleted(
    SharedPreferences prefs,
  ) async {
    final instansiId = prefs.getString('instansi_id') ?? 'unknown-instansi';
    final keys = prefs
        .getKeys()
        .where(
          (key) =>
              key == tenantSetupPreferenceKey(prefs) ||
              key.startsWith(
                'pos_operational_setup_completed_v1:$instansiId:',
              ) ||
              key.startsWith('pos_cashier_tour_v1:$instansiId:'),
        )
        .toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  static Widget initialDestination(SharedPreferences prefs) {
    final needsWorkspace =
        prefs.getBool('needs_workspace_setup') == true ||
        (prefs.getString('instansi_id')?.trim().isEmpty ?? true);
    return needsWorkspace
        ? const BusinessSetupPage()
        : const PosOnboardingGate();
  }

  @override
  State<PosOnboardingPage> createState() => _PosOnboardingPageState();
}

class PosOnboardingGate extends StatefulWidget {
  const PosOnboardingGate({super.key});

  @override
  State<PosOnboardingGate> createState() => _PosOnboardingGateState();
}

class _PosOnboardingGateState extends State<PosOnboardingGate> {
  Widget? _destination;
  String? _setupError;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    if (_resolving) return;
    _resolving = true;
    if (mounted) setState(() => _setupError = null);
    final prefs = sl<SharedPreferences>();
    Map<String, dynamic> runtime = {};
    try {
      runtime = Map<String, dynamic>.from(
        jsonDecode(prefs.getString('pos_runtime_config') ?? '{}') as Map,
      );
    } catch (_) {
      /* Old installations can have no runtime cache. */
    }
    final initial = runtime['initial_setup'];
    if (initial is Map &&
        initial['automatic'] == true &&
        initial['status'] == 'pending' &&
        initial['can_manage'] == true) {
      final recovery = await sl<PosSettingsRepository>().ensureInitialSetup();
      if (!mounted) return;
      if (recovery.isLeft()) {
        _resolving = false;
        recovery.fold(
          (failure) => setState(() => _setupError = failure.message),
          (_) {},
        );
        return;
      }
      recovery.fold(
        (_) {},
        (value) => runtime['initial_setup'] = {
          ...Map<String, dynamic>.from(initial),
          'status': value['status'],
        },
      );
      await prefs.setString('pos_runtime_config', jsonEncode(runtime));
    }
    final result = await sl<PosSettingsRepository>().getSettings();
    final destination = await result.fold<Future<Widget>>(
      (_) async {
        // Saat server tidak dapat dijangkau, cache lokal hanya dipakai sebagai
        // fallback agar kasir yang sudah pernah setup tetap dapat bekerja.
        if (PosOnboardingPage.isCompleted(prefs) ||
            PosOnboardingPage.canManageSettings(prefs) == false) {
          await prefs.setBool(PosOnboardingPage.preferenceKey(prefs), true);
          return PosShellPage(
            showSetupGuide: !PosOnboardingPage.isOperationalSetupCompleted(
              prefs,
            ),
          );
        }
        return const PosOnboardingPage();
      },
      (settings) async {
        final completed = settings.onboardingCompleted == true;
        if (completed) {
          await prefs.remove(PosOnboardingPage.pendingProfileKey(prefs));
        }
        await prefs.setBool(PosOnboardingPage.preferenceKey(prefs), completed);
        if (!completed) {
          // Reset dari Web Admin/database harus menang terhadap cache perangkat.
          await PosOnboardingPage.clearOperationalSetupCompleted(prefs);
          // Setup awal milik tenant. Operator tanpa izin kelola tetap masuk
          // POS, bukan terjebak di wizard baca-saja yang tidak dapat mereka simpan.
          if (PosOnboardingPage.canManageSettings(prefs) == false) {
            await prefs.setBool(PosOnboardingPage.preferenceKey(prefs), true);
            return const PosShellPage();
          }
          return const PosOnboardingPage();
        }
        if (settings.operationalSetupCompleted == true) {
          await prefs.setBool(
            PosOnboardingPage.tenantSetupPreferenceKey(prefs),
            true,
          );
        } else if (PosOnboardingPage.isOperationalSetupCompleted(prefs)) {
          // Migrasikan instalasi lama yang sebelumnya hanya menyimpan progres
          // tour secara lokal ke status per-instansi di server.
          await sl<PosSettingsRepository>().markOperationalSetupCompleted();
        }
        return PosShellPage(
          showSetupGuide: !PosOnboardingPage.isOperationalSetupCompleted(prefs),
        );
      },
    );
    if (!mounted) return;
    _resolving = false;
    setState(() => _destination = destination);
  }

  @override
  Widget build(BuildContext context) =>
      _destination ??
      PosSetupScaffold(
        backgroundDecoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/geometric_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        body: Center(
          child: _setupError == null
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PosText(_setupError!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _resolveDestination,
                        child: const PosText('Coba lagi'),
                      ),
                    ],
                  ),
                ),
        ),
      );
}

class _PosOnboardingPageState extends State<PosOnboardingPage> {
  PosRemoteProfileCatalog _catalog = PosRemoteProfileCatalog.bundled();
  Map<String, dynamic> _config = {};
  String _profile = 'retail', _fulfillment = 'take_away';
  Map<String, bool> _features = {};
  PosSettings? _settings;
  bool _loading = true, _saving = false;
  String? _error;
  late final String _scope;

  bool get _sameScope =>
      _scope == PosOnboardingPage.pendingProfileKey(sl<SharedPreferences>());
  bool get _canManage {
    final permissions = _config['permissions'];
    return permissions is Map && permissions['manage_settings'] == true;
  }

  bool get _requiresTracking {
    final inventory = _config['inventory_profile']?.toString() ?? 'simple';
    if (inventory == 'centralized' || inventory == 'advanced') return true;
    final policy = _config['inventory_policy'];
    return inventory == 'custom' &&
        policy is Map &&
        const [
          'use_central_warehouse',
          'use_transfer_request',
          'use_transfer_approval',
          'use_in_transit',
          'use_store_warehouse',
          'use_display_stock',
        ].any((key) => policy[key] == true);
  }

  List<String> get _issues {
    final health = _config['configuration_health'];
    final issues = health is Map && health['issues'] is List
        ? (health['issues'] as List).map((item) => item.toString()).toList()
        : <String>[];
    if (health is Map && health['valid'] == false && issues.isEmpty) {
      issues.add('Konfigurasi POS belum valid');
    }
    if (_requiresTracking && _features['track_stock'] != true) {
      issues.add('Tracking stok POS wajib aktif untuk profil Inventory ini.');
    }
    return issues;
  }

  bool get _validTax {
    final tax = _settings?.pajakPersen ?? 0;
    return tax.isFinite && tax >= 0 && tax <= 100;
  }

  @override
  void initState() {
    super.initState();
    _scope = PosOnboardingPage.pendingProfileKey(sl<SharedPreferences>());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (runtime, result, catalog) = await (
        sl<PosRepository>().getRuntimeConfig(),
        sl<PosSettingsRepository>().getSettings(),
        sl<PosSettingsRepository>().getProfileCatalog(),
      ).wait.timeout(const Duration(seconds: 25));
      if (!mounted || !_sameScope) return;
      final settings = result.fold((failure) {
        _error = failure.message;
        return null;
      }, (value) => value);
      if (settings == null) {
        setState(() => _loading = false);
        return;
      }
      _config = runtime;
      _catalog = catalog;
      _settings = settings;
      _profile = settings.businessProfile ?? 'retail';
      _features = {
        ...catalog.featuresFor(_profile),
        ...settings.enabledFeatures,
      };
      if (_requiresTracking) _features['track_stock'] = true;
      _fulfillment = settings.defaultTipePesanan ?? 'take_away';
      if (_fulfillment == 'online_delivery') _fulfillment = 'delivery';
      if (!catalog.orderTypes(_profile, _features).contains(_fulfillment)) {
        _fulfillment = 'take_away';
      }
      final pending = sl<SharedPreferences>().getString(_scope);
      final shouldComplete =
          pending != null && catalog.profile(pending) != null && _canManage;
      // A committed setup wins over a pending selection after a lost response.
      if (settings.onboardingCompleted == true) {
        await sl<SharedPreferences>().remove(_scope);
        if (mounted && _sameScope) await _openPos();
        return;
      }
      if (shouldComplete) _applyProfile(pending);
      setState(() => _loading = false);
      if (shouldComplete && _issues.isEmpty) await _save();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Konfigurasi POS belum dapat dimuat. Coba lagi.';
      });
    }
  }

  void _applyProfile(String value) {
    _profile = value;
    _features = _catalog.featuresFor(value, current: _features);
    if (_requiresTracking) _features['track_stock'] = true;
    _fulfillment = _catalog.defaultOrderType(
      value,
      _features,
      current: _fulfillment,
    );
  }

  Future<void> _save() async {
    final settings = _settings;
    if (_saving ||
        _loading ||
        settings == null ||
        !_canManage ||
        !_sameScope ||
        _issues.isNotEmpty ||
        !_validTax) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Preserve financial/channel defaults; only the selected profile changes.
      final result = await sl<PosSettingsRepository>()
          .updateSettings({
            'onboarding_completed': true,
            'onboarding_version': 1,
            'business_profile': _profile,
            'enabled_features': {
              for (final entry in _features.entries)
                if (PosSettings.featureFlagKeys.contains(entry.key))
                  entry.key: entry.value,
            },
            'default_channel_penjualan':
                settings.defaultChannelPenjualan ?? 'retail',
            'default_price_level': settings.defaultPriceLevel ?? 'retail',
            'default_tipe_pesanan': _fulfillment,
            'auto_print_receipt': settings.autoPrintReceipt ?? false,
            'pajak_persen': settings.pajakPersen ?? 0,
          })
          .timeout(const Duration(seconds: 25));
      if (!mounted || !_sameScope) return;
      await result.fold(
        (failure) async {
          setState(() {
            _saving = false;
            _error = failure.message;
          });
        },
        (_) async {
          final prefs = sl<SharedPreferences>();
          await prefs.setString(
            'pos_runtime_config',
            jsonEncode({
              ..._config,
              'business_profile': _profile,
              'features': _features,
              'default_sales_channel':
                  settings.defaultChannelPenjualan ?? 'retail',
              'default_price_level': settings.defaultPriceLevel ?? 'retail',
              'default_order_type': _fulfillment,
              'tax_percent': settings.pajakPersen ?? 0,
              'auto_print_receipt': settings.autoPrintReceipt ?? false,
            }),
          );
          await prefs.remove(_scope);
          if (mounted && _sameScope) await _openPos();
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Konfigurasi POS belum dapat dimuat. Coba lagi.';
      });
    }
  }

  Future<void> _openPos() async {
    if (!_sameScope) return;
    final prefs = sl<SharedPreferences>();
    await prefs.setBool(PosOnboardingPage.preferenceKey(prefs), true);
    if (!mounted || !_sameScope) return;
    if (widget.onCompleted case final completed?) {
      setState(() {
        _loading = false;
        _saving = false;
      });
      completed();
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const PosShellPage(prepareSalesData: true, showSetupGuide: true),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) => PosSetupScaffold(
    backgroundColor: AppColors.primary,
    body: PosSetupScrollBody(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/pantoo.png', height: 60),
              const SizedBox(height: 20),
              if (_loading || _saving) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 12),
                const PosText(
                  'Menyiapkan Pantoo POS…',
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                PosText(
                  'Pilih profil usaha',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const PosText(
                  'Fitur operasional mengikuti profil usaha. Sesuaikan nanti di Pengaturan POS → Transaksi & Penjualan.',
                ),
                const SizedBox(height: 22),
                if (_settings != null)
                  PosBusinessProfileSelector(
                    value: _profile,
                    catalog: _catalog,
                    onChanged: !_canManage
                        ? null
                        : (value) => setState(() {
                            _applyProfile(value);
                            _error = null;
                          }),
                  ),
                if (_issues.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  PosText(
                    _issues.join('\n'),
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
                if (!_validTax) ...[
                  const SizedBox(height: 16),
                  const PosText(
                    'Pajak harus antara 0 dan 100 persen',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  PosText(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _settings == null
                      ? _load
                      : !_canManage || _issues.isNotEmpty || !_validTax
                      ? null
                      : _save,
                  child: PosText(_settings == null ? 'Coba lagi' : 'Simpan'),
                ),
                TextButton(onPressed: _openPos, child: const PosText('Lewati')),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
