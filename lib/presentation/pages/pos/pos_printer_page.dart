import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
  bool _previewExpanded = false;
  PosReceiptTemplate? _previewTemplate;
  bool _isTestPrinting = false;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    // Browser tidak menyediakan enumerasi printer yang stabil. Memanggil
    // Printing.info/listPrinters saat debug web dapat mengganti execution
    // context Chrome dan memutus Flutter Inspector. Web selalu memakai dialog
    // cetak sistem, jadi lewati discovery printer sepenuhnya.
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _printers = const [];
          _selectedPrinterUrl = '';
          _printersLoading = false;
        });
      }
      return;
    }

    final service = PosReceiptPrintService(sl());
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
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
                const SizedBox(height: 16),
                _buildPrinterDeviceSection(state.company),
                const SizedBox(height: 16),
                _buildReceiptPreview(state.company),
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
        onChanged: (_) => setState(() {}),
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
    final previewTemplate = _previewTemplate ?? _draftTemplate;
    return _buildSection(
      title: 'Preview & Tes Cetak',
      icon: Icons.receipt_long_outlined,
      children: [
        const Text(
          'Preview menggunakan renderer yang sama dengan struk transaksi.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 12),
        if (!_previewExpanded)
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _previewTemplate = _draftTemplate;
              _previewExpanded = true;
            }),
            icon: const Icon(Icons.visibility_outlined),
            label: const Text('Tampilkan preview struk'),
          )
        else ...[
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _previewTemplate = _draftTemplate;
              }),
              icon: const Icon(Icons.refresh),
              label: const Text('Perbarui preview'),
            ),
          ),
          _buildLightweightReceiptPreview(previewTemplate, company),
        ],
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
    final title = (template.headerTitle ?? '').trim().isNotEmpty
        ? template.headerTitle!.trim()
        : (company['nama_instansi'] ?? '').trim().isNotEmpty
        ? company['nama_instansi']!.trim()
        : 'PANTOO POS';
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
                  if (template.showLogo != false)
                    const Icon(
                      Icons.storefront_outlined,
                      size: 34,
                      color: AppColors.primary,
                    ),
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
                    if ((value ?? '').trim().isNotEmpty)
                      Text(value!.trim(), textAlign: TextAlign.center),
                  const Divider(height: 18),
                  if (template.showInvoice != false)
                    const Text('No: INV-20260909-001'),
                  if (template.showTanggal != false)
                    const Text('Tanggal: 09/09/2026 14:30'),
                  if (template.showKasir != false)
                    const Text('Kasir: Kasir Pantoo'),
                  if (template.showToko == true) const Text('Toko: Toko Utama'),
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
                    if ((value ?? '').trim().isNotEmpty)
                      Text(value!.trim(), textAlign: TextAlign.center),
                  if ([
                    template.footerLine1,
                    template.footerLine2,
                    template.footerLine3,
                  ].every((value) => (value ?? '').trim().isEmpty))
                    const Text(
                      'Terima kasih atas kunjungan Anda',
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

  Widget _buildPrinterDeviceSection(Map<String, String> company) {
    return _buildSection(
      title: 'Printer Terminal Ini',
      icon: Icons.print_outlined,
      children: [
        if (_printersLoading)
          const LinearProgressIndicator()
        else if (_printers.isEmpty)
          const Text(
            'Platform tidak menyediakan daftar printer. Pencetakan tetap menggunakan dialog cetak sistem.',
            style: TextStyle(color: Colors.black54),
          )
        else ...[
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
        const SizedBox(height: 8),
        const Text(
          'Pilihan printer disimpan hanya pada perangkat ini. Jika direct print tidak didukung driver, sistem otomatis membuka dialog cetak.',
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
          'Printer tidak merespons. Periksa koneksi atau driver printer.',
        );
      }
    } catch (_) {
      if (mounted) AppToast.error(context, 'Tes cetak gagal dibuka');
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
