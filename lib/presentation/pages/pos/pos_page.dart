import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/pos/pos_bloc.dart';
import '../../bloc/pos/pos_event.dart';
import '../../bloc/pos/pos_state.dart';
import '../../widgets/skeleton_loading.dart';
import '../../widgets/app_toast.dart';
import 'widgets/pos_product_panel.dart';
import 'widgets/pos_cart_panel.dart';
import 'pos_payment_page.dart';
import 'widgets/pos_category_sidebar.dart';
import 'widgets/shift_management_panel.dart';
import 'widgets/pos_info_panel.dart';

class PosPage extends StatelessWidget {
  const PosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PosPageView();
  }
}

class PosPageView extends StatefulWidget {
  const PosPageView({super.key});

  @override
  State<PosPageView> createState() => _PosPageViewState();
}

class _PosPageViewState extends State<PosPageView> {
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

  Future<void> _onRefresh() async {
    final bloc = context.read<PosBloc>();
    bloc.add(LoadPosData());
    await bloc.stream
        .firstWhere((s) => s.status != PosStatus.loading)
        .timeout(const Duration(seconds: 5), onTimeout: () => bloc.state);
    if (mounted) AppToast.success(context, 'Data berhasil dimuat ulang');
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
          const SingleActivator(LogicalKeyboardKey.f4): () {
            final bloc = context.read<PosBloc>();
            if (bloc.state.cart.isEmpty) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: bloc,
                  child: const PosPaymentPage(),
                ),
              ),
            );
          },
          const SingleActivator(LogicalKeyboardKey.f8): () {
            if (context.read<PosBloc>().state.cart.isNotEmpty) {
              _holdOrder(context);
            }
          },
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
                        Icon(Icons.check_circle, color: Colors.green, size: 28),
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
                        color: Colors.red,
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
                    final availableCategories = <String>{
                      ..._categories,
                      ...state.products.map((product) => product.category),
                    }.where((category) => category.trim().isNotEmpty).toList();
                    if (state.status == PosStatus.loading &&
                        state.products.isEmpty) {
                      return const PosPageSkeleton();
                    }

                    if (state.activeShift == null && state.stores.isNotEmpty) {
                      return const ShiftManagementPanel();
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: isMobile
                              ? DefaultTabController(
                                  length: 2,
                                  child: Column(
                                    children: [
                                      Container(
                                        color: Colors.white,
                                        child: const TabBar(
                                          labelColor: AppColors.secondary,
                                          indicatorColor: AppColors.secondary,
                                          tabs: [
                                            Tab(text: 'Katalog Produk'),
                                            Tab(text: 'Keranjang'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Expanded(
                                        child: TabBarView(
                                          children: [
                                            PosProductPanel(
                                              isMobile: isMobile,
                                              selectedCategory:
                                                  _selectedCategory,
                                              categories: availableCategories,
                                              onCategorySelected: (category) =>
                                                  setState(
                                                    () => _selectedCategory =
                                                        category,
                                                  ),
                                            ),
                                            _buildRightSide(isMobile),
                                          ],
                                        ),
                                      ),
                                    ],
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          const Expanded(child: PosCartPanel()),
          _buildFooterActions(context),
        ],
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
                    child: OutlinedButton(
                      onPressed: state.cart.isEmpty
                          ? null
                          : () => _confirmClearCart(context),
                      style: OutlinedButton.styleFrom(
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.cart.isEmpty
                          ? null
                          : () => _showDiscountDialog(context, state),
                      style: OutlinedButton.styleFrom(
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showSalesContext(context),
                      style: OutlinedButton.styleFrom(
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
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: state.cart.isEmpty
                          ? null
                          : () => _holdOrder(context),
                      style: OutlinedButton.styleFrom(
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
                          Icon(Icons.download, color: Colors.grey, size: 18),
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
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: state.cart.isEmpty
                    ? null
                    : () {
                        final posBloc = context.read<PosBloc>();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: posBloc,
                              child: const PosPaymentPage(),
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
                        color: Colors.amber,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${state.totalItems}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Bayar',
                          style: TextStyle(
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
        child: FractionallySizedBox(
          heightFactor: isMobile ? 0.82 : 0.68,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                  title: Text(order.id),
                  subtitle: Text(
                    '${order.cart.length} produk${order.notes.isNotEmpty ? ' · ${order.notes}' : ''}',
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
          decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
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
}
