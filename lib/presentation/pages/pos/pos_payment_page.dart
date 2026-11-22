import 'package:mobile_pos_pantoo/core/subscription/pos_subscription_service.dart';
import 'dart:async';
import '../../../core/utils/logger.dart';
import 'pos_subscription_page.dart';
import 'package:mobile_pos_pantoo/l10n/app_language_controller.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:mobile_pos_pantoo/core/customer_display/pos_customer_display_service.dart';
import 'package:flutter/material.dart';
import 'utils/pos_service_quantity.dart';
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
import '../../widgets/pos_time_picker.dart';
import '../../../../domain/models/pos_order.dart';
import '../../../../domain/models/pos_customer.dart';
import 'widgets/pos_quick_customer_dialog.dart';
import 'widgets/pos_payment_connection_badge.dart';

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
      if (sl.isRegistered<PosSubscriptionService>()) {
        unawaited(
          sl<PosSubscriptionService>().prepareCheckout().catchError((
            Object error,
            StackTrace stack,
          ) {
            appLogger.w(
              'Persiapan akses pembayaran belum tersedia',
              error: error,
              stackTrace: stack,
            );
          }),
        );
      }
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
    // Stable business keys; translate only when rendering their labels.
    'transfer' => 'Transfer',
    'qris' => 'QRIS',
    'debit' => 'Kartu Debit',
    'kartu_kredit' || 'credit_card' => 'Kartu Kredit',
    'e_wallet' => 'E-Wallet',
    'tempo' => 'Tempo / Piutang',
    _ => 'Tunai',
  };

  @override
  Widget build(BuildContext context) {
    if (!sl.isRegistered<PosSubscriptionService>()) {
      return _buildPayment(context);
    }
    final service = sl<PosSubscriptionService>();
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final restricted = service.required && !service.canSell;
        // Keep the payment listener mounted if expiry happens while an already
        // accepted response is in flight. Its receipt must still be shown.
        return Stack(
          children: [
            ExcludeFocus(excluding: restricted, child: _buildPayment(context)),
            if (restricted)
              Positioned.fill(child: PosSubscriptionPage(service: service)),
          ],
        );
      },
    );
  }

  Widget _buildPayment(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      resizeToAvoidBottomInset: false,
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
            if (MediaQuery.sizeOf(context).width >= 600) ...[
              const Icon(
                Icons.storefront_outlined,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PosText(
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
            child: Center(child: PosPaymentConnectionBadge()),
          ),
        ],
      ),
      body: BlocConsumer<PosBloc, PosState>(
        listener: (context, state) {
          if (state.status == PosStatus.paymentSuccess) {
            final transaction = state.lastTransaction;
            if (transaction == null) return;
            sl<PosCustomerDisplayService>().publishCart(
              items: const [],
              subtotal: transaction.subtotal,
              discount: transaction.discount,
              total: transaction.total,
              storeName: transaction.storeName.isNotEmpty
                  ? transaction.storeName
                  : _activeStoreName(context),
              status: 'payment_success',
            );
            final posBloc = context.read<PosBloc>();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(name: 'pos_payment_success'),
                builder: (_) => PosSuccessPage(
                  transaction: transaction,
                  autoPrint: state.runtimeConfig['auto_print_receipt'] == true,
                  onDone: () => posBloc.add(RefreshProducts()),
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
                title: PosText(_failureTitle(message)),
                content: PosText(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const PosText('Tutup'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(context);
                    },
                    child: const PosText('Kembali ke Keranjang'),
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
              final compact =
                  constraints.maxWidth < 760 || constraints.maxHeight < 480;
              if (compact) {
                return _buildMobilePayment(
                  state,
                  total,
                  subtotal,
                  discount,
                  tax,
                  belowCashMinimum,
                );
              }
              return Flex(
                key: const Key('payment_desktop_layout'),
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
                                    ('Total Tagihan').tr(context),
                                    total,
                                    Colors.black,
                                  ),
                                ),
                                Expanded(
                                  child: _buildAmountBlock(
                                    ('Sisa Tagihan').tr(context),
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
                                  ('Pisah Bayar').tr(context),
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
                                      : 'Buat Pesanan / Ambil Nanti',
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
                                              Expanded(
                                                child: PosText(
                                                  'Metode Pembayaran',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: 4),
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
                                        _buildPaymentMethodTile(
                                          'Tempo / Piutang',
                                        ),
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
                                                ('Uang Pas').tr(context),
                                                total,
                                              ),
                                              _buildCashOption(
                                                ('Rp 20.000').tr(context),
                                                20000,
                                              ),
                                              _buildCashOption(
                                                ('Rp 50.000').tr(context),
                                                50000,
                                              ),
                                              _buildCashOption(
                                                ('Lainnya').tr(context),
                                                0,
                                              ),
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
                                                    posLocale(
                                                      context,
                                                    ).pos18a9e21cb58b(
                                                      (_paymentMethod)
                                                          .toString(),
                                                    ),
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  const PosText(
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
                                                    child: PosText(
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
                                      ('Transaksi Baru').tr(context),
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
                                    ? state.unitPriceFor(product!) * qty
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
                                _buildSummaryRow(
                                  ('Subtotal').tr(context),
                                  subtotal,
                                ),
                                if (discount > 0)
                                  _buildSummaryRow(
                                    ('Diskon').tr(context),
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
                                            ? ('Total Invoice').tr(context)
                                            : posLocale(
                                                context,
                                              ).posbd45ba0ddb67(
                                                (state.totalItems ==
                                                            state.totalItems
                                                                .truncateToDouble()
                                                        ? state.totalItems
                                                              .toStringAsFixed(
                                                                0,
                                                              )
                                                        : state.totalItems
                                                              .toStringAsFixed(
                                                                3,
                                                              )
                                                              .replaceFirst(
                                                                RegExp(r'0+$'),
                                                                '',
                                                              ))
                                                    .toString(),
                                              ),
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
                                posLocale(context).pos9e159b1c2295(
                                  (_money(
                                    state.minimumCashTransaction,
                                  )).toString(),
                                ),
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          _buildPaymentSubmitButton(
                            state,
                            total,
                            belowCashMinimum,
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
            Expanded(child: PosText('Otorisasi Barang Kedaluwarsa')),
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
                decoration: InputDecoration(
                  labelText: ('Username supervisor').tr(dialogContext),
                ),
              ),
              TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: ('PIN supervisor').tr(dialogContext),
                ),
              ),
              TextField(
                controller: reasonController,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                decoration: InputDecoration(
                  labelText: ('Alasan penjualan').tr(dialogContext),
                  hintText: ('Minimal 5 karakter').tr(dialogContext),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const PosText('Batal'),
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
            child: const PosText('Otorisasi & Lanjutkan'),
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
      'Tempo / Piutang' => 'tempo',
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
    String mode = profile == 'laundry' ? 'kiloan' : 'satuan';
    String validationMessage = '';
    ModalRoute<Map<String, dynamic>>? serviceDialogRoute;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        serviceDialogRoute = ModalRoute.of<Map<String, dynamic>>(dialogContext);
        return StatefulBuilder(
          builder: (context, setDialogState) => PosKeyboardStableFormDialog(
            width: 520,
            height: 620,
            title: Text(
              profile == 'laundry'
                  ? ('Detail cucian').tr(context)
                  : ('Detail layanan').tr(context),
            ),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (profile == 'laundry') ...[
                      DropdownButtonFormField<String>(
                        initialValue: mode,
                        decoration: InputDecoration(
                          labelText: ('Model layanan').tr(context),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'kiloan',
                            child: PosText('Kiloan'),
                          ),
                          DropdownMenuItem(
                            value: 'satuan',
                            child: PosText('Satuan'),
                          ),
                          DropdownMenuItem(
                            value: 'paket',
                            child: PosText('Paket'),
                          ),
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
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: InputDecoration(
                                labelText: ('Berat (kg)').tr(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: pieces,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: ('Jumlah item').tr(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tag,
                        decoration: InputDecoration(
                          labelText: ('Tag kantong').tr(context),
                        ),
                      ),
                      if (serviceEntries.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        PosText(
                          'Jumlah tagihan mengikuti jumlah layanan di keranjang. '
                          'Ketuk angka jumlah pada keranjang untuk mengubah berat/jumlah.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ] else ...[
                      TextField(
                        controller: subject,
                        decoration: InputDecoration(
                          labelText: features?['use_vehicle_data'] == true
                              ? ('Objek/jenis kendaraan').tr(context)
                              : ('Objek layanan').tr(context),
                        ),
                      ),
                      if (features?['use_vehicle_data'] == true) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: vehicleNo,
                                textCapitalization:
                                    TextCapitalization.characters,
                                decoration: InputDecoration(
                                  labelText: ('No. polisi / ID unit').tr(
                                    context,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: vehicleModel,
                                decoration: InputDecoration(
                                  labelText: ('Model / tipe').tr(context),
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
                          decoration: InputDecoration(
                            labelText: ('Teknisi / staf penanggung jawab').tr(
                              context,
                            ),
                          ),
                        ),
                      ],
                      // Reservation owns its schedule in one dedicated form.
                      // Direct jasa has no booking date; other service profiles
                      // may still record an optional appointment.
                      if (features?['use_appointments'] == true &&
                          state.orderType != 'reservation' &&
                          profile != 'jasa') ...[
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
                                ? ('Jadwal layanan (opsional)').tr(context)
                                : DateFormat(
                                    'dd MMM yyyy · HH:mm',
                                    AppLanguageController
                                        .instance
                                        .effectiveLocale
                                        .languageCode,
                                  ).format(appointmentAt!),
                          ),
                          trailing: appointmentAt == null
                              ? const Icon(Icons.chevron_right)
                              : IconButton(
                                  tooltip: ('Hapus jadwal').tr(context),
                                  onPressed: () => setDialogState(
                                    () => appointmentAt = null,
                                  ),
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
                            final time = await showPosTimePicker(
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
                            ? ('Kondisi/catatan').tr(context)
                            : ('Keluhan / catatan layanan').tr(context),
                      ),
                    ),
                    if (profile != 'laundry') ...[
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: PosText(
                          'Isi objek layanan atau keluhan, minimal salah satu.',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                    ],
                    if (validationMessage.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: PosText(
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
                child: const PosText('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  final kg =
                      double.tryParse(weight.text.replaceAll(',', '.')) ?? 0;
                  final count = int.tryParse(pieces.text) ?? 0;
                  final billedQuantity = mode == 'kiloan'
                      ? kg
                      : count.toDouble();
                  final quantityMismatch =
                      profile == 'laundry' &&
                      serviceEntries.isNotEmpty &&
                      (billedQuantity - serviceQuantity).abs() > 0.000001;
                  if ((profile == 'laundry' && kg <= 0 && count <= 0) ||
                      quantityMismatch ||
                      (profile != 'laundry' &&
                          subject.text.trim().isEmpty &&
                          notes.text.trim().isEmpty)) {
                    setDialogState(() {
                      validationMessage = quantityMismatch
                          ? 'Berat/jumlah harus sama dengan jumlah layanan di keranjang '
                                '(${_quantityText(serviceQuantity)}).'
                          : 'Lengkapi detail layanan sebelum melanjutkan.';
                    });
                    return;
                  }
                  final pricingBasis = posServicePricingBasis(profile, mode);
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
                    'service_type': profile == 'laundry'
                        ? 'Laundry'
                        : 'Service',
                    'service_subject': profile == 'laundry'
                        ? 'Cucian pelanggan'
                        : subject.text.trim(),
                    'complaint': notes.text.trim(),
                    'condition_notes': profile == 'laundry'
                        ? notes.text.trim()
                        : '',
                    'service_mode': profile == 'laundry' ? mode : '',
                    'weight_kg': profile == 'laundry' && mode != 'kiloan'
                        ? 0
                        : kg,
                    'item_count': count,
                    'bag_tag': tag.text.trim(),
                    'vehicle_no': vehicleNo.text.trim().toUpperCase(),
                    'vehicle_model': vehicleModel.text.trim(),
                    'technician_name': technician.text.trim(),
                    if (appointmentAt != null)
                      'appointment_at': appointmentAt!
                          .toUtc()
                          .toIso8601String(),
                    'status': 'diterima',
                    if (serviceLines.isNotEmpty) 'service_lines': serviceLines,
                  });
                },
                child: const PosText('Simpan'),
              ),
            ],
          ),
        );
      },
    );
    // showDialog completes when pop is requested, before its reverse animation
    // removes the TextFields. Their controllers must remain alive until then.
    await serviceDialogRoute?.completed;
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
        sl<PosCustomerDisplayService>().publishCart(
          items: const [],
          subtotal: order.subtotal,
          discount: order.discountAmount,
          total: order.total,
          storeName: _activeStoreName(context),
          status: 'payment_success',
        );
        context.read<PosBloc>().add(RefreshOrders());
        context.read<PosBloc>().add(
          const RefreshPosRuntimeConfig(preserveCheckout: true),
        );
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
    final posBloc = context.read<PosBloc>();
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
                        PosText(
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
                      decoration: InputDecoration(
                        labelText: ('Cari pelanggan').tr(context),
                        hintText: ('Nama atau nomor telepon').tr(context),
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
                            runtimeConfig: posBloc.state.runtimeConfig,
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
                        label: const PosText('Tambah pelanggan baru'),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: PosText('Pelanggan tidak ditemukan'),
                          )
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
          title: const PosText('Pelanggan Wajib Dipilih'),
          content: PosText(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const PosText('Batal'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.people_outline),
              label: const PosText('Pilih Pelanggan'),
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
    return state.checkoutStore?.name ?? 'Pantoo POS';
  }

  String _failureTitle(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('kadaluarsa') ||
        normalized.contains('kedaluwarsa')) {
      return ('Produk Kedaluwarsa').trCurrent();
    }
    if (normalized.contains('stok')) return ('Stok Tidak Cukup').trCurrent();
    if (normalized.contains('uang diterima')) {
      return ('Pembayaran Tidak Cukup').trCurrent();
    }
    if (normalized.contains('shift')) {
      return ('Shift Kasir Bermasalah').trCurrent();
    }
    return ('Transaksi Ditolak').trCurrent();
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

  Widget _mobilePaymentPanel(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE4E7EC)),
    ),
    child: child,
  );

  Widget _buildMobilePayment(
    PosState state,
    double total,
    double subtotal,
    double discount,
    double tax,
    bool belowCashMinimum,
  ) {
    final busy =
        state.status == PosStatus.loading ||
        _payingPendingInvoice ||
        _creatingInvoice;
    final cash = _paymentMethod == 'Tunai';
    final english = Localizations.localeOf(context).languageCode == 'en';
    final itemCount = widget.pendingOrder?.items.length ?? state.cart.length;
    final suggestions = <double>{
      total,
      (total / 50000).ceil() * 50000.0,
      (total / 100000).ceil() * 100000.0,
    }.where((n) => n > 0).toList();
    return Column(
      key: const Key('payment_mobile_layout'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            key: const Key('payment_mobile_scroll'),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: IgnorePointer(
              ignoring: busy,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _mobilePaymentPanel(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PosText(
                          'Total Tagihan',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _money(total),
                            key: const Key('payment_mobile_total'),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.heading,
                            ),
                          ),
                        ),
                        if (cash && _cashReceived > 0) ...[
                          const Divider(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _mobileBalance(
                                  'Sisa Tagihan',
                                  (total - _cashReceived)
                                      .clamp(0, double.infinity)
                                      .toDouble(),
                                  color: _cashReceived < total
                                      ? AppColors.danger
                                      : AppColors.heading,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _mobileBalance(
                                  'Kembalian',
                                  (_cashReceived - total)
                                      .clamp(0, double.infinity)
                                      .toDouble(),
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    child: ListTile(
                      key: const Key('payment_mobile_customer'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: const Icon(
                        Icons.person_outline,
                        color: AppColors.textSecondary,
                      ),
                      title: Text(
                        _customerLabel(state).tr(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: widget.pendingOrder == null
                          ? null
                          : Text(
                              widget.pendingOrder!.invoice,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing: const Icon(Icons.edit_outlined, size: 20),
                      onTap: () => _selectPaymentCustomer(state),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const PosText(
                    'Metode Pembayaran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final method in [
                        'Tunai',
                        'QRIS',
                        'Transfer',
                        'Kartu Debit',
                        'E-Wallet',
                        'Kartu Kredit',
                        'Tempo / Piutang',
                      ])
                        ChoiceChip(
                          key: ValueKey('payment_mobile_method:$method'),
                          label: Text(
                            method.tr(context),
                            style: TextStyle(
                              fontSize: 14,
                              color: _paymentMethod == method
                                  ? AppColors.primary
                                  : AppColors.heading,
                              fontWeight: _paymentMethod == method
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          selected: _paymentMethod == method,
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary.withValues(
                            alpha: 0.08,
                          ),
                          checkmarkColor: AppColors.primary,
                          side: BorderSide(
                            color: _paymentMethod == method
                                ? AppColors.primary
                                : const Color(0xFFD0D5DD),
                          ),
                          showCheckmark: true,
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          onSelected: (_) {
                            if (_paymentMethod == method) return;
                            setState(() {
                              _paymentMethod = method;
                              _cashReceived = 0;
                              _splitPayments = [];
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (cash) ...[
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        key: const Key('payment_mobile_cash_input'),
                        borderRadius: BorderRadius.circular(12),
                        onTap: _enterCustomCash,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const PosText(
                                      'Uang diterima',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        _money(_cashReceived),
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.edit_outlined,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) => Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final amount in suggestions)
                            SizedBox(
                              width: (constraints.maxWidth - 12) / 2,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 56,
                                ),
                                child: _buildCashOption(
                                  amount == total ? 'Uang Pas' : _money(amount),
                                  amount,
                                ),
                              ),
                            ),
                          SizedBox(
                            width: (constraints.maxWidth - 12) / 2,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 56),
                              child: _buildCashOption('Lainnya', 0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_paymentMethod == 'Pisah Bayar')
                    _mobilePaymentPanel(_buildSplitSummary(total))
                  else
                    _mobilePaymentPanel(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _paymentMethod.tr(context),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const PosText(
                            'Pastikan pembayaran sudah diterima pada perangkat atau rekening merchant sebelum memproses transaksi. POS mencatat metode pembayaran dan tidak menjalankan payment gateway otomatis.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    key: const Key('payment_mobile_split'),
                    onPressed: () => _configureSplitPayment(total),
                    icon: const Icon(Icons.call_split),
                    label: const PosText('Pisah Bayar'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD0D5DD)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      key: const Key('payment_mobile_summary'),
                      title: Text(
                        english ? 'Order summary' : 'Ringkasan pesanan',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('$itemCount item'),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        for (var index = 0; index < itemCount; index++)
                          _mobilePaymentItem(state, index),
                        const Divider(height: 24),
                        _buildSummaryRow('Subtotal', subtotal),
                        if (discount > 0)
                          _buildSummaryRow(
                            'Diskon',
                            -discount,
                            color: AppColors.primary,
                          ),
                        if (tax > 0) _buildSummaryRow('Pajak', tax),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: _editNote,
                        icon: const Icon(Icons.edit_note),
                        label: PosText(
                          _invoiceNote.isEmpty ? 'Catatan' : 'Catatan ✓',
                        ),
                      ),
                      TextButton.icon(
                        onPressed:
                            _creatingInvoice || widget.pendingOrder != null
                            ? null
                            : () => _createInvoice(context, state),
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: PosText(
                          state.orderType == 'dine_in'
                              ? 'Simpan ke Meja'
                              : 'Buat Pesanan / Ambil Nanti',
                        ),
                      ),
                    ],
                  ),
                  if (_invoiceNote.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        _invoiceNote,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE4E7EC))),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (belowCashMinimum)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        posLocale(context).pos9e159b1c2295(
                          (_money(state.minimumCashTransaction)).toString(),
                        ),
                        style: const TextStyle(color: AppColors.warning),
                      ),
                    ),
                  Row(
                    children: [
                      const Expanded(
                        child: PosText(
                          'Total Tagihan',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            _money(total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildPaymentSubmitButton(
                      state,
                      total,
                      belowCashMinimum,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobileBalance(String label, double value, {required Color color}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PosText(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _money(value),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      );

  Widget _mobilePaymentItem(PosState state, int index) {
    final pending = widget.pendingOrder?.items[index];
    final product = pending == null ? state.cart.keys.elementAt(index) : null;
    final qty = pending?['qty'] as num? ?? state.cart[product]!;
    final name = pending?['nama']?.toString() ?? product!.name;
    final amount = pending == null
        ? state.unitPriceFor(product!) * qty
        : (pending['subtotal'] as num?)?.toDouble() ??
              ((pending['harga_satuan'] as num?)?.toDouble() ?? 0) * qty;
    final unitPrice = pending == null
        ? state.unitPriceFor(product!)
        : (pending['harga_satuan'] as num?)?.toDouble() ??
              (qty > 0 ? amount / qty : 0.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${_quantityText(qty.toDouble())} × ${_money(unitPrice)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(_money(amount), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildAmountBlock(String label, double amount, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PosText(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PosText(
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
          Expanded(
            child: PosText(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              _money(amount),
              style: TextStyle(
                color: color ?? Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
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
      label: PosText(
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
      builder: (dialogContext) => _PaymentFormLifetime(
        onDispose: controller.dispose,
        child: AlertDialog(
          scrollable: true,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          title: const PosText('Catatan transaksi'),
          content: TextField(
            key: const Key('payment_note_value'),
            controller: controller,
            autofocus: true,
            maxLength: 500,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: ('Contoh: pesanan tanpa sambal, referensi pembayaran…')
                  .tr(dialogContext),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const PosText('Batal'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, controller.text.trim()),
              child: const PosText('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (result != null && mounted) setState(() => _invoiceNote = result);
  }

  Future<bool> _ensureReservationDetails(PosState state) async {
    if (state.orderType != 'reservation') return true;
    if (_reservationStartAt != null && _reservationEndAt != null) return true;
    final guests = TextEditingController(
      text: _reservationGuestCount.toString(),
    );
    final deposit = TextEditingController(
      text: _reservationDepositAmount > 0
          ? formatRupiahAmount(_reservationDepositAmount)
          : '',
    );
    var start =
        _reservationStartAt ??
        (_serviceOrder?['appointment_at'] != null
            ? DateTime.tryParse(_serviceOrder!['appointment_at'].toString())
            : null);
    var end = _reservationEndAt ?? start?.add(const Duration(hours: 2));
    String error = '';
    ModalRoute<bool>? reservationDialogRoute;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        reservationDialogRoute = ModalRoute.of<bool>(dialogContext);
        return StatefulBuilder(
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
              final time = await showPosTimePicker(
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
                : DateFormat('dd MMM yyyy, HH:mm').format(value.toLocal());
            return PosKeyboardStableFormDialog(
              width: 480,
              height: 520,
              title: const PosText('Detail reservasi'),
              content: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                        title: const PosText('Mulai reservasi *'),
                        subtitle: PosText(dateLabel(start)),
                        trailing: const Icon(Icons.event_outlined),
                        onTap: () => pickDateTime(true),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const PosText('Selesai reservasi (opsional)'),
                        subtitle: PosText(dateLabel(end)),
                        trailing: const Icon(Icons.event_available_outlined),
                        onTap: () => pickDateTime(false),
                      ),
                      const PosText(
                        'Jika tidak diubah, durasi awal reservasi 2 jam.',
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
                              decoration: InputDecoration(
                                labelText: ('Jumlah tamu').tr(context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: deposit,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: const [
                                RupiahInputFormatter(decimalDigits: 2),
                              ],
                              decoration: InputDecoration(
                                labelText: ('Deposit diminta').tr(context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (error.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        PosText(
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
                  child: const PosText('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    final guestCount = int.tryParse(guests.text) ?? 0;
                    final depositAmount = parseRupiahAmount(deposit.text);
                    if (start == null ||
                        end == null ||
                        !end!.isAfter(start!) ||
                        guestCount < 1 ||
                        !depositAmount.isFinite ||
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
                        'appointment_at': start!.toUtc().toIso8601String(),
                      };
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const PosText('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
    await reservationDialogRoute?.completed;
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
      // SelectCustomer is dispatched asynchronously. The picker result is
      // authoritative even before that event has updated the captured state.
      final checkoutCustomer =
          _paymentCustomer ?? state.selectedCustomer ?? widget.initialCustomer;
      final checkoutStore = state.checkoutStore;
      if (checkoutStore == null) {
        AppToast.warning(
          context,
          'Toko aktif belum terhubung ke lokasi stok. Periksa toko dan shift kasir.',
        );
        return;
      }
      if (state.activeShift == null &&
          state.runtimeConfig['allow_out_of_shift'] != true) {
        AppToast.warning(context, 'Buka shift kasir sebelum membuat pesanan.');
        return;
      }
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
                ? ('Simpan reservasi & lanjut bayar?').tr(dialogContext)
                : state.orderType == 'dine_in'
                ? ('Simpan pesanan ke meja?').tr(dialogContext)
                : ('Buat pesanan / ambil nanti?').tr(dialogContext),
          ),
          content: Text(
            continueToPayment
                ? ('Jadwal reservasi diperiksa sebelum pembayaran. Jika pembayaran dibatalkan, reservasi tetap tersedia di Pesanan Aktif untuk dilanjutkan.')
                      .tr(dialogContext)
                : state.orderType == 'dine_in'
                ? posLocale(
                    dialogContext,
                  ).pos3b458bf929ac((state.selectedTableName).toString())
                : ('Pesanan operasional disimpan untuk disiapkan dan dibayar kemudian. Bukan invoice piutang Finance. Buka dari Pesanan atau Riwayat Transaksi; untuk keranjang sementara gunakan Simpan pesanan.')
                      .tr(dialogContext),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const PosText('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                state.orderType == 'dine_in'
                    ? ('Simpan ke Meja').tr(dialogContext)
                    : ('Buat Pesanan').tr(dialogContext),
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
        selectedUnits: state.selectedUnits,
        tokoId: checkoutStore.id,
        shiftId: activeShift?['_id']?.toString() ?? '',
        orderType: state.orderType,
        tableId: state.selectedTableId,
        customerId: checkoutCustomer?.id,
        customerName: checkoutCustomer?.name,
        note: _invoiceNote,
        discountPercent: state.subTotal > 0
            ? (state.totalDiscount / state.subTotal * 100)
                  .clamp(0, 100)
                  .toDouble()
            : 0,
        promoCode: state.promoCode,
        discountPolicy: state.discountPolicy,
        manualDiscount: state.manualDiscount,
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
                    'pelanggan_id': checkoutCustomer?.id,
                    'pelanggan_nama': checkoutCustomer?.name,
                  }),
                  initialCustomer: checkoutCustomer,
                ),
              ),
            ),
          );
          return;
        }
        context.read<PosBloc>().add(
          const RefreshPosRuntimeConfig(preserveCheckout: true),
        );
        AppToast.success(
          context,
          state.orderType == 'dine_in'
              ? 'Pesanan meja ${state.selectedTableName ?? ''} berhasil disimpan.'
              : 'Pesanan ${invoice['order_no'] ?? ''} tersedia di Pesanan dan Riwayat Transaksi.',
        );
        Navigator.pop(context);
      });
    } finally {
      _invoiceFlowOpen = false;
      if (mounted && _creatingInvoice) setState(() => _creatingInvoice = false);
    }
  }

  Widget _buildPaymentSubmitButton(
    PosState state,
    double total,
    bool belowCashMinimum,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: const Key('payment_submit'),
        onPressed:
            (state.status == PosStatus.loading ||
                _payingPendingInvoice ||
                _creatingInvoice ||
                belowCashMinimum)
            ? null
            : ((_paymentMethod == 'Pisah Bayar' &&
                      (_splitPayments.fold<double>(
                                    0,
                                    (sum, item) =>
                                        sum +
                                        (item['jumlah'] as num).toDouble(),
                                  ) -
                                  total)
                              .abs() <
                          0.01) ||
                  (_paymentMethod != 'Tunai' &&
                      _paymentMethod != 'Pisah Bayar') ||
                  _cashReceived + 0.5 >= total)
            ? () async {
                final normalizedMethod = switch (_paymentMethod) {
                  'Tunai' => 'tunai',
                  'Transfer' => 'transfer',
                  'QRIS' => 'qris',
                  'Kartu Debit' => 'debit',
                  'E-Wallet' => 'e_wallet',
                  'Kartu Kredit' => 'kartu_kredit',
                  'Tempo / Piutang' => 'tempo',
                  'Pisah Bayar' => 'split',
                  _ => '',
                };
                if (normalizedMethod.isEmpty) return;
                if (normalizedMethod == 'tempo' &&
                    (_paymentCustomer ?? state.selectedCustomer) == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: PosText(
                        'Pilih pelanggan terlebih dahulu untuk penjualan tempo.',
                      ),
                    ),
                  );
                  return;
                }
                if (widget.pendingOrder == null &&
                    state.orderType == 'reservation') {
                  await _createInvoice(context, state, continueToPayment: true);
                  return;
                }
                if (!await _ensureServiceOrder(state)) {
                  return;
                }
                if (!mounted) return;
                if (!await _ensureRequiredCustomer(state)) {
                  return;
                }
                if (!mounted) return;
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
                          _paymentCustomer ?? widget.initialCustomer,
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
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child:
            state.status == PosStatus.loading ||
                _payingPendingInvoice ||
                _creatingInvoice
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.pendingOrder != null
                          ? ('Bayar Invoice').tr(context)
                          : ('Proses Bayar').tr(context),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color:
                            (_paymentMethod != 'Tunai' ||
                                _cashReceived + 0.5 >= total)
                            ? Colors.white
                            : Colors.grey,
                      ),
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
    );
  }

  Future<void> _enterCustomCash() async {
    var cashInput = '';
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        title: const PosText('Uang diterima'),
        content: TextField(
          key: const Key('payment_custom_cash_value'),
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: const [RupiahInputFormatter()],
          onChanged: (value) => cashInput = value,
          decoration: const InputDecoration(
            prefixText: 'Rp ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const PosText('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, parseRupiah(cashInput)),
            child: const PosText('Gunakan'),
          ),
        ],
      ),
    );
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
    final removedDrafts = <_SplitPaymentDraft>[];
    final result = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (dialogContext) => _PaymentFormLifetime(
        onDispose: () {
          for (final draft in [...drafts, ...removedDrafts]) {
            draft.dispose();
          }
        },
        child: StatefulBuilder(
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
              title: const PosText('Pisah Bayar'),
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
                          key: ObjectKey(drafts[index]),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildSplitDraftFields(
                            drafts[index],
                            onChanged: () => setDialogState(() {}),
                            onRemove: drafts.length <= 2
                                ? null
                                : () => setDialogState(() {
                                    removedDrafts.add(drafts.removeAt(index));
                                  }),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setDialogState(
                            () => drafts.add(_SplitPaymentDraft()),
                          ),
                          icon: const Icon(Icons.add),
                          label: const PosText('Tambah metode pembayaran'),
                        ),
                      ),
                      const Divider(),
                      _buildSplitTotalRow(('Total tagihan').tr(context), total),
                      _buildSplitTotalRow(
                        ('Sudah dialokasikan').tr(context),
                        paid(),
                      ),
                      _buildSplitTotalRow(
                        difference >= 0 ? 'Sisa' : 'Kelebihan',
                        difference.abs(),
                        color: isValid ? AppColors.success : AppColors.danger,
                      ),
                      if (!isValid)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: PosText(
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
                  child: const PosText('Batal'),
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
                  child: const PosText('Gunakan'),
                ),
              ],
            );
          },
        ),
      ),
    );
    if (result == null || !mounted) return;
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

  Widget _buildSplitDraftFields(
    _SplitPaymentDraft draft, {
    required VoidCallback onChanged,
    required VoidCallback? onRemove,
  }) {
    final method = DropdownButtonFormField<String>(
      initialValue: draft.method,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: ('Metode').tr(context),
        border: const OutlineInputBorder(),
      ),
      items: _splitPaymentMethods.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: PosText(
                entry.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        draft.method = value;
        onChanged();
      },
    );
    final amount = TextField(
      controller: draft.controller,
      keyboardType: TextInputType.number,
      inputFormatters: const [RupiahInputFormatter()],
      decoration: InputDecoration(
        labelText: ('Jumlah').tr(context),
        prefixText: 'Rp ',
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) => onChanged(),
    );
    final remove = IconButton(
      tooltip: ('Hapus metode').tr(context),
      onPressed: onRemove,
      icon: const Icon(Icons.remove_circle_outline),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            children: [
              method,
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: amount),
                  const SizedBox(width: 4),
                  remove,
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 4, child: method),
            const SizedBox(width: 12),
            Expanded(flex: 5, child: amount),
            remove,
          ],
        );
      },
    );
  }

  Widget _buildSplitTotalRow(String label, double amount, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: PosText(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              posLocale(
                context,
              ).pos70272f418def((formatRupiahAmount(amount)).toString()),
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.right,
            ),
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
                posLocale(context).pos70272f418def(
                  (formatRupiahAmount((item['jumlah'] as num))).toString(),
                ),
              ),
            ),
          ),
        Text(
          posLocale(
            context,
          ).pos1b58713d0d0e((formatRupiahAmount(total)).toString()),
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
        _splitPayments = [];
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
          method.tr(context),
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
        child: PosText(
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
  'tempo': 'Tempo / Piutang',
};

/// A dialog future resolves before its exit animation finishes. Controllers
/// remain owned by the route's subtree until its fields have actually unmounted.
class _PaymentFormLifetime extends StatefulWidget {
  const _PaymentFormLifetime({required this.child, required this.onDispose});
  final Widget child;
  final VoidCallback onDispose;
  @override
  State<_PaymentFormLifetime> createState() => _PaymentFormLifetimeState();
}

class _PaymentFormLifetimeState extends State<_PaymentFormLifetime> {
  @override
  Widget build(BuildContext context) => widget.child;
  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }
}

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
