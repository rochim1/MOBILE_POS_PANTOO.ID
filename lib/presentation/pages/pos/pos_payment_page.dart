import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../bloc/pos/pos_bloc.dart';
import '../../bloc/pos/pos_event.dart';
import '../../bloc/pos/pos_state.dart';
import 'pos_success_page.dart';
import '../../../../injections.dart';
import '../../../../domain/repositories/pos_repository.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_keyboard_stable_dialog.dart';
import '../../widgets/pos_keyboard_stable_sheet.dart';
import '../../../../domain/models/pos_order.dart';
import '../../../../domain/models/pos_customer.dart';
import 'widgets/pos_quick_customer_dialog.dart';

class PosPaymentPage extends StatefulWidget {
  final PosOrder? pendingOrder;
  final PosCustomer? initialCustomer;
  final String requestedCustomerName;
  final String requestedCustomerPhone;

  const PosPaymentPage({
    super.key,
    this.pendingOrder,
    this.initialCustomer,
    this.requestedCustomerName = '',
    this.requestedCustomerPhone = '',
  });

  @override
  State<PosPaymentPage> createState() => _PosPaymentPageState();
}

class _PosPaymentPageState extends State<PosPaymentPage> {
  String _paymentMethod = 'Tunai';
  double _cashReceived = 0;
  List<Map<String, dynamic>> _splitPayments = [];
  String _invoiceNote = '';
  bool _creatingInvoice = false;
  bool _invoiceFlowOpen = false;
  final String _invoiceRequestId = const Uuid().v4();
  bool _payingPendingInvoice = false;
  bool _customerPromptOpen = false;
  PosCustomer? _paymentCustomer;
  Map<String, dynamic>? _serviceOrder;
  DateTime? _reservationStartAt;
  DateTime? _reservationEndAt;
  int _reservationGuestCount = 1;
  double _reservationDepositAmount = 0;

