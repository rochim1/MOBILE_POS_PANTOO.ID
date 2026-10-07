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
import 'widgets/pos_category_sidebar.dart';
import 'widgets/shift_management_panel.dart';
import 'widgets/pos_info_panel.dart';
import 'widgets/pos_cashier_tour.dart';

class PosPage extends StatelessWidget {
  final PosCashierTourTargets? tourTargets;
  final VoidCallback? onOpenTableOrders;
  const PosPage({super.key, this.tourTargets, this.onOpenTableOrders});

  @override
  Widget build(BuildContext context) {
    return PosPageView(
      tourTargets: tourTargets,
      onOpenTableOrders: onOpenTableOrders,
    );
  }
}

class PosPageView extends StatefulWidget {
  final PosCashierTourTargets? tourTargets;
  final VoidCallback? onOpenTableOrders;
  const PosPageView({super.key, this.tourTargets, this.onOpenTableOrders});

  @override
  State<PosPageView> createState() => _PosPageViewState();
}

class _PosPageViewState extends State<PosPageView> {
  bool _savingTableOrder = false;
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
      subtotal: state.subTotal,
      discount: state.totalDiscount,
      total: state.grandTotal,
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
              if (ModalRoute.of(context)?.isCurrent != true) return;
              _publishCustomerDisplay(state);
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
                        Text(
                          'Pembayaran Berhasil',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    content: const Text('Transaksi telah berhasil diproses.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
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
                        label: const Text(
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
                    title: const Text(
                      'Pembayaran Gagal',
                      style: TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: Text(state.errorMessage),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Tutup'),
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
                    final availableCategories = <String>{
                      ..._categories,
                      ...state.products.map((product) => product.category),
                    }.where((category) => category.trim().isNotEmpty).toList();
                    if (state.status == PosStatus.loading &&
                        state.products.isEmpty) {
                      return const PosPageSkeleton();
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
                                            tabs: [
                                              const PosFullWidthTab(
                                                icon: Icons.storefront_outlined,
                                                label: 'Katalog Produk',
                                              ),
                                              PosFullWidthTab(
                                                icon: Icons
                                                    .shopping_cart_outlined,
                                                label: state.cart.isEmpty
                                                    ? 'Keranjang'
                                                    : 'Keranjang ($cartQuantityLabel)',
                                              ),
                                            ],
                                          ),
                                          Expanded(
                                            child: TabBarView(
                                              children: [
                                                PosProductPanel(
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
                            '${state.heldOrders.length} pesanan tersimpan',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Text(
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
                      message: 'Kosongkan seluruh keranjang',
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
                      message: 'Atur diskon manual dan kode promo',
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
                        child: const Tooltip(
                          message: 'Channel, level harga, pajak dan promo',
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
                        message: 'Simpan sementara untuk dilanjutkan nanti',
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
                                child: Text(
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
                              ? 'Menyimpan...'
                              : state.editingOrderId != null
                              ? 'Simpan Perubahan'
                              : state.orderType == 'dine_in'
                              ? 'Simpan ke Meja'
                              : 'Bayar',
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
                              state.grandTotal.toStringAsFixed(0),
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
        title: const Text('Kosongkan keranjang?'),
        content: const Text('Semua item dalam pesanan akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
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
        title: const Text('Diskon & Promo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: discountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Diskon manual (%)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: promoController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Kode promo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, {
              'discount': discountController.text,
              'promo': promoController.text.trim(),
            }),
            child: const Text('Terapkan'),
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
    final bloc = context.read<PosBloc>();
    if (bloc.state.heldOrders.isNotEmpty) {
      final createNew = await showModalBottomSheet<bool>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text(
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
                        : 'Pesanan ${order.customer?.name ?? 'tersimpan'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${order.id} · ${order.cart.length} produk',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    bloc.add(RestoreHeldOrder(order));
                    Navigator.pop(sheetContext, false);
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Simpan pesanan saat ini'),
                onTap: () => Navigator.pop(sheetContext, true),
              ),
            ],
          ),
        ),
      );
      if (createNew != true) return;
      if (!context.mounted) return;
    }
    final notesController = TextEditingController();
    final notes = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Simpan pesanan'),
        content: TextField(
          controller: notesController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nama pesanan',
            hintText: 'Contoh: Pesanan Pak Budi',
            helperText: 'Nama ini ditampilkan sebagai judul pesanan tersimpan.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, notesController.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    notesController.dispose();
    if (notes != null && context.mounted) {
      context.read<PosBloc>().add(HoldCurrentOrder(notes));
      AppToast.success(context, 'Pesanan disimpan sementara');
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
              'unit': entry.key.saleUnit,
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
    final result = await sl<PosRepository>().createUnpaidInvoice(
      cart: state.cart,
      tokoId:
          state.activeShift?['toko_id']?.toString() ??
          state.stores
              .where((store) => store.status.toLowerCase() == 'active')
              .firstOrNull
              ?.id ??
          '',
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
