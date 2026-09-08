import 'package:flutter/material.dart';
import 'dart:typed_data';

import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:mobile_pos_pantoo/core/utils/product_image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_product_management_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_product_management/pos_product_management_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_product_management/pos_product_management_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_product_management/pos_product_management_state.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/skeleton_loading.dart';
import 'pos_barcode_scanner_page.dart';

class PosProductPage extends StatefulWidget {
  final bool isGridView;

  const PosProductPage({super.key, this.isGridView = true});

  @override
  State<PosProductPage> createState() => _PosProductPageState();
}

class _PosProductPageState extends State<PosProductPage> {
  String _searchQuery = '';
  String? _categoryFilter;
  String _stockFilter = 'all';
  bool _waitingForCatalogRefresh = false;

  List<PosProduct> _getFilteredProducts(
    List<PosProduct> products, {
    required bool trackStock,
  }) {
    final query = _searchQuery.toLowerCase();
    return products.where((product) {
      final matchesSearch =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.code.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query);
      final matchesCategory =
          _categoryFilter == null || product.category == _categoryFilter;
      final matchesStock = !trackStock
          ? true
          : switch (_stockFilter) {
              'available' => product.stock > 0,
              'low' => product.stock > 0 && product.stock <= 10,
              'empty' => product.stock <= 0,
              _ => true,
            };
      return matchesSearch && matchesCategory && matchesStock;
    }).toList();
  }

  int _activeFilterCount(bool trackStock) =>
      (_categoryFilter == null ? 0 : 1) +
      (!trackStock || _stockFilter == 'all' ? 0 : 1);

  bool _tracksStock(BuildContext context) {
    final features =
        context.read<PosBloc>().state.runtimeConfig['features'] as Map?;
    return features?['track_stock'] != false;
  }

  bool _canManageProducts(BuildContext context) {
    final config = context.read<PosBloc>().state.runtimeConfig;
    final permissions = config['permissions'] as Map?;
    return permissions?['manage_products'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 760;

    return BlocProvider(
      create: (context) => sl<PosProductManagementBloc>(),
      child: BlocConsumer<PosProductManagementBloc, PosProductManagementState>(
        listener: (context, mgmtState) {
          if (mgmtState.status == PosProductManagementStatus.success) {
            AppToast.success(context, mgmtState.successMessage);
            // Urutan katalog ditentukan oleh backend. Menyisipkan hasil
            // mutation di posisi pertama membuat daftar meloncat saat refetch
            // kembali dengan urutan alfabetis.
            setState(() => _waitingForCatalogRefresh = true);
            context.read<PosBloc>().add(RefreshProducts());
          } else if (mgmtState.status == PosProductManagementStatus.failure) {
            AppToast.error(context, mgmtState.errorMessage);
          }
        },
        builder: (context, mgmtState) {
          return BlocConsumer<PosBloc, PosState>(
            listenWhen: (previous, current) =>
                previous.productsRefreshing && !current.productsRefreshing,
            listener: (context, state) {
              if (_waitingForCatalogRefresh) {
                setState(() => _waitingForCatalogRefresh = false);
              }
              if (state.errorMessage == 'Katalog gagal dimuat ulang') {
                AppToast.error(context, state.errorMessage);
              }
            },
            builder: (context, state) {
              final trackStock = _tracksStock(context);
              final filteredProducts = _getFilteredProducts(
                state.products,
                trackStock: trackStock,
              );

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCatalogSourceNotice(),
                    const SizedBox(height: 12),
                    _buildActionRow(
                      isMobile,
                      context,
                      state.products,
                      trackStock,
                    ),
                    const SizedBox(height: 16),
                    if (mgmtState.status == PosProductManagementStatus.loading)
                      const LinearProgressIndicator(),
                    Expanded(
                      child:
                          (_waitingForCatalogRefresh ||
                              state.productsRefreshing)
                          ? _buildCatalogSkeleton(isMobile)
                          : widget.isGridView
                          ? _buildProductCards(isMobile, filteredProducts)
                          : _buildProductTable(filteredProducts),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCatalogSkeleton(bool isMobile) {
    if (!widget.isGridView) {
      return ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: isMobile ? 5 : 7,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => const SkeletonProductListItem(),
      );
    }
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 2 : 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isMobile ? .9 : 1.2,
      ),
      itemCount: isMobile ? 6 : 8,
      itemBuilder: (_, _) => const SkeletonProductCard(),
    );
  }

  Widget _buildCatalogSourceNotice() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, color: AppColors.primary, size: 20),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Katalog Penjualan · Produk bersumber dari Inventory. Detail master, HPP, satuan, batch, dan saldo lokasi dikelola melalui alur Inventory.',
            style: TextStyle(fontSize: 12.5, height: 1.35),
          ),
        ),
      ],
    ),
  );

  Widget _buildActionRow(
    bool isMobile,
    BuildContext context,
    List<PosProduct> products,
    bool trackStock,
  ) {
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _buildSearchField()),
                  const SizedBox(width: 10),
                  _buildFilterButton(context, products, trackStock),
                ],
              ),
              const SizedBox(height: 12),
              if (_canManageProducts(context))
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCatalogProductForm(context, true),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Produk'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
            ],
          )
        : Row(
            children: [
              Expanded(child: _buildSearchField()),
              const SizedBox(width: 10),
              _buildFilterButton(context, products, trackStock),
              const SizedBox(width: 16),
              if (_canManageProducts(context))
                ElevatedButton.icon(
                  onPressed: () => _showCatalogProductForm(context, false),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Produk'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                  ),
                ),
            ],
          );
  }

  Widget _buildFilterButton(
    BuildContext context,
    List<PosProduct> products,
    bool trackStock,
  ) {
    return Badge(
      isLabelVisible: _activeFilterCount(trackStock) > 0,
      label: Text('${_activeFilterCount(trackStock)}'),
      child: IconButton.filledTonal(
        tooltip: 'Filter produk',
        onPressed: () => _showFilterSheet(context, products, trackStock),
        icon: const Icon(Icons.tune),
        style: IconButton.styleFrom(
          minimumSize: const Size(52, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _showFilterSheet(
    BuildContext context,
    List<PosProduct> products,
    bool trackStock,
  ) async {
    final categories =
        products
            .map((product) => product.category)
            .where((category) => category.trim().isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    var selectedCategory = _categoryFilter;
    var selectedStock = _stockFilter;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter Produk',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String?>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua kategori'),
                    ),
                    ...categories.map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => selectedCategory = value),
                ),
                if (trackStock) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStock,
                    decoration: const InputDecoration(
                      labelText: 'Kondisi stok',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Semua stok')),
                      DropdownMenuItem(
                        value: 'available',
                        child: Text('Tersedia'),
                      ),
                      DropdownMenuItem(
                        value: 'low',
                        child: Text('Stok menipis (1–10)'),
                      ),
                      DropdownMenuItem(
                        value: 'empty',
                        child: Text('Stok habis'),
                      ),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => selectedStock = value ?? 'all'),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          selectedCategory = null;
                          selectedStock = 'all';
                          Navigator.pop(sheetContext, true);
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: const Text('Terapkan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (applied == true && mounted) {
      setState(() {
        _categoryFilter = selectedCategory;
        _stockFilter = selectedStock;
      });
    }
  }

  Widget _buildProductImage(PosProduct product, {double size = 56}) {
    Widget fallback() => Container(
      width: size,
      height: size,
      color: AppColors.primary.withValues(alpha: 0.08),
      alignment: Alignment.center,
      child: Icon(Icons.inventory_2_outlined, color: AppColors.primary),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: product.imageUrl.trim().isEmpty
          ? fallback()
          : Image.network(
              product.imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback(),
            ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Cari SKU atau nama produk...',
        filled: true,
        fillColor: Colors.white,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildProductTable(List<PosProduct> filteredProducts) {
    final trackStock = _tracksStock(context);
    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Tidak ada produk yang cocok',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                showCheckboxColumn: false,
                headingRowColor: WidgetStatePropertyAll(Colors.grey.shade100),
                columns: [
                  const DataColumn(label: Text('#')),
                  const DataColumn(label: Text('Foto')),
                  const DataColumn(label: Text('SKU')),
                  const DataColumn(label: Text('Produk')),
                  const DataColumn(label: Text('Kategori')),
                  const DataColumn(label: Text('Harga')),
                  if (trackStock) const DataColumn(label: Text('Stok')),
                ],
                rows: filteredProducts
                    .asMap()
                    .entries
                    .map(
                      (entry) => DataRow(
                        onSelectChanged: (_) =>
                            _showProductDetails(context, entry.value, false),
                        cells: [
                          DataCell(Text('${entry.key + 1}')),
                          DataCell(_buildProductImage(entry.value, size: 44)),
                          DataCell(Text(entry.value.code)),
                          DataCell(Text(entry.value.name)),
                          DataCell(Text(entry.value.category)),
                          DataCell(
                            Text('Rp ${entry.value.price.toStringAsFixed(0)}'),
                          ),
                          if (trackStock)
                            DataCell(Text('${entry.value.stock}')),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCards(bool isMobile, List<PosProduct> filteredProducts) {
    final trackStock = _tracksStock(context);
    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Tidak ada produk yang cocok',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (isMobile) {
      return ListView.separated(
        itemCount: filteredProducts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return InkWell(
            onTap: () => _showProductDetails(context, product, true),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.04),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductImage(product, size: 72),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.category,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          trackStock
                              ? 'SKU: ${product.code} • Stok ${product.stock}'
                              : 'SKU: ${product.code}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rp ${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        itemCount: filteredProducts.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: constraints.maxWidth >= 1200 ? 4 : 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          mainAxisExtent: 252,
        ),
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.zero,
            child: InkWell(
              onTap: () => _showProductDetails(context, product, false),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 126,
                    child: product.imageUrl.trim().isEmpty
                        ? Container(
                            color: AppColors.primarySoft,
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              size: 44,
                              color: AppColors.primary,
                            ),
                          )
                        : Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.primarySoft,
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                size: 44,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Rp ${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            trackStock
                                ? '${product.category} • Stok ${product.stock}'
                                : product.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Legacy dialog retained temporarily for compatibility with older routes.
  // ignore: unused_element
  void _showAddProductForm(BuildContext context, bool isMobile) {
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final bloc = context.read<PosProductManagementBloc>();
    final formContent = Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Tambah Produk',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: 'Nama Produk',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: skuCtrl,
            decoration: InputDecoration(
              labelText: 'SKU',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: const [RupiahInputFormatter()],
            decoration: InputDecoration(
              labelText: 'Harga',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_tracksStock(context)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Produk baru dibuat dengan stok 0. Saldo awal atau perubahan stok dicatat melalui menu Stok Toko agar lokasi dan riwayat stok tetap valid.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
                AppToast.error(
                  context,
                  'Mohon isi field yang wajib (Nama dan Harga)',
                );
                return;
              }
              final input = {
                'nama_inventaris': nameCtrl.text,
                if (skuCtrl.text.trim().isNotEmpty) 'sku': skuCtrl.text.trim(),
                'harga_jual': parseRupiah(priceCtrl.text),
                'stok': 0,
                'kategori': 'barang_dagangan',
              };
              bloc.add(CreateProduct(input));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: formContent,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(width: 400, child: formContent),
        ),
      );
    }
  }

  void _showCatalogProductForm(
    BuildContext context,
    bool isMobile, {
    PosProduct? product,
  }) {
    final bloc = context.read<PosProductManagementBloc>();
    final form = _CatalogProductForm(
      product: product,
      repository: bloc.repository,
      onSubmit: (input) async {
        if (product == null) {
          bloc.add(CreateProduct(input));
        } else {
          bloc.add(UpdateProduct(product.id, input));
        }
        final result = await bloc.stream.firstWhere(
          (state) =>
              state.status == PosProductManagementStatus.success ||
              state.status == PosProductManagementStatus.failure,
        );
        return result.status == PosProductManagementStatus.success;
      },
    );
    if (isMobile) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => FractionallySizedBox(heightFactor: .92, child: form),
      );
    } else {
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(width: 720, height: 680, child: form),
        ),
      );
    }
  }

  void _showProductDetails(
    BuildContext context,
    PosProduct product,
    bool isMobile,
  ) {
    final content = Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Kategori: ${product.category}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            _DetailRow('SKU', product.code),
            _DetailRow('Harga', 'Rp ${product.price.toStringAsFixed(0)}'),
            if (_tracksStock(context))
              _DetailRow('Stok Tersedia', '${product.stock}'),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
                if (_canManageProducts(context)) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showCatalogProductForm(
                        context,
                        isMobile,
                        product: product,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Edit Produk'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final bloc = context.read<PosProductManagementBloc>();
                      Navigator.pop(context);
                      _showDeleteConfirmation(context, product, bloc);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Hapus'),
                  ),
                ],
              ],
            ),
            if (!_canManageProducts(context)) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Katalog hanya-baca. Perubahan master produk dilakukan oleh admin Inventory.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => content,
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(width: 400, child: content),
        ),
      );
    }
  }

  // Legacy dialog retained temporarily for compatibility with older routes.
  // ignore: unused_element
  void _showEditProductForm(
    BuildContext context,
    PosProduct product,
    bool isMobile,
  ) {
    final nameCtrl = TextEditingController(text: product.name);
    final skuCtrl = TextEditingController(text: product.code);
    final priceCtrl = TextEditingController(
      text: formatRupiahInput(product.price),
    );

    final formContent = Padding(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Edit Produk',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: 'Nama Produk',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: skuCtrl,
            decoration: InputDecoration(
              labelText: 'SKU',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: const [RupiahInputFormatter()],
            decoration: InputDecoration(
              labelText: 'Harga',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_tracksStock(context)) ...[
            const SizedBox(height: 12),
            InputDecorator(
              decoration: InputDecoration(
                labelText: 'Stok (hanya baca)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                helperText:
                    'Ubah melalui menu Stok Toko agar tercatat dalam riwayat.',
              ),
              child: Text(product.stock.toString()),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
                    AppToast.error(
                      context,
                      'Mohon isi field yang wajib (Nama dan Harga)',
                    );
                    return;
                  }
                  final input = {
                    'nama_inventaris': nameCtrl.text,
                    if (skuCtrl.text.trim().isNotEmpty)
                      'sku': skuCtrl.text.trim(),
                    'harga_jual': parseRupiah(priceCtrl.text),
                  };
                  context.read<PosProductManagementBloc>().add(
                    UpdateProduct(product.id, input),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Simpan'),
              ),
            ],
          ),
        ],
      ),
    );

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: formContent,
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(width: 400, child: formContent),
        ),
      );
    }
  }

  void _showDeleteConfirmation(
    BuildContext context,
    PosProduct product,
    PosProductManagementBloc bloc,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Apakah Anda yakin ingin menghapus produk "${product.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              bloc.add(DeleteProduct(product.id));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _CatalogProductForm extends StatefulWidget {
  final PosProduct? product;
  final PosProductManagementRepository repository;
  final Future<bool> Function(Map<String, dynamic>) onSubmit;

  const _CatalogProductForm({
    required this.product,
    required this.repository,
    required this.onSubmit,
  });

  @override
  State<_CatalogProductForm> createState() => _CatalogProductFormState();
}

