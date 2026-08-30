import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/_core.dart';
import '../../../../domain/repositories/pos_settings_repository.dart';
import '../../../../injections.dart';
import 'pos_shell_page.dart';
import '../login/business_setup_page.dart';

class PosOnboardingPage extends StatefulWidget {
  const PosOnboardingPage({super.key});

  static String preferenceKey(SharedPreferences prefs) {
    final userId = prefs.getString('user_id') ?? 'unknown-user';
    final instansiId = prefs.getString('instansi_id') ?? 'unknown-instansi';
    return 'pos_onboarding_completed_v2:$instansiId:$userId';
  }

  static bool isCompleted(SharedPreferences prefs) =>
      prefs.getBool(preferenceKey(prefs)) ?? false;
  static String setupPreferenceKey(SharedPreferences prefs) {
    final userId = prefs.getString('user_id') ?? 'unknown-user';
    final instansiId = prefs.getString('instansi_id') ?? 'unknown-instansi';
    return 'pos_operational_setup_completed_v1:$instansiId:$userId';
  }

  static String cashierTourPreferenceKey(SharedPreferences prefs) {
    final userId = prefs.getString('user_id') ?? 'unknown-user';
    final instansiId = prefs.getString('instansi_id') ?? 'unknown-instansi';
    return 'pos_cashier_tour_v1:$instansiId:$userId';
  }

  static bool isOperationalSetupCompleted(SharedPreferences prefs) =>
      (prefs.getBool(setupPreferenceKey(prefs)) ?? false) ||
      (prefs.getBool(cashierTourPreferenceKey(prefs)) ?? false);

  static Future<void> markOperationalSetupCompleted(
    SharedPreferences prefs,
  ) async {
    // Simpan kedua flag secara atomik dari sudut pandang flow aplikasi.
    // Flag tour dipertahankan untuk kompatibilitas dengan instalasi lama.
    await prefs.setBool(cashierTourPreferenceKey(prefs), true);
    await prefs.setBool(setupPreferenceKey(prefs), true);
  }

  static Future<void> clearOperationalSetupCompleted(
    SharedPreferences prefs,
  ) async {
    await prefs.remove(cashierTourPreferenceKey(prefs));
    await prefs.remove(setupPreferenceKey(prefs));
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

  @override
  void initState() {
    super.initState();
    _resolveDestination();
  }

  Future<void> _resolveDestination() async {
    final prefs = sl<SharedPreferences>();
    final result = await sl<PosSettingsRepository>().getSettings();
    final destination = await result.fold<Future<Widget>>(
      (_) async {
        // Saat server tidak dapat dijangkau, cache lokal hanya dipakai sebagai
        // fallback agar kasir yang sudah pernah setup tetap dapat bekerja.
        return PosOnboardingPage.isCompleted(prefs)
            ? PosShellPage(
                showSetupGuide: !PosOnboardingPage.isOperationalSetupCompleted(
                  prefs,
                ),
              )
            : const PosOnboardingPage();
      },
      (settings) async {
        final completed = settings.onboardingCompleted == true;
        await prefs.setBool(PosOnboardingPage.preferenceKey(prefs), completed);
        if (!completed) {
          // Reset dari Web Admin/database harus menang terhadap cache perangkat.
          await PosOnboardingPage.clearOperationalSetupCompleted(prefs);
          return const PosOnboardingPage();
        }
        return PosShellPage(
          showSetupGuide: !PosOnboardingPage.isOperationalSetupCompleted(prefs),
        );
      },
    );
    if (!mounted) return;
    setState(() => _destination = destination);
  }

  @override
  Widget build(BuildContext context) =>
      _destination ??
      const Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/geometric_bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
}

class _PosOnboardingPageState extends State<PosOnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;
  bool _saving = false;
  late Map<String, dynamic> _config;
  late String _profile;
  late Map<String, bool> _features;
  late String _channel;
  late String _priceLevel;
  late String _fulfillment;
  bool _autoPrint = false;
  late List<String> _channels;
  late List<String> _priceLevels;

