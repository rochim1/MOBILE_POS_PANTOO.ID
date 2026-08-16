import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/auth_cubit.dart';

import '../../common/feature_placeholder_page.dart';
import '../../login/login_page.dart';
import '../pos_settings_page.dart';

class PosDrawer extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;

  const PosDrawer({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
  });

  @override
  State<PosDrawer> createState() => _PosDrawerState();
}

class _PosDrawerState extends State<PosDrawer> {
  /// Tutup drawer lalu push halaman baru, dengan inject PosBloc
  void _closeAndNavigate(Widget page, {bool needsBloc = false}) {
    final posBloc = context.read<PosBloc>();
    Navigator.pop(context); // Tutup drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            needsBloc ? BlocProvider.value(value: posBloc, child: page) : page,
      ),
    );
  }

  /// Tutup drawer lalu switch tab di Shell
  void _closeAndSwitchTab(int index) {
    Navigator.pop(context); // Tutup drawer
    widget.onIndexChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ===== HEADER =====
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const Icon(Icons.store, color: Colors.white, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Pantoo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Aplikasi Kasir Online',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: BlocBuilder<PosBloc, PosState>(
              builder: (context, state) => _buildPosTab(state.runtimeConfig),
            ),
          ),

          // ===== LOGOUT =====
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              top: false,
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('Konfirmasi Keluar'),
                        content: const Text(
                          'Apakah Anda yakin ingin keluar dari aplikasi?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text(
                              'Batal',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final authCubit = context.read<AuthCubit>();
                              Navigator.pop(dialogContext);
                              await authCubit.logout();
                              if (!context.mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text(
                              'Keluar',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 16),
                    Text(
                      'Keluar',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB POS — Sesuai pos-sidebar.vue
  // ==========================================
  Widget _buildPosTab(Map<String, dynamic> runtimeConfig) {
    final features = Map<String, dynamic>.from(
      runtimeConfig['features'] as Map? ?? const {},
    );
    final permissions = Map<String, dynamic>.from(
      runtimeConfig['permissions'] as Map? ?? const {},
    );
    final useTables = features['use_tables'] == true;
    final viewTables = permissions['view_tables'] == true;
    final trackStock = features['track_stock'] != false;
    final canViewStock =
        permissions['view_stock'] == true ||
        permissions['adjust_stock'] == true;
    final manageTables = permissions['manage_tables'] == true;
    // Fail-safe: menu hanya muncul setelah server memberi izin eksplisit.
    bool can(String key) => permissions[key] == true;
    final inventoryProfile =
        runtimeConfig['inventory_profile']?.toString() ?? 'simple';
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // ---- Point of Sale ----
        _buildSectionHeader('POINT OF SALE'),
        if (can('view_dashboard'))
          _buildShellItem(Icons.dashboard_outlined, 'Dashboard', 0),
        if (can('use_cashier'))
          _buildShellItem(Icons.point_of_sale_outlined, 'Kasir', 1),
        if (useTables && viewTables)
          _buildShellItem(Icons.restaurant_menu_outlined, 'Table Order', 5),

        // ---- Manajemen ----
        _buildSectionHeader('MANAJEMEN'),
        if (can('view_products'))
          _buildShellItem(Icons.inventory_2_outlined, 'Katalog POS', 2),
        if (useTables && manageTables)
          _buildShellItem(Icons.table_bar_outlined, 'Manajemen Meja', 6),
        if (trackStock && canViewStock) ...[
          _buildShellItem(Icons.store_outlined, 'Stok Toko', 7),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
            child: Text(
              'Profil inventory: ${_profileLabel(inventoryProfile)}. Pengelolaan gudang, pembelian, transfer, dan opname dilakukan melalui Web Admin.',
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),
        ],
        if (can('view_promos'))
          _buildShellItem(Icons.discount_outlined, 'Promo & Voucher', 8),
        if (can('view_customers'))
          _buildShellItem(Icons.people_outline, 'Pelanggan', 9),
        if (can('view_stores'))
          _buildShellItem(Icons.storefront_outlined, 'Toko', 10),
        if (can('view_shifts'))
          _buildShellItem(Icons.schedule_outlined, 'Shift Kasir', 11),

        // ---- Laporan ----
        _buildSectionHeader('LAPORAN'),
        if (can('view_transactions'))
          _buildShellItem(Icons.receipt_long_outlined, 'Riwayat Transaksi', 3),
        if (can('view_reports'))
          _buildShellItem(Icons.bar_chart_outlined, 'Laporan Penjualan', 12),
        if (can('view_returns'))
          _buildShellItem(
            Icons.keyboard_return_outlined,
            'Retur Penjualan',
            13,
          ),

        // ---- Pengaturan ----
        _buildSectionHeader('PENGATURAN'),
        if (can('view_settings'))
          _buildNavItem(
            Icons.settings_outlined,
            'Pengaturan Default',
            const PosSettingsPage(),
          ),
        if (can('view_receipt'))
          _buildShellItem(Icons.print_outlined, 'Pengaturan Struk', 14),
      ],
    );
  }

  // ==========================================
  // TAB INVENTORY — Sesuai inventory-sidebar.vue
  // ==========================================
  // Dipertahankan sementara sebagai referensi migrasi, tidak ditampilkan agar
  // fitur Inventory yang belum terhubung tidak terlihat sebagai fitur aktif.
  // ignore: unused_element
  Widget _buildInventoryTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // ---- Utama ----
        _buildSectionHeader('UTAMA'),
        _buildPlaceholderItem(Icons.dashboard_outlined, 'Dashboard Inventory'),
        _buildPlaceholderItem(Icons.shopping_cart_outlined, 'Barang Dagangan'),
        _buildPlaceholderItem(Icons.list_alt, 'Semua Inventaris'),
        _buildPlaceholderItem(Icons.add_circle_outline, 'Tambah Inventaris'),
        _buildPlaceholderItem(Icons.scale_outlined, 'Saldo Awal Persediaan'),

        // ---- Stok & Gudang ----
        _buildSectionHeader('STOK & GUDANG'),
        _buildPlaceholderItem(Icons.archive_outlined, 'Stok Saat Ini'),
        _buildPlaceholderItem(Icons.compare_arrows, 'Transfer Stok'),
        _buildPlaceholderItem(Icons.assignment_outlined, 'Stock Opname'),
        _buildPlaceholderItem(Icons.timer_outlined, 'Batch & Kadaluarsa'),
        _buildPlaceholderItem(Icons.business_outlined, 'Gudang'),

        // ---- Pembelian ----
        _buildSectionHeader('PEMBELIAN'),
        _buildPlaceholderItem(Icons.local_shipping_outlined, 'Supplier'),
        _buildPlaceholderItem(Icons.shopping_bag_outlined, 'Purchase Order'),
        _buildPlaceholderItem(Icons.inbox_outlined, 'Penerimaan Barang'),
        _buildPlaceholderItem(Icons.keyboard_return, 'Retur Pembelian'),
        _buildPlaceholderItem(Icons.directions_boat_outlined, 'Landed Cost'),
        _buildPlaceholderItem(Icons.delete_outline, 'Scrap & Insiden'),

        // ---- Kategori Lainnya ----
        _buildSectionHeader('KATEGORI LAINNYA'),
        _buildExpandableItem(Icons.folder_outlined, 'Kategori Inventaris', [
          'Aset Tetap',
          'Habis Pakai',
          'Bahan Baku',
          'Barang Dalam Proses',
          'MRO Supplies',
          'Intangible',
        ]),
        _buildExpandableItem(Icons.calculate_outlined, 'Akuntansi Aset', [
          'Depresiasi',
        ]),
        _buildPlaceholderItem(Icons.settings_outlined, 'Pengaturan'),

        // ---- Laporan ----
        _buildSectionHeader('LAPORAN'),
        _buildPlaceholderItem(Icons.insert_chart_outlined, 'Laporan Stok'),
        _buildPlaceholderItem(Icons.sync_alt, 'Laporan Pergerakan'),
        _buildPlaceholderItem(
          Icons.warning_amber_outlined,
          'Reorder Alert & HPP',
        ),
        _buildPlaceholderItem(Icons.show_chart, 'Sales Forecasting'),

        // ---- Aset & Kendaraan ----
        _buildSectionHeader('ASET & KENDARAAN'),
        _buildExpandableItem(Icons.directions_car_outlined, 'Kendaraan', [
          'Data Kendaraan',
          'Tambah Kendaraan',
          'Pengaturan Kendaraan',
          'Laporan Kendaraan',
        ]),
        _buildPlaceholderItem(Icons.vpn_key_outlined, 'Sewa Aset'),

        // ---- Mitra ----
        _buildSectionHeader('MITRA'),
        _buildExpandableItem(Icons.storefront_outlined, 'Data Mitra', [
          'Data Mitra',
          'Kandidat Mitra',
          'Mitra Non-Aktif',
          'Tambah Mitra',
        ]),
      ],
    );
  }

  // ==========================================
  // WIDGET BUILDERS
  // ==========================================

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  String _profileLabel(String profile) => switch (profile) {
    'centralized' => 'Terpusat',
    'advanced' => 'Advanced',
    'custom' => 'Custom',
    _ => 'Sederhana',
  };

  /// Item yang berpindah tab di dalam Shell (index 0-4)
  Widget _buildShellItem(IconData icon, String title, int index) {
    final isSelected = widget.selectedIndex == index;
    return ListTile(
      dense: true,
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : Colors.black87,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFFE6F7F3),
      onTap: () => _closeAndSwitchTab(index),
    );
  }

  /// Item yang membuka halaman baru via Navigator.push
  Widget _buildNavItem(
    IconData icon,
    String title,
    Widget page, {
    bool needsBloc = false,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.black87, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
      ),
      onTap: () => _closeAndNavigate(page, needsBloc: needsBloc),
    );
  }

  /// Item yang membuka FeaturePlaceholderPage (shortcut)
  Widget _buildPlaceholderItem(IconData icon, String title) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.black87, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
      ),
      onTap: () => _closeAndNavigate(FeaturePlaceholderPage(title: title)),
    );
  }

  /// Item yang bisa di-expand/collapse dengan sub-items
  Widget _buildExpandableItem(
    IconData icon,
    String title,
    List<String> subItems,
  ) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.black87, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
      ),
      childrenPadding: const EdgeInsets.only(left: 24),
      children: subItems.map((subTitle) {
        return ListTile(
          dense: true,
          leading: const Icon(Icons.circle, size: 6, color: Colors.black54),
          title: Text(
            subTitle,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
          onTap: () =>
              _closeAndNavigate(FeaturePlaceholderPage(title: subTitle)),
        );
      }).toList(),
    );
  }
}