class _CatalogProductFormState extends State<_CatalogProductForm> {
  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _price;
  late final TextEditingController _purchasePrice;
  late final TextEditingController _description;
  late final TextEditingController _brand;
  late final TextEditingController _barcode;
  late final TextEditingController _image;
  late final TextEditingController _minimumStock;
  late final TextEditingController _maximumStock;
  late final TextEditingController _reorderPoint;
  late final TextEditingController _baseUnit;
  List<Map<String, dynamic>> _categories = const [];
  List<PosProduct> _packageCandidates = const [];
  // Nullable agar State lama hasil Flutter web hot-reload tetap aman ketika
  // field ini baru ditambahkan. Hot restart akan menginisialisasinya normal.
  List<String>? _unitOptions;
  List<String> get _availableUnitOptions =>
      _unitOptions ?? PosProductManagementRepository.fallbackUnitOptions;
  final Map<String, TextEditingController> _componentQty = {};
  final List<_UnitConversionDraft> _unitConversions = [];
  Uint8List? _pickedImageBytes;
  String _pickedImageName = '';
  bool _uploadingImage = false;
  bool _submitting = false;
  int _formTab = 0;
  String? _categoryId;
  String _productType = 'product';
  bool _loadingCategories = true;
  bool _categoryLoadFailed = false;
  bool _savingCategory = false;
  bool _generatingIdentifiers = false;