  bool get _canManage {
    final value = _config['permissions'];
    return value is Map && value['manage_settings'] == true;
  }

  bool get _inventoryRequiresStockTracking {
    final profile = _config['inventory_profile']?.toString() ?? 'simple';
    if (profile == 'centralized' || profile == 'advanced') return true;
    if (profile != 'custom') return false;
    final policy = _config['inventory_policy'];
    if (policy is! Map) return false;
    return const [
      'use_central_warehouse',
      'use_transfer_request',
      'use_transfer_approval',
      'use_in_transit',
      'use_store_warehouse',
      'use_display_stock',
    ].any((key) => policy[key] == true);
  }

  @override
  void initState() {
    super.initState();
    final raw = sl<SharedPreferences>().getString('pos_runtime_config');
    try {
      final value = raw == null ? null : jsonDecode(raw);
      _config = value is Map<String, dynamic> ? value : {};
    } catch (_) {
      _config = {};
    }
    _profile = _config['business_profile']?.toString() ?? 'retail';
    final flags = _config['features'];
    bool enabled(String key, {bool defaultValue = false}) =>
        flags is Map ? flags[key] == true : defaultValue;
    _features = {
      'use_tables': enabled('use_tables'),
      'use_kitchen_flow': enabled('use_kitchen_flow'),
      'use_service_order': enabled('use_service_order'),
      'use_appointments': enabled('use_appointments'),
      'use_technicians': enabled('use_technicians'),
      'use_vehicle_data': enabled('use_vehicle_data'),
      'use_delivery': enabled('use_delivery'),
      'require_customer': enabled('require_customer'),
      'track_stock': enabled('track_stock', defaultValue: true),
    };
    _channels = <String>{
      'retail',
      ...(_config['sales_channel_options'] as List? ?? const []).map(
        (e) => e.toString(),
      ),
    }.toList();
    _priceLevels = <String>{
      'retail',
      ...(_config['price_level_options'] as List? ?? const []).map(
        (e) => e.toString(),
      ),
    }.toList();
    final channel = _config['default_sales_channel']?.toString() ?? 'retail';
    _channel = _channels.contains(channel) ? channel : 'retail';
    final price = _config['default_price_level']?.toString() ?? 'retail';
    _priceLevel = _priceLevels.contains(price) ? price : 'retail';
    _fulfillment = _config['default_order_type']?.toString() ?? 'take_away';
    if (_fulfillment == 'online_delivery') _fulfillment = 'delivery';
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final result = await sl<PosSettingsRepository>().getSettings();
    if (!mounted) return;
    result.fold((_) {}, (settings) {
      if (settings.onboardingCompleted == true) {
        _openPos();
        return;
      }
      setState(() => _autoPrint = settings.autoPrintReceipt ?? false);
    });
  }

  String _label(String value) {
    const values = {
      'retail': 'POS / Retail',
      'restoran': 'Restoran / Cafe',
      'bengkel': 'Bengkel',
      'jasa': 'Jasa',
      'custom': 'Custom',
      'dine_in': 'Makan di Tempat',
      'free_table': 'Makan di Tempat (Tanpa Meja)',
      'take_away': 'Bawa Pulang',
      'delivery': 'Pesan Antar',
      'quick_service': 'Layanan Cepat',
      'reservation': 'Reservasi',
    };
    return values[value] ??
        value
            .split('_')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
  }

  void _applyProfile(String value) {
    final base = <String, bool>{
      'use_tables': false,
      'use_kitchen_flow': false,
      'use_service_order': false,
      'use_appointments': false,
      'use_technicians': false,
      'use_vehicle_data': false,
      'use_delivery': false,
      'require_customer': false,
      'track_stock': true,
    };
    final presets = {
      'retail': base,
      'restoran': {
        ...base,
        'use_tables': true,
        'use_kitchen_flow': true,
        'use_delivery': true,
      },
      'bengkel': {
        ...base,
        'use_service_order': true,
        'use_appointments': true,
        'use_technicians': true,
        'use_vehicle_data': true,
        'require_customer': true,
      },
      'jasa': {
        ...base,
        'use_service_order': true,
        'use_appointments': true,
        'use_technicians': true,
        'require_customer': true,
        'track_stock': false,
      },
    };
    setState(() {
      _profile = value;
      if (value != 'custom') _features = {...presets[value] ?? base};
      if (_inventoryRequiresStockTracking) _features['track_stock'] = true;
      _fulfillment = value == 'restoran' ? 'dine_in' : 'take_away';
    });
  }

