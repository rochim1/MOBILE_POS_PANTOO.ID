import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pos_page.dart';
import 'pos_product_page.dart';
import 'pos_order_page.dart';
import 'pos_more_menu_page.dart';
import 'pos_order_table_hub_page.dart';
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
import 'pos_notification_page.dart';
import 'pos_kitchen_display_page.dart';
import 'widgets/pos_cashier_tour.dart';
import 'widgets/pos_setup_tour.dart';
import 'widgets/pos_drawer.dart';
import 'utils/pos_keyboard_navigation_policy.dart';
import '../home/home_page.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/auth_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_state.dart';
import 'package:mobile_pos_pantoo/core/network/sync_service.dart';
import 'package:mobile_pos_pantoo/core/customer_display/pos_customer_display_service.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_notification_repository.dart';
import '../../widgets/pos_employee_avatar.dart';
import '../../widgets/pos_customer_display_pairing.dart';

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
  int _tableOrdersRefresh = 0;
  // 0 = expanded, 1 = icons only, 2 = completely hidden.
  int _sidebarMode = 1;
  bool _productGridView = true;
  bool _stockGridView = true;
  bool _historyGridView = false;
  bool? _orderTableGridView;
  bool get _useOrderTableGridView => _orderTableGridView ?? true;
  bool _posDataRequested = false;
  bool _showUnlockLoading = false;
  bool _returnToCashierAfterShiftOpen = false;
  late bool _showSetupGuide;
  bool _setupCompleted = false;
  String _inventoryInitialSection = 'stock';
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _offlineSyncTimer;
  final PosCashierTourTargets _cashierTourTargets = PosCashierTourTargets();
  final PosSetupTourTargets _setupTourTargets = PosSetupTourTargets();
  final PosWarehouseTourController _warehouseTourController =
      PosWarehouseTourController();
  final PosSetupActionController _outletTourController =
      PosSetupActionController();
  final PosSetupActionController _productTourController =
      PosSetupActionController();
  final PosSetupActionController _pinManagementTourController =
      PosSetupActionController();
  late final PosBloc _posBloc;
  List<Map<String, dynamic>> _navbarNotifications = const [];
  int _unreadNotifications = 0;
  bool _notificationsLoading = false;
  int _offlineUnresolved = 0;

  bool get _railExpanded => _sidebarMode == 0;

  static const _destinations = <({String label, IconData icon})>[
    (label: 'Dashboard', icon: Icons.dashboard_outlined),
    (label: 'Kasir', icon: Icons.point_of_sale_outlined),
    (label: 'Katalog Penjualan', icon: Icons.inventory_2_outlined),
    (label: 'Riwayat', icon: Icons.receipt_long_outlined),
    (label: 'Menu', icon: Icons.apps_outlined),
    (label: 'Pesanan Aktif & Meja', icon: Icons.table_restaurant_outlined),
    // Alias indeks lama agar deep-link/state tersimpan tetap menuju hub baru.
    (label: 'Pesanan Aktif & Meja', icon: Icons.table_restaurant_outlined),
    (label: 'Inventori', icon: Icons.warehouse_outlined),
    (label: 'Promo & Voucher', icon: Icons.discount_outlined),
    (label: 'Pelanggan', icon: Icons.people_outline),
    (label: 'Toko', icon: Icons.storefront_outlined),
    (label: 'Shift Kasir', icon: Icons.schedule_outlined),
    (label: 'Laporan Penjualan', icon: Icons.bar_chart_outlined),
    (label: 'Retur Penjualan', icon: Icons.keyboard_return_outlined),
    (label: 'Pengaturan Printer', icon: Icons.print_outlined),
    (label: 'Antrean Transaksi Offline', icon: Icons.cloud_sync_outlined),
    (label: 'Retur ke Supplier', icon: Icons.assignment_return_outlined),
    (label: 'Pengaturan POS', icon: Icons.settings_outlined),
    (label: 'Tampilan Dapur', icon: Icons.soup_kitchen_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _posBloc = sl<PosBloc>();
    _showSetupGuide = widget.showSetupGuide;
    _setupCompleted = PosOnboardingPage.isOperationalSetupCompleted(
      sl<SharedPreferences>(),
    );
    if (widget.prepareDashboard) {
      _posDataRequested = true;
      _showUnlockLoading = true;
      _posBloc.add(LoadPosData());
      sl<SyncService>().syncOfflineTransactions();
    }
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadNavbarNotifications();
        _refreshOfflineQueueSummary();
      }
    });
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (!results.contains(ConnectivityResult.none)) {
        sl<SyncService>().syncOfflineTransactions().whenComplete(
          _refreshOfflineQueueSummary,
        );
      }
    });
    // Connectivity dapat tetap berstatus Wi-Fi saat API sedang mati. Polling
    // ringan ini memastikan antrean bergerak lagi tanpa menunggu jaringan
    // berganti atau pengguna membuka ulang aplikasi. Backoff tetap diterapkan
    // oleh SyncService per transaksi.
    _offlineSyncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      sl<SyncService>().syncOfflineTransactions().whenComplete(
        _refreshOfflineQueueSummary,
      );
    });
  }

  Future<void> _refreshOfflineQueueSummary() async {
    final summary = await sl<SyncService>().getQueueSummary();
    if (!mounted) return;
    setState(
      () => _offlineUnresolved = (summary['unresolved'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> _loadNavbarNotifications() async {
    if (_notificationsLoading) return;
    _notificationsLoading = true;
    final result = await sl<PosNotificationRepository>()
        .getOperationalNotifications(limit: 50);
    if (!mounted) return;
    result.fold((_) {}, (data) {
      setState(() {
        _navbarNotifications = data.items;
        _unreadNotifications = data.unreadCount;
      });
    });
    _notificationsLoading = false;
  }

  Future<void> _openNotifications() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PosNotificationPage()));
    if (mounted) _loadNavbarNotifications();
  }

  Future<void> _readNavbarNotification(String id) async {
    if (id.isEmpty) return;
    await sl<PosNotificationRepository>().markAsRead(id);
    if (mounted) _loadNavbarNotifications();
  }

  Widget _notificationButton({bool compact = false}) {
    final availableWidth = MediaQuery.sizeOf(context).width - 24;
    final popupWidth = availableWidth.clamp(240.0, 360.0);
    return PopupMenuButton<String>(
      tooltip: 'Notifikasi',
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 8,
      offset: const Offset(0, 46),
      padding: EdgeInsets.zero,
      iconSize: compact ? 20 : 24,
      constraints: BoxConstraints(
        minWidth: compact ? popupWidth : 320,
        maxWidth: popupWidth,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) {
        if (value == 'all') {
          _openNotifications();
        } else if (value.startsWith('read:')) {
          _readNavbarNotification(value.substring(5));
        }
      },
      icon: Badge(
        isLabelVisible: _unreadNotifications > 0,
        label: Text(
          _unreadNotifications > 99 ? '99+' : '$_unreadNotifications',
        ),
        child: const Icon(Icons.notifications_none, color: Colors.white),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          enabled: false,
          height: 52,
          child: Row(
            children: [
              Icon(Icons.notifications_outlined, color: AppColors.primary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Notifikasi operasional',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              Text(
                'POS & Inventori',
                style: TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        if (_navbarNotifications.isEmpty)
          const PopupMenuItem<String>(
            enabled: false,
            child: Text('Belum ada notifikasi baru'),
          )
        else
          ..._navbarNotifications.take(5).map((item) {
            final id = item['_id']?.toString() ?? '';
            final unread = item['is_read'] != true;
            return PopupMenuItem<String>(
              value: 'read:$id',
              height: 66,
              child: SizedBox(
                width: compact ? popupWidth - 32 : 320,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _notificationIcon(item['module_type']?.toString()),
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']?.toString() ?? 'Notifikasi',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          Text(
                            item['body']?.toString() ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.black54,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'all',
          height: 48,
          child: Center(
            child: Text(
              'Selengkapnya',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _notificationIcon(String? module) => switch (module) {
    'inventory' => Icons.inventory_2_outlined,
    'POS' => Icons.point_of_sale_outlined,
    _ => Icons.notifications_outlined,
  };

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _offlineSyncTimer?.cancel();
    _posBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sl<SyncService>().syncOfflineTransactions().whenComplete(
        _refreshOfflineQueueSummary,
      );
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
      setState(() {
        _showUnlockLoading = false;
        if (dashboardReady && _setupCompleted && !_showSetupGuide) {
          final activeStores = state.stores
              .where((store) => store.status.toLowerCase() == 'active')
              .toList(growable: false);
          if (activeStores.isEmpty) {
            _selectedIndex = 10;
          } else if (state.activeShift == null &&
              state.runtimeConfig['allow_out_of_shift'] != true) {
            _returnToCashierAfterShiftOpen = true;
            _selectedIndex = 11;
          } else {
            _selectedIndex = 1;
          }
        }
      });
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
    await PosOnboardingPage.markOperationalSetupCompleted(prefs);
    if (!mounted) return;
    setState(() => _setupCompleted = true);
  }

  Future<void> _startSetupStepTour(
    int stepNumber,
    String title,
    int? destination,
    String? section,
    List<PosSetupTourStage> stages,
  ) async {
    final targets = switch (stepNumber) {
      1 => [_setupTourTargets.warehouseAdd],
      2 => [_setupTourTargets.outletAdd],
      3 => [_setupTourTargets.productAdd],
      4 => [
        _setupTourTargets.settingsProfile,
        _setupTourTargets.settingsStock,
        _setupTourTargets.settingsSave,
      ],
      5 => [
        _setupTourTargets.stockLocation,
        _setupTourTargets.stockContent,
        _setupTourTargets.stockAdjust,
      ],
      6 => [
        posPinOperatorTourTarget,
        posPinEntryTourTarget,
        posPinSubmitTourTarget,
      ],
      7 => [
        _setupTourTargets.shiftStore,
        _setupTourTargets.shiftForm,
        _setupTourTargets.shiftOpen,
      ],
      _ => [_setupTourTargets.productAdd],
    };
    if (destination != null) {
      _navigateSetupTarget(destination, section);
    }
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    final targetedStages = stages
        .take(targets.length)
        .indexed
        .map((entry) => entry.$2.withTarget(targets[entry.$1]))
        .toList(growable: false);
    if (stepNumber == 1 && targetedStages.isNotEmpty) {
      const first = PosSetupTourStage(
        title: 'Tambah lokasi stok',
        description:
            'Ketuk Tambah Warehouse untuk membuka formulir lokasi penyimpanan pertama.',
      );
      await showInteractivePosSetupTour(
        context,
        fallbackTarget: targets.first,
        stepTitle: 'Langkah $stepNumber · $title',
        totalStageCount: 5,
        stages: [
          first.withTarget(
            targets.first,
            onTargetTap: _warehouseTourController.openGuidedCreate,
          ),
        ],
      );
      return;
    }
    if ((stepNumber == 2 || stepNumber == 3) && targetedStages.isNotEmpty) {
      final action = stepNumber == 2
          ? _outletTourController.run
          : _productTourController.run;
      await showInteractivePosSetupTour(
        context,
        fallbackTarget: targets.first,
        stepTitle: 'Langkah $stepNumber · $title',
        totalStageCount: stepNumber == 3 ? 8 : 4,
        stages: [
          (stepNumber == 3
                  ? const PosSetupTourStage(
                      title: 'Tambah produk baru',
                      description:
                          'Ketuk Tambah Produk untuk membuka formulir dan mulai menyiapkan item yang akan dijual.',
                    )
                  : targetedStages.first)
              .withTarget(targets.first, onTargetTap: action),
        ],
      );
      return;
    }
    if (stepNumber == 6) {
      await showInteractivePosSetupTour(
        context,
        fallbackTarget: _setupTourTargets.pinManage,
        stepTitle: 'Langkah 6 · $title',
        totalStageCount: 4,
        stages: [
          PosSetupTourStage(
            title: 'Buka pengelolaan PIN operator',
            description:
                'Kelola PIN karyawan dari Pengaturan POS tanpa mengunci sesi admin.',
            target: _setupTourTargets.pinManage,
            onTargetTap: _pinManagementTourController.run,
          ),
        ],
      );
      return;
    }
    await showInteractivePosSetupTour(
      context,
      fallbackTarget: targets.first,
      stepTitle: 'Langkah $stepNumber · $title',
      stages: targetedStages,
    );
  }

  List<Widget> get _pages => [
    HomePage(
      onNavigate: (index) {
        if (!mounted || index < 0 || index >= _destinations.length) return;
        setState(() => _selectedIndex = index);
      },
    ),
    PosPage(
      tourTargets: _cashierTourTargets,
      onOpenTableOrders: () => setState(() {
        _tableOrdersRefresh++;
        _selectedIndex = 5;
      }),
    ),
    PosProductPage(
      isGridView: _productGridView,
      setupTourKey: _setupTourTargets.productAdd,
      setupTourTargets: _setupTourTargets,
      tourController: _productTourController,
    ),
    PosOrderPage(isGridView: _historyGridView),
    PosMoreMenuPage(
      onNavigate: (index) {
        if (!mounted || index < 0 || index >= _destinations.length) return;
        setState(() => _selectedIndex = index);
      },
    ),
    PosOrderTableHubPage(
      key: ValueKey('table-orders-$_tableOrdersRefresh'),
      isGridView: _useOrderTableGridView,
      onEditOrder: (order) {
        _posBloc.add(EditActiveOrder(order));
        setState(() => _selectedIndex = 1);
      },
    ),
    PosOrderTableHubPage(
      key: ValueKey('table-orders-legacy-$_tableOrdersRefresh'),
      isGridView: _useOrderTableGridView,
      onEditOrder: (order) {
        _posBloc.add(EditActiveOrder(order));
        setState(() => _selectedIndex = 1);
      },
    ),
    PosInventoryPage(
      key: ValueKey('inventory-$_inventoryInitialSection'),
      isGridView: _stockGridView,
      initialSection: _inventoryInitialSection,
      warehouseTourKey: _setupTourTargets.warehouseAdd,
      stockTourKey: _setupTourTargets.stockLocation,
      setupTourTargets: _setupTourTargets,
      warehouseTourController: _warehouseTourController,
    ),
    const PosPromoPage(),
    const PosCustomerPage(),
    PosOutletPage(
      setupTourKey: _setupTourTargets.outletAdd,
      setupTourTargets: _setupTourTargets,
      tourController: _outletTourController,
    ),
    PosShiftPage(
      storeTourKey: _setupTourTargets.shiftStore,
      formTourKey: _setupTourTargets.shiftForm,
      openTourKey: _setupTourTargets.shiftOpen,
      onShiftOpened: () async {
        _posBloc.add(LoadPosData());
        try {
          await _posBloc.stream
              .firstWhere(
                (state) =>
                    state.status == PosStatus.failure ||
                    (state.status == PosStatus.success &&
                        state.activeShift != null),
              )
              .timeout(const Duration(seconds: 15));
        } on TimeoutException {
          // Shift sudah diterima server; halaman kasir tetap dapat memuat ulang
          // status terbaru ketika jaringan sedang lambat.
        }
        if (!_returnToCashierAfterShiftOpen || !mounted) return;
        setState(() {
          _returnToCashierAfterShiftOpen = false;
          _selectedIndex = 1;
        });
      },
    ),
    const PosReportPage(),
    const PosReturnPage(),
    const PosPrinterPage(),
    const PosOfflineQueuePage(),
    const PosPurchaseReturnPage(),
    PosSettingsPage(
      setupTourKey: _setupTourTargets.settingsSave,
      setupTourTargets: _setupTourTargets,
      pinTourController: _pinManagementTourController,
    ),
    const PosKitchenDisplayPage(),
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
    final sharedReadiness = Map<String, dynamic>.from(
      pos.runtimeConfig['operational_readiness'] as Map? ?? const {},
    );
    if (sharedReadiness.isNotEmpty) {
      switch (sharedReadiness['next_step']?.toString()) {
        case 'warehouse':
          _navigateSetupTarget(7, 'warehouse');
          return;
        case 'store':
          _navigateSetupTarget(10);
          return;
        case 'product':
          _navigateSetupTarget(2);
          return;
        case 'configuration':
          _navigateSetupTarget(17);
          return;
        case 'stock':
          _navigateSetupTarget(7, 'stock');
          return;
        case 'pin':
          await lockCubit.lock();
          return;
        case 'shift':
          _navigateSetupTarget(11);
          return;
        case 'cashier_tour':
          await _completeSetupAndStartCashier();
          return;
      }
    }
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
    if (pos.runtimeConfig['pos_lock_enabled'] != false && !hasPin) {
      await lockCubit.lock();
      return;
    }
    if (pos.activeShift == null &&
        pos.runtimeConfig['allow_out_of_shift'] != true) {
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
        onStartWalkthrough: _startSetupStepTour,
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
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 6 : 9,
                ),
                child: isMobile
                    ? Row(
                        children: [
                          Icon(
                            Icons.route_outlined,
                            color: AppColors.warning,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Setup POS belum selesai',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Lanjutkan setup',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints.tightFor(
                              width: 36,
                              height: 36,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () => _continueSetup(bannerContext),
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 19,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Icon(Icons.route_outlined, color: AppColors.warning),
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
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 17,
                            ),
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

  void _navigateWithKeyboard(int index) {
    if (_showUnlockLoading ||
        context.read<AppLockCubit>().state.status != AppLockStatus.unlocked ||
        ModalRoute.of(context)?.isCurrent != true ||
        FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<EditableText>() !=
            null) {
      return;
    }
    if (!canOpenPosKeyboardDestination(_posBloc.state.runtimeConfig, index)) {
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _showKeyboardHelp() {
    if (context.read<AppLockCubit>().state.status != AppLockStatus.unlocked) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Shortcut keyboard Pantoo POS'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Navigasi: Tab / Shift+Tab untuk berpindah, Enter atau Spasi untuk memilih.',
              ),
              SizedBox(height: 10),
              Text('Alt+1 Dashboard · Alt+2 Kasir · Alt+3 Katalog'),
              Text('Alt+4 Pesanan & Meja · Alt+5 Inventori · Alt+6 Riwayat'),
              SizedBox(height: 10),
              Text(
                'Kasir: F2 cari produk · F3 scan barcode · F4 bayar/simpan meja',
              ),
              Text('F6 keranjang · F7 diskon · F8 simpan pesanan'),
              Text('F9 pesanan tersimpan · F10 pengaturan penjualan'),
              Text('Ctrl+Delete kosongkan keranjang · F1 tampilkan bantuan'),
              SizedBox(height: 10),
              Text(
                'Shortcut halaman hanya tersedia jika operator mempunyai izin. Saat mengetik di formulir, shortcut navigasi tidak dijalankan.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _withKeyboardNavigation(Widget child) => CallbackShortcuts(
    bindings: <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.digit1, alt: true): () =>
          _navigateWithKeyboard(0),
      const SingleActivator(LogicalKeyboardKey.digit2, alt: true): () =>
          _navigateWithKeyboard(1),
      const SingleActivator(LogicalKeyboardKey.digit3, alt: true): () =>
          _navigateWithKeyboard(2),
      const SingleActivator(LogicalKeyboardKey.digit4, alt: true): () =>
          _navigateWithKeyboard(5),
      const SingleActivator(LogicalKeyboardKey.digit5, alt: true): () =>
          _navigateWithKeyboard(7),
      const SingleActivator(LogicalKeyboardKey.digit6, alt: true): () =>
          _navigateWithKeyboard(3),
      const SingleActivator(LogicalKeyboardKey.f1): _showKeyboardHelp,
    },
    child: Focus(autofocus: true, child: child),
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;
    final isSmallScreen = width < 600;

    return BlocProvider.value(
      value: _posBloc,
      child: Builder(
        builder: (_) {
          return BlocListener<AppLockCubit, AppLockState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
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
                _loadNavbarNotifications();
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
                    backgroundColor: const Color(0xFFF7F8FA),
                    appBar: AppBar(
                      elevation: 0,
                      backgroundColor: AppColors.primary,
                      toolbarHeight: isSmallScreen ? 48 : 64,
                      leadingWidth: isSmallScreen ? 44 : 56,
                      iconTheme: IconThemeData(
                        color: Colors.white,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      actionsIconTheme: IconThemeData(
                        color: Colors.white,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      titleSpacing: 0,
                      leading: isMobile
                          ? Builder(
                              builder: (context) => IconButton(
                                tooltip: 'Buka menu',
                                style: isSmallScreen
                                    ? IconButton.styleFrom(
                                        fixedSize: const Size.square(40),
                                        padding: EdgeInsets.zero,
                                      )
                                    : null,
                                icon: const Icon(
                                  Icons.menu,
                                  color: Colors.white,
                                ),
                                onPressed: () =>
                                    Scaffold.of(context).openDrawer(),
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
                              final activeStoreId = state
                                  .activeShift?['toko_id']
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
                              final activeEmployee = lockState.employees
                                  .where(
                                    (employee) =>
                                        employee['_id']?.toString() ==
                                        lockState.activeEmployeeId,
                                  )
                                  .firstOrNull;
                              final username =
                                  activeEmployeeName ??
                                  context.watch<AuthCubit>().state.username ??
                                  'Pengguna';

                              return Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: isMobile ? 8 : 0,
                                    ),
                                    child: PosEmployeeAvatar(
                                      employee: activeEmployee,
                                      radius: isSmallScreen ? 15 : 20,
                                      fallbackColor: AppColors.warningBorder,
                                    ),
                                  ),
                                  SizedBox(width: isMobile ? 4 : 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isMobile
                                              ? storeName.toString()
                                              : _destinations[_selectedIndex]
                                                    .label,
                                          style:
                                              const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ).copyWith(
                                                fontSize: isSmallScreen
                                                    ? 14
                                                    : 18,
                                              ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxWidth: isSmallScreen
                                                  ? 132
                                                  : 320,
                                            ),
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isSmallScreen
                                                    ? 5
                                                    : 6,
                                                vertical: isSmallScreen ? 1 : 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color:
                                                              AppColors.success,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      isMobile
                                                          ? username
                                                          : '$storeName • $username',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: Colors.black87,
                                                        fontSize: isSmallScreen
                                                            ? 9
                                                            : 11,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
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
                        if (width >= 1200)
                          IconButton(
                            tooltip: 'Shortcut keyboard (F1)',
                            icon: const Icon(
                              Icons.keyboard_alt_outlined,
                              color: Colors.white,
                            ),
                            onPressed: _showKeyboardHelp,
                          ),
                        if (!isSmallScreen)
                          ValueListenableBuilder<PosCustomerDisplayState>(
                            valueListenable:
                                sl<PosCustomerDisplayService>().state,
                            builder: (context, displayState, _) => IconButton(
                              tooltip:
                                  displayState.connection ==
                                      PosCustomerDisplayConnection.connected
                                  ? 'Layar pelanggan terhubung'
                                  : 'Hubungkan layar pelanggan',
                              icon: Badge(
                                isLabelVisible:
                                    displayState.connection ==
                                    PosCustomerDisplayConnection.connected,
                                smallSize: 8,
                                backgroundColor: AppColors.success,
                                child: const Icon(
                                  Icons.connected_tv_outlined,
                                  color: Colors.white,
                                ),
                              ),
                              onPressed: () =>
                                  showPosCustomerDisplayPairing(context),
                            ),
                          ),
                        if (!isSmallScreen)
                          Builder(
                            builder: (posBlocContext) => IconButton(
                              tooltip: 'Checklist kesiapan POS',
                              icon: Icon(
                                _showSetupGuide
                                    ? Icons.checklist_rounded
                                    : Icons.fact_check_outlined,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (_showSetupGuide) {
                                  setState(() => _showSetupGuide = false);
                                } else {
                                  _openSetupGuide(posBlocContext);
                                }
                              },
                            ),
                          ),
                        SizedBox(
                          width: isSmallScreen ? 40 : 48,
                          child: _notificationButton(compact: isSmallScreen),
                        ),
                        if (!isSmallScreen)
                          IconButton(
                            tooltip: 'Kunci POS',
                            icon: const Icon(
                              Icons.lock_outline,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                context.read<AppLockCubit>().lock(),
                          )
                        else
                          Builder(
                            builder: (menuContext) => SizedBox(
                              width: 40,
                              child: PopupMenuButton<String>(
                                tooltip: 'Aksi lainnya',
                                padding: EdgeInsets.zero,
                                iconSize: 20,
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                                onSelected: (value) {
                                  if (value == 'setup') {
                                    if (_showSetupGuide) {
                                      setState(() => _showSetupGuide = false);
                                    } else {
                                      _openSetupGuide(menuContext);
                                    }
                                  } else if (value == 'lock') {
                                    menuContext.read<AppLockCubit>().lock();
                                  } else if (value == 'customer_display') {
                                    showPosCustomerDisplayPairing(menuContext);
                                  } else if (value == 'keyboard_help') {
                                    _showKeyboardHelp();
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'keyboard_help',
                                    child: ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        Icons.keyboard_alt_outlined,
                                      ),
                                      title: Text('Shortcut keyboard'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'setup',
                                    child: ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(Icons.fact_check_outlined),
                                      title: Text('Checklist kesiapan'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'customer_display',
                                    child: ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        Icons.connected_tv_outlined,
                                      ),
                                      title: Text('Layar pelanggan'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'lock',
                                    child: ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(Icons.lock_outline),
                                      title: Text('Kunci POS'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_selectedIndex == 1) ...[
                          BlocBuilder<PosBloc, PosState>(
                            builder: (context, state) {
                              return IconButton(
                                style: isSmallScreen
                                    ? IconButton.styleFrom(
                                        fixedSize: const Size.square(40),
                                        padding: EdgeInsets.zero,
                                      )
                                    : null,
                                icon: Icon(
                                  state.isGridView
                                      ? Icons.list
                                      : Icons.grid_view,
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
                            style: isSmallScreen
                                ? IconButton.styleFrom(
                                    fixedSize: const Size.square(40),
                                    padding: EdgeInsets.zero,
                                  )
                                : null,
                            tooltip: _productGridView
                                ? 'Tampilkan sebagai tabel'
                                : 'Tampilkan sebagai grid',
                            icon: Icon(
                              _productGridView
                                  ? Icons.table_rows
                                  : Icons.grid_view,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(
                                () => _productGridView = !_productGridView,
                              );
                            },
                          ),
                        if (_selectedIndex == 7)
                          IconButton(
                            style: isSmallScreen
                                ? IconButton.styleFrom(
                                    fixedSize: const Size.square(40),
                                    padding: EdgeInsets.zero,
                                  )
                                : null,
                            tooltip: _stockGridView
                                ? 'Tampilkan sebagai tabel'
                                : 'Tampilkan sebagai grid',
                            icon: Icon(
                              _stockGridView
                                  ? Icons.table_rows
                                  : Icons.grid_view,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(() => _stockGridView = !_stockGridView);
                            },
                          ),
                        if (_selectedIndex == 3)
                          IconButton(
                            style: isSmallScreen
                                ? IconButton.styleFrom(
                                    fixedSize: const Size.square(40),
                                    padding: EdgeInsets.zero,
                                  )
                                : null,
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
                              setState(
                                () => _historyGridView = !_historyGridView,
                              );
                            },
                          ),
                        if (_selectedIndex == 5 || _selectedIndex == 6)
                          IconButton(
                            style: isSmallScreen
                                ? IconButton.styleFrom(
                                    fixedSize: const Size.square(40),
                                    padding: EdgeInsets.zero,
                                  )
                                : null,
                            tooltip: _useOrderTableGridView
                                ? 'Tampilkan sebagai list'
                                : 'Tampilkan sebagai grid',
                            icon: Icon(
                              _useOrderTableGridView
                                  ? Icons.view_list_rounded
                                  : Icons.grid_view_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              setState(
                                () => _orderTableGridView =
                                    !_useOrderTableGridView,
                              );
                            },
                          ),
                        SizedBox(width: isSmallScreen ? 2 : 8),
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
                          ? Theme(
                              data: Theme.of(context).copyWith(
                                visualDensity: const VisualDensity(
                                  horizontal: -2,
                                  vertical: -2,
                                ),
                              ),
                              child: _withKeyboardNavigation(
                                _buildShellBody(isMobile),
                              ),
                            )
                          : _withKeyboardNavigation(_buildShellBody(isMobile)),
                    ),
                    floatingActionButton:
                        isMobile &&
                            MediaQuery.of(context).viewInsets.bottom == 0
                        ? FloatingActionButton.small(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 4,
                            onPressed: () {
                              setState(() {
                                _selectedIndex = 1;
                              });
                            },
                            child: const Icon(Icons.point_of_sale, size: 22),
                          )
                        : null,
                    floatingActionButtonLocation:
                        FloatingActionButtonLocation.centerDocked,
                    bottomNavigationBar: isMobile
                        ? BottomAppBar(
                            shape: const CircularNotchedRectangle(),
                            notchMargin: 6.0,
                            color: Colors.white,
                            padding: EdgeInsets.zero,
                            height: 52,
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
                                const SizedBox(width: 56),
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
          );
        },
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
    final useKitchenFlow = features['use_kitchen_flow'] == true;
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
      // Order dan manajemen meja sudah dilebur dalam satu workspace. Tampilkan
      // satu menu bila pengguna memiliki salah satu hak akses terkait.
      if (useTables && (viewTables || manageTables)) _sidebarItem(5),
      if (useKitchenFlow && viewTables) _sidebarItem(18),
      _sidebarSection('MANAJEMEN'),
      if (can('view_products')) _sidebarItem(2),
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
      if (can('view_settings')) _sidebarItem(17),
      if (can('view_receipt')) _sidebarItem(14),
      _sidebarItem(15),
      _sidebarSection('BANTUAN'),
      if (_railExpanded)
        ListTile(
          dense: true,
          leading: const Icon(Icons.keyboard_alt_outlined),
          title: const Text('Shortcut keyboard'),
          subtitle: const Text('F1 untuk melihat panduan'),
          onTap: _showKeyboardHelp,
        )
      else
        Tooltip(
          message: 'Shortcut keyboard (F1)',
          child: IconButton(
            onPressed: _showKeyboardHelp,
            icon: const Icon(Icons.keyboard_alt_outlined),
          ),
        ),
    ];
  }

  Widget _sidebarItem(int index) {
    final destination = _destinations[index];
    final selected = _selectedIndex == index;
    final item = InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      focusColor: AppColors.primary.withValues(alpha: 0.24),
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
                  _sidebarIcon(destination, selected, index),
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
                  if (index == 15 && _offlineUnresolved > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _offlineUnresolved > 99 ? '99+' : '$_offlineUnresolved',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              )
            : Center(child: _sidebarIcon(destination, selected, index)),
      ),
    );
    return _railExpanded
        ? item
        : Tooltip(message: destination.label, child: item);
  }

  Widget _sidebarIcon(
    ({String label, IconData icon}) destination,
    bool selected,
    int index,
  ) {
    final icon = Icon(
      destination.icon,
      size: 22,
      color: selected ? AppColors.primary : Colors.black54,
    );
    if (index != 15 || _offlineUnresolved == 0) return icon;
    return Badge(
      label: Text(_offlineUnresolved > 99 ? '99+' : '$_offlineUnresolved'),
      child: icon,
    );
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
          Icon(isSelected ? selectedIcon : icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
