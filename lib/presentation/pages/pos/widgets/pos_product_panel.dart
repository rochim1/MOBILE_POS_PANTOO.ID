import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pos_customer_page.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/pos/pos_bloc.dart';
import '../../../bloc/pos/pos_event.dart';
import '../../../bloc/pos/pos_state.dart';
import '../../../widgets/app_toast.dart';
import '../../../../domain/models/pos_product.dart';
import '../../../../domain/models/pos_customer.dart';
import '../pos_barcode_scanner_page.dart';
import '../pos_table_order_page.dart';

class PosProductPanel extends StatefulWidget {
  final bool isMobile;
  final String selectedCategory;
  final List<String> categories;
  final ValueChanged<String> onCategorySelected;

  const PosProductPanel({
    super.key,
    required this.isMobile,
    required this.selectedCategory,
    required this.categories,
    required this.onCategorySelected,
  });

  @override
  State<PosProductPanel> createState() => _PosProductPanelState();
}

class _PosProductPanelState extends State<PosProductPanel> {
  String _searchQuery = '';
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        final filteredProducts = state.products.where((p) {
          final catMatch =
              widget.selectedCategory == 'Semua Kategori' ||
              (widget.selectedCategory == 'Favorit' &&
                  state.favoriteProductIds.contains(p.id)) ||
              (widget.selectedCategory == 'Produk Paket' &&
                  p.productType == 'package') ||
              (widget.selectedCategory == 'Produk Layanan' &&
                  p.productType == 'service') ||
              (widget.selectedCategory == 'Promo' && p.promoEligible) ||
              (widget.selectedCategory == 'Deposit' &&
                  p.productType == 'deposit') ||
              p.category == widget.selectedCategory;
          final searchMatch =
              _searchQuery.isEmpty ||
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.sku.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.barcode.toLowerCase().contains(_searchQuery.toLowerCase());
          return catMatch && searchMatch;
        }).toList();

