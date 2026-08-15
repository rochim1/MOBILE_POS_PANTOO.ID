import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'pos_page.dart';
import 'pos_product_page.dart';
import 'pos_order_page.dart';
import 'pos_more_menu_page.dart';
import 'pos_table_order_page.dart';
import 'pos_table_management_page.dart';
import 'pos_stock_page.dart';
import 'pos_customer_page.dart';
import 'pos_outlet_page.dart';
import 'pos_shift_page.dart';
import 'pos_return_page.dart';
import 'pos_printer_page.dart';
import 'pos_promo_page.dart';
import 'pos_settings_page.dart';
import 'pos_report_page.dart';
import 'widgets/pos_drawer.dart';
import '../home/home_page.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/auth_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_state.dart';
import 'package:mobile_pos_pantoo/core/network/sync_service.dart';

class PosShellPage extends StatefulWidget {
  const PosShellPage({super.key});

  @override
  State<PosShellPage> createState() => _PosShellPageState();
}

class _PosShellPageState extends State<PosShellPage> {
  int _selectedIndex = 0;
  // 0 = expanded, 1 = icons only, 2 = completely hidden.
  int _sidebarMode = 1;
  bool _productGridView = true;
  bool _stockGridView = true;
  bool _historyGridView = true;
  bool _posDataRequested = false;

  bool get _railExpanded => _sidebarMode == 0;

  static const _destinations = <({String label, IconData icon})>[
    (label: 'Dashboard', icon: Icons.dashboard_outlined),
    (label: 'Kasir', icon: Icons.point_of_sale_outlined),
    (label: 'Produk', icon: Icons.inventory_2_outlined),
    (label: 'Riwayat', icon: Icons.receipt_long_outlined),
    (label: 'Menu', icon: Icons.apps_outlined),
    (label: 'Table Order', icon: Icons.table_restaurant_outlined),
    (label: 'Manajemen Meja', icon: Icons.chair_alt_outlined),
    (label: 'Stok Toko', icon: Icons.warehouse_outlined),
  ];

  @override
  void initState() {
    super.initState();
  }

  void _loadPOSAfterUnlock(BuildContext context) {
    if (_posDataRequested) return;
    _posDataRequested = true;
    context.read<PosBloc>().add(LoadPosData());
    sl<SyncService>().syncOfflineTransactions();
  }

