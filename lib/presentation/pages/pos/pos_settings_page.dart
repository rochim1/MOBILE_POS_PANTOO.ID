import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/_core.dart';
import '../../../../injections.dart';
import '../../bloc/pos_settings/pos_settings_bloc.dart';
import '../../bloc/pos_settings/pos_settings_event.dart';
import '../../bloc/pos_settings/pos_settings_state.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_ui.dart';
import '../../widgets/loading_indicator_widget.dart';
import '../../widgets/pos_category_navigation.dart';
import 'pos_offline_queue_page.dart';
import 'pos_outlet_page.dart';
import 'pos_printer_page.dart';

enum _SettingsSection {
  transaction,
  finance,
  cashier,
  outlet,
  receipt,
  synchronization,
}

class PosSettingsPage extends StatelessWidget {
  const PosSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PosSettingsBloc>()..add(LoadSettings()),
      child: const _PosSettingsView(),
    );
  }
}

class _PosSettingsView extends StatefulWidget {
  const _PosSettingsView();

  @override
  State<_PosSettingsView> createState() => _PosSettingsViewState();
}

class _PosSettingsViewState extends State<_PosSettingsView> {
  final _pajakController = TextEditingController();
  final _minTransaksiTunaiController = TextEditingController();
  final _invoicePrefixController = TextEditingController();
  final _defaultCatatanController = TextEditingController();

  String _pembulatanHarga = 'none';
  String _metodePembayaran = 'tunai';
  String _channel = 'retail';
  String _priceLevel = 'retail';
  List<String> _channelOptions = const ['retail'];
  List<String> _priceLevelOptions = const ['retail'];
  String _discountPolicy = 'stack';

  bool _autoPrintReceipt = false;
  bool _allowKasirPriceEdit = false;
  bool _allowOutOfShift = false;

  bool _isInitialized = false;
  _SettingsSection _selectedSection = _SettingsSection.transaction;

  static const _sections = <PosCategoryItem<_SettingsSection>>[
    PosCategoryItem(
      value: _SettingsSection.transaction,
      icon: Icons.tune_outlined,
      label: 'Transaksi & Penjualan',
      group: 'Operasional',
    ),
    PosCategoryItem(
      value: _SettingsSection.finance,
      icon: Icons.account_balance_wallet_outlined,
      label: 'Pajak & Keuangan',
      group: 'Operasional',
    ),
    PosCategoryItem(
      value: _SettingsSection.cashier,
      icon: Icons.point_of_sale_outlined,
      label: 'Kasir & Keamanan',
      group: 'Operasional',
    ),
    PosCategoryItem(
      value: _SettingsSection.outlet,
      icon: Icons.storefront_outlined,
      label: 'Info Outlet',
      group: 'Akun & Akses',
    ),
    PosCategoryItem(
      value: _SettingsSection.receipt,
      icon: Icons.receipt_long_outlined,
      label: 'Struk & Printer',
      group: 'Aplikasi',
    ),
    PosCategoryItem(
      value: _SettingsSection.synchronization,
      icon: Icons.sync_outlined,
      label: 'Sinkronisasi',
      group: 'Aplikasi',
    ),
  ];

  @override
  void dispose() {
    _pajakController.dispose();
    _minTransaksiTunaiController.dispose();
    _invoicePrefixController.dispose();
    _defaultCatatanController.dispose();
    super.dispose();
  }

  void _initFields(PosSettingsState state) {
    if (_isInitialized || state.settings == null) return;

    final s = state.settings!;
    _pajakController.text = s.pajakPersen?.toString() ?? '0';
    _minTransaksiTunaiController.text = formatRupiahInput(
      s.minTransaksiTunai ?? 0,
    );
    _invoicePrefixController.text = s.invoicePrefix ?? '';
    _defaultCatatanController.text = s.defaultCatatan ?? '';

    _pembulatanHarga = s.pembulatanHarga ?? 'none';
    _metodePembayaran = s.defaultMetodePembayaran ?? 'tunai';
    _channelOptions = <String>{'retail', ...s.salesChannelOptions}.toList();
    final channel = s.defaultChannelPenjualan ?? 'retail';
    _channel = _channelOptions.contains(channel) ? channel : 'retail';
    _priceLevelOptions = <String>{'retail', ...s.priceLevelOptions}.toList();
    final priceLevel = s.defaultPriceLevel ?? 'retail';
    _priceLevel = _priceLevelOptions.contains(priceLevel)
        ? priceLevel
        : 'retail';
    final discountPolicy = s.defaultDiscountPolicy ?? 'stack';
    _discountPolicy =
        const {
          'stack',
          'promo_only',
          'manual_only',
          'best_of_manual_or_promo',
        }.contains(discountPolicy)
        ? discountPolicy
        : 'stack';

    _autoPrintReceipt = s.autoPrintReceipt ?? false;
    _allowKasirPriceEdit = s.allowKasirPriceEdit ?? false;
    _allowOutOfShift = s.allowOutOfShift ?? false;

    _isInitialized = true;
  }

