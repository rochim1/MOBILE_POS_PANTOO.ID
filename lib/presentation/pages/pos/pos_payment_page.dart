import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/pos/pos_bloc.dart';
import '../../bloc/pos/pos_event.dart';
import '../../bloc/pos/pos_state.dart';
import 'pos_success_page.dart';
import '../../../../injections.dart';
import '../../../../domain/repositories/pos_repository.dart';
import '../../widgets/app_toast.dart';
import '../../../../domain/models/pos_order.dart';

class PosPaymentPage extends StatefulWidget {
  final PosOrder? pendingOrder;

  const PosPaymentPage({super.key, this.pendingOrder});

  @override
  State<PosPaymentPage> createState() => _PosPaymentPageState();
}

class _PosPaymentPageState extends State<PosPaymentPage> {
  String _paymentMethod = 'Tunai';
  double _cashReceived = 0;
  List<Map<String, dynamic>> _splitPayments = [];
  String _invoiceNote = '';
  bool _creatingInvoice = false;
  bool _payingPendingInvoice = false;

  @override
  void initState() {
    super.initState();
    _invoiceNote = widget.pendingOrder?.note ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        toolbarHeight: 64,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.storefront_outlined,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pembayaran',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _activeStoreName(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Online',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<PosBloc, PosState>(
        listener: (context, state) {
          if (state.status == PosStatus.paymentSuccess) {
            final transaction = state.lastTransaction;
            if (transaction == null) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PosSuccessPage(transaction: transaction),
              ),
            );
          } else if (state.status == PosStatus.failure &&
              state.errorMessage.isNotEmpty) {
            final message = state.errorMessage;
            final canRequestOverride =
                state.runtimeConfig['expired_sale_policy'] ==
                    'allow_with_permission' &&
                (message.toLowerCase().contains('sudah kadaluarsa') ||
                    message.toLowerCase().contains('sudah kedaluwarsa'));
            if (canRequestOverride) {
              _requestExpiredSaleOverride();
              return;
            }
            showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                icon: Icon(
                  _failureIcon(message),
                  color: Colors.orange.shade700,
                  size: 42,
                ),
                title: Text(_failureTitle(message)),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Tutup'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(context);
                    },
                    child: const Text('Kembali ke Keranjang'),
                  ),
                ],
              ),
            );
          }
        },
        builder: (context, state) {
          final total = widget.pendingOrder?.total ?? state.grandTotal;
          final subtotal = widget.pendingOrder?.subtotal ?? state.subTotal;
          final discount =
              widget.pendingOrder?.discountAmount ?? state.totalDiscount;
          final tax = widget.pendingOrder?.taxAmount ?? state.taxAmount;
          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              return Flex(
                direction: compact ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left Panel
                  Expanded(
                    flex: 6,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          // Top Totals
                          Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildAmountBlock(
                                    'Total Tagihan',
                                    total,
                                    Colors.black,
                                  ),
                                ),
                                Expanded(
                                  child: _buildAmountBlock(
                                    'Sisa Tagihan',
                                    total - _cashReceived > 0
                                        ? total - _cashReceived
                                        : 0,
                                    Colors.red,
                                  ),
                                ),
                                Expanded(
                                  child: _buildAmountBlock(
                                    'Kembalian',
                                    _cashReceived - total > 0
                                        ? _cashReceived - total
                                        : 0,
                                    Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  Icons.account_balance_wallet,
                                  'Pisah Bayar',
                                  onPressed: () =>
                                      _configureSplitPayment(total),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 60,
                                color: Colors.grey.shade200,
                              ),
                              Expanded(
                                child: _buildActionButton(
                                  Icons.receipt_long,
                                  'Jadikan Invoice',
                                  onPressed:
                                      _creatingInvoice ||
                                          widget.pendingOrder != null
                                      ? null
                                      : () => _createInvoice(context, state),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 60,
                                color: Colors.grey.shade200,
                              ),
                              Expanded(
                                child: _buildActionButton(
                                  Icons.edit,
                                  _invoiceNote.isEmpty
                                      ? 'Catatan'
                                      : 'Catatan ✓',
                                  onPressed: _editNote,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 1),
                          // Payment Methods & Options
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Methods List
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                    ),
                                    child: ListView(
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Metode Pembayaran',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Icon(Icons.sort, size: 20),
                                            ],
                                          ),
                                        ),
                                        _buildPaymentMethodTile('Tunai'),
                                        _buildPaymentMethodTile('Kartu Debit'),
                                        _buildPaymentMethodTile('Transfer'),
                                        _buildPaymentMethodTile('QRIS'),
                                        _buildPaymentMethodTile('E-Wallet'),
                                        _buildPaymentMethodTile('Kartu Kredit'),
                                      ],
                                    ),
                                  ),
                                ),
                                // Cash Options
                                Expanded(
                                  flex: 7,
                                  child: Container(
                                    color: const Color(0xFFF9FAFB),
                                    padding: const EdgeInsets.all(24),
                                    child: _paymentMethod == 'Pisah Bayar'
                                        ? _buildSplitSummary(total)
                                        : _paymentMethod == 'Tunai'
                                        ? GridView.count(
                                            crossAxisCount: 2,
                                            childAspectRatio: 3,
                                            crossAxisSpacing: 16,
                                            mainAxisSpacing: 16,
                                            children: [
                                              _buildCashOption(
                                                'Uang Pas',
                                                total,
                                              ),
                                              _buildCashOption(
                                                'Rp 20.000',
                                                20000,
                                              ),
                                              _buildCashOption(
                                                'Rp 50.000',
                                                50000,
                                              ),
                                              _buildCashOption('Lainnya', 0),
                                            ],
                                          )
                                        : Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(24),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.verified_outlined,
                                                    size: 42,
                                                    color: AppColors.primary,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    'Konfirmasi $_paymentMethod',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  const Text(
                                                    'Pastikan pembayaran sudah diterima pada perangkat atau rekening merchant sebelum memproses transaksi. POS mencatat metode pembayaran dan tidak menjalankan payment gateway otomatis.',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ],
                                              ),
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
                  // Right Panel (Cart Summary)
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.account_circle_outlined,
                                      color: Colors.black54,
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        widget.pendingOrder?.customer ??
                                            state.selectedCustomer?.name ??
                                            'Tanpa Pelanggan',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  widget.pendingOrder?.invoice ??
                                      'Transaksi Baru',
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount:
                                  widget.pendingOrder?.items.length ??
                                  state.cart.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final pendingItem =
                                    widget.pendingOrder?.items[index];
                                final product = pendingItem == null
                                    ? state.cart.keys.elementAt(index)
                                    : null;
                                final qty =
                                    pendingItem?['qty'] as num? ??
                                    state.cart[product]!;
                                final name =
                                    pendingItem?['nama']?.toString() ??
                                    product!.name;
                                final itemTotal = pendingItem == null
                                    ? product!.price * qty
                                    : (pendingItem['subtotal'] as num?)
                                              ?.toDouble() ??
                                          ((pendingItem['harga_satuan'] as num?)
                                                      ?.toDouble() ??
                                                  0) *
                                              qty;
                                return Row(
                                  children: [
                                    Expanded(flex: 1, child: Text('$qty')),
                                    Expanded(flex: 5, child: Text(name)),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        _money(itemTotal),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade200),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildSummaryRow('Subtotal', subtotal),
                                if (discount > 0)
                                  _buildSummaryRow(
                                    'Diskon',
                                    -discount,
                                    color: Colors.green.shade700,
                                  ),
                                if (tax > 0) _buildSummaryRow('Pajak', tax),
                                if (_invoiceNote.trim().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.notes_outlined,
                                        size: 16,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _invoiceNote,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const Divider(height: 18),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.pendingOrder != null
                                            ? 'Total Invoice'
                                            : 'Total ${state.totalItems} Produk',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _money(total),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  (state.status == PosStatus.loading ||
                                      _payingPendingInvoice)
                                  ? null
                                  : ((_paymentMethod == 'Pisah Bayar' &&
                                            (_splitPayments.fold<double>(
                                                          0,
                                                          (sum, item) =>
                                                              sum +
                                                              (item['jumlah']
                                                                      as num)
                                                                  .toDouble(),
                                                        ) -
                                                        total)
                                                    .abs() <
                                                0.01) ||
                                        (_paymentMethod != 'Tunai' &&
                                            _paymentMethod != 'Pisah Bayar') ||
                                        _cashReceived >= total)
                                  ? () {
                                      final normalizedMethod =
                                          switch (_paymentMethod) {
                                            'Tunai' => 'tunai',
                                            'Transfer' => 'transfer',
                                            'QRIS' => 'qris',
                                            'Kartu Debit' => 'debit',
                                            'E-Wallet' => 'e_wallet',
                                            'Kartu Kredit' => 'kartu_kredit',
                                            'Pisah Bayar' => 'split',
                                            _ => '',
                                          };
                                      if (normalizedMethod.isEmpty) return;
                                      if (widget.pendingOrder != null) {
                                        _payPendingInvoice(normalizedMethod);
                                      } else {
                                        context.read<PosBloc>().add(
                                          SubmitPayment(
                                            paymentMethod: normalizedMethod,
                                            cashReceived: _cashReceived,
                                            payments: _splitPayments,
                                            note: _invoiceNote,
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                disabledBackgroundColor: Colors.grey.shade300,
                                minimumSize: const Size.fromHeight(60),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                              ),
                              child:
                                  state.status == PosStatus.loading ||
                                      _payingPendingInvoice
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          widget.pendingOrder != null
                                              ? 'Bayar Invoice'
                                              : 'Proses Bayar',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color:
                                                (_paymentMethod != 'Tunai' ||
                                                    _cashReceived >= total)
                                                ? Colors.white
                                                : Colors.grey,
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color:
                                              (_paymentMethod != 'Tunai' ||
                                                  _cashReceived >= total)
                                              ? Colors.white
                                              : Colors.grey,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _requestExpiredSaleOverride() async {
    final usernameController = TextEditingController();
    final pinController = TextEditingController();
    final reasonController = TextEditingController();
    final authorization = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: const Text('Otorisasi Barang Kedaluwarsa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Username supervisor',
              ),
            ),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'PIN supervisor'),
            ),
            TextField(
              controller: reasonController,
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Alasan penjualan',
                hintText: 'Minimal 5 karakter',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final username = usernameController.text.trim();
              final pin = pinController.text.trim();
              final reason = reasonController.text.trim();
              if (username.isNotEmpty &&
                  RegExp(r'^\d{4,6}$').hasMatch(pin) &&
                  reason.length >= 5) {
                Navigator.pop(dialogContext, {
                  'username': username,
                  'pin': pin,
                  'reason': reason,
                });
              }
            },
            child: const Text('Otorisasi & Lanjutkan'),
          ),
        ],
      ),
    );
    usernameController.dispose();
    pinController.dispose();
    reasonController.dispose();
    if (!mounted || authorization == null) return;
    final normalizedMethod = switch (_paymentMethod) {
      'Tunai' => 'tunai',
      'Transfer' => 'transfer',
      'QRIS' => 'qris',
      'Kartu Debit' => 'debit',
      'E-Wallet' => 'e_wallet',
      'Kartu Kredit' => 'kartu_kredit',
      'Pisah Bayar' => 'split',
      _ => '',
    };
    if (normalizedMethod.isEmpty) return;
    context.read<PosBloc>().add(
      SubmitPayment(
        paymentMethod: normalizedMethod,
        cashReceived: _cashReceived,
        payments: _splitPayments,
        note: _invoiceNote,
        expiredSaleReason: authorization['reason']!,
        expiredSaleAuthorizerUsername: authorization['username']!,
        expiredSaleAuthorizerPin: authorization['pin']!,
      ),
    );
  }

  Future<void> _payPendingInvoice(String method) async {
    final order = widget.pendingOrder;
    if (order == null || _payingPendingInvoice) return;
    setState(() => _payingPendingInvoice = true);
    final result = await sl<PosRepository>().payPendingOrder(
      orderId: order.id,
      method: method,
      cashReceived: method == 'tunai' ? _cashReceived : order.total,
      splitPayments: method == 'split' ? _splitPayments : const [],
    );
    if (!mounted) return;
    setState(() => _payingPendingInvoice = false);
    result.fold((failure) => AppToast.error(context, failure.message), (_) {
      context.read<PosBloc>().add(RefreshOrders());
      AppToast.success(context, 'Invoice ${order.invoice} berhasil dibayar');
      Navigator.pop(context);
    });
  }

  String _activeStoreName(BuildContext context) {
    final state = context.read<PosBloc>().state;
    final fromShift = state.activeShift?['toko']?['nama_toko']
        ?.toString()
        .trim();
    if (fromShift != null && fromShift.isNotEmpty) return fromShift;
    final storeId = state.activeShift?['toko_id']?.toString();
    final matching = state.stores.where((store) => store.id == storeId);
    if (matching.isNotEmpty) return matching.first.name;
    if (state.stores.length == 1) return state.stores.first.name;
    return 'Pantoo POS';
  }

  String _failureTitle(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('kadaluarsa') ||
        normalized.contains('kedaluwarsa')) {
      return 'Produk Kedaluwarsa';
    }
    if (normalized.contains('stok')) return 'Stok Tidak Cukup';
    if (normalized.contains('uang diterima')) return 'Pembayaran Tidak Cukup';
    if (normalized.contains('shift')) return 'Shift Kasir Bermasalah';
    return 'Transaksi Ditolak';
  }

  IconData _failureIcon(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('kadaluarsa') ||
        normalized.contains('kedaluwarsa')) {
      return Icons.event_busy;
    }
    if (normalized.contains('stok')) return Icons.inventory_2_outlined;
    if (normalized.contains('uang diterima')) return Icons.payments_outlined;
    return Icons.warning_amber_rounded;
  }

  Widget _buildAmountBlock(String label, double amount, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rp ',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              formatRupiahInput(amount),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _money(double amount) {
    final prefix = amount < 0 ? '-Rp ' : 'Rp ';
    return '$prefix${formatRupiahInput(amount.abs())}';
  }

  Widget _buildSummaryRow(String label, double amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(
            _money(amount),
            style: TextStyle(
              color: color ?? Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label, {
    VoidCallback? onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.primary),
      label: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  Future<void> _editNote() async {
    final controller = TextEditingController(text: _invoiceNote);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Catatan transaksi'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 500,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Contoh: pesanan tanpa sambal, referensi pembayaran…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && mounted) setState(() => _invoiceNote = result);
  }

  Future<void> _createInvoice(BuildContext context, PosState state) async {
    if (state.orderType == 'dine_in') {
      AppToast.warning(
        context,
        'Invoice dine-in harus dibuat dari Table Order agar meja tercatat.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Jadikan Invoice?'),
        content: const Text(
          'Pesanan akan disimpan sebagai tagihan belum dibayar. Stok belum dipotong sampai invoice dibayar dari Daftar Order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Buat Invoice'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _creatingInvoice = true);
    final activeShift = state.activeShift;
    final result = await sl<PosRepository>().createUnpaidInvoice(
      cart: state.cart,
      tokoId: activeShift?['toko_id']?.toString() ?? '',
      shiftId: activeShift?['_id']?.toString() ?? '',
      orderType: state.orderType,
      customerId: state.selectedCustomer?.id,
      customerName: state.selectedCustomer?.name,
      note: _invoiceNote,
      discountPercent: state.subTotal > 0
          ? (state.totalDiscount / state.subTotal * 100)
                .clamp(0, 100)
                .toDouble()
          : 0,
      taxPercent: state.taxPercent,
      salesChannel: state.salesChannel,
      customerSegment: state.customerSegment,
      priceLevel: state.priceLevel,
      itemPrices: {
        for (final product in state.cart.keys)
          product.id: state.unitPriceFor(product),
      },
    );
    if (!mounted) return;
    setState(() => _creatingInvoice = false);
    result.fold((failure) => AppToast.error(context, failure.message), (
      invoice,
    ) {
      context.read<PosBloc>().add(ClearCart());
      context.read<PosBloc>().add(RefreshOrders());
      AppToast.success(
        context,
        'Invoice ${invoice['order_no'] ?? ''} berhasil dibuat.',
      );
      Navigator.pop(context);
    });
  }

  Future<void> _enterCustomCash() async {
    final controller = TextEditingController();
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Uang diterima'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          decoration: const InputDecoration(
            prefixText: 'Rp ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, parseRupiah(controller.text)),
            child: const Text('Gunakan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result > 0 && mounted) {
      setState(() => _cashReceived = result);
    }
  }

  Future<void> _configureSplitPayment(double total) async {
    final drafts = _splitPayments.length >= 2
        ? _splitPayments
              .map(
                (item) => _SplitPaymentDraft(
                  method: item['metode'] as String? ?? 'tunai',
                  amount: (item['jumlah'] as num?)?.toDouble() ?? 0,
                ),
              )
              .toList()
        : [
            _SplitPaymentDraft(method: 'tunai'),
            _SplitPaymentDraft(method: 'qris'),
          ];
    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          double paid() => drafts.fold(0, (sum, draft) => sum + draft.amount);
          final difference = total - paid();
          final isValid =
              drafts.length >= 2 &&
              drafts.every((draft) => draft.amount > 0) &&
              difference.abs() < 0.01;
          return AlertDialog(
            title: const Text('Pisah Bayar'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < drafts.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: DropdownButtonFormField<String>(
                                initialValue: drafts[index].method,
                                decoration: const InputDecoration(
                                  labelText: 'Metode',
                                  border: OutlineInputBorder(),
                                ),
                                items: _splitPaymentMethods.entries
                                    .map(
                                      (entry) => DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(entry.value),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) => setDialogState(
                                  () => drafts[index].method = value!,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: TextField(
                                controller: drafts[index].controller,
                                keyboardType: TextInputType.number,
                                inputFormatters: const [RupiahInputFormatter()],
                                decoration: const InputDecoration(
                                  labelText: 'Jumlah',
                                  prefixText: 'Rp ',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) => setDialogState(() {}),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Hapus metode',
                              onPressed: drafts.length <= 2
                                  ? null
                                  : () => setDialogState(() {
                                      drafts.removeAt(index).dispose();
                                    }),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => setDialogState(
                          () => drafts.add(_SplitPaymentDraft()),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah metode pembayaran'),
                      ),
                    ),
                    const Divider(),
                    _buildSplitTotalRow('Total tagihan', total),
                    _buildSplitTotalRow('Sudah dialokasikan', paid()),
                    _buildSplitTotalRow(
                      difference >= 0 ? 'Sisa' : 'Kelebihan',
                      difference.abs(),
                      color: isValid ? Colors.green : Colors.red,
                    ),
                    if (!isValid)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Minimal 2 metode, setiap jumlah harus lebih dari 0, dan total harus tepat.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: isValid
                    ? () => Navigator.pop(
                        dialogContext,
                        drafts
                            .map(
                              (draft) => {
                                'metode': draft.method,
                                'jumlah': draft.amount,
                              },
                            )
                            .toList(),
                      )
                    : null,
                child: const Text('Gunakan'),
              ),
            ],
          );
        },
      ),
    );
    for (final draft in drafts) {
      draft.dispose();
    }
    if (result == null) return;
    setState(() {
      _paymentMethod = 'Pisah Bayar';
      _splitPayments = result;
      _cashReceived = result
          .where((item) => item['metode'] == 'tunai')
          .fold<double>(
            0,
            (sum, item) => sum + (item['jumlah'] as num).toDouble(),
          );
    });
  }

  Widget _buildSplitTotalRow(String label, double amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            'Rp ${amount.toStringAsFixed(0)}',
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitSummary(double total) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final item in _splitPayments)
          Material(
            color: Colors.transparent,
            child: ListTile(
              title: Text(item['metode'].toString().toUpperCase()),
              trailing: Text(
                'Rp ${(item['jumlah'] as num).toStringAsFixed(0)}',
              ),
            ),
          ),
        Text(
          'Total: Rp ${total.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(String method) {
    final isSelected = _paymentMethod == method;
    return InkWell(
      onTap: () => setState(() {
        _paymentMethod = method;
        _cashReceived = 0; // reset
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F7F3) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 4,
            ),
            bottom: BorderSide(color: Colors.grey.shade100),
          ),
        ),
        child: Text(
          method,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCashOption(String label, double amount) {
    final isSelected = _cashReceived == amount && amount != 0;
    return InkWell(
      onTap: () {
        if (amount == 0) {
          _enterCustomCash();
          return;
        }
        setState(() {
          _cashReceived = amount;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}

const _splitPaymentMethods = <String, String>{
  'tunai': 'Tunai',
  'debit': 'Kartu Debit',
  'transfer': 'Transfer',
  'qris': 'QRIS',
  'e_wallet': 'E-Wallet',
  'kartu_kredit': 'Kartu Kredit',
};

class _SplitPaymentDraft {
  _SplitPaymentDraft({this.method = 'tunai', double amount = 0})
    : controller = TextEditingController(
        text: amount > 0 ? formatRupiahInput(amount) : '',
      );

  String method;
  final TextEditingController controller;

  double get amount => parseRupiah(controller.text);

  void dispose() => controller.dispose();
}
