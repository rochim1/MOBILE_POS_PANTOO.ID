import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';

import '../../../../core/_core.dart';
import '../../../../core/receipt/pos_receipt_document_builder.dart';
import '../../../../core/receipt/pos_receipt_print_service.dart';
import '../../../../domain/models/pos_receipt_template.dart';
import '../../../../injections.dart';
import '../../bloc/pos_receipt/pos_receipt_bloc.dart';
import '../../bloc/pos_receipt/pos_receipt_event.dart';
import '../../bloc/pos_receipt/pos_receipt_state.dart';
import '../../widgets/app_toast.dart';

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
  bool _showOrderType = true;

  int _paperWidth = 58;
  int _fontSize = 12;

  bool _isInitialized = false;
  bool _printersLoading = true;
  List<Printer> _printers = const [];
  String _selectedPrinterUrl = '';
  String _selectedBluetoothName = '';
  bool _isTestPrinting = false;
  String _printMode = 'fast';

  @override
  void initState() {
    super.initState();
    _printMode = PosReceiptPrintService(sl()).renderMode;
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    final service = PosReceiptPrintService(sl());
    _selectedBluetoothName = service.selectedBluetoothName;
    // Browser tidak menyediakan enumerasi printer yang stabil. Memanggil
    // Printing.info/listPrinters saat debug web dapat mengganti execution
    // context Chrome dan memutus Flutter Inspector. Web selalu memakai dialog
    // cetak sistem, jadi lewati discovery printer sepenuhnya.
    // Android thermal uses the Bluetooth plugin directly. The `printing`
    // plugin's system-printer enumeration is not available on many Android
    // builds and is unrelated to Bluetooth discovery, so do not show a
    // misleading "platform does not provide printers" state here.
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
      if (mounted) {
        setState(() {
          _printers = const [];
          _selectedPrinterUrl = '';
          _printersLoading = false;
        });
      }
      return;
    }

    try {
      final printers = await service.availablePrinters().timeout(
        const Duration(seconds: 8),
      );
      if (!mounted) return;
      final selectedStillExists = printers.any(
        (printer) => printer.url == service.selectedPrinterUrl,
      );
      if (service.selectedPrinterUrl.isNotEmpty && !selectedStillExists) {
        await service.selectPrinter(null);
      }
      if (!mounted) return;
      setState(() {
        _printers = printers;
        _selectedPrinterUrl = selectedStillExists
            ? service.selectedPrinterUrl
            : '';
        _printersLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _printersLoading = false);
    }
  }

  Future<void> _selectPrinter(String? url) async {
    final printer = url == null || url.isEmpty
        ? null
        : _printers.where((item) => item.url == url).firstOrNull;
    await PosReceiptPrintService(sl()).selectPrinter(printer);
    if (mounted) setState(() => _selectedPrinterUrl = url ?? '');
  }

  Future<void> _selectBluetoothPrinter() async {
    try {
      final pickerContext = context;
      if (!await _ensureBluetoothPermission()) return;
      if (!pickerContext.mounted) return;
      final selected = await PosReceiptPrintService(
        sl(),
      ).selectBluetoothPrinter(pickerContext);
      if (!mounted || !selected) return;
      setState(() {
        _selectedBluetoothName = PosReceiptPrintService(
          sl(),
        ).selectedBluetoothName;
        _selectedPrinterUrl = '';
      });
      AppToast.success(context, 'Printer Bluetooth berhasil dipilih');
    } catch (_) {
      if (mounted) {
        AppToast.error(
          context,
          'Bluetooth tidak dapat diakses. Aktifkan Bluetooth dan izinkan perangkat terdekat.',
        );
      }
    }
  }

  Future<bool> _ensureBluetoothPermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    final requested = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    var ready = requested.values.every((status) => status.isGranted);

    // Android 10/11 requires location permission while discovering nearby
    // Bluetooth devices. Android 12+ uses Nearby devices instead.
    if (!ready) {
      final location = await Permission.locationWhenInUse.request();
      ready =
          location.isGranted &&
          (await Permission.bluetoothScan.status).isGranted &&
          (await Permission.bluetoothConnect.status).isGranted;
    }
    if (ready) return true;

    final permanentlyDenied =
        (await Permission.bluetoothScan.status).isPermanentlyDenied ||
        (await Permission.bluetoothConnect.status).isPermanentlyDenied ||
        (await Permission.locationWhenInUse.status).isPermanentlyDenied;
    if (mounted) {
      AppToast.error(
        context,
        permanentlyDenied
            ? 'Izin Bluetooth ditolak permanen. Aktifkan Perangkat terdekat dari Pengaturan Aplikasi.'
            : 'Izinkan Perangkat terdekat (Android 12+) atau Lokasi (Android 10/11) untuk mencari printer.',
      );
    }
    if (permanentlyDenied) await openAppSettings();
    return false;
  }

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
    _showOrderType = t.showOrderType ?? true;

    final storedWidth = t.paperWidth ?? 58;
    // Template lama web menyimpan lebar dalam px (umumnya 280). Mulai kini
    // kontrak lintas platform menyimpan ukuran fisik 58 atau 80 mm.
    _paperWidth = storedWidth == 80 ? 80 : 58;
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
      'show_tipe_pesanan': _showOrderType,
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
          return LayoutBuilder(
            builder: (context, constraints) {
              final settings = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.status == PosReceiptStatus.loading ||
                      state.status == PosReceiptStatus.initial) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text(
                      'Memuat pengaturan struk… Anda tetap dapat melihat halaman ini.',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (state.status == PosReceiptStatus.failure) ...[
                    Material(
                      color: AppColors.dangerBackground,
                      borderRadius: BorderRadius.circular(10),
                      child: ListTile(
                        leading: const Icon(
                          Icons.error_outline,
                          color: AppColors.danger,
                        ),
                        title: const Text('Pengaturan struk gagal dimuat'),
                        subtitle: Text(state.errorMessage),
                        trailing: TextButton(
                          onPressed: () => context.read<PosReceiptBloc>().add(
                            LoadReceiptTemplate(),
                          ),
                          child: const Text('Coba lagi'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildSection(
                    title: 'Header Struk',
                    icon: Icons.title,
                    children: [
                      _buildPlaceholderHint(),
                      _buildSwitch(
                        'Tampilkan Logo Toko',
                        _showLogo,
                        (v) => setState(() => _showLogo = v),
                      ),
                      _buildTextField(
                        'Judul (Baris 1)',
                        _headerTitleController,
                      ),
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
                        'Segmen Pelanggan',
                        _showSegment,
                        (v) => setState(() => _showSegment = v),
                      ),
                      _buildSwitch(
                        'Jenis Pesanan',
                        _showOrderType,
                        (v) => setState(() => _showOrderType = v),
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
                      _buildPlaceholderHint(),
                      _buildTextField(
                        'Catatan Bawah 1',
                        _footerLine1Controller,
                        maxLines: 3,
                      ),
                      _buildTextField(
                        'Catatan Bawah 2',
                        _footerLine2Controller,
                        maxLines: 3,
                      ),
                      _buildTextField(
                        'Catatan Bawah 3',
                        _footerLine3Controller,
                        maxLines: 3,
                      ),
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
                        items: const [
                          '8',
                          '9',
                          '10',
                          '11',
                          '12',
                          '13',
                          '14',
                          '15',
                          '16',
                          '17',
                          '18',
                        ],
                        onChanged: (val) =>
                            setState(() => _fontSize = int.parse(val!)),
                        suffix: 'pt',
                      ),
                      _buildDropdown(
                        label: 'Mode Cetak Bluetooth',
                        value: _printMode,
                        items: const ['fast', 'pdf'],
                        labels: const {
                          'fast': 'Cepat (teks ESC/POS)',
                          'pdf': 'Presisi (PDF + logo)',
                        },
                        onChanged: (val) async {
                          final mode = val ?? 'fast';
                          setState(() => _printMode = mode);
                          await PosReceiptPrintService(
                            sl(),
                          ).setRenderMode(mode);
                        },
                      ),
                      const Text(
                        'Cepat memakai teks ESC/POS dan tetap mengikuti field template. '
                        'Pilih Presisi jika logo dan tampilan PDF harus sama persis dengan preview.',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPrinterDeviceSection(state.company),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed:
                        state.status == PosReceiptStatus.saving ||
                            state.status == PosReceiptStatus.loading ||
                            state.status == PosReceiptStatus.initial
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
                  const SizedBox(height: 24),
                ],
              );
              final preview = _buildReceiptPreview(state.company);
              final wide = constraints.maxWidth >= 980;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: settings),
                          const SizedBox(width: 16),
                          Expanded(flex: 4, child: preview),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          settings,
                          const SizedBox(height: 16),
                          preview,
                        ],
                      ),
              );
            },
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        onChanged: (_) => setState(() {}),
        minLines: maxLines > 1 ? 2 : 1,
        maxLines: maxLines,
        keyboardType: maxLines > 1
            ? TextInputType.multiline
            : TextInputType.text,
        textInputAction: maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.done,
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

  Widget _buildPlaceholderHint() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: const Text(
        'Placeholder kasir: {{nama_kasir}}  (alias: {{kasir}}). '
        'Contoh: Dilayani oleh {{nama_kasir}}',
        style: TextStyle(fontSize: 12, color: Colors.black87),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? suffix,
    Map<String, String>? labels,
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
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(labels?[item] ?? item),
                    ),
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

  PosReceiptTemplate get _draftTemplate => PosReceiptTemplate(
    showLogo: _showLogo,
    headerTitle: _headerTitleController.text,
    headerSubtitle: _headerSubtitleController.text,
    headerLine3: _headerLine3Controller.text,
    headerLine4: _headerLine4Controller.text,
    showInvoice: _showInvoice,
    showTanggal: _showTanggal,
    showKasir: _showKasir,
    showToko: _showToko,
    showPelanggan: _showPelanggan,
    showChannel: _showChannel,
    showSegment: _showSegment,
    showPromo: _showPromo,
    showOrderType: _showOrderType,
    footerLine1: _footerLine1Controller.text,
    footerLine2: _footerLine2Controller.text,
    footerLine3: _footerLine3Controller.text,
    paperWidth: _paperWidth,
    fontSize: _fontSize,
  );

  Widget _buildReceiptPreview(Map<String, String> company) {
    final previewTemplate = _draftTemplate;
    return _buildSection(
      title: 'Preview Struk',
      icon: Icons.receipt_long_outlined,
      children: [
        const Text(
          'Preview diperbarui langsung mengikuti pengaturan di sebelah kiri.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        _buildLightweightReceiptPreview(previewTemplate, company),
      ],
    );
  }

  Widget _buildLightweightReceiptPreview(
    PosReceiptTemplate template,
    Map<String, String> company,
  ) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    const previewCashierName = 'Kasir Pantoo';
    final title = _interpolate(
      template.headerTitle,
      company,
      cashierName: previewCashierName,
    );
    final receiptWidth = template.paperWidth == 80 ? 380.0 : 300.0;

    Widget line(String label, String value, {bool bold = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );

    return Container(
      color: AppColors.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: receiptWidth),
        child: Material(
          color: Colors.white,
          elevation: 2,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: DefaultTextStyle(
              style: TextStyle(
                color: Colors.black87,
                fontSize: (template.fontSize ?? 12).clamp(10, 14).toDouble(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (template.showLogo != false &&
                      (company['logo'] ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Image.network(
                        company['logo']!,
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  if (title.isNotEmpty)
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  for (final value in [
                    template.headerSubtitle,
                    template.headerLine3,
                    template.headerLine4,
                  ])
                    if (_interpolate(
                      value,
                      company,
                      cashierName: previewCashierName,
                    ).isNotEmpty)
                      Text(
                        _interpolate(
                          value,
                          company,
                          cashierName: previewCashierName,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  const Divider(height: 18),
                  if (template.showInvoice != false)
                    const Text('No: INV-20260909-001'),
                  if (template.showTanggal != false)
                    const Text('Tanggal: 09/09/2026 14:30'),
                  if (template.showKasir != false)
                    const Text('Kasir: Kasir Pantoo'),
                  if (template.showToko != false)
                    const Text('Toko: Toko Utama'),
                  if (template.showPelanggan != false)
                    const Text('Pelanggan: Pelanggan Umum'),
                  if (template.showChannel == true)
                    const Text('Channel: Retail'),
                  if (template.showSegment == true)
                    const Text('Segmen: Regular'),
                  if (template.showOrderType != false)
                    const Text('Jenis pesanan: Bawa Pulang'),
                  const Text('Bayar: TUNAI'),
                  const Divider(height: 18),
                  const Text(
                    'Produk Contoh A',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  line('2 x ${currency.format(15000)}', currency.format(30000)),
                  const SizedBox(height: 4),
                  const Text(
                    'Produk Contoh B',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  line('1 x ${currency.format(25000)}', currency.format(25000)),
                  const Divider(height: 18),
                  line('Subtotal', currency.format(55000)),
                  if (template.showPromo != false)
                    line('Promo', '-${currency.format(5000)}'),
                  line('Pajak', currency.format(5500)),
                  line('TOTAL', currency.format(55500), bold: true),
                  line('Diterima', currency.format(60000)),
                  line('Kembalian', currency.format(4500)),
                  const SizedBox(height: 12),
                  for (final value in [
                    template.footerLine1,
                    template.footerLine2,
                    template.footerLine3,
                  ])
                    if (_interpolate(
                      value,
                      company,
                      cashierName: previewCashierName,
                    ).isNotEmpty)
                      Text(
                        _interpolate(
                          value,
                          company,
                          cashierName: previewCashierName,
                        ),
                        textAlign: TextAlign.center,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _interpolate(
    String? raw,
    Map<String, String> company, {
    String cashierName = '',
  }) {
    var value = raw?.trim() ?? '';
    final aliases = <String, String>{
      ...company,
      'telpon_nomor': company['telpon_number'] ?? '',
      'npwp': company['NPWP'] ?? '',
      'nama_kasir': cashierName,
      'kasir': cashierName,
      'cashier_name': cashierName,
    };
    aliases.forEach((key, replacement) {
      value = value.replaceAll('{{$key}}', replacement);
    });
    return value.replaceAll(RegExp(r'\{\{[^}]+\}\}'), '').trim();
  }

  Widget _buildPrinterDeviceSection(Map<String, String> company) {
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return _buildSection(
      title: 'Printer Terminal Ini',
      icon: Icons.print_outlined,
      children: [
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bluetooth, color: Colors.teal),
            title: Text(
              _selectedBluetoothName.isEmpty
                  ? 'Printer Bluetooth thermal'
                  : _selectedBluetoothName,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _selectedBluetoothName.isEmpty
                  ? 'Cetak langsung tanpa dialog sistem'
                  : 'Aktif untuk cetak struk kasir',
            ),
            trailing: FilledButton.icon(
              onPressed: _selectBluetoothPrinter,
              icon: const Icon(Icons.search, size: 17),
              label: Text(_selectedBluetoothName.isEmpty ? 'Pilih' : 'Ganti'),
            ),
          ),
          if (_selectedBluetoothName.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await PosReceiptPrintService(sl()).clearBluetoothPrinter();
                  if (mounted) setState(() => _selectedBluetoothName = '');
                },
                icon: const Icon(Icons.link_off, size: 16),
                label: const Text('Gunakan printer sistem'),
              ),
            ),
          const Divider(height: 12),
        ],
        if (!isAndroid && _printersLoading)
          const LinearProgressIndicator()
        else if (!isAndroid && _printers.isEmpty) ...[
          Text(
            kIsWeb
                ? 'Situs web tidak dapat meminta izin untuk membaca daftar printer sistem. Buka contoh struk PDF, lalu pilih printer melalui dialog cetak browser.'
                : 'Belum ada printer sistem yang terdeteksi. Periksa koneksi dan driver printer, lalu muat ulang.',
            style: const TextStyle(color: Colors.black54),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 8),
            const Text(
              'Unduh contoh struk PDF, buka file tersebut lalu cetak dari browser. Untuk printer Bluetooth thermal langsung, gunakan aplikasi Android.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (!kIsWeb) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadPrinters,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Muat ulang'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isTestPrinting ? null : () => _testPrint(company),
                  icon: _isTestPrinting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          kIsWeb
                              ? Icons.download_outlined
                              : Icons.print_outlined,
                        ),
                  label: Text(
                    _isTestPrinting
                        ? 'Menyiapkan…'
                        : kIsWeb
                        ? 'Unduh contoh struk'
                        : 'Tes cetak',
                  ),
                ),
              ),
            ],
          ),
        ] else if (!isAndroid) ...[
          DropdownButtonFormField<String>(
            initialValue: _selectedPrinterUrl,
            decoration: const InputDecoration(
              labelText: 'Printer default terminal',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Selalu pilih melalui dialog sistem'),
              ),
              ..._printers.map(
                (printer) => DropdownMenuItem(
                  value: printer.url,
                  child: Text(
                    printer.isDefault
                        ? '${printer.name} (default)'
                        : printer.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: _selectPrinter,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loadPrinters,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Muat ulang printer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isTestPrinting ? null : () => _testPrint(company),
                  icon: _isTestPrinting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print_outlined),
                  label: Text(_isTestPrinting ? 'Menyiapkan…' : 'Tes cetak'),
                ),
              ),
            ],
          ),
        ],
        if (isAndroid) ...[
          const SizedBox(height: 8),
          const Text(
            'Android menggunakan printer Bluetooth thermal yang dipilih di atas. Printer sistem/Wi‑Fi tidak digunakan untuk struk kasir.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isTestPrinting ? null : () => _testPrint(company),
                  icon: _isTestPrinting
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print_outlined),
                  label: Text(
                    _isTestPrinting ? 'Menyiapkan…' : 'Tes cetak Bluetooth',
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        const Text(
          'Pilihan printer disimpan hanya pada perangkat ini. Printer Bluetooth thermal dicetak langsung dalam format ESC/POS; printer sistem menggunakan dialog cetak.',
          style: TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  Future<void> _testPrint(Map<String, String> company) async {
    if (_isTestPrinting) return;
    setState(() => _isTestPrinting = true);
    try {
      final bytes = await PosReceiptDocumentBuilder.build(
        data: _sampleReceipt,
        template: _draftTemplate,
        company: company,
      ).timeout(const Duration(seconds: 12));
      if (kIsWeb) {
        // printing_web.layoutPdf waits for an iframe load event that some
        // browsers never dispatch. Downloading the sample avoids a stuck
        // print dialog and lets the user print the PDF from the browser.
        final downloaded = await Printing.sharePdf(
          bytes: bytes,
          filename: 'Tes-Struk-Pantoo.pdf',
        ).timeout(const Duration(seconds: 8));
        if (!downloaded) throw StateError('Unduhan contoh struk dibatalkan');
        if (mounted) {
          AppToast.success(
            context,
            'Contoh struk diunduh. Buka PDF untuk mencetak.',
          );
        }
        return;
      }
      await PosReceiptPrintService(sl())
          .printPdf(
            bytes: bytes,
            name: 'Tes-Struk-Pantoo',
            format: PosReceiptDocumentBuilder.pageFormatFor(
              _draftTemplate,
              _sampleReceipt.items.length,
            ),
          )
          .timeout(const Duration(seconds: 45));
    } on TimeoutException {
      if (mounted) {
        AppToast.error(
          context,
          kIsWeb
              ? 'Contoh struk gagal disiapkan. Coba lagi tanpa logo atau periksa koneksi.'
              : 'Printer tidak merespons. Periksa koneksi atau driver printer.',
        );
      }
    } catch (error) {
      debugPrint('[Printer] Tes cetak gagal: $error');
      if (mounted) {
        AppToast.error(
          context,
          kIsWeb ? 'Contoh struk gagal diunduh' : 'Tes cetak gagal dibuka',
        );
      }
    } finally {
      if (mounted) setState(() => _isTestPrinting = false);
    }
  }

  static const _sampleReceipt = PosReceiptDocumentData(
    invoice: 'INV-20260909-001',
    dateLabel: '09/09/2026 14:30',
    cashierName: 'Kasir Pantoo',
    storeName: 'Toko Utama',
    customerName: 'Pelanggan Umum',
    paymentMethod: 'tunai',
    salesChannel: 'retail',
    customerSegment: 'regular',
    orderType: 'Bawa Pulang',
    promoCode: 'HEMAT10',
    subtotal: 55000,
    promoDiscount: 5000,
    tax: 5500,
    total: 55500,
    cashReceived: 60000,
    change: 4500,
    items: [
      {
        'nama_inventaris': 'Produk Contoh A',
        'qty': 2,
        'harga_jual': 15000,
        'subtotal': 30000,
      },
      {
        'nama_inventaris': 'Produk Contoh B',
        'qty': 1,
        'harga_jual': 25000,
        'subtotal': 25000,
      },
    ],
  );
}
