import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/auth_cubit.dart';
import 'package:mobile_pos_pantoo/core/network/sync_service.dart';
import 'package:mobile_pos_pantoo/injections.dart';

import '../../common/feature_placeholder_page.dart';
import '../../login/login_page.dart';

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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = (screenWidth * .84).clamp(232.0, 272.0);
    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(14)),
      ),
      child: Column(
        children: [
          // ===== HEADER =====
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const Icon(Icons.storefront, color: Colors.white, size: 26),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        PosText(
                          'Pantoo POS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PosText(
                          'Aplikasi Kasir Online',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: ('Tutup sidebar').tr(context),
                    visualDensity: VisualDensity.compact,
                    iconSize: 21,
                    color: Colors.white,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.chevron_left_rounded),
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
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 9),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: SafeArea(
              top: false,
              child: InkWell(
                onTap: () async {
                  final summary = await sl<SyncService>().getQueueSummary();
                  if (!context.mounted) return;
                  final unresolved =
                      (summary['unresolved'] as num?)?.toInt() ?? 0;
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const PosText('Konfirmasi Keluar'),
                        content: Text(
                          unresolved > 0
                              ? posLocale(dialogContext).pos452e3bc76740((unresolved).toString())
                              : ('Apakah Anda yakin ingin keluar dari aplikasi?').tr(dialogContext),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const PosText(
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
                              backgroundColor: AppColors.danger,
                            ),
                            child: const PosText(
                              'Keluar',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                child: const SizedBox(
                  height: 38,
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AppColors.danger, size: 20),
                      SizedBox(width: 11),
                      PosText(
                        'Keluar',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
    final useKitchenFlow = features['use_kitchen_flow'] == true;
    final viewTables = permissions['view_tables'] == true;
    final trackStock = features['track_stock'] != false;
    final canViewStock =
        permissions['view_stock'] == true ||
        permissions['adjust_stock'] == true;
    final canViewInventory =
        (trackStock && canViewStock) ||
        permissions['view_inventory_purchases'] == true ||
        permissions['view_inventory_opnames'] == true ||
        permissions['view_inventory_transfers'] == true ||
        permissions['view_inventory_scraps'] == true ||
        permissions['view_purchase_returns'] == true;
    final manageTables = permissions['manage_tables'] == true;
    // Fail-safe: menu hanya muncul setelah server memberi izin eksplisit.
    bool can(String key) => permissions[key] == true;
    final inventoryProfile =
        runtimeConfig['inventory_profile']?.toString() ?? 'simple';
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        // ---- Point of Sale ----
        _buildSectionHeader(('POINT OF SALE').tr(context)),
        if (can('view_dashboard'))
          _buildShellItem(Icons.dashboard_outlined, ('Dashboard').tr(context), 0),
        if (can('use_cashier'))
          _buildShellItem(Icons.point_of_sale_outlined, ('Kasir').tr(context), 1),
        if (viewTables || (useTables && manageTables))
          _buildShellItem(
            Icons.restaurant_menu_outlined,
            useTables ? 'Pesanan Aktif & Meja' : 'Pesanan Aktif',
            5,
          ),
        if (useKitchenFlow && viewTables)
          _buildShellItem(Icons.soup_kitchen_outlined, ('Tampilan Dapur').tr(context), 18),

        // ---- Manajemen ----
        _buildSectionHeader('MANAJEMEN'),
        if (can('view_products'))
          _buildShellItem(Icons.inventory_2_outlined, ('Katalog POS').tr(context), 2),
        if (canViewInventory) ...[
          _buildShellItem(Icons.inventory_2_outlined, ('Inventori').tr(context), 7),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 5),
            child: Text(
              posLocale(context).pos647182c03196((_profileLabel(inventoryProfile)).toString()),
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ),
        ],
        if (can('view_promos'))
          _buildShellItem(Icons.discount_outlined, ('Promo & Voucher').tr(context), 8),
        if (can('view_customers'))
          _buildShellItem(Icons.people_outline, ('Pelanggan').tr(context), 9),
        if (can('view_stores'))
          _buildShellItem(Icons.storefront_outlined, ('Toko').tr(context), 10),
        if (can('view_shifts'))
          _buildShellItem(Icons.schedule_outlined, ('Shift Kasir').tr(context), 11),

        // ---- Laporan ----
        _buildSectionHeader('LAPORAN'),
        if (can('view_transactions'))
          _buildShellItem(Icons.receipt_long_outlined, ('Riwayat Transaksi').tr(context), 3),
        if (can('view_reports'))
          _buildShellItem(Icons.bar_chart_outlined, ('Laporan Penjualan').tr(context), 12),
        if (can('view_returns'))
          _buildShellItem(
            Icons.keyboard_return_outlined,
            ('Retur Penjualan').tr(context),
            13,
          ),

        // ---- Pengaturan ----
        _buildSectionHeader('PENGATURAN'),
        if (can('view_settings'))
          _buildShellItem(Icons.settings_outlined, ('Pengaturan POS').tr(context), 17),
        if (can('view_receipt'))
          _buildShellItem(Icons.print_outlined, ('Pengaturan Struk').tr(context), 14),
        _buildShellItem(
          Icons.cloud_sync_outlined,
          ('Antrean Transaksi Offline').tr(context),
          15,
        ),
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
        _buildPlaceholderItem(Icons.dashboard_outlined, ('Dashboard Inventory').tr(context)),
        _buildPlaceholderItem(Icons.shopping_cart_outlined, ('Barang Dagangan').tr(context)),
        _buildPlaceholderItem(Icons.list_alt, ('Semua Inventaris').tr(context)),
        _buildPlaceholderItem(Icons.add_circle_outline, ('Tambah Inventaris').tr(context)),
        _buildPlaceholderItem(Icons.scale_outlined, ('Saldo Awal Persediaan').tr(context)),

        // ---- Stok & Gudang ----
        _buildSectionHeader(('STOK & GUDANG').tr(context)),
        _buildPlaceholderItem(Icons.archive_outlined, ('Stok Saat Ini').tr(context)),
        _buildPlaceholderItem(Icons.compare_arrows, ('Transfer Stok').tr(context)),
        _buildPlaceholderItem(Icons.assignment_outlined, ('Stock Opname').tr(context)),
        _buildPlaceholderItem(Icons.timer_outlined, ('Batch & Kadaluarsa').tr(context)),

        // ---- Pembelian ----
        _buildSectionHeader('PEMBELIAN'),
        _buildPlaceholderItem(Icons.local_shipping_outlined, ('Supplier').tr(context)),
        _buildPlaceholderItem(Icons.shopping_bag_outlined, ('Purchase Order').tr(context)),
        _buildPlaceholderItem(Icons.inbox_outlined, ('Penerimaan Barang').tr(context)),
        _buildPlaceholderItem(Icons.keyboard_return, ('Retur Pembelian').tr(context)),
        _buildPlaceholderItem(Icons.directions_boat_outlined, ('Landed Cost').tr(context)),
        _buildPlaceholderItem(Icons.delete_outline, ('Scrap & Insiden').tr(context)),

        // ---- Kategori Lainnya ----
        _buildSectionHeader(('KATEGORI LAINNYA').tr(context)),
        _buildExpandableItem(Icons.folder_outlined, ('Kategori Inventaris').tr(context), [
          'Aset Tetap',
          'Habis Pakai',
          'Bahan Baku',
          'Barang Dalam Proses',
          'MRO Supplies',
          'Intangible',
        ]),
        _buildExpandableItem(Icons.calculate_outlined, ('Akuntansi Aset').tr(context), [
          'Depresiasi',
        ]),
        _buildPlaceholderItem(Icons.settings_outlined, 'Pengaturan'),

        // ---- Laporan ----
        _buildSectionHeader('LAPORAN'),
        _buildPlaceholderItem(Icons.insert_chart_outlined, ('Laporan Stok').tr(context)),
        _buildPlaceholderItem(Icons.sync_alt, ('Laporan Pergerakan').tr(context)),
        _buildPlaceholderItem(
          Icons.warning_amber_outlined,
          ('Reorder Alert & HPP').tr(context),
        ),
        _buildPlaceholderItem(Icons.show_chart, ('Sales Forecasting').tr(context)),

        // ---- Aset & Kendaraan ----
        _buildSectionHeader(('ASET & KENDARAAN').tr(context)),
        _buildExpandableItem(Icons.directions_car_outlined, 'Kendaraan', [
          'Data Kendaraan',
          'Tambah Kendaraan',
          'Pengaturan Kendaraan',
          'Laporan Kendaraan',
        ]),
        _buildPlaceholderItem(Icons.vpn_key_outlined, ('Sewa Aset').tr(context)),

        // ---- Mitra ----
        _buildSectionHeader('MITRA'),
        _buildExpandableItem(Icons.storefront_outlined, ('Data Mitra').tr(context), [
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
      padding: const EdgeInsets.only(left: 14, top: 10, bottom: 3),
      child: PosText(
        title,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 9.5,
          letterSpacing: 1,
        ),
      ),
    );
  }

  String _profileLabel(String profile) => switch (profile) {
    'centralized' => ('Terpusat').trCurrent(),
    'advanced' => ('Advanced').trCurrent(),
    'custom' => ('Custom').trCurrent(),
    _ => ('Sederhana').trCurrent(),
  };

  /// Item yang berpindah tab di dalam Shell (index 0-4)
  Widget _buildShellItem(IconData icon, String title, int index) {
    final isSelected = widget.selectedIndex == index;
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
      minTileHeight: 40,
      minLeadingWidth: 26,
      horizontalTitleGap: 8,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14),
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : Colors.black87,
        size: 19,
      ),
      title: PosText(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12.5,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFFE6F4F2),
      onTap: () => _closeAndSwitchTab(index),
    );
  }

  /// Item yang membuka FeaturePlaceholderPage (shortcut)
  Widget _buildPlaceholderItem(IconData icon, String title) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: Colors.black87, size: 22),
      title: PosText(
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
      title: PosText(
        title,
        style: const TextStyle(color: Colors.black87, fontSize: 14),
      ),
      childrenPadding: const EdgeInsets.only(left: 24),
      children: subItems.map((subTitle) {
        return ListTile(
          dense: true,
          leading: const Icon(Icons.circle, size: 6, color: Colors.black54),
          title: PosText(
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