  Future<void> _openPos() async {
    final prefs = sl<SharedPreferences>();
    await prefs.setBool(PosOnboardingPage.preferenceKey(prefs), true);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) =>
            const PosShellPage(prepareDashboard: true, showSetupGuide: true),
      ),
      (_) => false,
    );
  }

  Future<void> _save() async {
    if (!_canManage) return _openPos();
    setState(() => _saving = true);
    final result = await sl<PosSettingsRepository>().updateSettings({
      'onboarding_completed': true,
      'onboarding_version': 1,
      'business_profile': _profile,
      'enabled_features': _features,
      'default_channel_penjualan': _channel,
      'default_price_level': _priceLevel,
      'default_tipe_pesanan': _fulfillment,
      'auto_print_receipt': _autoPrint,
    });
    if (!mounted) return;
    await result.fold(
      (failure) async {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: Colors.red),
        );
      },
      (_) async {
        _config = {
          ..._config,
          'business_profile': _profile,
          'features': _features,
          'default_sales_channel': _channel,
          'default_price_level': _priceLevel,
          'default_order_type': _fulfillment,
        };
        await sl<SharedPreferences>().setString(
          'pos_runtime_config',
          jsonEncode(_config),
        );
        await _openPos();
      },
    );
  }

  void _next() {
    if (_index == 3) {
      _save();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _dropdown(
    String title,
    String value,
    List<String> options,
    ValueChanged<String> changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : options.first,
          decoration: InputDecoration(
            hintText: 'Pilih ${title.toLowerCase()}',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
          ),
          items: options
              .map(
                (item) =>
                    DropdownMenuItem(value: item, child: Text(_label(item))),
              )
              .toList(),
          onChanged: _canManage
              ? (selected) {
                  if (selected != null) changed(selected);
                }
              : null,
        ),
      ],
    ),
  );

  Widget _switch(String key, String title, String subtitle) => Material(
    type: MaterialType.transparency,
    child: SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: _features[key] ?? false,
      onChanged:
          _canManage &&
              !(key == 'track_stock' && _inventoryRequiresStockTracking)
          ? (value) => setState(() => _features[key] = value)
          : null,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const profiles = ['retail', 'restoran', 'bengkel', 'jasa', 'custom'];
    const fulfillments = [
      'dine_in',
      'free_table',
      'take_away',
      'delivery',
      'quick_service',
      'reservation',
    ];
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Container(
        color: AppColors.primary,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 10, 2),
                child: Row(
                  children: [
                    Image.asset('assets/images/pantoo.png', height: 34),
                    const Spacer(),
                    TextButton(
                      onPressed: _saving ? null : _openPos,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white38,
                      ),
                      child: const Text('Lewati'),
                    ),
                  ],
                ),
              ),
              if (!_canManage)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  child: Text(
                    'Mode lihat saja. Perubahan memerlukan izin Kelola Pengaturan POS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const _OnboardingScrollBehavior(),
                  child: PageView(
                    controller: _controller,
                    physics: const PageScrollPhysics(),
                    dragStartBehavior: DragStartBehavior.start,
                    onPageChanged: (value) => setState(() => _index = value),
                    children: [
                      _Slide(
                        stepLabel: 'Langkah 1 dari 4 · Profil Usaha',
                        icon: Icons.storefront_outlined,
                        title: 'Pilih profil usaha',
                        description:
                            'Profil usaha mengaktifkan konfigurasi awal yang relevan dan dapat diubah kembali nanti.',
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Profil usaha',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profiles
                                  .map(
                                    (item) => ChoiceChip(
                                      label: Text(_label(item)),
                                      selected: _profile == item,
                                      onSelected: _canManage
                                          ? (_) => _applyProfile(item)
                                          : null,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                      _Slide(
                        stepLabel: 'Langkah 2 dari 4 · Fitur Operasional',
                        icon: Icons.tune_rounded,
                        title: 'Kebutuhan operasional',
                        description:
                            'Aktifkan hanya fitur yang digunakan usaha Anda.',
                        children: [
                          _switch(
                            'use_delivery',
                            'Pesan antar',
                            'Melayani pengiriman dari outlet',
                          ),
                          _switch(
                            'use_tables',
                            'Meja',
                            'Manajemen meja dan dine-in',
                          ),
                          _switch(
                            'use_appointments',
                            'Reservasi',
                            'Pesanan berdasarkan jadwal',
                          ),
                          _switch(
                            'require_customer',
                            'Wajib pelanggan',
                            'Transaksi harus memilih pelanggan',
                          ),
                          _switch(
                            'track_stock',
                            'Tracking stok',
                            _inventoryRequiresStockTracking
                                ? 'Wajib aktif untuk profil Inventory saat ini'
                                : 'Kurangi stok saat transaksi selesai',
                          ),
                        ],
                      ),
                      _Slide(
                        stepLabel: 'Langkah 3 dari 4 · Default Transaksi',
                        icon: Icons.point_of_sale_outlined,
                        title: 'Default transaksi',
                        description:
                            'Channel, tipe pemenuhan, dan level harga disimpan sebagai konteks terpisah.',
                        children: [
                          _dropdown(
                            'Channel penjualan',
                            _channel,
                            _channels,
                            (value) => setState(() => _channel = value),
                          ),
                          _dropdown(
                            'Tipe pemenuhan',
                            _fulfillment,
                            fulfillments,
                            (value) => setState(() => _fulfillment = value),
                          ),
                          _dropdown(
                            'Level harga',
                            _priceLevel,
                            _priceLevels,
                            (value) => setState(() => _priceLevel = value),
                          ),
                        ],
                      ),
                      _Slide(
                        stepLabel: 'Langkah 4 dari 4 · Konfirmasi',
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Konfirmasi dan mulai',
                        description:
                            'Pengaturan disimpan ke database dan digunakan bersama POS Admin serta Inventory.',
                        children: [
                          _Summary('Profil usaha', _label(_profile)),
                          _Summary('Channel', _label(_channel)),
                          _Summary('Tipe pemenuhan', _label(_fulfillment)),
                          _Summary('Level harga', _label(_priceLevel)),
                          Material(
                            type: MaterialType.transparency,
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              value: _autoPrint,
                              onChanged: _canManage
                                  ? (value) =>
                                        setState(() => _autoPrint = value)
                                  : null,
                              title: const Text(
                                'Cetak struk otomatis',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: const Text(
                                'Printer dapat dipilih dari menu Pengaturan Printer',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        4,
                        (value) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: value == _index ? 20 : 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: value == _index
                                ? Colors.white
                                : Colors.white38,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.swipe_left_outlined,
                          size: 18,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Geser card',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _saving ? null : _next,
                          icon: _saving
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  _index == 3
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                          label: Text(_index == 3 ? 'Simpan' : 'Lanjut'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            disabledBackgroundColor: Colors.white38,
                            disabledForegroundColor: Colors.white70,
                            minimumSize: const Size(112, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingScrollBehavior extends MaterialScrollBehavior {
  const _OnboardingScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}

class _Slide extends StatelessWidget {
  final String stepLabel;
  final IconData icon;
  final String title;
  final String description;
  final List<Widget> children;
  const _Slide({
    required this.stepLabel,
    required this.icon,
    required this.title,
    required this.description,
    required this.children,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withValues(alpha: .06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      stepLabel,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(icon, size: 30, color: AppColors.primary),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Summary extends StatelessWidget {
  final String label;
  final String value;
  const _Summary(this.label, this.value);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.bgPrimary,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