  @override
  void initState() {
    super.initState();
    _invoiceNote = widget.pendingOrder?.note ?? '';
    _paymentCustomer = widget.initialCustomer;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<PosBloc>();
      final state = bloc.state;
      if (_invoiceNote.isEmpty) {
        _invoiceNote = state.defaultTransactionNote;
      }
      _paymentMethod = _paymentMethodLabel(state.defaultPaymentMethod);
      setState(() {});
      if (widget.initialCustomer != null &&
          state.selectedCustomer?.id != widget.initialCustomer!.id) {
        bloc.add(SelectCustomer(widget.initialCustomer));
      }
    });
  }

  String _paymentMethodLabel(String value) => switch (value.toLowerCase()) {
    'transfer' => 'Transfer',
    'qris' => 'QRIS',
    'debit' => 'Kartu Debit',
    'kartu_kredit' || 'credit_card' => 'Kartu Kredit',
    'e_wallet' => 'E-Wallet',
    _ => 'Tunai',
  };

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
                        color: AppColors.success,
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
                builder: (context) => PosSuccessPage(
                  transaction: transaction,
                  autoPrint: state.runtimeConfig['auto_print_receipt'] == true,
                ),
              ),
            );
          } else if (state.status == PosStatus.failure &&
              state.errorMessage.isNotEmpty) {
            final message = state.errorMessage;
            if (message.toLowerCase().contains('pelanggan')) {
              _showRequiredCustomerFlow(
                state,
                message: message,
                invalidateSelection:
                    message.toLowerCase().contains('tidak ditemukan') ||
                    message.toLowerCase().contains('tidak valid'),
              );
              return;
            }
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
                  color: AppColors.warning,
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
          final belowCashMinimum =
              _paymentMethod == 'Tunai' &&
              state.minimumCashTransaction > 0 &&
              total < state.minimumCashTransaction;
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
                                    AppColors.danger,
                                  ),
                                ),
                                Expanded(
                                  child: _buildAmountBlock(
                                    'Kembalian',
                                    _cashReceived - total > 0
                                        ? _cashReceived - total
                                        : 0,
                                    AppColors.info,
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
                                  state.orderType == 'dine_in'
                                      ? 'Simpan ke Meja'
                                      : 'Jadikan Invoice',
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
                                    color: const Color(0xFFF7F8FA),
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
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.account_circle_outlined,
                                        color: Colors.black54,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          child: InkWell(
                                            onTap: () =>
                                                _selectPaymentCustomer(state),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 2,
                                                  ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      _customerLabel(state),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(
                                                    Icons.edit_outlined,
                                                    size: 14,
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
                                const SizedBox(width: 8),
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
                              color: const Color(0xFFF7F8FA),
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
                                    color: AppColors.success,
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
                                            : 'Total ${state.totalItems == state.totalItems.truncateToDouble() ? state.totalItems.toStringAsFixed(0) : state.totalItems.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '')} Produk',
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
                          if (belowCashMinimum)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              color: AppColors.warningBackground,
                              child: Text(
                                'Minimum transaksi tunai ${_money(state.minimumCashTransaction)}. Pilih metode lain atau tambah transaksi.',
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  (state.status == PosStatus.loading ||
                                      _payingPendingInvoice ||
                                      belowCashMinimum)
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
                                        _cashReceived + 0.5 >= total)
                                  ? () async {
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
                                      if (widget.pendingOrder == null &&
                                          state.orderType == 'reservation') {
                                        await _createInvoice(
                                          context,
                                          state,
                                          continueToPayment: true,
                                        );
                                        return;
                                      }
                                      if (!await _ensureServiceOrder(state)) {
                                        return;
                                      }
                                      if (!context.mounted) return;
                                      if (!await _ensureRequiredCustomer(
                                        state,
                                      )) {
                                        return;
                                      }
                                      if (!context.mounted) return;
                                      if (widget.pendingOrder != null) {
                                        _payPendingInvoice(normalizedMethod);
                                      } else {
                                        context.read<PosBloc>().add(
                                          SubmitPayment(
                                            paymentMethod: normalizedMethod,
                                            cashReceived: _cashReceived,
                                            payments: _splitPayments,
                                            note: _invoiceNote,
                                            customerOverride:
                                                widget.initialCustomer,
                                            serviceOrder: _serviceOrder,
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
                                                    _cashReceived + 0.5 >=
                                                        total)
                                                ? Colors.white
                                                : Colors.grey,
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color:
                                              (_paymentMethod != 'Tunai' ||
                                                  _cashReceived + 0.5 >= total)
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
      builder: (dialogContext) => PosKeyboardStableFormDialog(
        width: 480,
        height: 540,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning),
            SizedBox(width: 8),
            Expanded(child: Text('Otorisasi Barang Kedaluwarsa')),
          ],
        ),
        content: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(dialogContext).bottom,
          ),
          child: Column(
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
        customerOverride: widget.initialCustomer,
        serviceOrder: _serviceOrder,
      ),
    );
  }

  Future<bool> _ensureServiceOrder(PosState state) async {
    final features = state.runtimeConfig['features'] as Map?;
    if (features?['use_service_order'] != true || widget.pendingOrder != null) {
      return true;
    }
    if (_serviceOrder != null) return true;
    final profile = state.runtimeConfig['business_profile']?.toString() ?? '';
    final serviceEntries = state.cart.entries
        .where((entry) => entry.key.productType == 'service')
        .toList();
    final serviceQuantity = serviceEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.value,
    );
    final subject = TextEditingController();
    final notes = TextEditingController();
    final weight = TextEditingController(
      text: profile == 'laundry' && serviceQuantity > 0
          ? _quantityText(serviceQuantity)
          : '',
    );
    final pieces = TextEditingController(
      text: profile == 'laundry' && serviceQuantity > 0
          ? serviceQuantity.round().toString()
          : '',
    );
    final tag = TextEditingController();
    final vehicleNo = TextEditingController();
    final vehicleModel = TextEditingController();
    final technician = TextEditingController();
    DateTime? appointmentAt;
    String mode = 'kiloan';
    String validationMessage = '';
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => PosKeyboardStableFormDialog(
          width: 520,
          height: 620,
          title: Text(
            profile == 'laundry' ? 'Detail cucian' : 'Detail layanan',
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (profile == 'laundry') ...[
                    DropdownButtonFormField<String>(
                      initialValue: mode,
                      decoration: const InputDecoration(
                        labelText: 'Model layanan',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'kiloan',
                          child: Text('Kiloan'),
                        ),
                        DropdownMenuItem(
                          value: 'satuan',
                          child: Text('Satuan'),
                        ),
                        DropdownMenuItem(value: 'paket', child: Text('Paket')),
                      ],
                      onChanged: (value) => setDialogState(() {
                        mode = value ?? 'kiloan';
                        if (serviceQuantity <= 0) return;
                        if (mode == 'kiloan') {
                          weight.text = _quantityText(serviceQuantity);
                        } else {
                          pieces.text = serviceQuantity.round().toString();
                        }
                      }),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weight,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Berat (kg)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: pieces,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Jumlah item',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tag,
                      decoration: const InputDecoration(
                        labelText: 'Tag kantong',
                      ),
                    ),
                    if (serviceEntries.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Jumlah tagihan mengikuti jumlah layanan di keranjang. '
                        'Ketuk angka jumlah pada keranjang untuk mengubah berat/jumlah.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ] else ...[
                    TextField(
                      controller: subject,
                      decoration: InputDecoration(
                        labelText: features?['use_vehicle_data'] == true
                            ? 'Objek/jenis kendaraan *'
                            : 'Objek layanan *',
                      ),
                    ),
                    if (features?['use_vehicle_data'] == true) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: vehicleNo,
                              textCapitalization: TextCapitalization.characters,
                              decoration: const InputDecoration(
                                labelText: 'No. polisi / ID unit',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: vehicleModel,
                              decoration: const InputDecoration(
                                labelText: 'Model / tipe',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (features?['use_technicians'] == true) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: technician,
                        decoration: const InputDecoration(
                          labelText: 'Teknisi / staf penanggung jawab',
                        ),
                      ),
                    ],
                    if (features?['use_appointments'] == true) ...[
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade400),
                        ),
                        leading: const Icon(Icons.event_outlined),
                        title: Text(
                          appointmentAt == null
                              ? 'Pilih jadwal layanan'
                              : DateFormat(
                                  'dd MMM yyyy · HH:mm',
                                  'id_ID',
                                ).format(appointmentAt!),
                        ),
                        trailing: appointmentAt == null
                            ? const Icon(Icons.chevron_right)
                            : IconButton(
                                tooltip: 'Hapus jadwal',
                                onPressed: () =>
                                    setDialogState(() => appointmentAt = null),
                                icon: const Icon(Icons.close),
                              ),
                        onTap: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: dialogContext,
                            initialDate: appointmentAt ?? now,
                            firstDate: DateTime(now.year, now.month, now.day),
                            lastDate: now.add(const Duration(days: 730)),
                          );
                          if (date == null || !dialogContext.mounted) return;
                          final time = await showTimePicker(
                            context: dialogContext,
                            initialTime: appointmentAt == null
                                ? TimeOfDay.now()
                                : TimeOfDay.fromDateTime(appointmentAt!),
                          );
                          if (time == null) return;
                          setDialogState(
                            () => appointmentAt = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: notes,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: profile == 'laundry'
                          ? 'Kondisi/catatan'
                          : 'Keluhan *',
                    ),
                  ),
                  if (validationMessage.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        validationMessage,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final kg =
                    double.tryParse(weight.text.replaceAll(',', '.')) ?? 0;
                final count = int.tryParse(pieces.text) ?? 0;
                final billedQuantity = mode == 'kiloan' ? kg : count.toDouble();
                final quantityMismatch =
                    profile == 'laundry' &&
                    serviceEntries.isNotEmpty &&
                    (billedQuantity - serviceQuantity).abs() > 0.000001;
                final reservationRequiresSchedule =
                    state.orderType == 'reservation' && appointmentAt == null;
                if ((profile == 'laundry' && kg <= 0 && count <= 0) ||
                    quantityMismatch ||
                    (profile != 'laundry' &&
                        subject.text.trim().isEmpty &&
                        notes.text.trim().isEmpty) ||
                    reservationRequiresSchedule) {
                  setDialogState(() {
                    validationMessage = quantityMismatch
                        ? 'Berat/jumlah harus sama dengan jumlah layanan di keranjang '
                              '(${_quantityText(serviceQuantity)}).'
                        : reservationRequiresSchedule
                        ? 'Jadwal layanan wajib dipilih untuk reservasi.'
                        : 'Lengkapi detail layanan sebelum melanjutkan.';
                  });
                  return;
                }
                final pricingBasis = switch (mode) {
                  'kiloan' => 'per_kg',
                  'paket' => 'package',
                  _ => 'per_item',
                };
                final serviceLines = serviceEntries.indexed.map((indexed) {
                  final index = indexed.$1;
                  final entry = indexed.$2;
                  return <String, dynamic>{
                    'product_id': entry.key.id,
                    'name': entry.key.name,
                    'object_type': profile.isEmpty ? 'service' : profile,
                    'pricing_basis': pricingBasis,
                    'quantity': pricingBasis == 'per_kg' ? 0 : entry.value,
                    'weight_kg': pricingBasis == 'per_kg' ? entry.value : 0,
                    'unit': pricingBasis == 'per_kg'
                        ? 'kg'
                        : entry.key.saleUnit,
                    if (index == 0 && tag.text.trim().isNotEmpty)
                      'tag_code': tag.text.trim(),
                    'condition_notes': notes.text.trim(),
                    'status': 'diterima',
                  };
                }).toList();
                Navigator.pop(dialogContext, {
                  'service_type': profile == 'laundry' ? 'Laundry' : 'Service',
                  'service_subject': profile == 'laundry'
                      ? 'Cucian pelanggan'
                      : subject.text.trim(),
                  'complaint': notes.text.trim(),
                  'condition_notes': profile == 'laundry'
                      ? notes.text.trim()
                      : '',
                  'service_mode': profile == 'laundry' ? mode : '',
                  'weight_kg': kg,
                  'item_count': count,
                  'bag_tag': tag.text.trim(),
                  'vehicle_no': vehicleNo.text.trim().toUpperCase(),
                  'vehicle_model': vehicleModel.text.trim(),
                  'technician_name': technician.text.trim(),
                  if (appointmentAt != null)
                    'appointment_at': appointmentAt!.toIso8601String(),
                  'status': 'diterima',
                  if (serviceLines.isNotEmpty) 'service_lines': serviceLines,
                });
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    subject.dispose();
    notes.dispose();
    weight.dispose();
    pieces.dispose();
    tag.dispose();
    vehicleNo.dispose();
    vehicleModel.dispose();
    technician.dispose();
    if (result == null) return false;
    setState(() => _serviceOrder = result);
    return true;
  }

  String _quantityText(double value) => value == value.truncateToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');

  Future<void> _payPendingInvoice(String method) async {
    final order = widget.pendingOrder;
    if (order == null || _payingPendingInvoice) return;
    final state = context.read<PosBloc>().state;
    if (!await _ensureRequiredCustomer(state)) {
      return;
    }
    if (!mounted) return;
    setState(() => _payingPendingInvoice = true);
    final result = await sl<PosRepository>().payPendingOrder(
      orderId: order.id,
      method: method,
      cashReceived: (method == 'tunai' ? _cashReceived : order.total)
          .roundToDouble(),
      splitPayments: method == 'split' ? _splitPayments : const [],
      customerId:
          _paymentCustomer?.id ??
          widget.pendingOrder?.customerId ??
          (widget.pendingOrder == null ? state.selectedCustomer?.id : null),
    );
    if (!mounted) return;
    setState(() => _payingPendingInvoice = false);
    result.fold(
      (failure) {
        if (failure.message.toLowerCase().contains('pelanggan')) {
          _showRequiredCustomerFlow(
            context.read<PosBloc>().state,
            message: failure.message,
            invalidateSelection:
                failure.message.toLowerCase().contains('tidak ditemukan') ||
                failure.message.toLowerCase().contains('tidak valid'),
          );
          return;
        }
        AppToast.error(context, failure.message);
      },
      (_) {
        context.read<PosBloc>().add(RefreshOrders());
        AppToast.success(context, 'Invoice ${order.invoice} berhasil dibayar');
        Navigator.pop(context);
      },
    );
  }

  bool _requiresCustomer(PosState state) {
    final orderType = widget.pendingOrder?.orderType.isNotEmpty == true
        ? widget.pendingOrder!.orderType
        : state.orderType;
    return widget.requestedCustomerPhone.isNotEmpty ||
        widget.pendingOrder?.customerProfileRequested == true ||
        (state.runtimeConfig['features'] as Map?)?['require_customer'] ==
            true ||
        const {
          'delivery',
          'online_delivery',
          'reservation',
        }.contains(orderType);
  }

  bool _orderHasNamedCustomer() {
    final name = widget.pendingOrder?.customer.trim() ?? '';
    return name.isNotEmpty && name.toLowerCase() != 'pelanggan umum';
  }

  bool _hasCustomer(PosState state) =>
      (_paymentCustomer?.id.trim().isNotEmpty ?? false) ||
      (widget.pendingOrder?.customerId?.trim().isNotEmpty ?? false) ||
      (widget.pendingOrder == null &&
          (state.selectedCustomer?.id.trim().isNotEmpty ?? false));

  String _customerLabel(PosState state) =>
      _paymentCustomer?.name ??
      (widget.pendingOrder == null ? state.selectedCustomer?.name : null) ??
      (_orderHasNamedCustomer() ? widget.pendingOrder!.customer : null) ??
      'Pilih pelanggan';

  String get _requestedCustomerPhone => widget.requestedCustomerPhone.isNotEmpty
      ? widget.requestedCustomerPhone
      : widget.pendingOrder?.customerPhone ?? '';

  String get _requestedCustomerName => widget.requestedCustomerName.isNotEmpty
      ? widget.requestedCustomerName
      : widget.pendingOrder?.customer ?? '';

  Future<bool> _selectPaymentCustomer(PosState state) async {
    final customers = state.customers;
    final selected = await showModalBottomSheet<PosCustomer>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        var query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final needle = query.trim().toLowerCase();
            final filtered = customers
                .where(
                  (customer) =>
                      needle.isEmpty ||
                      customer.name.toLowerCase().contains(needle) ||
                      customer.phone.toLowerCase().contains(needle),
                )
                .toList();
            return PosKeyboardStableSheet(
              heightFactor: .68,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: Row(
                      children: [
                        Icon(Icons.people_outline, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text(
                          'Pilih Pelanggan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      autofocus: true,
                      onChanged: (value) => setSheetState(() => query = value),
                      decoration: const InputDecoration(
                        labelText: 'Cari pelanggan',
                        hintText: 'Nama atau nomor telepon',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () async {
                          final created = await showPosQuickCustomerDialog(
                            context,
                            initialName: _requestedCustomerName,
                            initialPhone: _requestedCustomerPhone,
                            requirePhone:
                                widget.pendingOrder?.customerProfileRequested ==
                                    true ||
                                _requestedCustomerPhone.isNotEmpty,
                          );
                          if (created != null && sheetContext.mounted) {
                            Navigator.pop(sheetContext, created);
                          }
                        },
                        icon: const Icon(Icons.person_add_alt_1),
                        label: const Text('Tambah pelanggan baru'),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('Pelanggan tidak ditemukan'))
                        : ListView.separated(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.viewInsetsOf(context).bottom,
                            ),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final customer = filtered[index];
                              return ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person_outline),
                                ),
                                title: Text(customer.name),
                                subtitle: customer.phone.isEmpty
                                    ? null
                                    : Text(customer.phone),
                                onTap: () =>
                                    Navigator.pop(sheetContext, customer),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (selected == null || !mounted) return false;
    setState(() => _paymentCustomer = selected);
    context.read<PosBloc>().add(SelectCustomer(selected));
    return true;
  }

  Future<bool> _ensureRequiredCustomer(PosState state) async {
    if (!_requiresCustomer(state) || _hasCustomer(state)) return true;
    return _showRequiredCustomerFlow(
      state,
      message:
          widget.pendingOrder?.customerProfileRequested == true ||
              _requestedCustomerPhone.isNotEmpty
          ? 'Pemesan meminta menjadi pelanggan dengan nomor $_requestedCustomerPhone. Konfirmasi lalu pilih profil yang ada atau tambah pelanggan baru.'
          : 'Profil atau tipe pemenuhan ini mewajibkan pelanggan.',
    );
  }

  Future<bool> _showRequiredCustomerFlow(
    PosState state, {
    required String message,
    bool invalidateSelection = false,
  }) async {
    if (_customerPromptOpen || !mounted) return false;
    _customerPromptOpen = true;
    try {
      if (invalidateSelection) {
        setState(() => _paymentCustomer = null);
        context.read<PosBloc>().add(const SelectCustomer(null));
      }
      final proceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.person_search_outlined,
            color: AppColors.warning,
            size: 42,
          ),
          title: const Text('Pelanggan Wajib Dipilih'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.people_outline),
              label: const Text('Pilih Pelanggan'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return false;
      return _selectPaymentCustomer(context.read<PosBloc>().state);
    } finally {
      _customerPromptOpen = false;
    }
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

  Future<bool> _ensureReservationDetails(PosState state) async {
    if (state.orderType != 'reservation') return true;
    final guests = TextEditingController(
      text: _reservationGuestCount.toString(),
    );
    final deposit = TextEditingController(
      text: _reservationDepositAmount > 0
          ? _reservationDepositAmount.toStringAsFixed(0)
          : '',
    );
    var start =
        _reservationStartAt ??
        (_serviceOrder?['appointment_at'] != null
            ? DateTime.tryParse(_serviceOrder!['appointment_at'].toString())
            : null);
    var end = _reservationEndAt;
    String error = '';
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickDateTime(bool isStart) async {
            final current = (isStart ? start : end) ?? DateTime.now();
            final date = await showDatePicker(
              context: context,
              initialDate: current,
              firstDate: DateTime.now().subtract(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 730)),
            );
            if (date == null || !context.mounted) return;
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(current),
            );
            if (time == null) return;
            setDialogState(() {
              final selected = DateTime(
                date.year,
                date.month,
                date.day,
                time.hour,
                time.minute,
              );
              if (isStart) {
                start = selected;
                end ??= selected.add(const Duration(hours: 2));
              } else {
                end = selected;
              }
            });
          }

          String dateLabel(DateTime? value) => value == null
              ? 'Pilih tanggal & waktu'
              : DateFormat('dd MMM yyyy, HH:mm').format(value);
          return PosKeyboardStableFormDialog(
            width: 480,
            height: 520,
            title: const Text('Detail reservasi'),
            content: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mulai reservasi *'),
                      subtitle: Text(dateLabel(start)),
                      trailing: const Icon(Icons.event_outlined),
                      onTap: () => pickDateTime(true),
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Selesai reservasi *'),
                      subtitle: Text(dateLabel(end)),
                      trailing: const Icon(Icons.event_available_outlined),
                      onTap: () => pickDateTime(false),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: guests,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Jumlah tamu',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: deposit,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Deposit diminta',
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        error,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  final guestCount = int.tryParse(guests.text) ?? 0;
                  final depositAmount =
                      double.tryParse(deposit.text.replaceAll(',', '.')) ?? 0;
                  if (start == null ||
                      end == null ||
                      !end!.isAfter(start!) ||
                      guestCount < 1 ||
                      depositAmount < 0) {
                    setDialogState(
                      () => error =
                          'Lengkapi waktu yang valid dan jumlah tamu minimal 1.',
                    );
                    return;
                  }
                  _reservationStartAt = start;
                  _reservationEndAt = end;
                  _reservationGuestCount = guestCount;
                  _reservationDepositAmount = depositAmount;
                  if (_serviceOrder != null) {
                    _serviceOrder = {
                      ..._serviceOrder!,
                      'appointment_at': start!.toIso8601String(),
                    };
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
    guests.dispose();
    deposit.dispose();
    return result == true;
  }

  Future<void> _createInvoice(
    BuildContext context,
    PosState state, {
    bool continueToPayment = false,
  }) async {
    if (_invoiceFlowOpen || _creatingInvoice) return;
    _invoiceFlowOpen = true;
    try {
      if (!await _ensureServiceOrder(state)) return;
      if (!context.mounted) return;
      if (!await _ensureReservationDetails(state)) return;
      if (!context.mounted) return;
      if (!await _ensureRequiredCustomer(state)) return;
      if (!context.mounted) return;
      state = context.read<PosBloc>().state;
      if (state.orderType == 'dine_in' &&
          (state.selectedTableId == null || state.selectedTableId!.isEmpty)) {
        AppToast.warning(
          context,
          'Pilih meja terlebih dahulu dari halaman kasir.',
        );
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(
            continueToPayment
                ? 'Simpan reservasi & lanjut bayar?'
                : state.orderType == 'dine_in'
                ? 'Simpan pesanan ke meja?'
                : 'Jadikan Invoice?',
          ),
          content: Text(
            continueToPayment
                ? 'Jadwal reservasi diperiksa sebelum pembayaran. Jika pembayaran dibatalkan, reservasi tetap tersedia di Pesanan Aktif untuk dilanjutkan.'
                : state.orderType == 'dine_in'
                ? 'Pesanan akan dicatat pada meja ${state.selectedTableName}. Meja ditandai terisi dan tagihan dapat dilanjutkan dari Pesanan Aktif & Meja.'
                : 'Pesanan akan disimpan sebagai tagihan belum dibayar. Stok belum dipotong sampai invoice dibayar dari Daftar Order.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                state.orderType == 'dine_in'
                    ? 'Simpan ke Meja'
                    : 'Buat Invoice',
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() => _creatingInvoice = true);
      final activeShift = state.activeShift;
      final result = await sl<PosRepository>().createUnpaidInvoice(
        clientRequestId: _invoiceRequestId,
        cart: state.cart,
        tokoId: activeShift?['toko_id']?.toString() ?? '',
        shiftId: activeShift?['_id']?.toString() ?? '',
        orderType: state.orderType,
        tableId: state.selectedTableId,
        customerId: state.selectedCustomer?.id ?? widget.initialCustomer?.id,
        customerName:
            state.selectedCustomer?.name ?? widget.initialCustomer?.name,
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
        serviceOrder: _serviceOrder,
        reservationStartAt: _reservationStartAt,
        reservationEndAt: _reservationEndAt,
        reservationGuestCount: _reservationGuestCount,
        reservationDepositAmount: _reservationDepositAmount,
        expectedTotal: state.grandTotal,
      );
      if (!mounted) return;
      setState(() => _creatingInvoice = false);
      result.fold((failure) => AppToast.error(context, failure.message), (
        invoice,
      ) {
        context.read<PosBloc>().add(ClearCart());
        if (invoice['offline_queued'] == true) {
          AppToast.warning(
            context,
            'Invoice offline tersimpan. Belum bisa dibayar; cek Antrean & Sinkronisasi.',
          );
          Navigator.pop(context);
          return;
        }
        context.read<PosBloc>().add(RefreshOrders());
        if (continueToPayment) {
          final bloc = context.read<PosBloc>();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider.value(
                value: bloc,
                child: PosPaymentPage(
                  pendingOrder: PosOrder.fromPendingOrderJson({
                    ...invoice,
                    'tipe_pesanan': state.orderType,
                    'pelanggan_id':
                        state.selectedCustomer?.id ??
                        widget.initialCustomer?.id,
                    'pelanggan_nama':
                        state.selectedCustomer?.name ??
                        widget.initialCustomer?.name,
                  }),
                  initialCustomer:
                      state.selectedCustomer ?? widget.initialCustomer,
                ),
              ),
            ),
          );
          return;
        }
        AppToast.success(
          context,
          state.orderType == 'dine_in'
              ? 'Pesanan meja ${state.selectedTableName ?? ''} berhasil disimpan.'
              : 'Invoice ${invoice['order_no'] ?? ''} berhasil dibuat.',
        );
        Navigator.pop(context);
      });
    } finally {
      _invoiceFlowOpen = false;
      if (mounted && _creatingInvoice) setState(() => _creatingInvoice = false);
    }
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
          return PosKeyboardStableFormDialog(
            width: 560,
            height: 590,
            title: const Text('Pisah Bayar'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
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
                      color: isValid ? AppColors.success : AppColors.danger,
                    ),
                    if (!isValid)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Minimal 2 metode, setiap jumlah harus lebih dari 0, dan total harus tepat.',
                          style: TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                          ),
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
          color: isSelected ? const Color(0xFFE6F4F2) : Colors.transparent,
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
