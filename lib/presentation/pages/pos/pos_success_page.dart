import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import '../../widgets/app_toast.dart';
import '../../../domain/models/pos_transaction_result.dart';
import 'package:intl/intl.dart';
import 'pos_printer_page.dart';
import '../../widgets/pos_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class PosSuccessPage extends StatelessWidget {
  final PosTransactionResult transaction;
  const PosSuccessPage({super.key, required this.transaction});

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
                            color: Color(0xFF5DCA74), // Light green
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
                                  style: TextStyle(color: Colors.orange),
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
                                    child: OutlinedButton.icon(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const PosPrinterPage(),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.print,
                                        color: AppColors.primary,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Atur Struk',
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
      '${transaction.customerName.isEmpty ? '' : 'Pelanggan: ${transaction.customerName}\n'}'
      'Total: ${_currency(transaction.total)}\n'
      'Pembayaran: ${transaction.paymentMethod.toUpperCase()}\n'
      '${transaction.change > 0 ? 'Kembalian: ${_currency(transaction.change)}\n' : ''}'
      'Terima kasih.';

  Future<void> _showShareOptions(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bagikan struk melalui',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                leading: const Icon(Icons.chat, color: Color(0xFF25D366)),
                title: const Text('WhatsApp'),
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
              ListTile(
                leading: const Icon(
                  Icons.email_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Email'),
                subtitle: Text(
                  transaction.customerEmail.isEmpty
                      ? 'Masukkan email tujuan'
                      : transaction.customerEmail,
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _shareEmail(context);
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

  Future<void> _shareEmail(BuildContext context) async {
    final email = await _requestDestination(
      context,
      title: 'Email pelanggan',
      initialValue: transaction.customerEmail,
      keyboardType: TextInputType.emailAddress,
    );
    if (email == null || email.isEmpty) return;
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Struk ${transaction.invoice}',
        'body': _receiptText,
      },
    );
    if (!context.mounted) return;
    await _launchOrCopy(context, uri);
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