  bool get _tracksStock => _productType == 'product';
  bool get _usesUnits => const {'product', 'package'}.contains(_productType);

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name ?? '');
    _sku = TextEditingController(text: product?.sku ?? '');
    _price = TextEditingController(
      text: product == null ? '' : formatRupiahInput(product.price),
    );
    _purchasePrice = TextEditingController(
      text: product == null ? '' : formatRupiahInput(product.purchasePrice),
    );
    _description = TextEditingController(text: product?.description ?? '');
    _brand = TextEditingController(text: product?.brand ?? '');
    _barcode = TextEditingController(text: product?.barcode ?? '');
    _image = TextEditingController(text: product?.imageUrl ?? '');
    _minimumStock = TextEditingController(
      text: product == null ? '' : product.minimumStock.toStringAsFixed(0),
    );
    _maximumStock = TextEditingController(
      text: product == null || product.maximumStock == 0
          ? ''
          : product.maximumStock.toStringAsFixed(0),
    );
    _reorderPoint = TextEditingController(
      text: product == null || product.reorderPoint == 0
          ? ''
          : product.reorderPoint.toStringAsFixed(0),
    );
    _baseUnit = TextEditingController(text: product?.saleUnit ?? 'unit');
    _unitOptions = {
      ...PosProductManagementRepository.fallbackUnitOptions,
      _baseUnit.text.trim().toLowerCase(),
      ...(product?.unitConversions ?? const [])
          .map((row) => row['unit']?.toString().trim().toLowerCase() ?? '')
          .where((value) => value.isNotEmpty),
    }.where((value) => value.isNotEmpty).toList();
    _categoryId = product?.categoryId.isEmpty == true
        ? null
        : product?.categoryId;
    _productType =
        const {
          'product',
          'package',
          'service',
          'deposit',
        }.contains(product?.productType)
        ? product!.productType
        : 'product';
    for (final component in product?.packageComponents ?? const []) {
      final id = component['inventaris_id']?.toString() ?? '';
      if (id.isNotEmpty) {
        _componentQty[id] = TextEditingController(
          text: component['qty_base']?.toString() ?? '1',
        );
      }
    }
    for (final conversion in product?.unitConversions ?? const []) {
      final unit = conversion['unit']?.toString() ?? '';
      final factor =
          double.tryParse(conversion['factor']?.toString() ?? '1') ?? 1;
      if (unit.isNotEmpty &&
          unit.toLowerCase() != product?.saleUnit.toLowerCase()) {
        _unitConversions.add(_UnitConversionDraft(unit: unit, factor: factor));
      }
    }
    _loadCategories();
    _loadPackageCandidates();
    _loadUnitOptions();
    if (product == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refreshIdentifiers();
      });
    }
  }

  Future<void> _refreshIdentifiers() async {
    if (_generatingIdentifiers) return;
    setState(() => _generatingIdentifiers = true);
    final result = await widget.repository.generateProductIdentifiers();
    if (!mounted) return;
    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (values) => setState(() {
        _sku.text = values['sku'] ?? '';
        _barcode.text = values['barcode'] ?? '';
      }),
    );
    if (mounted) setState(() => _generatingIdentifiers = false);
  }

  Future<void> _loadPackageCandidates() async {
    final result = await widget.repository.getPackageCandidates();
    if (!mounted) return;
    result.fold(
      (_) {},
      (items) => setState(() {
        _packageCandidates = items
            .where((item) => item.id != widget.product?.id)
            .toList();
      }),
    );
  }

  Future<void> _loadUnitOptions() async {
    final values = await widget.repository.getUnitOptions();
    if (!mounted) return;
    final legacyValues = <String>[
      _baseUnit.text.trim().toLowerCase(),
      ..._unitConversions.map((row) => row.unit.text.trim().toLowerCase()),
    ].where((value) => value.isNotEmpty);
    setState(() => _unitOptions = {...values, ...legacyValues}.toList());
  }

  Future<void> _scanBarcode() async {
    final value = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const PosBarcodeScannerPage()),
    );
    if (!mounted || value == null || value.trim().isEmpty) return;
    setState(() => _barcode.text = value.trim());
  }

  Future<void> _loadCategories() async {
    if (mounted) {
      setState(() {
        _loadingCategories = true;
        _categoryLoadFailed = false;
      });
    }
    final result = await widget.repository.getCategories();
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _categoryLoadFailed = true),
      (items) => setState(() {
        _categories = items;
        _categoryLoadFailed = false;
      }),
    );
    if (mounted) setState(() => _loadingCategories = false);
  }

  Future<void> _quickAddCategory() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tambah kategori'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama kategori',
            hintText: 'Contoh: Minuman',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(dialogContext, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
    if (name == null || !mounted) return;
    setState(() => _savingCategory = true);
    final result = await widget.repository.createCategory(name);
    if (!mounted) return;
    result.fold((failure) => AppToast.error(context, failure.message), (
      category,
    ) {
      setState(() {
        final categoryId = category['_id']?.toString();
        _categories = [
          ..._categories.where((item) => item['_id']?.toString() != categoryId),
          category,
        ];
        _categoryId = categoryId;
      });
      AppToast.success(context, 'Kategori berhasil ditambahkan');
    });
    if (mounted) setState(() => _savingCategory = false);
  }

  Future<void> _choosePackageComponents() async {
    final selected = Set<String>.from(_componentQty.keys);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('Pilih komponen paket'),
          content: SizedBox(
            width: 520,
            height: 420,
            child: _packageCandidates.isEmpty
                ? const Center(
                    child: Text('Belum ada produk fisik yang dapat dipilih.'),
                  )
                : ListView.builder(
                    itemCount: _packageCandidates.length,
                    itemBuilder: (_, index) {
                      final product = _packageCandidates[index];
                      return CheckboxListTile(
                        value: selected.contains(product.id),
                        title: Text(product.name),
                        subtitle: Text('${product.code} • ${product.saleUnit}'),
                        onChanged: (checked) => setDialogState(() {
                          if (checked == true) {
                            selected.add(product.id);
                          } else {
                            selected.remove(product.id);
                          }
                        }),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selected),
              child: const Text('Terapkan'),
            ),
          ],
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      for (final id
          in _componentQty.keys.where((id) => !result.contains(id)).toList()) {
        _componentQty.remove(id)?.dispose();
      }
      for (final id in result) {
        _componentQty.putIfAbsent(id, () => TextEditingController(text: '1'));
      }
    });
  }

  PosProduct? _candidateById(String id) {
    for (final item in _packageCandidates) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> _pickImage() async {
    try {
      final file = await pickProductImage();
      if (file == null || !mounted) return;
      final extension = file.name.split('.').last.toLowerCase();
      if (!const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        AppToast.error(context, 'Format foto harus JPG, PNG, atau WebP');
        return;
      }
      final bytes = file.bytes;
      if (!mounted) return;
      if (bytes.length > 5 * 1024 * 1024) {
        AppToast.error(context, 'Ukuran foto maksimal 5 MB');
        return;
      }
      if (bytes.isEmpty) {
        AppToast.error(context, 'File gambar tidak dapat dibaca');
        return;
      }
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageName = file.name;
      });
    } catch (error) {
      if (mounted) {
        AppToast.error(context, 'Gagal membuka gambar: $error');
      }
    }
  }

  Future<void> _submit() async {
    if (_submitting || _uploadingImage) return;
    if (_name.text.trim().isEmpty || _price.text.trim().isEmpty) {
      setState(() => _formTab = 0);
      AppToast.error(context, 'Nama dan harga jual wajib diisi');
      return;
    }
    final unit = _baseUnit.text.trim().toLowerCase();
    if (_usesUnits && unit.isEmpty) {
      setState(() => _formTab = 1);
      AppToast.error(context, 'Satuan dasar wajib diisi');
      return;
    }
    final minimumStock =
        double.tryParse(_minimumStock.text.replaceAll(',', '.')) ?? 0;
    final maximumStock =
        double.tryParse(_maximumStock.text.replaceAll(',', '.')) ?? 0;
    final reorderPoint =
        double.tryParse(_reorderPoint.text.replaceAll(',', '.')) ?? 0;
    if (_tracksStock && maximumStock > 0 && maximumStock < minimumStock) {
      setState(() => _formTab = 1);
      AppToast.error(
        context,
        'Stok maksimum tidak boleh di bawah stok minimum',
      );
      return;
    }
    if (_tracksStock && maximumStock > 0 && reorderPoint > maximumStock) {
      setState(() => _formTab = 1);
      AppToast.error(
        context,
        'Titik pemesanan ulang tidak boleh melebihi stok maksimum',
      );
      return;
    }
    final components = _componentQty.entries
        .map(
          (entry) => {
            'inventaris_id': entry.key,
            'qty_base':
                double.tryParse(entry.value.text.replaceAll(',', '.')) ?? 0,
          },
        )
        .toList();
    if (_productType == 'package' &&
        (components.isEmpty ||
            components.any((row) => (row['qty_base'] as double) <= 0))) {
      setState(() => _formTab = 1);
      AppToast.error(
        context,
        'Paket wajib memiliki komponen dengan jumlah yang valid',
      );
      return;
    }
    final sku = _sku.text.trim();
    var imageUrl = _image.text.trim();
    if (_pickedImageBytes != null) {
      setState(() => _uploadingImage = true);
      final upload = await widget.repository.uploadProductImage(
        bytes: _pickedImageBytes!,
        filename: _pickedImageName,
      );
      if (!mounted) return;
      final failed = upload.fold(
        (failure) {
          AppToast.error(context, failure.message);
          return true;
        },
        (url) {
          imageUrl = url;
          return false;
        },
      );
      setState(() => _uploadingImage = false);
      if (failed) return;
    }
    final conversions = <Map<String, dynamic>>[
      if (_usesUnits) {'unit': unit, 'factor': 1.0},
      ..._unitConversions
          .where((row) => row.unit.text.trim().isNotEmpty)
          .map(
            (row) => {
              'unit': row.unit.text.trim().toLowerCase(),
              'factor':
                  double.tryParse(row.factor.text.replaceAll(',', '.')) ?? 0,
            },
          ),
    ];
    if (conversions.any((row) => (row['factor'] as double) <= 0) ||
        conversions.map((row) => row['unit']).toSet().length !=
            conversions.length) {
      setState(() => _formTab = 1);
      AppToast.error(
        context,
        'Konversi satuan harus unik dan bernilai lebih dari 0',
      );
      return;
    }
    setState(() => _submitting = true);
    final saved = await widget.onSubmit({
      'nama_inventaris': _name.text.trim(),
      if (sku.isNotEmpty) 'sku': sku,
      'deskripsi': _description.text.trim(),
      'brand': _brand.text.trim(),
      'harga_beli': parseRupiah(_purchasePrice.text),
      'harga_beli_source': widget.product?.purchasePriceSource == 'avco'
          ? 'avco'
          : 'manual',
      'harga_jual': parseRupiah(_price.text),
      'kategori': 'barang_dagangan',
      'pos_product_type': _productType,
      'sellable_in_pos': true,
      'tracks_stock': _tracksStock,
      'merchandise_category_id': _categoryId,
      'pos_package_components': _productType == 'package'
          ? components
          : const [],
      'base_unit': _usesUnits ? unit : 'unit',
      'unit': _usesUnits ? unit : 'unit',
      'unit_conversions': _usesUnits ? conversions : const [],
      'barcode': _barcode.text.trim(),
      'foto': imageUrl,
      'stok_minimum': _tracksStock ? minimumStock : 0,
      'stok_maksimum': _tracksStock ? maximumStock : 0,
      'titik_reorder': _tracksStock ? reorderPoint : 0,
      if (widget.product == null) 'stok': 0,
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    if (saved) Navigator.pop(context);
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _price.dispose();
    _purchasePrice.dispose();
    _description.dispose();
    _brand.dispose();
    _barcode.dispose();
    _image.dispose();
    _minimumStock.dispose();
    _maximumStock.dispose();
    _reorderPoint.dispose();
    _baseUnit.dispose();
    for (final controller in _componentQty.values) {
      controller.dispose();
    }
    for (final conversion in _unitConversions) {
      conversion.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 650;
    final fields = <Widget>[
      TextField(
        controller: _name,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Nama produk *',
          border: OutlineInputBorder(),
        ),
      ),
      TextField(
        controller: _sku,
        decoration: InputDecoration(
          labelText: 'SKU internal',
          hintText: _generatingIdentifiers
              ? 'Sedang membuat SKU...'
              : 'Dibuat otomatis oleh server',
          helperText:
              'Unik per instansi dan dapat diisi manual bila diperlukan.',
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            tooltip: 'Generate ulang SKU dan barcode',
            onPressed: _generatingIdentifiers ? null : _refreshIdentifiers,
            icon: _generatingIdentifiers
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ),
      ),
      TextField(
        controller: _brand,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Merek',
          hintText: 'Opsional',
          border: OutlineInputBorder(),
        ),
      ),
      TextField(
        controller: _description,
        minLines: 1,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Deskripsi produk',
          hintText: 'Opsional',
          border: OutlineInputBorder(),
        ),
      ),
      TextField(
        controller: _purchasePrice,
        enabled: widget.product?.purchasePriceSource != 'avco',
        keyboardType: TextInputType.number,
        inputFormatters: const [RupiahInputFormatter()],
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: 'Harga beli / HPP',
          prefixText: 'Rp ',
          helperText: widget.product?.purchasePriceSource == 'avco'
              ? 'Dihitung otomatis dari penerimaan barang (AVCO)'
              : 'Digunakan untuk estimasi margin',
          border: const OutlineInputBorder(),
        ),
      ),
      TextField(
        controller: _price,
        keyboardType: TextInputType.number,
        inputFormatters: const [RupiahInputFormatter()],
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          labelText: 'Harga jual *',
          prefixText: 'Rp ',
          border: OutlineInputBorder(),
        ),
      ),
      DropdownButtonFormField<String>(
        initialValue: _productType,
        decoration: const InputDecoration(
          labelText: 'Bentuk penjualan *',
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(
            value: 'product',
            child: Text('Produk fisik (stok sendiri)'),
          ),
          const DropdownMenuItem(
            value: 'package',
            child: Text('Paket / bundel (stok komponen)'),
          ),
          if (widget.product?.productType == 'service')
            const DropdownMenuItem(
              value: 'service',
              child: Text('Jasa lama (tanpa stok)'),
            ),
          if (widget.product?.productType == 'deposit')
            const DropdownMenuItem(
              value: 'deposit',
              child: Text('Deposit lama (tanpa stok)'),
            ),
        ],
        onChanged: (value) => setState(() => _productType = value ?? 'product'),
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue:
                  _categories.any((e) => e['_id']?.toString() == _categoryId)
                  ? _categoryId
                  : null,
              decoration: InputDecoration(
                labelText: 'Kategori barang',
                border: const OutlineInputBorder(),
                suffixIcon: _loadingCategories
                    ? const Center(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _categoryLoadFailed
                    ? IconButton(
                        tooltip: 'Muat ulang kategori',
                        onPressed: _loadCategories,
                        icon: const Icon(Icons.refresh),
                      )
                    : null,
              ),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category['_id']?.toString(),
                      child: Text(category['nama']?.toString() ?? '-'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _categoryId = value),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Tambah kategori cepat',
            onPressed: _savingCategory ? null : _quickAddCategory,
            icon: _savingCategory
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
          ),
        ],
      ),
      if (_productType == 'package')
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: _choosePackageComponents,
              icon: const Icon(Icons.inventory_2_outlined),
              label: Text(
                _componentQty.isEmpty
                    ? 'Pilih komponen paket *'
                    : '${_componentQty.length} komponen dipilih',
              ),
            ),
            const SizedBox(height: 8),
            ..._componentQty.entries.map((entry) {
              final product = _candidateById(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: entry.value,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: product?.name ?? 'Komponen',
                    suffixText: product?.saleUnit ?? 'unit',
                    border: const OutlineInputBorder(),
                  ),
                ),
              );
            }),
          ],
        ),
      if (_usesUnits)
        DropdownButtonFormField<String>(
          initialValue:
              _availableUnitOptions.contains(_baseUnit.text.toLowerCase())
              ? _baseUnit.text.toLowerCase()
              : null,
          decoration: const InputDecoration(
            labelText: 'Satuan dasar *',
            helperText: 'Stok selalu disimpan dalam satuan ini.',
            border: OutlineInputBorder(),
          ),
          items: _availableUnitOptions
              .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
              .toList(),
          onChanged: (value) {
            if (value != null) setState(() => _baseUnit.text = value);
          },
        ),
      if (_usesUnits)
        Column(
          key: const ValueKey('unit-conversions'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Konversi satuan',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(
                    () => _unitConversions.add(
                      _UnitConversionDraft(unit: '', factor: 1),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                ),
              ],
            ),
            const Text(
              'Contoh: 1 dus = 12 pcs. Faktor selalu terhadap satuan dasar.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            ..._unitConversions.asMap().entries.map((entry) {
              final row = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue:
                            _availableUnitOptions.contains(row.unit.text)
                            ? row.unit.text
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Satuan',
                          border: OutlineInputBorder(),
                        ),
                        items: _availableUnitOptions
                            .where((unit) => unit != _baseUnit.text)
                            .map(
                              (unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) row.unit.text = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: row.factor,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Isi satuan dasar',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Hapus konversi',
                      onPressed: () => setState(() {
                        _unitConversions.removeAt(entry.key).dispose();
                      }),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      if (_tracksStock)
        TextField(
          key: const ValueKey('minimum-stock'),
          controller: _minimumStock,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Peringatan stok minimum',
            border: OutlineInputBorder(),
          ),
        ),
      if (_tracksStock)
        TextField(
          key: const ValueKey('reorder-point'),
          controller: _reorderPoint,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Titik pemesanan ulang',
            helperText: 'Saran jumlah stok saat perlu melakukan pembelian',
            border: OutlineInputBorder(),
          ),
        ),
      if (_tracksStock)
        TextField(
          key: const ValueKey('maximum-stock'),
          controller: _maximumStock,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Stok maksimum',
            helperText: 'Opsional, untuk membatasi kelebihan persediaan',
            border: OutlineInputBorder(),
          ),
        ),
      TextField(
        controller: _barcode,
        decoration: InputDecoration(
          labelText: 'Barcode',
          hintText: _generatingIdentifiers
              ? 'Sedang membuat barcode...'
              : 'Scan/isi barcode kemasan atau kosongkan',
          helperText: 'Jika kosong, server membuat barcode internal EAN-13.',
          border: const OutlineInputBorder(),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Generate ulang SKU dan barcode',
                onPressed: _generatingIdentifiers ? null : _refreshIdentifiers,
                icon: _generatingIdentifiers
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              ),
              IconButton(
                tooltip: 'Scan barcode dengan kamera',
                onPressed: _scanBarcode,
                icon: const Icon(Icons.qr_code_scanner),
              ),
            ],
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox.square(
                dimension: 72,
                child: _pickedImageBytes != null
                    ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                    : _image.text.trim().isNotEmpty
                    ? Image.network(
                        _image.text.trim(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.broken_image_outlined),
                      )
                    : const ColoredBox(
                        color: Color(0xFFF2F4F7),
                        child: Icon(Icons.image_outlined),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Foto produk',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'JPG, PNG, atau WebP • maksimal 5 MB',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: _uploadingImage ? null : _pickImage,
                    icon: const Icon(Icons.upload_outlined),
                    label: Text(
                      _pickedImageBytes == null
                          ? 'Pilih gambar'
                          : 'Ganti gambar',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Builder(
        builder: (_) {
          final selling = parseRupiah(_price.text);
          final cost = parseRupiah(_purchasePrice.text);
          final margin = selling <= 0 ? 0 : ((selling - cost) / selling) * 100;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: .35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.trending_up),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Estimasi margin: Rp ${formatRupiahInput(selling - cost)} '
                    '(${margin.toStringAsFixed(1)}%)',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ];
    // Delapan elemen pertama bersifat tetap. Identitas memakai 0..5 dan
    // kategori di indeks 7; tipe produk (6) membuka aturan dinamis sesudahnya.
    // Tiga elemen terakhir selalu barcode, foto, dan ringkasan margin.
    final informationFields = <Widget>[
      ...fields.take(6),
      fields[7],
      ...fields.skip(fields.length - 3),
    ];
    final stockFields = <Widget>[
      fields[6],
      ...fields.skip(8).take(fields.length - 11),
    ];
    final visibleFields = _formTab == 0 ? informationFields : stockFields;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 12, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product == null ? 'Tambah Produk' : 'Edit Produk',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Data transaksi stok, batch, dan kedaluwarsa dicatat saat penerimaan.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                icon: Icon(Icons.info_outline),
                label: Text('Informasi Produk'),
              ),
              ButtonSegment(
                value: 1,
                icon: Icon(Icons.inventory_2_outlined),
                label: Text('Stok & Satuan'),
              ),
            ],
            selected: {_formTab},
            showSelectedIcon: false,
            onSelectionChanged: (value) =>
                setState(() => _formTab = value.first),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              18,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: wide
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 14.0;
                      final availableWidth = constraints.maxWidth;
                      final thresholdWidth = (availableWidth - spacing * 2) / 3;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: visibleFields.map((field) {
                          final key = field.key;
                          final isFullWidth =
                              _formTab == 1 &&
                              key == const ValueKey('unit-conversions');
                          final isThreshold =
                              _formTab == 1 &&
                              {
                                const ValueKey('minimum-stock'),
                                const ValueKey('reorder-point'),
                                const ValueKey('maximum-stock'),
                              }.contains(key);
                          return SizedBox(
                            width: isFullWidth
                                ? availableWidth
                                : isThreshold
                                ? thresholdWidth
                                : 325,
                            child: field,
                          );
                        }).toList(),
                      );
                    },
                  )
                : Column(
                    children: visibleFields
                        .expand((field) => [field, const SizedBox(height: 13)])
                        .toList(),
                  ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _uploadingImage || _submitting ? null : _submit,
                icon: _uploadingImage || _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _uploadingImage
                      ? 'Mengunggah...'
                      : _submitting
                      ? 'Menyimpan...'
                      : 'Simpan produk',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UnitConversionDraft {
  final TextEditingController unit;
  final TextEditingController factor;

  _UnitConversionDraft({required String unit, required double factor})
    : unit = TextEditingController(text: unit),
      factor = TextEditingController(text: factor.toString());

  void dispose() {
    unit.dispose();
    factor.dispose();
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
