import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/core/customer_display/pos_customer_display_service.dart';

import '../../bloc/pos/pos_bloc.dart';
import '../../bloc/pos/pos_event.dart';
import '../../bloc/pos/pos_state.dart';
import '../../widgets/skeleton_loading.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_keyboard_stable_sheet.dart';
import '../../widgets/pos_full_width_tabs.dart';
import '../../../../domain/repositories/pos_repository.dart';
import '../../../../domain/repositories/pos_order_repository.dart';
import '../../../../domain/repositories/pos_receipt_repository.dart';
import '../../../../injections.dart';
import 'widgets/pos_product_panel.dart';
import 'widgets/pos_cart_panel.dart';
import 'pos_payment_page.dart';
import 'pos_success_page.dart';
import 'widgets/pos_checkout_recovery_panel.dart';
import 'widgets/pos_category_sidebar.dart';
import 'widgets/shift_management_panel.dart';
import 'widgets/pos_shift_sync_error.dart';
import 'widgets/pos_info_panel.dart';
import 'widgets/pos_cashier_tour.dart';
import 'widgets/pos_held_order_name_dialog.dart';
import 'widgets/pos_held_order_flow.dart';
import '../../../domain/models/hold_order.dart';

class PosPage extends StatelessWidget {
  final PosCashierTourTargets? tourTargets;
  final VoidCallback? onOpenTableOrders;
  final VoidCallback? onManageProducts;
  const PosPage({
    super.key,
    this.tourTargets,
    this.onOpenTableOrders,
    this.onManageProducts,
  });

  @override
  Widget build(BuildContext context) {
    return PosPageView(
      tourTargets: tourTargets,
      onOpenTableOrders: onOpenTableOrders,
      onManageProducts: onManageProducts,
    );
  }
}

class PosPageView extends StatefulWidget {
  final PosCashierTourTargets? tourTargets;
  final VoidCallback? onOpenTableOrders;
  final VoidCallback? onManageProducts;
  const PosPageView({
    super.key,
    this.tourTargets,
    this.onOpenTableOrders,
    this.onManageProducts,
  });

  @override
  State<PosPageView> createState() => _PosPageViewState();
}

class _PosPageViewState extends State<PosPageView> {
  bool _recoveringCheckout = false;
  String _recoveryError = '';
  bool _savingTableOrder = false;
  bool _heldOrderFlowOpen = false;
  bool _cartHasFocus = false;
  TabController? _cashierTabs;
  final FocusNode _cartFocusNode = FocusNode();
  final FocusNode _productSearchFocusNode = FocusNode();
  String _selectedCategory = 'Semua Kategori';
  final List<String> _categories = [
    'Semua Kategori',
    'Favorit',
    'Produk Paket',
    'Produk Layanan',
    'Promo',
    'Deposit',
    'Makanan',
  ];

  @override
  void initState() {
    super.initState();
    sl<PosCustomerDisplayService>().state.addListener(
      _onCustomerDisplayConnectionChanged,
    );
    // Warm the receipt template while the cashier is idle. Printing from the
    // success page can then use the cached data without a visible network
    // delay. Errors remain non-blocking; the print flow still has its normal
    // fallback handling.
    unawaited(sl<PosReceiptRepository>().preloadReceiptPrintData());
  }

  @override
  void dispose() {
    _cartFocusNode.dispose();
    _productSearchFocusNode.dispose();
    sl<PosCustomerDisplayService>().state.removeListener(
      _onCustomerDisplayConnectionChanged,
    );
    super.dispose();
  }