        return CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.f2): () =>
                _searchFocusNode.requestFocus(),
            const SingleActivator(LogicalKeyboardKey.f3): () =>
                _scanBarcode(context, state),
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildSearchAndFilter(context, state)),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (!state.isGridView) ...[
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'Produk',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'SKU',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'Stok',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Harga',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: Divider(height: 1, color: Colors.grey),
                ),
              ],
              if (filteredProducts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Container(
                    color: Colors.white,
                    child: const Center(
                      child: Text('Tidak ada produk ditemukan'),
                    ),
                  ),
                )
              else if (state.isGridView)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildProductGridItem(
                        context,
                        filteredProducts[index],
                      ),
                      childCount: filteredProducts.length,
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildProductListItem(context, filteredProducts[index]),
                    childCount: filteredProducts.length,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilter(BuildContext context, PosState state) {
    final orderTypes = _availableOrderTypes(state);
    final selectedOrderType =
        orderTypes.any((type) => type.value == state.orderType)
        ? state.orderType
        : 'take_away';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: TextField(
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Ketik minimal 3 karakter untuk mulai mencari...',
                hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Colors.black54),
                suffixIcon: IconButton(
                  tooltip: 'Scan barcode',
                  onPressed: () => _scanBarcode(context, state),
                  icon: const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.black54,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          if (widget.isMobile) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Pilih kategori',
              initialValue: widget.selectedCategory,
              onSelected: widget.onCategorySelected,
              itemBuilder: (_) => widget.categories
                  .map(
                    (category) =>
                        PopupMenuItem(value: category, child: Text(category)),
                  )
                  .toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Pilih pelanggan',
              onPressed: () => _selectCustomer(context),
              icon: Icon(
                state.selectedCustomer == null
                    ? Icons.person_add_alt_outlined
                    : Icons.person,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            _buildOrderMenu(context, state, selectedOrderType, compact: true),
          ],
          if (!widget.isMobile) ...[
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: _buildOrderMenu(
                context,
                state,
                selectedOrderType,
                compact: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: TextButton(
                onPressed: () => _selectCustomer(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: AppColors.primary, size: 18),
                    SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Pelanggan',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderMenu(
    BuildContext context,
    PosState state,
    String selectedOrderType, {
    required bool compact,
  }) {
    final orderTypes = _availableOrderTypes(state);
    return PopupMenuButton<String>(
      tooltip: 'Jenis order: ${_orderTypeLabel(selectedOrderType)}',
      initialValue: selectedOrderType,
      onSelected: (value) {
        if (value == '__table') {
          final posBloc = context.read<PosBloc>();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: posBloc,
                child: const PosTableOrderPage(),
              ),
            ),
          );
          return;
        }
        if (value == '__served_by') {
          _showServedByInfo(context, state);
          return;
        }
        if (value == '__reset') {
          final defaultType =
              state.runtimeConfig['default_order_type']?.toString() ??
              'take_away';
          context.read<PosBloc>()
            ..add(UpdateOrderType(defaultType))
            ..add(const SelectCustomer(null));
          return;
        }
        context.read<PosBloc>().add(UpdateOrderType(value));
      },
      itemBuilder: (_) {
        final features = state.runtimeConfig['features'] as Map? ?? const {};
        return [
          if (features['use_tables'] == true)
            const PopupMenuItem<String>(
              value: '__table',
              child: _OrderMenuRow(
                icon: Icons.table_restaurant_outlined,
                label: 'Meja',
              ),
            ),
          ...orderTypes.map(
            (type) => PopupMenuItem<String>(
              value: type.value,
              child: _OrderMenuRow(
                icon: type.icon,
                label: type.label,
                selected: selectedOrderType == type.value,
              ),
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem<String>(
            value: '__served_by',
            child: _OrderMenuRow(
              icon: Icons.badge_outlined,
              label: 'Dilayani Oleh',
            ),
          ),
          const PopupMenuItem<String>(
            value: '__reset',
            child: _OrderMenuRow(icon: Icons.sync, label: 'Reset'),
          ),
        ];
      },
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
        decoration: BoxDecoration(
          color: compact ? AppColors.primarySoft : Colors.white,
          border: Border.all(
            color: compact ? AppColors.primarySoft : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: compact
            ? const Icon(Icons.room_service_outlined, color: AppColors.primary)
            : Row(
                children: [
                  const Icon(
                    Icons.room_service_outlined,
                    size: 19,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _orderTypeLabel(selectedOrderType),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                ],
              ),
      ),
    );
  }

  List<({String value, String label, IconData icon})> _availableOrderTypes(
    PosState state,
  ) {
    return const [
      (
        value: 'dine_in',
        label: 'Makan di Tempat',
        icon: Icons.restaurant_outlined,
      ),
      (
        value: 'free_table',
        label: 'Free Table',
        icon: Icons.chair_alt_outlined,
      ),
      (
        value: 'take_away',
        label: 'Bawa Pulang',
        icon: Icons.shopping_bag_outlined,
      ),
      (
        value: 'delivery',
        label: 'Pengiriman',
        icon: Icons.local_shipping_outlined,
      ),
      (
        value: 'online_delivery',
        label: 'Ojek Online',
        icon: Icons.two_wheeler_outlined,
      ),
      (
        value: 'quick_service',
        label: 'Quick Service',
        icon: Icons.timer_outlined,
      ),
      (
        value: 'reservation',
        label: 'Reservasi',
        icon: Icons.event_available_outlined,
      ),
    ];
  }

  bool _isUnavailable(PosProduct product, PosState state) {
    final features = state.runtimeConfig['features'] as Map?;
    final trackStock = features?['track_stock'] != false;
    return product.isUnavailableForSale(trackStock: trackStock);
  }

  String _orderTypeLabel(String value) => switch (value) {
    'dine_in' => 'Makan di Tempat',
    'free_table' => 'Free Table',
    'delivery' => 'Pengiriman',
    'online_delivery' => 'Ojek Online',
    'quick_service' => 'Quick Service',
    'reservation' => 'Reservasi',
    _ => 'Bawa Pulang',
  };

  Future<void> _showServedByInfo(BuildContext context, PosState state) {
    final cashier =
        state.activeShift?['kasir_user']?['name']?.toString() ??
        state.activeShift?['opened_by']?['name']?.toString() ??
        'Kasir shift aktif';
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dilayani Oleh'),
        content: Text(
          '$cashier\n\nTransaksi otomatis dicatat atas kasir yang membuka shift aktif.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductListItem(BuildContext context, PosProduct product) {
    return InkWell(
      onTap: () {
        final state = context.read<PosBloc>().state;
        if (_isUnavailable(product, state)) {
          AppToast.warning(context, 'Stok ${product.name} habis');
          return;
        }
        context.read<PosBloc>().add(AddToCart(product));
        AppToast.info(context, '${product.name} ditambahkan ke keranjang');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Text(
                product.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            IconButton(
              tooltip: 'Favorit',
              onPressed: () => context.read<PosBloc>().add(
                ToggleFavoriteProduct(product.id),
              ),
              icon: BlocBuilder<PosBloc, PosState>(
                builder: (context, state) => Icon(
                  state.favoriteProductIds.contains(product.id)
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                product.code,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${product.stock}',
                style: const TextStyle(color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Rp ${product.price.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.black87),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductGridItem(BuildContext context, PosProduct product) {
    return InkWell(
      onTap: () {
        final state = context.read<PosBloc>().state;
        if (_isUnavailable(product, state)) {
          AppToast.warning(context, 'Stok ${product.name} habis');
          return;
        }
        context.read<PosBloc>().add(AddToCart(product));
        AppToast.info(context, '${product.name} ditambahkan ke keranjang');
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: product.imageUrl.trim().isEmpty
                          ? const Center(
                              child: Icon(
                                Icons.image,
                                size: 40,
                                color: Colors.grey,
                              ),
                            )
                          : Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  size: 38,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: IconButton(
                      onPressed: () => context.read<PosBloc>().add(
                        ToggleFavoriteProduct(product.id),
                      ),
                      icon: BlocBuilder<PosBloc, PosState>(
                        builder: (context, state) => Icon(
                          state.favoriteProductIds.contains(product.id)
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanBarcode(BuildContext context, PosState state) async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const PosBarcodeScannerPage()),
    );
    if (!context.mounted || code == null) return;
    final normalized = code.trim().toLowerCase();
    final matches = state.products
        .where(
          (product) =>
              product.barcode.toLowerCase() == normalized ||
              product.sku.toLowerCase() == normalized ||
              product.code.toLowerCase() == normalized,
        )
        .toList();
    if (matches.isEmpty) {
      AppToast.warning(context, 'Barcode $code tidak ditemukan');
      return;
    }
    final product = matches.first;
    if (_isUnavailable(product, state)) {
      AppToast.warning(context, 'Stok ${product.name} habis');
      return;
    }
    context.read<PosBloc>().add(AddToCart(product));
    AppToast.success(context, '${product.name} ditambahkan');
  }

  Future<void> _selectCustomer(BuildContext context) async {
    final customer = await Navigator.push<PosCustomer>(
      context,
      MaterialPageRoute(
        builder: (_) => const PosCustomerPage(selectionMode: true),
      ),
    );
    if (!context.mounted || customer == null) return;
    context.read<PosBloc>().add(SelectCustomer(customer));
    AppToast.success(context, '${customer.name} dipilih');
  }
}

class _OrderMenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _OrderMenuRow({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        if (selected)
          const Icon(Icons.check, size: 18, color: AppColors.primary),
      ],
    );
  }
}