  void _saveSettings() {
    final input = {
      'pajak_persen': double.tryParse(_pajakController.text) ?? 0,
      'min_transaksi_tunai': parseRupiah(_minTransaksiTunaiController.text),
      'pembulatan_harga': _pembulatanHarga,
      'default_metode_pembayaran': _metodePembayaran,
      'default_channel_penjualan': _channel,
      'default_price_level': _priceLevel,
      'default_discount_policy': _discountPolicy,
      'invoice_prefix': _invoicePrefixController.text,
      'default_catatan': _defaultCatatanController.text,
      'auto_print_receipt': _autoPrintReceipt,
      'allow_kasir_price_edit': _allowKasirPriceEdit,
      'allow_out_of_shift': _allowOutOfShift,
    };

    context.read<PosSettingsBloc>().add(UpdateSettings(input: input));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const PosAppBarTitle(
          title: 'Pengaturan POS',
          subtitle: 'Default transaksi dan keamanan',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<PosSettingsBloc, PosSettingsState>(
        listener: (context, state) {
          if (state.status == PosSettingsStatus.loaded) {
            _initFields(state);
          } else if (state.status == PosSettingsStatus.saved) {
            AppToast.success(context, state.successMessage);
          } else if (state.status == PosSettingsStatus.failure) {
            AppToast.error(context, state.errorMessage);
          }
        },
        builder: (context, state) {
          if (state.status == PosSettingsStatus.loading ||
              state.status == PosSettingsStatus.initial) {
            return const Center(child: LoadingIndicatorWidget());
          }

          final content = _settingsContent(state);
          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 760) {
                return Row(
                  children: [
                    PosCategorySidebar<_SettingsSection>(
                      title: 'Kategori Pengaturan',
                      items: _sections,
                      selected: _selectedSection,
                      onSelected: (value) =>
                          setState(() => _selectedSection = value),
                      expandedWidth: 230,
                      footer:
                          'Pengaturan berlaku sebagai default operasional POS.',
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: content),
                  ],
                );
              }
              return Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                    child: PosCategoryDropdown<_SettingsSection>(
                      label: 'Kategori pengaturan',
                      items: _sections,
                      selected: _selectedSection,
                      onSelected: (value) =>
                          setState(() => _selectedSection = value),
                    ),
                  ),
                  Expanded(child: content),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _settingsContent(PosSettingsState state) {
    if (_selectedSection == _SettingsSection.outlet) {
      return const PosOutletPage();
    }
    if (_selectedSection == _SettingsSection.receipt) {
      return const PosPrinterPage();
    }
    if (_selectedSection == _SettingsSection.synchronization) {
      return const PosOfflineQueuePage();
    }
    final section = switch (_selectedSection) {
      _SettingsSection.finance => _buildSection(
        title: 'Pajak & Keuangan',
        icon: Icons.account_balance_wallet_outlined,
        children: [
          _buildTextField('Pajak (%)', _pajakController, isNumber: true),
          _buildTextField(
            'Minimal Transaksi Tunai (Rp)',
            _minTransaksiTunaiController,
            isNumber: true,
            isCurrency: true,
          ),
          _buildDropdown(
            label: 'Pembulatan Harga',
            value: _pembulatanHarga,
            items: const ['none', '100', '500', '1000'],
            onChanged: (val) => setState(() => _pembulatanHarga = val!),
          ),
        ],
      ),
      _SettingsSection.transaction => _buildSection(
        title: 'Transaksi & Penjualan',
        icon: Icons.tune_outlined,
        children: [
          _buildDropdown(
            label: 'Metode Pembayaran',
            value: _metodePembayaran,
            items: const [
              'tunai',
              'transfer',
              'qris',
              'kartu_debit',
              'kartu_kredit',
              'e_wallet',
            ],
            onChanged: (val) => setState(() => _metodePembayaran = val!),
          ),
          _buildDropdown(
            label: 'Channel Penjualan',
            value: _channel,
            items: _channelOptions,
            onChanged: (val) => setState(() => _channel = val!),
          ),
          _buildDropdown(
            label: 'Level Harga Default',
            value: _priceLevel,
            items: _priceLevelOptions,
            onChanged: (val) => setState(() => _priceLevel = val!),
          ),
          _buildDropdown(
            label: 'Discount Policy',
            value: _discountPolicy,
            items: const [
              'stack',
              'promo_only',
              'manual_only',
              'best_of_manual_or_promo',
            ],
            onChanged: (val) => setState(() => _discountPolicy = val!),
          ),
          _buildTextField('Prefix Invoice', _invoicePrefixController),
          _buildTextField(
            'Default Catatan',
            _defaultCatatanController,
            maxLines: 3,
          ),
        ],
      ),
      _SettingsSection.cashier => _buildSection(
        title: 'Kasir & Keamanan',
        icon: Icons.point_of_sale_outlined,
        children: [
          _buildSwitch(
            'Cetak Struk Otomatis',
            _autoPrintReceipt,
            (v) => setState(() => _autoPrintReceipt = v),
          ),
          _buildSwitch(
            'Izinkan Kasir Edit Harga',
            _allowKasirPriceEdit,
            (v) => setState(() => _allowKasirPriceEdit = v),
          ),
          _buildSwitch(
            'Izinkan Penjualan Tanpa Shift Aktif',
            _allowOutOfShift,
            (v) => setState(() => _allowOutOfShift = v),
          ),
        ],
      ),
      _SettingsSection.outlet ||
      _SettingsSection.receipt ||
      _SettingsSection.synchronization => const SizedBox.shrink(),
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            section,
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: state.status == PosSettingsStatus.saving
                  ? null
                  : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: state.status == PosSettingsStatus.saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Simpan Pengaturan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    bool isCurrency = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        inputFormatters: isCurrency ? const [RupiahInputFormatter()] : null,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    // Ensure value exists in items to avoid dropdown error
    final safeValue = items.contains(value) ? value : items.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        initialValue: safeValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, void Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
