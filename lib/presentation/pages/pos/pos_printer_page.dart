import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/_core.dart';
import '../../../../injections.dart';
import '../../bloc/pos_receipt/pos_receipt_bloc.dart';
import '../../bloc/pos_receipt/pos_receipt_event.dart';
import '../../bloc/pos_receipt/pos_receipt_state.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/loading_indicator_widget.dart';

class PosPrinterPage extends StatelessWidget {
  const PosPrinterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PosReceiptBloc>()..add(LoadReceiptTemplate()),
      child: const _PosPrinterView(),
    );
  }
}

class _PosPrinterView extends StatefulWidget {
  const _PosPrinterView();

  @override
  State<_PosPrinterView> createState() => _PosPrinterViewState();
}

class _PosPrinterViewState extends State<_PosPrinterView> {
  final _headerTitleController = TextEditingController();
  final _headerSubtitleController = TextEditingController();
  final _headerLine3Controller = TextEditingController();
  final _headerLine4Controller = TextEditingController();
  final _footerLine1Controller = TextEditingController();
  final _footerLine2Controller = TextEditingController();
  final _footerLine3Controller = TextEditingController();

  bool _showLogo = true;
  bool _showInvoice = true;
  bool _showTanggal = true;
  bool _showKasir = true;
  bool _showToko = true;
  bool _showPelanggan = true;
  bool _showChannel = false;
  bool _showSegment = false;
  bool _showPromo = true;

  int _paperWidth = 58;
  int _fontSize = 12;

  bool _isInitialized = false;

  @override
  void dispose() {
    _headerTitleController.dispose();
    _headerSubtitleController.dispose();
    _headerLine3Controller.dispose();
    _headerLine4Controller.dispose();
    _footerLine1Controller.dispose();
    _footerLine2Controller.dispose();
    _footerLine3Controller.dispose();
    super.dispose();
  }

  void _initFields(PosReceiptState state) {
    if (_isInitialized || state.template == null) return;

    final t = state.template!;
    _headerTitleController.text = t.headerTitle ?? '';
    _headerSubtitleController.text = t.headerSubtitle ?? '';
    _headerLine3Controller.text = t.headerLine3 ?? '';
    _headerLine4Controller.text = t.headerLine4 ?? '';
    _footerLine1Controller.text = t.footerLine1 ?? '';
    _footerLine2Controller.text = t.footerLine2 ?? '';
    _footerLine3Controller.text = t.footerLine3 ?? '';

    _showLogo = t.showLogo ?? true;
    _showInvoice = t.showInvoice ?? true;
    _showTanggal = t.showTanggal ?? true;
    _showKasir = t.showKasir ?? true;
    _showToko = t.showToko ?? true;
    _showPelanggan = t.showPelanggan ?? true;
    _showChannel = t.showChannel ?? false;
    _showSegment = t.showSegment ?? false;
    _showPromo = t.showPromo ?? true;

    _paperWidth = t.paperWidth ?? 58;
    _fontSize = t.fontSize ?? 12;

    _isInitialized = true;
  }

  void _saveSettings() {
    final input = {
      'show_logo': _showLogo,
      'header_title': _headerTitleController.text,
      'header_subtitle': _headerSubtitleController.text,
      'header_line3': _headerLine3Controller.text,
      'header_line4': _headerLine4Controller.text,
      'show_invoice': _showInvoice,
      'show_tanggal': _showTanggal,
      'show_kasir': _showKasir,
      'show_toko': _showToko,
      'show_pelanggan': _showPelanggan,
      'show_channel': _showChannel,
      'show_segment': _showSegment,
      'show_promo': _showPromo,
      'footer_line1': _footerLine1Controller.text,
      'footer_line2': _footerLine2Controller.text,
      'footer_line3': _footerLine3Controller.text,
      'paper_width': _paperWidth,
      'font_size': _fontSize,
    };

    context.read<PosReceiptBloc>().add(UpdateReceiptTemplate(input));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgPrimary,
      child: BlocConsumer<PosReceiptBloc, PosReceiptState>(
        listener: (context, state) {
          if (state.status == PosReceiptStatus.loaded) {
            _initFields(state);
          } else if (state.status == PosReceiptStatus.saved) {
            AppToast.success(context, state.successMessage);
          } else if (state.status == PosReceiptStatus.failure) {
            AppToast.error(context, state.errorMessage);
          }
        },
        builder: (context, state) {
          if (state.status == PosReceiptStatus.loading ||
              state.status == PosReceiptStatus.initial) {
            return const Center(child: LoadingIndicatorWidget());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSection(
                  title: 'Header Struk',
                  icon: Icons.title,
                  children: [
                    _buildSwitch(
                      'Tampilkan Logo Toko',
                      _showLogo,
                      (v) => setState(() => _showLogo = v),
                    ),
                    _buildTextField('Judul (Baris 1)', _headerTitleController),
                    _buildTextField(
                      'Sub Judul (Baris 2)',
                      _headerSubtitleController,
                    ),
                    _buildTextField('Baris 3', _headerLine3Controller),
                    _buildTextField('Baris 4', _headerLine4Controller),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Kolom Ditampilkan',
                  icon: Icons.view_list_outlined,
                  children: [
                    _buildSwitch(
                      'Nomor Invoice',
                      _showInvoice,
                      (v) => setState(() => _showInvoice = v),
                    ),
                    _buildSwitch(
                      'Tanggal & Waktu',
                      _showTanggal,
                      (v) => setState(() => _showTanggal = v),
                    ),
                    _buildSwitch(
                      'Nama Kasir',
                      _showKasir,
                      (v) => setState(() => _showKasir = v),
                    ),
                    _buildSwitch(
                      'Nama Toko / Outlet',
                      _showToko,
                      (v) => setState(() => _showToko = v),
                    ),
                    _buildSwitch(
                      'Nama Pelanggan',
                      _showPelanggan,
                      (v) => setState(() => _showPelanggan = v),
                    ),
                    _buildSwitch(
                      'Channel Penjualan',
                      _showChannel,
                      (v) => setState(() => _showChannel = v),
                    ),
                    _buildSwitch(
                      'Customer Segment',
                      _showSegment,
                      (v) => setState(() => _showSegment = v),
                    ),
                    _buildSwitch(
                      'Informasi Promo',
                      _showPromo,
                      (v) => setState(() => _showPromo = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Footer Struk',
                  icon: Icons.horizontal_rule,
                  children: [
                    _buildTextField('Catatan Bawah 1', _footerLine1Controller),
                    _buildTextField('Catatan Bawah 2', _footerLine2Controller),
                    _buildTextField('Catatan Bawah 3', _footerLine3Controller),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Pengaturan Cetak',
                  icon: Icons.print_outlined,
                  children: [
                    _buildDropdown(
                      label: 'Lebar Kertas',
                      value: _paperWidth.toString(),
                      items: const ['58', '80'],
                      onChanged: (val) =>
                          setState(() => _paperWidth = int.parse(val!)),
                      suffix: 'mm',
                    ),
                    _buildDropdown(
                      label: 'Ukuran Font Default',
                      value: _fontSize.toString(),
                      items: const ['10', '11', '12', '13', '14'],
                      onChanged: (val) =>
                          setState(() => _fontSize = int.parse(val!)),
                      suffix: 'pt',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: state.status == PosReceiptStatus.saving
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
                  child: state.status == PosReceiptStatus.saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Template Struk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
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

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
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
    String? suffix,
  }) {
    final safeValue = items.contains(value) ? value : items.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: safeValue,
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 12),
            Text(
              suffix,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 8),
          ],
        ],
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
