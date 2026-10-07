import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/receipt/pos_receipt_document_builder.dart';
import '../../../core/receipt/pos_receipt_print_service.dart';
import '../../../domain/models/pos_receipt_template.dart';
import '../../../domain/repositories/pos_receipt_repository.dart';
import '../../../injections.dart';
import '../../widgets/app_toast.dart';
import '../../../domain/models/pos_transaction_result.dart';
import 'package:intl/intl.dart';
import '../../widgets/pos_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class PosSuccessPage extends StatelessWidget {
  final PosTransactionResult transaction;
  final bool autoPrint;
  const PosSuccessPage({
    super.key,
    required this.transaction,
    this.autoPrint = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const PosAppBarTitle(
          title: 'Pembayaran Berhasil',
          subtitle: 'Transaksi telah selesai diproses',
        ),
      ),
      bottomSheet: autoPrint
          ? _AutoPrintTrigger(onPrint: () => _printReceipt(context))
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const pagePadding = 24.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(pagePadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (pagePadding * 2),
                ),
                child: Center(
                  child: Container(
                    width: 500,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF087F75), // Light green
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Sukses!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              _buildRow('Invoice', transaction.invoice),
                              const SizedBox(height: 16),
                              _buildRow(
                                'Total Tagihan',
                                _currency(transaction.total),
                              ),
                              const SizedBox(height: 16),
                              _buildRow(
                                transaction.paymentMethod.toUpperCase(),
                                _currency(transaction.cashReceived),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Divider(
                                  color: Colors.black12,
                                  height: 1,
                                ),
                              ),
                              _buildRow(
                                'Kembalian',
                                _currency(transaction.change),
                              ),
                              if (transaction.pendingSync) ...[
                                const SizedBox(height: 16),
                                const Text(
                                  'Menunggu sinkronisasi server',
                                  style: TextStyle(color: AppColors.warning),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _showShareOptions(context),
                                      icon: const Icon(
                                        Icons.share,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Bagikan Struk',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        side: const BorderSide(
                                          color: AppColors.primary,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _PrintReceiptButton(
                                      onPressed: () => _printReceipt(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Navigate back to the very first route (PosPage)
                                    Navigator.popUntil(
                                      context,
                                      (route) => route.isFirst,
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Selesai',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ],
    );
  }

  String _currency(double value) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  ).format(value);

  String get _receiptText =>
      'Struk ${transaction.invoice}\n'
      '${transaction.storeName.isEmpty ? '' : '${transaction.storeName}\n'}'
      '${transaction.cashierName.isEmpty ? '' : 'Kasir: ${transaction.cashierName}\n'}'
      '${transaction.customerName.isEmpty ? '' : 'Pelanggan: ${transaction.customerName}\n'}'
      '${transaction.date.isEmpty ? '' : '${transaction.date}\n'}'
      '\n'
      '${transaction.items.map(_formatThermalItem).join('\n')}\n'
      '\n'
      'Subtotal: ${_currency(transaction.subtotal)}\n'
      '${transaction.discount > 0 ? 'Diskon: -${_currency(transaction.discount)}\n' : ''}'
      'Total: ${_currency(transaction.total)}\n'
      'Pembayaran: ${transaction.paymentMethod.toUpperCase()}\n'
      'Dibayar: ${_currency(transaction.cashReceived)}\n'
      '${transaction.change > 0 ? 'Kembalian: ${_currency(transaction.change)}\n' : ''}'
      '${transaction.note.trim().isEmpty ? '' : 'Catatan: ${transaction.note}\n'}'
      'Terima kasih.';

  String _buildThermalReceiptText(PosReceiptPrintData printData) {
    final parsedDate = DateTime.tryParse(transaction.date)?.toLocal();
    return PosReceiptDocumentBuilder.buildThermalText(
      data: PosReceiptDocumentData(
        invoice: transaction.invoice,
        dateLabel: parsedDate == null
            ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())
            : DateFormat('dd/MM/yyyy HH:mm').format(parsedDate),
        cashierName: transaction.cashierName,
        storeName: transaction.storeName,
        customerName: transaction.customerName,
        paymentMethod: transaction.paymentMethod,
        salesChannel: transaction.salesChannel,
        customerSegment: transaction.customerSegment,
        orderType: transaction.orderType,
        promoCode: transaction.promoCode,
        subtotal: transaction.subtotal,
        discount: transaction.discount,
        promoDiscount: transaction.promoDiscount,
        tax: transaction.tax,
        total: transaction.total,
        cashReceived: transaction.cashReceived,
        change: transaction.change,
        note: transaction.note,
        items: transaction.items,
      ),
      template: printData.template,
      company: printData.company,
    );
  }

  String _formatThermalItem(Map<String, dynamic> item) {
    final name = (item['nama'] ??
            item['nama_produk'] ??
            item['name'] ??
            item['product_name'] ??
            'Produk')
        .toString();
    final qty = item['qty'] ?? item['quantity'] ?? item['jumlah'] ?? 1;
    final amount = item['total'] ??
        item['subtotal'] ??
        item['jumlah_harga'] ??
        item['harga_total'] ??
        0;
    final amountValue = amount is num
        ? amount.toDouble()
        : double.tryParse(amount.toString()) ?? 0;
    return '$name x$qty  ${_currency(amountValue)}';
  }

  Future<void> _showShareOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bagikan struk melalui',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (transaction.customerName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  transaction.customerName,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.image_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Bagikan sebagai PNG'),
                subtitle: const Text('Pilih WhatsApp atau aplikasi lain'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareReceiptFile(context, _ReceiptFileType.png);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.danger,
                ),
                title: const Text('Bagikan sebagai PDF'),
                subtitle: const Text('Cocok untuk arsip dan cetak ulang'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareReceiptFile(context, _ReceiptFileType.pdf);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
                title: const Text('WhatsApp sebagai teks'),
                subtitle: Text(
                  transaction.customerPhone.isEmpty
                      ? 'Masukkan nomor tujuan'
                      : transaction.customerPhone,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareWhatsApp(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _requestDestination(
    BuildContext context, {
    required String title,
    required String initialValue,
    required TextInputType keyboardType,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          autofocus: initialValue.isEmpty,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _shareWhatsApp(BuildContext context) async {
    final rawPhone = await _requestDestination(
      context,
      title: 'Nomor WhatsApp',
      initialValue: transaction.customerPhone,
      keyboardType: TextInputType.phone,
    );
    if (rawPhone == null || rawPhone.isEmpty) return;
    var phone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.startsWith('0')) phone = '62${phone.substring(1)}';
    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(_receiptText)}',
    );
    if (!context.mounted) return;
    await _launchOrCopy(context, uri);
  }

  Future<void> _shareReceiptFile(
    BuildContext context,
    _ReceiptFileType type,
  ) async {
    try {
      final isPng = type == _ReceiptFileType.png;
      final bytes = isPng ? await _buildReceiptPng() : await _buildReceiptPdf();
      if (!context.mounted) return;

      final extension = isPng ? 'png' : 'pdf';
      final mimeType = isPng ? 'image/png' : 'application/pdf';
      final safeInvoice = transaction.invoice
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '-')
          .replaceAll(RegExp(r'-+'), '-');
      final fileName =
          'Struk-${safeInvoice.isEmpty ? 'POS' : safeInvoice}.$extension';
      final box = context.findRenderObject() as RenderBox?;

      await SharePlus.instance.share(
        ShareParams(
          title: 'Bagikan struk ${transaction.invoice}',
          subject: 'Struk ${transaction.invoice}',
          text: 'Struk transaksi ${transaction.invoice} dari Pantoo POS.',
          files: [XFile.fromData(bytes, mimeType: mimeType, name: fileName)],
          fileNameOverrides: [fileName],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (context.mounted) {
        AppToast.error(context, 'Gagal membuat file struk. Silakan coba lagi.');
      }
    }
  }

  Future<PosReceiptPrintData> _loadReceiptPrintData() async {
    final result = await sl<PosReceiptRepository>().getReceiptPrintData();
    return result.fold(
      (_) => const PosReceiptPrintData(
        template: PosReceiptTemplate(),
        company: {},
      ),
      (value) => value,
    );
  }

  Future<Uint8List> _buildReceiptPdf({PosReceiptPrintData? printData}) async {
    final resolvedPrintData = printData ?? await _loadReceiptPrintData();
    final rawDate = transaction.date.trim();
    final parsedDate = DateTime.tryParse(rawDate)?.toLocal();
    return PosReceiptDocumentBuilder.build(
      data: PosReceiptDocumentData(
        invoice: transaction.invoice,
        dateLabel: parsedDate == null
            ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())
            : DateFormat('dd/MM/yyyy HH:mm').format(parsedDate),
        cashierName: transaction.cashierName,
        storeName: transaction.storeName,
        customerName: transaction.customerName,
        paymentMethod: transaction.paymentMethod,
        salesChannel: transaction.salesChannel,
        customerSegment: transaction.customerSegment,
        orderType: transaction.orderType,
        promoCode: transaction.promoCode,
        subtotal: transaction.subtotal,
        discount: transaction.discount,
        promoDiscount: transaction.promoDiscount,
        tax: transaction.tax,
        total: transaction.total,
        cashReceived: transaction.cashReceived,
        change: transaction.change,
        note: [
          transaction.note,
          if (transaction.expiredSaleReason.isNotEmpty)
            'PERINGATAN: Barang kedaluwarsa dijual dengan otorisasi. Alasan: ${transaction.expiredSaleReason}',
        ].where((value) => value.trim().isNotEmpty).join('\n'),
        items: transaction.items,
      ),
      template: resolvedPrintData.template,
      company: resolvedPrintData.company,
    );
  }

  Future<Uint8List> _buildReceiptPng() async {
    final pdf = await _buildReceiptPdf();
    final page = await Printing.raster(pdf, pages: const [0], dpi: 180).first;
    return page.toPng();
  }

  Future<void> _printReceipt(BuildContext context) async {
    try {
      final printService = PosReceiptPrintService(sl());
      // Mini Bluetooth printers are text/ESC-POS devices. Use their direct
      // text channel instead of rendering a PDF to a bitmap first. The PDF
      // option remains available when visual fidelity/logo is preferred.
      if (printService.selectedBluetoothAddress.isNotEmpty &&
          printService.renderMode == 'fast') {
        final printData = await _loadReceiptPrintData().timeout(
          const Duration(seconds: 2),
          onTimeout: () => const PosReceiptPrintData(
            template: PosReceiptTemplate(),
            company: {},
          ),
        );
        try {
          await printService
              .printText(
                text: _buildThermalReceiptText(printData),
                charactersPerLine:
                    printData.template.paperWidth == 80 ? 48 : 32,
              )
              .timeout(const Duration(seconds: 10));
          return;
        } catch (_) {
          // Some mini printers expose Bluetooth but reject raw text writes.
          // Fall through to the image/PDF path so printing still succeeds.
        }
      }
      final printData = await _loadReceiptPrintData().timeout(
        const Duration(seconds: 10),
      );
      final bytes = await _buildReceiptPdf(
        printData: printData,
      ).timeout(const Duration(seconds: 15));
      await printService
          .printPdf(
            bytes: bytes,
            name: 'Struk-${transaction.invoice}',
            format: PosReceiptDocumentBuilder.pageFormatFor(
              printData.template,
              transaction.items.length,
            ),
          )
          .timeout(const Duration(seconds: 45));
    } catch (error) {
      if (context.mounted) {
        AppToast.error(
          context,
          error is TimeoutException
              ? 'Printer terlalu lama merespons. Periksa koneksi lalu coba lagi.'
              : error.toString().contains('PRINTER_NOT_CONFIGURED')
              ? 'Pilih printer Bluetooth di Pengaturan Printer terlebih dahulu.'
              : 'Printer Bluetooth tidak merespons. Periksa koneksi printer.',
        );
      }
    }
  }

  Future<void> _launchOrCopy(BuildContext context, Uri uri) async {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    await Clipboard.setData(ClipboardData(text: _receiptText));
    if (context.mounted) {
      AppToast.success(
        context,
        'Aplikasi tujuan tidak tersedia. Struk disalin.',
      );
    }
  }
}

class _PrintReceiptButton extends StatefulWidget {
  final Future<void> Function() onPressed;

  const _PrintReceiptButton({required this.onPressed});

  @override
  State<_PrintReceiptButton> createState() => _PrintReceiptButtonState();
}

class _PrintReceiptButtonState extends State<_PrintReceiptButton> {
  bool _printing = false;

  Future<void> _handlePressed() async {
    if (_printing) return;
    setState(() => _printing = true);
    try {
      await widget.onPressed();
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _printing ? null : _handlePressed,
      icon: _printing
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.print, color: AppColors.primary, size: 18),
      label: Text(
        _printing ? 'Mencetak…' : 'Cetak Struk',
        style: const TextStyle(color: AppColors.primary),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

enum _ReceiptFileType { png, pdf }

class _AutoPrintTrigger extends StatefulWidget {
  final Future<void> Function() onPrint;

  const _AutoPrintTrigger({required this.onPrint});

  @override
  State<_AutoPrintTrigger> createState() => _AutoPrintTriggerState();
}

class _AutoPrintTriggerState extends State<_AutoPrintTrigger> {
  bool _printing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runPrint();
    });
  }

  Future<void> _runPrint() async {
    await widget.onPrint();
    if (!mounted) return;
    setState(() => _printing = false);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_printing) return const SizedBox.shrink();
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text(
                'Mencetak struk…',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
