import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pos_page.dart';
import 'pos_product_page.dart';
import 'pos_order_page.dart';
import 'pos_more_menu_page.dart';
import 'pos_table_order_page.dart';
import 'pos_table_management_page.dart';
import 'pos_inventory_page.dart';
import 'pos_customer_page.dart';
import 'pos_outlet_page.dart';
import 'pos_shift_page.dart';
import 'pos_return_page.dart';
import 'pos_printer_page.dart';
import 'pos_offline_queue_page.dart';
import 'pos_promo_page.dart';
import 'pos_settings_page.dart';
import 'pos_report_page.dart';
import 'pos_purchase_return_page.dart';
import 'pos_setup_guide_page.dart';
import 'pos_onboarding_page.dart';
import 'widgets/pos_cashier_tour.dart';
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
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_repository.dart';

class PosShellPage extends StatefulWidget {
  final bool prepareDashboard;
  final bool showSetupGuide;

  const PosShellPage({
    super.key,
    this.prepareDashboard = false,
    this.showSetupGuide = false,
  });

  @override
  State<PosShellPage> createState() => _PosShellPageState();
}

class _PosShellPageState extends State<PosShellPage>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  // 0 = expanded, 1 = icons only, 2 = completely hidden.
  int _sidebarMode = 1;
  bool _productGridView = true;
  bool _stockGridView = true;
  bool _historyGridView = false;
  bool _posDataRequested = false;
  bool _showUnlockLoading = false;
  late bool _showSetupGuide;
  bool _setupCompleted = false;
  String _inventoryInitialSection = 'stock';
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final PosCashierTourTargets _cashierTourTargets = PosCashierTourTargets();

  bool get _railExpanded => _sidebarMode == 0;

  static const _destinations = <({String label, IconData icon})>[
    (label: 'Dashboard', icon: Icons.dashboard_outlined),
    (label: 'Kasir', icon: Icons.point_of_sale_outlined),
    (label: 'Katalog Penjualan', icon: Icons.inventory_2_outlined),
    (label: 'Riwayat', icon: Icons.receipt_long_outlined),
    (label: 'Menu', icon: Icons.apps_outlined),
    (label: 'Table Order', icon: Icons.table_restaurant_outlined),
    (label: 'Manajemen Meja', icon: Icons.chair_alt_outlined),
    (label: 'Inventori', icon: Icons.warehouse_outlined),
    (label: 'Promo & Voucher', icon: Icons.discount_outlined),
    (label: 'Pelanggan', icon: Icons.people_outline),
    (label: 'Toko', icon: Icons.storefront_outlined),
    (label: 'Shift Kasir', icon: Icons.schedule_outlined),
    (label: 'Laporan Penjualan', icon: Icons.bar_chart_outlined),
    (label: 'Retur Penjualan', icon: Icons.keyboard_return_outlined),
    (label: 'Pengaturan Printer', icon: Icons.print_outlined),
    (label: 'Antrean & Sinkronisasi', icon: Icons.cloud_sync_outlined),
    (label: 'Retur ke Supplier', icon: Icons.assignment_return_outlined),
    (label: 'Pengaturan POS', icon: Icons.settings_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _showSetupGuide = widget.showSetupGuide;
    _setupCompleted = PosOnboardingPage.isOperationalSetupCompleted(
      sl<SharedPreferences>(),
    );
    if (widget.prepareDashboard) {
      _posDataRequested = true;
      _showUnlockLoading = true;
    }
    WidgetsBinding.instance.addObserver(this);
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (!results.contains(ConnectivityResult.none)) {
        sl<SyncService>().syncOfflineTransactions();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sl<SyncService>().syncOfflineTransactions();
    }
  }

  void _loadPOSAfterUnlock(BuildContext context) {
    if (_posDataRequested) return;
    _posDataRequested = true;
    setState(() => _showUnlockLoading = true);
    context.read<PosBloc>().add(LoadPosData());
    sl<SyncService>().syncOfflineTransactions();
  }

  void _finishUnlockLoading(PosState state) {
    if (!_showUnlockLoading) return;
    final dashboardReady =
        state.status == PosStatus.success && state.dashboardData != null;
    if (dashboardReady || state.status == PosStatus.failure) {
      setState(() => _showUnlockLoading = false);
    }
  }

  Future<void> _completeSetupAndStartCashier() async {
    final prefs = sl<SharedPreferences>();
    setState(() {
      _showSetupGuide = false;
      _selectedIndex = 1;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await showInteractivePosCashierTour(context, _cashierTourTargets);
    await prefs.setBool(PosOnboardingPage.setupPreferenceKey(prefs), true);
    if (!mounted) return;
    setState(() => _setupCompleted = true);
  }

  List<Widget> get _pages => [
    HomePage(
      onNavigate: (index) {
        if (!mounted || index < 0 || index >= _destinations.length) return;
        setState(() => _selectedIndex = index);
      },
    ),
    PosPage(tourTargets: _cashierTourTargets),
    PosProductPage(isGridView: _productGridView),
    PosOrderPage(isGridView: _historyGridView),
    PosMoreMenuPage(
      onNavigate: (index) {
        if (!mounted || index < 0 || index >= _destinations.length) return;
        setState(() => _selectedIndex = index);
      },
    ),
    const PosTableOrderPage(),
    const PosTableManagementPage(),
    PosInventoryPage(
      key: ValueKey('inventory-$_inventoryInitialSection'),
      isGridView: _stockGridView,
      initialSection: _inventoryInitialSection,
    ),
    const PosPromoPage(),
    const PosCustomerPage(),
    const PosOutletPage(),
    const PosShiftPage(),
    const PosReportPage(),
    const PosReturnPage(),
    const PosPrinterPage(),
    const PosOfflineQueuePage(),
    const PosPurchaseReturnPage(),
    const PosSettingsPage(),
  ];

  void _openSetupGuide(BuildContext blocContext) {
    blocContext.read<PosBloc>().add(LoadPosData());
    setState(() => _showSetupGuide = true);
  }

  void _navigateSetupTarget(int index, [String? section]) {
    if (index < 0 || index >= _destinations.length) return;
    setState(() {
      if (index == 7 && section != null) {
        _inventoryInitialSection = section;
      }
      _showSetupGuide = false;
      _selectedIndex = index;
    });
  }

  Future<void> _continueSetup(BuildContext blocContext) async {
    final posBloc = blocContext.read<PosBloc>();
    final lockCubit = blocContext.read<AppLockCubit>();
    posBloc.add(LoadPosData());
    try {
      await posBloc.stream
          .firstWhere(
            (state) =>
                state.status == PosStatus.success ||
                state.status == PosStatus.failure,
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      // Tetap lanjut menggunakan cache terakhir saat jaringan sedang lambat.
    }
    if (!mounted) return;
    final pos = posBloc.state;
    final features = Map<String, dynamic>.from(
      pos.runtimeConfig['features'] as Map? ?? const {},
    );
    final health = Map<String, dynamic>.from(
      pos.runtimeConfig['configuration_health'] as Map? ?? const {},
    );
    final warehouseResult = await sl<PosInventoryRepository>().getWarehouses();
    final warehouses = warehouseResult.fold(
      (_) => <Map<String, dynamic>>[],
      (items) => items,
    );
    if (!mounted) return;
    if (features['track_stock'] != false && warehouses.isEmpty) {
      _navigateSetupTarget(7, 'warehouse');
      return;
    }
    if (!pos.stores.any((store) => store.status.toLowerCase() == 'active')) {
      _navigateSetupTarget(10);
      return;
    }
    if (pos.products.isEmpty) {
      _navigateSetupTarget(2);
      return;
    }
    if (health['valid'] == false) {
      _navigateSetupTarget(17);
      return;
    }
    final stockTrackedProducts = pos.products
        .where((product) => product.tracksStock)
        .toList();
    final hasInitialStock =
        features['track_stock'] == false ||
        stockTrackedProducts.isEmpty ||
        stockTrackedProducts.any((product) => product.stock > 0);
    if (!hasInitialStock) {
      _navigateSetupTarget(7, 'stock');
      return;
    }
    final lock = lockCubit.state;
    final hasPin =
        lock.hasPinConfigured ||
        (lock.activeEmployeeId?.isNotEmpty == true &&
            lock.operatorSessionToken.isNotEmpty);
    if (!hasPin) {
      await lockCubit.lock();
      return;
    }
    if (pos.activeShift == null) {
      _navigateSetupTarget(11);
      return;
    }
    await _completeSetupAndStartCashier();
  }

  Widget _buildShellBody(bool isMobile) {
    if (_showSetupGuide) {
      return PosSetupGuidePage(
        onNavigate: _navigateSetupTarget,
        onStartCashier: _completeSetupAndStartCashier,
      );
    }

    final page = isMobile
        ? _pages[_selectedIndex]
        : Row(
            children: [
              if (_sidebarMode != 2) ...[
                _buildDesktopSidebar(),
                const VerticalDivider(width: 1, thickness: 1),
              ],
              Expanded(child: _pages[_selectedIndex]),
            ],
          );
    if (_setupCompleted) return page;

    return Column(
      children: [
        Expanded(child: page),
        Builder(
          builder: (bannerContext) => Material(
            color: const Color(0xFFFFF7E6),
            child: InkWell(
              onTap: () => _openSetupGuide(bannerContext),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    Icon(Icons.route_outlined, color: Colors.orange.shade800),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Setup POS belum selesai. Simpan langkah ini, lalu kembali ke panduan.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openSetupGuide(bannerContext),
                      child: const Text('Ringkasan'),
                    ),
                    const SizedBox(width: 4),
                    FilledButton.icon(
                      onPressed: () => _continueSetup(bannerContext),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                      label: const Text('Selanjutnya'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;
    final isSmallScreen = width < 600;

    return BlocProvider(
      create: (_) {
        final bloc = sl<PosBloc>();
        if (widget.prepareDashboard) {
          bloc.add(LoadPosData());
          sl<SyncService>().syncOfflineTransactions();
        }
        return bloc;
      },
      child: BlocListener<AppLockCubit, AppLockState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == AppLockStatus.unlocked) {
            final setupCompleted =
                PosOnboardingPage.isOperationalSetupCompleted(
                  sl<SharedPreferences>(),
                );
            if (!setupCompleted) {
              setState(() {
                _setupCompleted = false;
                _showSetupGuide = true;
              });
            }
            _loadPOSAfterUnlock(context);
          } else {
            _posDataRequested = false;
            if (_showUnlockLoading) {
              setState(() => _showUnlockLoading = false);
            }
          }
        },
        child: BlocListener<PosBloc, PosState>(
          listener: (context, state) => _finishUnlockLoading(state),
          child: Stack(
            children: [
              Scaffold(
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
                            setState(
                              () => _sidebarMode = (_sidebarMode + 1) % 3,
                            );
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
                              state.activeShift?['toko']?['nama_toko']
                                  ?.toString() ??
                              (matchingStores.isNotEmpty
                                  ? matchingStores.first.name
                                  : (state.stores.length == 1
                                        ? state.stores.first.name
                                        : 'Belum ada toko aktif'));

                          final activeEmployeeName =
                              lockState.activeEmployeeName;
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
                      tooltip: 'Checklist kesiapan POS',
                      icon: Icon(
                        _showSetupGuide
                            ? Icons.checklist_rounded
                            : Icons.fact_check_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () =>
                          setState(() => _showSetupGuide = !_showSetupGuide),
                    ),
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
                          _historyGridView
                              ? Icons.table_rows
                              : Icons.view_agenda,
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
                body: SafeArea(child: _buildShellBody(isMobile)),
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
                          children: <Widget>[
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildBottomNavItem(
                                      icon: Icons.home_outlined,
                                      selectedIcon: Icons.home,
                                      label: 'Beranda',
                                      index: 0,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildBottomNavItem(
                                      icon: Icons.inventory_2_outlined,
                                      selectedIcon: Icons.inventory_2,
                                      label: 'Katalog',
                                      index: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 72),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _buildBottomNavItem(
                                      icon: Icons.receipt_long_outlined,
                                      selectedIcon: Icons.receipt_long,
                                      label: 'Transaksi',
                                      index: 3,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildBottomNavItem(
                                      icon: Icons.menu_outlined,
                                      selectedIcon: Icons.menu,
                                      label: 'Lainnya',
                                      index: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
              if (_showUnlockLoading)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.white,
                    child: SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 112,
                              height: 112,
                              child: ClipRect(
                                child: Image.asset(
                                  'assets/images/pantoo_loading.gif',
                                  fit: BoxFit.contain,
                                  gaplessPlayback: true,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Mempersiapkan dashboard...',
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                decoration: TextDecoration.none,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Mohon tunggu sebentar',
                              textScaler: TextScaler.noScaling,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Colors.black54,
                                decoration: TextDecoration.none,
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
    final canViewInventory =
        (trackStock && canViewStock) ||
        permissions['view_inventory_purchases'] == true ||
        permissions['view_inventory_opnames'] == true ||
        permissions['view_inventory_transfers'] == true ||
        permissions['view_inventory_scraps'] == true ||
        permissions['view_purchase_returns'] == true;

    return [
      _sidebarSection('POINT OF SALE'),
      if (can('view_dashboard')) _sidebarItem(0),
      if (can('use_cashier')) _sidebarItem(1),
      if (useTables && viewTables) _sidebarItem(5),
      _sidebarSection('MANAJEMEN'),
      if (can('view_products')) _sidebarItem(2),
      if (useTables && manageTables) _sidebarItem(6),
      if (canViewInventory) _sidebarItem(7),
      if (can('view_promos')) _sidebarItem(8),
      if (can('view_customers')) _sidebarItem(9),
      if (can('view_stores')) _sidebarItem(10),
      if (can('view_shifts')) _sidebarItem(11),
      _sidebarSection('LAPORAN'),
      if (can('view_transactions')) _sidebarItem(3),
      if (can('view_reports')) _sidebarItem(12),
      if (can('view_returns')) _sidebarItem(13),
      _sidebarSection('PENGATURAN'),
      if (can('view_settings'))
        _sidebarRouteItem(
          Icons.settings_outlined,
          'Pengaturan Default',
          const PosSettingsPage(),
          menuContext: menuContext,
        ),
      if (can('view_receipt')) _sidebarItem(14),
      _sidebarItem(15),
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
    final isSelected = index == 4
        ? _selectedIndex == 4 || _selectedIndex >= 5
        : _selectedIndex == index;
    final color = isSelected ? AppColors.primary : Colors.black54;
    return MaterialButton(
      minWidth: 0,
      padding: const EdgeInsets.symmetric(horizontal: 2),
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
