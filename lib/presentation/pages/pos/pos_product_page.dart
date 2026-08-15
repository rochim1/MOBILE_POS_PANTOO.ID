import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_product_management/pos_product_management_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_product_management/pos_product_management_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_product_management/pos_product_management_state.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import '../../widgets/app_toast.dart';

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
            context.read<PosBloc>().add(LoadPosData());
          } else if (mgmtState.status == PosProductManagementStatus.failure) {
            AppToast.error(context, mgmtState.errorMessage);
          }
        },
        builder: (context, mgmtState) {
          return BlocBuilder<PosBloc, PosState>(
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
                      child: widget.isGridView
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
                    onPressed: () => _showAddProductForm(context, true),
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
                  onPressed: () => _showAddProductForm(context, false),
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
              if (nameCtrl.text.isEmpty ||
                  skuCtrl.text.isEmpty ||
                  priceCtrl.text.isEmpty) {
                AppToast.error(
                  context,
                  'Mohon isi field yang wajib (Nama, SKU, Harga)',
                );
                return;
              }
              final input = {
                'nama_inventaris': nameCtrl.text,
                'kode_inventaris': skuCtrl.text,
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
                      _showEditProductForm(context, product, isMobile);
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
                  if (nameCtrl.text.isEmpty ||
                      skuCtrl.text.isEmpty ||
                      priceCtrl.text.isEmpty) {
                    AppToast.error(
                      context,
                      'Mohon isi field yang wajib (Nama, SKU, Harga)',
                    );
                    return;
                  }
                  final input = {
                    'nama_inventaris': nameCtrl.text,
                    'kode_inventaris': skuCtrl.text,
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
