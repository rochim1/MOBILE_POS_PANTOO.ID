import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';

import '../../bloc/pos/pos_bloc.dart';
import '../../bloc/pos/pos_state.dart';

/// Tujuan sekunder di mobile. Menu utama tetap berada di navbar bawah.
class PosMoreMenuPage extends StatelessWidget {
  const PosMoreMenuPage({
    super.key,
    required this.onNavigate,
    required this.onLogout,
  });

  final ValueChanged<int> onNavigate;
  final VoidCallback onLogout;

  /// Sama dengan aturan tampil sidebar POS: izin harus diberikan eksplisit.
  static Map<String, List<int>> visibleSections(
    Map<String, dynamic> runtimeConfig,
  ) {
    final features = Map<String, dynamic>.from(
      runtimeConfig['features'] as Map? ?? const {},
    );
    final permissions = Map<String, dynamic>.from(
      runtimeConfig['permissions'] as Map? ?? const {},
    );
    bool can(String key) => permissions[key] == true;
    final useTables = features['use_tables'] == true;
    final useKitchenFlow = features['use_kitchen_flow'] == true;
    final viewTables = can('view_tables');
    final canViewStock = can('view_stock') || can('adjust_stock');
    final canViewInventory =
        (features['track_stock'] != false && canViewStock) ||
        can('view_inventory_purchases') ||
        can('view_inventory_opnames') ||
        can('view_inventory_transfers') ||
        can('view_inventory_scraps') ||
        can('view_purchase_returns');

    return {
      'Operasional': [
        if (viewTables || (useTables && can('manage_tables'))) 5,
        if (useKitchenFlow && viewTables) 18,
        if (can('view_shifts')) 11,
        15, // Antrean offline tetap bisa diperiksa tanpa koneksi/izin server.
      ],
      'Kelola Bisnis': [
        if (canViewInventory) 7,
        if (can('view_promos')) 8,
        if (can('view_customers')) 9,
        if (can('view_stores')) 10,
        if (can('view_returns')) 13,
        if (can('view_purchase_returns')) 16,
      ],
      'Laporan': [if (can('view_reports')) 12],
      'Pengaturan': [if (can('view_settings')) 17, if (can('view_receipt')) 14],
    };
  }

  static const _destinations = <int, _MoreDestination>{
    5: _MoreDestination(
      'Pesanan Aktif & Meja',
      Icons.table_restaurant_outlined,
    ),
    18: _MoreDestination('Tampilan Dapur', Icons.soup_kitchen_outlined),
    11: _MoreDestination('Shift Kasir', Icons.schedule_outlined),
    15: _MoreDestination(
      'Antrean Transaksi Offline',
      Icons.cloud_sync_outlined,
    ),
    7: _MoreDestination('Inventori', Icons.warehouse_outlined),
    8: _MoreDestination('Promo & Voucher', Icons.discount_outlined),
    9: _MoreDestination('Pelanggan', Icons.people_outline),
    10: _MoreDestination('Toko', Icons.storefront_outlined),
    13: _MoreDestination('Retur Penjualan', Icons.keyboard_return_outlined),
    16: _MoreDestination('Retur ke Supplier', Icons.assignment_return_outlined),
    12: _MoreDestination('Laporan Penjualan', Icons.bar_chart_outlined),
    17: _MoreDestination('Pengaturan POS', Icons.settings_outlined),
    14: _MoreDestination('Pengaturan Struk', Icons.print_outlined),
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      buildWhen: (previous, current) =>
          previous.runtimeConfig != current.runtimeConfig,
      builder: (context, state) {
        final sections = visibleSections(state.runtimeConfig);
        return Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                const Text(
                  'Lainnya',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kelola operasional dan pengaturan toko.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                for (final section in sections.entries)
                  if (section.value.isNotEmpty)
                    _MenuSection(
                      title: section.key,
                      children: [
                        for (final index in section.value)
                          _MenuTile(
                            title:
                                index == 5 &&
                                    (state.runtimeConfig['features']
                                            as Map?)?['use_tables'] !=
                                        true
                                ? 'Pesanan Aktif'
                                : _destinations[index]!.title,
                            icon: _destinations[index]!.icon,
                            onTap: () => onNavigate(index),
                          ),
                      ],
                    ),
                _MenuSection(
                  title: 'Akun',
                  children: [
                    _MenuTile(
                      title: 'Keluar',
                      icon: Icons.logout,
                      color: AppColors.danger,
                      onTap: onLogout,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MoreDestination {
  const _MoreDestination(this.title, this.icon);

  final String title;
  final IconData icon;
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
          ),
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, indent: 52, color: Colors.grey.shade200),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.color = AppColors.primary,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color == AppColors.danger
                        ? AppColors.danger
                        : Colors.black87,
                  ),
                ),
              ),
              if (color != AppColors.danger)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.black38,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