  Future<void> _recoverCheckout(Map<String, dynamic> record) async {
    if (_recoveringCheckout) return;
    final bloc = context.read<PosBloc>();
    final originalState = bloc.state;
    final originalCart = originalState.cart;
    final input = record['input'] as Map;
    final snapshot = record['receipt'] as Map;
    final savedItems = (snapshot['receipt_items'] as List).cast<Map>();
    final matches =
        originalCart.length == savedItems.length &&
        originalCart.entries.every(
          (entry) => savedItems.any(
            (item) =>
                item['inventaris_id'] == entry.key.id &&
                item['qty'] == entry.value &&
                item['unit'] == bloc.state.unitFor(entry.key) &&
                item['harga_jual'] == bloc.state.unitPriceFor(entry.key),
          ),
        ) &&
        snapshot['total'] == originalState.grandTotal &&
        snapshot['manual_discount'] == originalState.manualDiscount &&
        snapshot['tax'] == originalState.taxAmount &&
        input['toko_id'] == originalState.checkoutStore?.id &&
        (input['pelanggan_id'] ?? '') ==
            (originalState.selectedCustomer?.id ?? '') &&
        input['tipe_pesanan'] == originalState.orderType &&
        (input['meja_id'] ?? '') == (originalState.selectedTableId ?? '') &&
        input['channel_penjualan'] == originalState.salesChannel &&
        input['price_level'] == originalState.priceLevel &&
        input['customer_segment'] == originalState.customerSegment;
    setState(() {
      _recoveringCheckout = true;
      _recoveryError = '';
    });
    final result = await bloc.posRepository.recoverPendingCheckout();
    if (!mounted) return;
    setState(() => _recoveringCheckout = false);
    result.fold((failure) => setState(() => _recoveryError = failure.message), (
      transaction,
    ) {
      // Recovery is not permission to discard a different draft/cart.
      if (matches && bloc.state == originalState) {
        bloc.add(ClearCart());
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PosSuccessPage(
            transaction: transaction,
            autoPrint: false,
            onDone: () => bloc.add(RefreshProducts()),
          ),
        ),
      );
    });
  }

  void _focusProductSearch() {
    if (MediaQuery.sizeOf(context).width < 900) {
      _cashierTabs?.animateTo(0, duration: Duration.zero);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _productSearchFocusNode.context != null) {
        _productSearchFocusNode.requestFocus();
      }
    });
  }

  void _focusCart() {
    if (MediaQuery.sizeOf(context).width < 900) {
      _cashierTabs?.animateTo(1, duration: Duration.zero);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _cartFocusNode.context != null) {
        _cartFocusNode.requestFocus();
      }
    });
  }

  void _onCustomerDisplayConnectionChanged() {
    if (!mounted || !sl<PosCustomerDisplayService>().state.value.isActive) {
      return;
    }
    _publishCustomerDisplay(context.read<PosBloc>().state);
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<PosBloc>();
    bloc.add(LoadPosData());
    await bloc.stream
        .firstWhere((s) => s.status != PosStatus.loading)
        .timeout(const Duration(seconds: 5), onTimeout: () => bloc.state);
    if (mounted) AppToast.success(context, 'Data berhasil dimuat ulang');
  }

  void _publishCustomerDisplay(PosState state) {
    final service = sl<PosCustomerDisplayService>();
    if (!service.state.value.isActive) return;
    final storeName =
        state.activeShift?['toko']?['nama_toko']?.toString() ??
        (state.stores.length == 1 ? state.stores.first.name : 'Pantoo POS');
    service.publishCart(
      items: state.cart.entries
          .map(
            (entry) => <String, dynamic>{
              'name': entry.key.name,
              'quantity': entry.value,
              'unit_price': state.unitPriceFor(entry.key),
              'subtotal': state.unitPriceFor(entry.key) * entry.value,
              'image_url': entry.key.imageUrl,
            },
          )
          .toList(),
      subtotal: state.status == PosStatus.paymentSuccess
          ? state.lastTransaction?.subtotal ?? state.subTotal
          : state.subTotal,
      discount: state.status == PosStatus.paymentSuccess
          ? state.lastTransaction?.discount ?? state.totalDiscount
          : state.totalDiscount,
      total: state.status == PosStatus.paymentSuccess
          ? state.lastTransaction?.total ?? state.grandTotal
          : state.grandTotal,
      storeName: storeName,
      status: state.status == PosStatus.paymentSuccess
          ? 'payment_success'
          : 'cart',
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.bgPrimary,
      body: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.f2): _focusProductSearch,
          const SingleActivator(LogicalKeyboardKey.f6): _focusCart,
          const SingleActivator(LogicalKeyboardKey.f7): () {
            final state = context.read<PosBloc>().state;
            if (state.cart.isNotEmpty) _showDiscountDialog(context, state);
          },
          const SingleActivator(LogicalKeyboardKey.f4): () {
            final bloc = context.read<PosBloc>();
            if (bloc.state.cart.isEmpty) return;
            if (bloc.state.orderType == 'dine_in' &&
                (bloc.state.selectedTableId == null ||
                    bloc.state.selectedTableId!.isEmpty)) {
              AppToast.warning(
                context,
                'Pilih meja dari menu tipe pemenuhan terlebih dahulu.',
              );
              return;
            }
            if (bloc.state.orderType == 'dine_in') {
              _saveTableOrder(context, bloc.state);
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: PosPaymentPage(
                    initialCustomer: bloc.state.selectedCustomer,
                  ),
                ),
              ),
            );
          },
          const SingleActivator(LogicalKeyboardKey.f8): () {
            final state = context.read<PosBloc>().state;
            if (state.cart.isNotEmpty && state.editingOrderId == null) {
              _holdOrder(context);
            }
          },
          const SingleActivator(LogicalKeyboardKey.f9): () {
            if (context.read<PosBloc>().state.heldOrders.isNotEmpty) {
              _showHeldOrders(context);
            }
          },
          const SingleActivator(LogicalKeyboardKey.f10): () =>
              _showSalesContext(context),
          const SingleActivator(LogicalKeyboardKey.delete, control: true): () {
            if (context.read<PosBloc>().state.cart.isNotEmpty) {
              _confirmClearCart(context);
            }
          },
        },
        child: Focus(
          autofocus: true,
          child: BlocListener<PosBloc, PosState>(
            listener: (context, state) {
              // Cart updates must reach the customer even while a cashier
              // dialog or payment page covers this route.
              _publishCustomerDisplay(state);
              if (ModalRoute.of(context)?.isCurrent != true) return;
              if (state.status == PosStatus.paymentSuccess) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 28,
                        ),
                        SizedBox(width: 8),
                        PosText(
                          'Pembayaran Berhasil',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    content: const PosText(
                      'Transaksi telah berhasil diproses.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const PosText(
                          'Tutup',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          AppToast.info(context, 'Mencetak struk...');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(
                          Icons.print,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const PosText(
                          'Print Struk',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              } else if (state.status == PosStatus.failure &&
                  state.errorMessage.isNotEmpty) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const PosText(
                      'Proses belum berhasil',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: PosText(state.errorMessage),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const PosText('Tutup'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                notificationPredicate: (_) => true,
                child: BlocBuilder<PosBloc, PosState>(
                  builder: (context, state) {
                    _cashierTabs = null;
                    Map<String, dynamic>? pendingCheckout;
                    String? invalidCheckout;
                    try {
                      pendingCheckout = context
                          .read<PosBloc>()
                          .posRepository
                          .pendingCheckout;
                    } on StateError catch (error) {
                      invalidCheckout = error.message.toString();
                    }
                    if (pendingCheckout != null || invalidCheckout != null) {
                      return PosCheckoutRecoveryPanel(
                        message:
                            invalidCheckout ??
                            (_recoveryError.isNotEmpty
                                ? _recoveryError
                                : 'Hasil pembayaran sebelumnya belum terkonfirmasi. Jangan terima pembayaran kedua. Sambungkan internet lalu pulihkan transaksi yang sama; stok dan kas tidak dicatat dua kali.'),
                        busy: _recoveringCheckout || state.paymentInProgress,
                        onRecover: pendingCheckout == null
                            ? null
                            : () => _recoverCheckout(pendingCheckout!),
                      );
                    }
                    final availableCategories = <String>{
                      ..._categories,
                      ...state.products.map((product) => product.category),
                    }.where((category) => category.trim().isNotEmpty).toList();
                    if (state.status == PosStatus.loading) {
                      return PosPageSkeleton(isGridView: state.isGridView);
                    }
                    if (state.status == PosStatus.failure &&
                        state.checkoutSyncFailed) {
                      return PosShiftSyncError(
                        message: state.errorMessage,
                        onRetry: () =>
                            context.read<PosBloc>().add(LoadPosData()),
                        onClearCart: state.cart.isEmpty
                            ? null
                            : () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const PosText(
                                      'Kosongkan keranjang?',
                                    ),
                                    content: const PosText(
                                      'Barang dalam keranjang akan dihapus dari keranjang, bukan dari stok. Setelah itu toko dan shift diperiksa kembali.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, false),
                                        child: const PosText('Batal'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(dialogContext, true),
                                        child: const PosText('Kosongkan'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true || !context.mounted) {
                                  return;
                                }
                                context.read<PosBloc>()
                                  ..add(ClearCart())
                                  ..add(LoadPosData());
                              },
                      );
                    }

                    final allowOutOfShift =
                        state.runtimeConfig['allow_out_of_shift'] == true;
                    if (state.activeShift == null &&
                        state.stores.isNotEmpty &&
                        !allowOutOfShift) {
                      return const ShiftManagementPanel();
                    }

                    final cartQuantityLabel =
                        state.totalItems == state.totalItems.truncateToDouble()
                        ? state.totalItems.toStringAsFixed(0)
                        : state.totalItems
                              .toStringAsFixed(3)
                              .replaceFirst(RegExp(r'0+$'), '');

                    return Column(
                      children: [
                        Expanded(
                          child: isMobile
                              ? DefaultTabController(
                                  length: 2,
                                  child: Builder(
                                    builder: (tabContext) {
                                      _cashierTabs = DefaultTabController.of(
                                        tabContext,
                                      );
                                      return Column(
                                        children: [
                                          PosFullWidthTabBar(
                                            height:
                                                MediaQuery.sizeOf(
                                                      context,
                                                    ).width <
                                                    600
                                                ? 44
                                                : 52,
                                            tabs: [
                                              PosFullWidthTab(
                                                icon: Icons.storefront_outlined,
                                                label: ('Katalog Produk').tr(
                                                  context,
                                                ),
                                              ),
                                              PosFullWidthTab(
                                                icon: Icons
                                                    .shopping_cart_outlined,
                                                label: state.cart.isEmpty
                                                    ? ('Keranjang').tr(context)
                                                    : posLocale(
                                                        context,
                                                      ).pos541eb83e5a0c(
                                                        (cartQuantityLabel)
                                                            .toString(),
                                                      ),
                                              ),
                                            ],
                                          ),
                                          Expanded(
                                            child: TabBarView(
                                              children: [
                                                PosProductPanel(
                                                  onManageProducts:
                                                      widget.onManageProducts,
                                                  searchFocusNode:
                                                      _productSearchFocusNode,
                                                  searchTourKey: widget
                                                      .tourTargets
                                                      ?.search,
                                                  isMobile: isMobile,
                                                  selectedCategory:
                                                      _selectedCategory,
                                                  categories:
                                                      availableCategories,
                                                  onCategorySelected:
                                                      (category) => setState(
                                                        () =>
                                                            _selectedCategory =
                                                                category,
                                                      ),
                                                ),
                                                _buildRightSide(isMobile),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                )
                              : Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    PosCategorySidebar(
                                      categories: availableCategories,
                                      selectedCategory: _selectedCategory,
                                      onCategorySelected: (category) =>
                                          setState(
                                            () => _selectedCategory = category,
                                          ),
                                    ),
                                    Expanded(
                                      flex: 5,
                                      child: PosProductPanel(
                                        onManageProducts:
                                            widget.onManageProducts,
                                        searchFocusNode:
                                            _productSearchFocusNode,
                                        searchTourKey:
                                            widget.tourTargets?.search,
                                        isMobile: isMobile,
                                        selectedCategory: _selectedCategory,
                                        categories: availableCategories,
                                        onCategorySelected: (category) =>
                                            setState(
                                              () =>
                                                  _selectedCategory = category,
                                            ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: _buildRightSide(isMobile),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRightSide(bool isMobile) {
    return Focus(
      focusNode: _cartFocusNode,
      onFocusChange: (focused) {
        if (mounted) setState(() => _cartHasFocus = focused);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(
              color: _cartHasFocus ? AppColors.primary : Colors.grey.shade200,
              width: _cartHasFocus ? 3 : 1,
            ),
          ),
        ),
        child: Column(
          children: [
            const Expanded(child: PosCartPanel()),
            _buildFooterActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.heldOrders.isNotEmpty)
              Material(
                color: AppColors.primary.withValues(alpha: 0.08),
                child: InkWell(
                  onTap: () => _showHeldOrders(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            posLocale(context).posc1d0cd74f8ec(
                              (state.heldOrders.length).toString(),
                            ),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const PosText(
                          'Buka',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                          size: 19,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: ('Kosongkan seluruh keranjang').tr(context),
                      child: OutlinedButton(
                        onPressed: state.cart.isEmpty
                            ? null
                            : () => _confirmClearCart(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Tooltip(
                      message: ('Atur diskon manual dan kode promo').tr(
                        context,
                      ),
                      child: OutlinedButton(
                        onPressed: state.cart.isEmpty
                            ? null
                            : () => _showDiscountDialog(context, state),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Icon(
                          Icons.discount_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: KeyedSubtree(
                      key: widget.tourTargets?.salesContext,
                      child: OutlinedButton(
                        onPressed: () => _showSalesContext(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Tooltip(
                          message: ('Channel, level harga, pajak dan promo').tr(
                            context,
                          ),
                          child: Icon(
                            Icons.tune_outlined,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: KeyedSubtree(
                      key: widget.tourTargets?.saveOrder,
                      child: Tooltip(
                        message: ('Simpan sementara untuk dilanjutkan nanti')
                            .tr(context),
                        child: OutlinedButton(
                          onPressed:
                              state.cart.isEmpty || state.editingOrderId != null
                              ? null
                              : () => _holdOrder(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 4,
                            ),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.download,
                                color: Colors.grey,
                                size: 18,
                              ),
                              SizedBox(width: 4),
                              Flexible(
                                child: PosText(
                                  'Simpan',
                                  style: TextStyle(color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
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
            SizedBox(
              key: widget.tourTargets?.payment,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.cart.isEmpty || _savingTableOrder
                    ? null
                    : () {
                        final posBloc = context.read<PosBloc>();
                        if (posBloc.state.orderType == 'dine_in' &&
                            (posBloc.state.selectedTableId == null ||
                                posBloc.state.selectedTableId!.isEmpty)) {
                          AppToast.warning(
                            context,
                            'Pilih meja dari menu tipe pemenuhan terlebih dahulu.',
                          );
                          return;
                        }
                        if (posBloc.state.orderType == 'dine_in') {
                          _saveTableOrder(context, posBloc.state);
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: posBloc,
                              child: PosPaymentPage(
                                initialCustomer: posBloc.state.selectedCustomer,
                              ),
                            ),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  minimumSize: const Size.fromHeight(60),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        state.totalItems == state.totalItems.truncateToDouble()
                            ? state.totalItems.toStringAsFixed(0)
                            : state.totalItems
                                  .toStringAsFixed(3)
                                  .replaceFirst(RegExp(r'0+$'), ''),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _savingTableOrder
                              ? ('Menyimpan...').tr(context)
                              : state.editingOrderId != null
                              ? ('Simpan Perubahan').tr(context)
                              : state.orderType == 'dine_in'
                              ? ('Simpan ke Meja').tr(context)
                              : ('Bayar').tr(context),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              formatRupiahAmount(state.grandTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: Colors.white),
                        ],
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
  }

  Future<void> _showSalesContext(BuildContext context) {
    final posBloc = context.read<PosBloc>();
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: posBloc,
        child: PosKeyboardStableSheet(
          heightFactor: isMobile ? 0.82 : 0.68,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
            child: PosInfoPanel(isMobile: isMobile),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearCart(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const PosText('Kosongkan keranjang?'),
        content: const PosText('Semua item dalam pesanan akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const PosText('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const PosText('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<PosBloc>().add(ClearCart());
    }
  }

  Future<void> _showDiscountDialog(BuildContext context, PosState state) async {
    final discountController = TextEditingController(
      text: state.manualDiscountPercent.toStringAsFixed(0),
    );
    final promoController = TextEditingController(text: state.promoCode);
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const PosText('Diskon & Promo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: discountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: ('Diskon manual (%)').tr(dialogContext),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: promoController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: ('Kode promo').tr(dialogContext),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const PosText('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, {
              'discount': discountController.text,
              'promo': promoController.text.trim(),
            }),
            child: const PosText('Terapkan'),
          ),
        ],
      ),
    );
    discountController.dispose();
    promoController.dispose();
    if (result == null || !context.mounted) return;
    final discount = double.tryParse(result['discount'] ?? '') ?? 0;
    if (discount < 0 || discount > 100) {
      AppToast.warning(context, 'Diskon harus antara 0–100%');
      return;
    }
    context.read<PosBloc>().add(
      UpdateDiscount(
        manualDiscountPercent: discount,
        promoCode: result['promo'] ?? '',
        discountPolicy: state.discountPolicy,
      ),
    );
  }

  Future<void> _holdOrder(BuildContext context) async {
    if (_heldOrderFlowOpen) return;
    _heldOrderFlowOpen = true;
    try {
      final bloc = context.read<PosBloc>();
      if (bloc.state.heldOrders.isNotEmpty) {
        final createNew = await showModalBottomSheet<Object>(
          context: context,
          builder: (sheetContext) => SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ListTile(
                    title: PosText(
                      'Pesanan tersimpan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...bloc.state.heldOrders.map(
                    (order) => ListTile(
                      leading: const Icon(Icons.restore),
                      title: Text(
                        order.notes.isNotEmpty
                            ? order.notes
                            : posLocale(sheetContext).pose27a8b678805(
                                (order.customer?.name ?? 'tersimpan')
                                    .toString(),
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        posLocale(sheetContext).posa6e5135e1c96(
                          (order.id).toString(),
                          (order.cart.length).toString(),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext, order);
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline),
                    title: const PosText('Simpan pesanan saat ini'),
                    onTap: () => Navigator.pop(sheetContext, true),
                  ),
                ],
              ),
            ),
          ),
        );
        if (!context.mounted) return;
        if (createNew is HoldOrder) {
          await restorePosHeldCart(context, bloc, createNew);
          return;
        }
        if (createNew != true) return;
        if (!context.mounted) return;
      }
      final notes = await showDialog<String>(
        context: context,
        builder: (_) => const PosHeldOrderNameDialog(),
      );
      if (notes != null && context.mounted) {
        final saved = await runPosHeldCartAction(
          context,
          bloc,
          (completion) => HoldCurrentOrder(notes, completion: completion),
        );
        if (saved && context.mounted)
          AppToast.success(context, 'Pesanan disimpan sementara');
      }
    } finally {
      _heldOrderFlowOpen = false;
    }
  }

  Future<void> _showHeldOrders(BuildContext context) => _holdOrder(context);

  Future<void> _saveTableOrder(BuildContext context, PosState state) async {
    if (_savingTableOrder) return;
    setState(() => _savingTableOrder = true);
    if (state.editingOrderId != null) {
      final items = state.cart.entries
          .map(
            (entry) => <String, dynamic>{
              'produk_id': entry.key.id,
              'nama': entry.key.name,
              'kode': entry.key.code,
              'qty': entry.value,
              'unit': state.unitFor(entry.key),
              'harga_satuan': state.unitPriceFor(entry.key),
            },
          )
          .toList();
      final update = await sl<PosOrderRepository>().updateOrderItems(
        state.editingOrderId!,
        items,
      );
      if (!mounted) return;
      setState(() => _savingTableOrder = false);
      update.fold((failure) => AppToast.error(context, failure.message), (_) {
        final number = state.editingOrderNumber ?? '';
        context.read<PosBloc>()
          ..add(ClearCart())
          ..add(RefreshOrders());
        AppToast.success(context, 'Pesanan $number berhasil diperbarui.');
        widget.onOpenTableOrders?.call();
      });
      return;
    }
    final checkoutStore = state.checkoutStore;
    if (checkoutStore == null ||
        (state.activeShift == null &&
            state.runtimeConfig['allow_out_of_shift'] != true)) {
      setState(() => _savingTableOrder = false);
      AppToast.warning(
        context,
        'Periksa toko aktif dan buka shift kasir sebelum membuat pesanan.',
      );
      return;
    }
    final result = await sl<PosRepository>().createUnpaidInvoice(
      cart: state.cart,
      selectedUnits: state.selectedUnits,
      tokoId: checkoutStore.id,
      shiftId: state.activeShift?['_id']?.toString() ?? '',
      orderType: 'dine_in',
      tableId: state.selectedTableId,
      customerId: state.selectedCustomer?.id,
      customerName: state.selectedCustomer?.name,
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
      expectedTotal: state.grandTotal,
      itemPrices: {
        for (final product in state.cart.keys)
          product.id: state.unitPriceFor(product),
      },
    );
    if (!mounted) return;
    setState(() => _savingTableOrder = false);
    result.fold((failure) => AppToast.error(context, failure.message), (order) {
      if (order['offline_queued'] == true) {
        context.read<PosBloc>().add(ClearCart());
        AppToast.warning(
          context,
          'Pesanan offline tersimpan. Belum masuk meja/dapur; cek Antrean & Sinkronisasi.',
        );
        return;
      }
      final tableName = state.selectedTableName ?? 'terpilih';
      context.read<PosBloc>()
        ..add(ClearCart())
        ..add(RefreshOrders());
      AppToast.success(
        context,
        'Pesanan ${order['order_no'] ?? ''} tersimpan di meja $tableName.',
      );
      widget.onOpenTableOrders?.call();
    });
  }
}
