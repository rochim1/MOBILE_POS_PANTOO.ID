import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/pos/pos_bloc.dart';
import '../../widgets/pos_full_width_tabs.dart';
import 'pos_table_management_page.dart';
import 'pos_table_order_page.dart';

/// Satu pintu UI untuk order dine-in dan master meja. API keduanya tetap
/// terpisah supaya lifecycle transaksi tidak tercampur dengan CRUD meja.
class PosOrderTableHubPage extends StatefulWidget {
  const PosOrderTableHubPage({super.key});

  @override
  State<PosOrderTableHubPage> createState() => _PosOrderTableHubPageState();
}

class _PosOrderTableHubPageState extends State<PosOrderTableHubPage> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final permissions =
        (context.read<PosBloc>().state.runtimeConfig['permissions'] as Map?) ??
        const {};
    final canViewOrders = permissions['view_tables'] == true;
    final canManageTables = permissions['manage_tables'] == true;
    final selectedTab = !canViewOrders
        ? 1
        : !canManageTables
        ? 0
        : _tab;

    if (!canViewOrders && !canManageTables) {
      return const Center(
        child: Text('Anda tidak memiliki akses Order & Meja.'),
      );
    }

    return Column(
      children: [
        PosFullWidthTabs(
          tabs: [
            if (canViewOrders)
              const PosFullWidthTab(
                icon: Icons.receipt_long_outlined,
                label: 'Daftar Order',
              ),
            if (canManageTables)
              const PosFullWidthTab(
                icon: Icons.table_restaurant_outlined,
                label: 'Peta & Pengaturan Meja',
              ),
          ],
          selectedIndex: canViewOrders && canManageTables ? selectedTab : 0,
          onSelected: (index) =>
              setState(() => _tab = canViewOrders ? index : 1),
        ),
        const Divider(height: 1),
        Expanded(
          child: selectedTab == 0
              ? const PosTableOrderPage()
              : const PosTableManagementPage(),
        ),
      ],
    );
  }
}