  List<Widget> get _pages => [
    HomePage(
      onNavigate: (index) {
        if (!mounted || index < 0 || index > 7) return;
        setState(() => _selectedIndex = index);
      },
    ),
    const PosPage(),
    PosProductPage(isGridView: _productGridView),
    PosOrderPage(isGridView: _historyGridView),
    const PosMoreMenuPage(),
    const PosTableOrderPage(),
    const PosTableManagementPage(),
    PosStockPage(isGridView: _stockGridView),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;
    final isSmallScreen = width < 600;

    return BlocProvider(
      create: (_) => sl<PosBloc>(),
      child: BlocListener<AppLockCubit, AppLockState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == AppLockStatus.unlocked,
        listener: (context, state) => _loadPOSAfterUnlock(context),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: const Color(0xFFF3F6FB),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: AppColors.primary,
            titleSpacing: 0,
            leading: isMobile
                ? Builder(
                    builder: (context) => IconButton(
                      tooltip: 'Buka menu',
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  )
                : IconButton(
                    tooltip: switch (_sidebarMode) {
                      0 => 'Ringkas sidebar',
                      1 => 'Sembunyikan sidebar',
                      _ => 'Tampilkan sidebar',
                    },
                    icon: Icon(switch (_sidebarMode) {
                      0 => Icons.menu_open,
                      1 => Icons.menu,
                      _ => Icons.keyboard_double_arrow_right,
                    }, color: Colors.white),
                    onPressed: () {
                      setState(() => _sidebarMode = (_sidebarMode + 1) % 3);
                    },
                  ),
            title: BlocBuilder<AppLockCubit, AppLockState>(
              builder: (context, lockState) {
                return BlocBuilder<PosBloc, PosState>(
                  builder: (context, state) {
                    final activeStoreId = state.activeShift?['toko_id']
                        ?.toString();
                    final matchingStores = state.stores.where(
                      (store) => store.id == activeStoreId,
                    );
                    final storeName =
                        state.activeShift?['toko']?['nama_toko']?.toString() ??
                        (matchingStores.isNotEmpty
                            ? matchingStores.first.name
                            : (state.stores.length == 1
                                  ? state.stores.first.name
                                  : 'Belum ada toko aktif'));

                    final activeEmployeeName = lockState.activeEmployeeName;
                    final username =
                        activeEmployeeName ??
                        context.watch<AuthCubit>().state.username ??
                        'Pengguna';
                    final initial = username.isNotEmpty
                        ? username
                              .substring(0, username.length >= 2 ? 2 : 1)
                              .toUpperCase()
                        : 'US';

                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.orange.shade300,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMobile
                                    ? storeName.toString()
                                    : _destinations[_selectedIndex].label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isMobile
                                          ? username
                                          : '$storeName • $username',
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            actions: [
              IconButton(
                tooltip: 'Kunci POS',
                icon: const Icon(Icons.lock_outline, color: Colors.white),
                onPressed: () => context.read<AppLockCubit>().lock(),
              ),
              if (_selectedIndex == 1) ...[
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                  ),
                  offset: const Offset(0, 50),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'notif1',
                      child: Text('Belum ada notifikasi baru'),
                    ),
                  ],
                ),
                BlocBuilder<PosBloc, PosState>(
                  builder: (context, state) {
                    return IconButton(
                      icon: Icon(
                        state.isGridView ? Icons.list : Icons.grid_view,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        context.read<PosBloc>().add(ToggleGridView());
                      },
                    );
                  },
                ),
                if (!isSmallScreen)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 8.0,
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedIndex =
                              3; // Index for Transaksi (PosOrderPage)
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors
                            .teal
                            .shade600, // A darker green for the button
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Daftar Order'),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 16),
                        ],
                      ),
                    ),
                  ),
              ],
              if (_selectedIndex == 2)
                IconButton(
                  tooltip: _productGridView
                      ? 'Tampilkan sebagai tabel'
                      : 'Tampilkan sebagai grid',
                  icon: Icon(
                    _productGridView ? Icons.table_rows : Icons.grid_view,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() => _productGridView = !_productGridView);
                  },
                ),
              if (_selectedIndex == 7)
                IconButton(
                  tooltip: _stockGridView
                      ? 'Tampilkan sebagai tabel'
                      : 'Tampilkan sebagai grid',
                  icon: Icon(
                    _stockGridView ? Icons.table_rows : Icons.grid_view,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() => _stockGridView = !_stockGridView);
                  },
                ),
              if (_selectedIndex == 3)
                IconButton(
                  tooltip: _historyGridView
                      ? 'Tampilkan sebagai tabel'
                      : 'Tampilkan sebagai kartu',
                  icon: Icon(
                    _historyGridView ? Icons.table_rows : Icons.view_agenda,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() => _historyGridView = !_historyGridView);
                  },
                ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: isMobile
              ? PosDrawer(
                  selectedIndex: _selectedIndex,
                  onIndexChanged: (index) {
                    setState(() => _selectedIndex = index);
                  },
                )
              : null,
          body: SafeArea(
            child: isMobile
                ? _pages[_selectedIndex]
                : Row(
                    children: [
                      if (_sidebarMode != 2) ...[
                        _buildDesktopSidebar(),
                        const VerticalDivider(width: 1, thickness: 1),
                      ],
                      Expanded(child: _pages[_selectedIndex]),
                    ],
                  ),
          ),
          floatingActionButton:
              isMobile && MediaQuery.of(context).viewInsets.bottom == 0
              ? FloatingActionButton(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                  child: const Icon(Icons.point_of_sale, size: 28),
                )
              : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: isMobile
              ? BottomAppBar(
                  shape: const CircularNotchedRectangle(),
                  notchMargin: 8.0,
                  color: Colors.white,
                  padding: EdgeInsets.zero,
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBottomNavItem(
                            icon: Icons.home_outlined,
                            selectedIcon: Icons.home,
                            label: 'Beranda',
                            index: 0,
                          ),
                          _buildBottomNavItem(
                            icon: Icons.inventory_2_outlined,
                            selectedIcon: Icons.inventory_2,
                            label: 'Produk',
                            index: 2,
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBottomNavItem(
                            icon: Icons.receipt_long_outlined,
                            selectedIcon: Icons.receipt_long,
                            label: 'Transaksi',
                            index: 3,
                          ),
                          _buildBottomNavItem(
                            icon: Icons.menu_outlined,
                            selectedIcon: Icons.menu,
                            label: 'Lainnya',
                            index: 4,
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: _railExpanded ? 224 : 72,
      color: Colors.white,
      child: ClipRect(
        child: Column(
          children: [
            Container(
              height: 82,
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: _railExpanded ? 18 : 0),
              color: AppColors.primary,
              child: _railExpanded
                  ? const Row(
                      children: [
                        Icon(Icons.store, color: Colors.white, size: 34),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pantoo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Aplikasi Kasir Online',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const Center(
                      child: Icon(Icons.store, color: Colors.white, size: 32),
                    ),
            ),
            Expanded(
              child: BlocBuilder<PosBloc, PosState>(
                buildWhen: (previous, current) =>
                    previous.runtimeConfig != current.runtimeConfig,
                builder: (context, state) => ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: _desktopSidebarItems(context, state.runtimeConfig),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sidebarSection(String label) {
    if (!_railExpanded) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  List<Widget> _desktopSidebarItems(
    BuildContext menuContext,
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
    final viewTables = permissions['view_tables'] == true;
    final manageTables = permissions['manage_tables'] == true;
    final trackStock = features['track_stock'] != false;
    final canViewStock =
        permissions['view_stock'] == true ||
        permissions['adjust_stock'] == true;

    return [
      _sidebarSection('POINT OF SALE'),
      if (can('view_dashboard')) _sidebarItem(0),
      if (can('use_cashier')) _sidebarItem(1),
      if (useTables && viewTables) _sidebarItem(5),
      _sidebarSection('MANAJEMEN'),
      if (can('view_products')) _sidebarItem(2),
      if (useTables && manageTables) _sidebarItem(6),
      if (trackStock && canViewStock) _sidebarItem(7),
      if (can('view_promos'))
        _sidebarRouteItem(
          Icons.discount_outlined,
          'Promo & Voucher',
          const PosPromoPage(),
          menuContext: menuContext,
        ),
      if (can('view_customers'))
        _sidebarRouteItem(
          Icons.people_outline,
          'Pelanggan',
          const PosCustomerPage(),
          menuContext: menuContext,
          needsBloc: true,
        ),
      if (can('view_stores'))
        _sidebarRouteItem(
          Icons.storefront_outlined,
          'Toko',
          const PosOutletPage(),
          menuContext: menuContext,
          needsBloc: true,
        ),
      if (can('view_shifts'))
        _sidebarRouteItem(
          Icons.schedule_outlined,
          'Shift Kasir',
          const PosShiftPage(),
          menuContext: menuContext,
          needsBloc: true,
        ),
      _sidebarItem(4),
      _sidebarSection('LAPORAN'),
      if (can('view_transactions')) _sidebarItem(3),
      if (can('view_reports'))
        _sidebarRouteItem(
          Icons.bar_chart_outlined,
          'Laporan Penjualan',
          const PosReportPage(),
          menuContext: menuContext,
        ),
      if (can('view_returns'))
        _sidebarRouteItem(
          Icons.keyboard_return_outlined,
          'Retur Penjualan',
          const PosReturnPage(),
          menuContext: menuContext,
        ),
      _sidebarSection('PENGATURAN'),
      if (can('view_settings'))
        _sidebarRouteItem(
          Icons.settings_outlined,
          'Pengaturan Default',
          const PosSettingsPage(),
          menuContext: menuContext,
        ),
      if (can('view_receipt'))
        _sidebarRouteItem(
          Icons.print_outlined,
          'Pengaturan Struk',
          const PosPrinterPage(),
          menuContext: menuContext,
          needsBloc: true,
        ),
    ];
  }

  Widget _sidebarRouteItem(
    IconData icon,
    String label,
    Widget page, {
    required BuildContext menuContext,
    bool needsBloc = false,
  }) {
    final item = InkWell(
      onTap: () {
        final posBloc = menuContext.read<PosBloc>();
        Navigator.of(menuContext).push(
          MaterialPageRoute(
            builder: (_) => needsBloc
                ? BlocProvider.value(value: posBloc, child: page)
                : page,
          ),
        );
      },
      child: Container(
        height: 48,
        margin: EdgeInsets.symmetric(
          horizontal: _railExpanded ? 10 : 8,
          vertical: 2,
        ),
        padding: EdgeInsets.symmetric(horizontal: _railExpanded ? 12 : 0),
        child: _railExpanded
            ? Row(
                children: [
                  Icon(icon, size: 22, color: Colors.black54),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              )
            : Center(child: Icon(icon, size: 22, color: Colors.black54)),
      ),
    );
    return _railExpanded ? item : Tooltip(message: label, child: item);
  }

  Widget _sidebarItem(int index) {
    final destination = _destinations[index];
    final selected = _selectedIndex == index;
    final item = InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 48,
        margin: EdgeInsets.symmetric(
          horizontal: _railExpanded ? 10 : 8,
          vertical: 2,
        ),
        padding: EdgeInsets.symmetric(horizontal: _railExpanded ? 12 : 0),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: _railExpanded
            ? Row(
                children: [
                  Icon(
                    destination.icon,
                    size: 22,
                    color: selected ? AppColors.primary : Colors.black54,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? AppColors.primary : Colors.black87,
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Icon(
                  destination.icon,
                  size: 22,
                  color: selected ? AppColors.primary : Colors.black54,
                ),
              ),
      ),
    );
    return _railExpanded
        ? item
        : Tooltip(message: destination.label, child: item);
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppColors.primary : Colors.black54;
    return MaterialButton(
      minWidth: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      onPressed: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSelected ? selectedIcon : icon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
