import 'package:mobile_pos_pantoo/core/subscription/pos_subscription_service.dart';
import 'pos_subscription_page.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import '../../../core/notifications/pos_push_service.dart';
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/repositories/pos_repository.dart';
import 'pos_page.dart';
import 'pos_product_page.dart';
import '../../../domain/models/pos_product.dart';
import 'pos_order_page.dart';
import 'pos_more_menu_page.dart';
import 'pos_order_table_hub_page.dart';
import 'pos_inventory_page.dart';
import 'pos_customer_page.dart';
import 'pos_outlet_page.dart';
import 'pos_shift_page.dart';
import 'pos_return_page.dart';
import 'pos_trade_workspace_page.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
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
import 'widgets/pos_cashier_entry_button.dart';
import 'widgets/pos_navbar_context_actions.dart';
import 'utils/pos_navbar_action_policy.dart';
import 'widgets/pos_setup_suggestion.dart';
import 'widgets/pos_setup_tour.dart';
import 'widgets/pos_first_sale_guide.dart';
import 'utils/pos_keyboard_navigation_policy.dart';
import 'utils/pos_mobile_navigation_policy.dart';
import 'utils/pos_order_workspace_policy.dart';
import '../login/login_page.dart';
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
  final bool prepareSalesData;
  final bool showSetupGuide;

  const PosShellPage({
    super.key,
    this.prepareSalesData = false,
    this.showSetupGuide = false,
  });

  @override
  State<PosShellPage> createState() => _PosShellPageState();
}

class _PosShellPageState extends State<PosShellPage>
    with WidgetsBindingObserver {
  int _selectedIndex = 1;
  // Asal halaman sekunder untuk tombol kembali di mobile.
  int _secondaryOriginIndex = 1;
  int _tableOrdersRefresh = 0;
  // 0 = expanded, 1 = icons only, 2 = completely hidden.
  int _sidebarMode = 1;
  bool _productGridView = true;
  bool _stockGridView = true;
  bool? _historyGridView;
  bool get _useHistoryGridView =>
      _historyGridView ?? MediaQuery.sizeOf(context).width < 600;
  bool? _orderTableGridView;
  bool get _useOrderTableGridView => _orderTableGridView ?? true;
  bool _posDataRequested = false;
  bool _showUnlockLoading = false;
  bool _returnToCashierAfterShiftOpen = false;
  late bool _showSetupGuide;
  bool _setupCompleted = false;
  String _inventoryInitialSection = 'stock';
  String? _openingProductId;
  bool _advancingFirstSale = false;
  String? _inventoryActiveSection = 'stock';
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
    // Reserved legacy index; dashboard is no longer a destination.
    (label: 'Kasir', icon: Icons.point_of_sale_outlined),
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
    (label: 'Laporan', icon: Icons.bar_chart_outlined),
    (label: 'Retur Penjualan', icon: Icons.keyboard_return_outlined),
    (label: 'Pengaturan Printer', icon: Icons.print_outlined),
    (label: 'Antrean Transaksi Offline', icon: Icons.cloud_sync_outlined),
    (label: 'Retur ke Supplier', icon: Icons.assignment_return_outlined),
    (label: 'Pengaturan POS', icon: Icons.settings_outlined),
    (label: 'Tampilan Dapur', icon: Icons.soup_kitchen_outlined),
    (label: 'Utang & Piutang', icon: Icons.account_balance_wallet_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _posBloc = sl<PosBloc>();
    _showSetupGuide = widget.showSetupGuide;
    _setupCompleted = PosOnboardingPage.isOperationalSetupCompleted(
      sl<SharedPreferences>(),
    );
    if (widget.prepareSalesData) {
      _posDataRequested = true;
      _showUnlockLoading = true;
      _posBloc.add(LoadPosData());
      sl<SyncService>().syncOfflineTransactions();
    }
    WidgetsBinding.instance.addObserver(this);
    if (sl.isRegistered<PosSubscriptionService>()) {
      sl<PosSubscriptionService>().recovered.addListener(
        _subscriptionRecovered,
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (context.read<AppLockCubit>().state.status ==
            AppLockStatus.unlocked) {
          _loadPOSAfterUnlock();
        }
        _loadNavbarNotifications();
        if (sl.isRegistered<PosPushService>()) {
          unawaited(sl<PosPushService>().activate());
        }
        _refreshOfflineQueueSummary();
        unawaited(sl<PosRepository>().syncPendingFavoriteProductIds());
      }
    });
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      if (!results.contains(ConnectivityResult.none)) {
        if (sl.isRegistered<PosPushService>()) {
          unawaited(sl<PosPushService>().activate());
        }
        sl<SyncService>().syncOfflineTransactions().whenComplete(
          _refreshOfflineQueueSummary,
        );
        unawaited(sl<PosRepository>().syncPendingFavoriteProductIds());
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
      unawaited(sl<PosRepository>().syncPendingFavoriteProductIds());
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
      tooltip: ('Notifikasi').tr(context),
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
                child: PosText(
                  'Notifikasi operasional',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              PosText(
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
            child: PosText('Belum ada notifikasi baru'),
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
                            item['title']?.toString() ??
                                ('Notifikasi').tr(context),
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
            child: PosText(
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
    if (sl.isRegistered<PosSubscriptionService>()) {
      sl<PosSubscriptionService>().recovered.removeListener(
        _subscriptionRecovered,
      );
    }
    _posBloc.close();
    super.dispose();
  }

  void _subscriptionRecovered() {
    if (!mounted || _posBloc.isClosed) return;
    _posBloc.add(const RefreshPosAccess(refreshProducts: true));
    sl<SyncService>()
        .syncOfflineTransactions(force: true)
        .whenComplete(_refreshOfflineQueueSummary);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sl<SyncService>().syncOfflineTransactions().whenComplete(
        _refreshOfflineQueueSummary,
      );
    }
  }

  void _loadPOSAfterUnlock() {
    if (_posDataRequested) return;
    _posDataRequested = true;
    setState(() => _showUnlockLoading = true);
    _posBloc.add(LoadPosData());
    sl<SyncService>().syncOfflineTransactions();
  }

  void _finishUnlockLoading(PosState state) {
    if (!_showUnlockLoading) return;
    // Wait for verified permissions, stores and catalog, without loading sales statistics.
    final salesReady = state.status == PosStatus.success;
    if (salesReady || state.status == PosStatus.failure) {
      setState(() {
        _showUnlockLoading = false;
        if (salesReady && !_showSetupGuide) {
          final activeStores = state.stores
              .where((store) => store.status.toLowerCase() == 'active')
              .toList(growable: false);
          _selectedIndex = mobilePosUnlockDestination(
            state.runtimeConfig,
            hasStore: activeStores.isNotEmpty,
            hasShift: state.activeShift != null,
            offline: state.runtimeConfig['_offline_snapshot'] == true,
          );
          if (mobilePosFirstSaleDestination(state.runtimeConfig) == 7) {
            _inventoryInitialSection = 'opening';
            _inventoryActiveSection = 'opening';
          }
          _secondaryOriginIndex = _mobilePrimaryIndex;
          _returnToCashierAfterShiftOpen = _selectedIndex == 11;
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
                  ? PosSetupTourStage(
                      title: ('Tambah produk baru').tr(context),
                      description:
                          ('Ketuk Tambah Produk untuk membuka formulir dan mulai menyiapkan item yang akan dijual.')
                              .tr(context),
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
            title: ('Buka pengelolaan PIN operator').tr(context),
            description:
                ('Kelola PIN karyawan dari Pengaturan POS tanpa mengunci sesi admin.')
                    .tr(context),
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
    // Keep legacy page indices stable for setup links and secondary destinations.
    const PosPage(),
    PosPage(
      tourTargets: _cashierTourTargets,
      onManageProducts: () => _navigateSetupTarget(2),
      onOpenTableOrders: () => setState(() {
        _tableOrdersRefresh++;
        _secondaryOriginIndex = 1;
        _selectedIndex = 5;
      }),
    ),
    PosProductPage(
      isGridView: _productGridView,
      onProductCreated: _afterFirstProduct,
      setupTourKey: _setupTourTargets.productAdd,
      setupTourTargets: _setupTourTargets,
      tourController: _productTourController,
    ),
    PosOrderPage(isGridView: _useHistoryGridView),
    PosMoreMenuPage(
      onNavigate: _openMoreDestination,
      onLogout: _confirmLogout,
      onOpenSetupGuide: () => _openSetupGuide(context),
      setupSuggestion: _setupCompleted
          ? null
          : PosSetupSuggestion(
              preferences: sl<SharedPreferences>(),
              onOpenGuide: () => _openSetupGuide(context),
            ),
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
      openingProductId: _openingProductId,
      onOpeningStockSaved: _advanceFirstSale,
      onActiveSectionChanged: (section) {
        if (mounted && _inventoryActiveSection != section) {
          setState(() => _inventoryActiveSection = section);
        }
      },
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
      onShiftClosed: () => _posBloc.add(LoadPosData()),
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
    PosReturnPage(
      permissions: Map<String, dynamic>.from(
        _posBloc.state.runtimeConfig['permissions'] as Map? ?? const {},
      ),
    ),
    const PosPrinterPage(),
    PosOfflineQueuePage(
      allowSync:
          !sl.isRegistered<PosSubscriptionService>() ||
          sl<PosSubscriptionService>().canSell,
    ),
    const PosPurchaseReturnPage(),
    PosSettingsPage(
      setupTourKey: _setupTourTargets.settingsSave,
      setupTourTargets: _setupTourTargets,
      pinTourController: _pinManagementTourController,
    ),
    const PosKitchenDisplayPage(),
    if (_posBloc.state.runtimeConfig['permissions']?['view_receivables'] ==
            true ||
        _posBloc.state.runtimeConfig['permissions']?['view_payables'] == true)
      PosTradeWorkspacePage(
        key: ValueKey((
          'trade',
          context.read<AppLockCubit>().state.activeEmployeeId,
          _posBloc.state.runtimeConfig['instansi_id'],
          _posBloc.state.runtimeConfig['permissions'],
          sl<GraphQLClientProvider>().client,
        )),
        operatorId: context.read<AppLockCubit>().state.activeEmployeeId ?? '',
      )
    else
      Center(child: Text(posLocale(context).tradeNoAccess)),
  ];

  void _openMoreDestination(int index) {
    if (!mounted || index < 0 || index >= _destinations.length) return;
    final visible = PosMoreMenuPage.visibleSections(
      _posBloc.state.runtimeConfig,
    ).values.any((items) => items.contains(index));
    if (!visible) return;
    setState(() {
      _secondaryOriginIndex = 4;
      _selectedIndex = index;
    });
  }

  int get _mobilePrimaryIndex =>
      (_posBloc.state.runtimeConfig['permissions'] as Map?)?['use_cashier'] ==
          true
      ? 1
      : 4;

  void _openCashierWorkspace() {
    if (_mobilePrimaryIndex != 1) return;
    setState(() {
      _showSetupGuide = false;
      _selectedIndex = 1;
    });
  }

  void _backWithinMobileShell() {
    final destination = mobilePosBackDestination(
      _selectedIndex,
      _secondaryOriginIndex,
      primaryIndex: _mobilePrimaryIndex,
    );
    if (destination == null) return;
    setState(() => _selectedIndex = destination);
  }

  Future<int?> _unresolvedQueueForLogout() async {
    try {
      final summary = await sl<SyncService>().getQueueSummary().timeout(
        const Duration(seconds: 3),
      );
      return (summary['unresolved'] as num?)?.toInt() ?? 0;
    } catch (_) {
      // Pemeriksaan gagal: jangan mengklaim tidak ada transaksi tertunda.
      return null;
    }
  }

  Future<void> _confirmLogout() async {
    final queueCheck = _unresolvedQueueForLogout();
    var loggingOut = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => FutureBuilder<int?>(
          future: queueCheck,
          builder: (dialogContext, snapshot) {
            final checking = snapshot.connectionState != ConnectionState.done;
            final unresolved = snapshot.data;
            return AlertDialog(
              title: const PosText('Konfirmasi Keluar'),
              content: checking
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Flexible(
                          child: PosText('Memeriksa antrean offline...'),
                        ),
                      ],
                    )
                  : Text(
                      unresolved == null
                          ? ('Antrean transaksi offline tidak dapat diperiksa. Data yang tersimpan di perangkat akan disinkronkan setelah akun ini login kembali. Yakin ingin keluar?')
                                .tr(dialogContext)
                          : unresolved > 0
                          ? posLocale(
                              dialogContext,
                            ).pos452e3bc76740((unresolved).toString())
                          : ('Apakah Anda yakin ingin keluar dari aplikasi?')
                                .tr(dialogContext),
                    ),
              actions: [
                TextButton(
                  onPressed: loggingOut
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const PosText('Batal'),
                ),
                FilledButton(
                  onPressed: checking || loggingOut
                      ? null
                      : () async {
                          setDialogState(() => loggingOut = true);
                          try {
                            await context.read<AuthCubit>().logout();
                          } catch (_) {
                            if (!dialogContext.mounted) return;
                            setDialogState(() => loggingOut = false);
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: PosText(
                                  'Gagal keluar dengan aman. Coba lagi.',
                                ),
                              ),
                            );
                            return;
                          }
                          if (!mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger,
                  ),
                  child: loggingOut
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const PosText('Keluar'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openSetupGuide(BuildContext blocContext) {
    _posBloc.add(LoadPosData());
    setState(() => _showSetupGuide = true);
  }

  void _navigateSetupTarget(int index, [String? section]) {
    if (index < 0 || index >= _destinations.length) return;
    setState(() {
      if (index >= 5) {
        _secondaryOriginIndex = _selectedIndex >= 5
            ? _secondaryOriginIndex
            : _selectedIndex;
      }
      if (index == 7 && section != null) {
        _inventoryInitialSection = section;
        _inventoryActiveSection = section;
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
          _navigateSetupTarget(7, 'opening');
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
      _navigateSetupTarget(7, 'opening');
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
    if (!sl.isRegistered<PosSubscriptionService>()) {
      return _buildSubscriptionShellBody(isMobile);
    }
    final service = sl<PosSubscriptionService>();
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        if (service.required &&
            !service.canSell &&
            !const {3, 4, 11, 12, 14, 15}.contains(_selectedIndex)) {
          return PosSubscriptionPage(service: service, embedded: true);
        }
        return _buildSubscriptionShellBody(isMobile);
      },
    );
  }

  Widget _buildSubscriptionShellBody(bool isMobile) {
    if (_showSetupGuide) {
      return Builder(
        builder: (guideContext) => PosSetupGuidePage(
          onNavigate: _navigateSetupTarget,
          onStartCashier: () => _continueSetup(guideContext),
          onClose: () => setState(() => _showSetupGuide = false),
          onOpenCashier: _openCashierWorkspace,
          onStartWalkthrough: _startSetupStepTour,
        ),
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
    final runtime = _posBloc.state.runtimeConfig;
    final first = mobilePosFirstSaleDestination(runtime);
    final setup = runtime['initial_setup'] as Map? ?? const {};
    final step = first == 2 ? 'product' : first == 7 ? 'opening' : _posBloc.state.activeShift == null ? 'cash' : 'cashier';
    final destination = first ?? (_posBloc.state.activeShift == null ? 11 : 1);
    final stages = switch (step) {
      'product' => [PosSetupTourStage(title: 'Tambahkan produk pertama',
        description: 'Ketuk Tambah Produk. Isi nama dan harga jual; pilih barang atau layanan sesuai usaha Anda.',
        target: _setupTourTargets.productAdd, onTargetTap: _productTourController.run)],
      'opening' => [
        PosSetupTourStage(title: 'Pilih barang stok', description: 'Pilih barang yang sudah dimiliki sebelum memakai POS, lalu isi jumlah dan biaya pada field yang tampil. Panduan dapat dibuka kembali kapan saja.', target: _setupTourTargets.openingProduct),
        PosSetupTourStage(title: 'Periksa lokasi stok', description: 'Gunakan lokasi toko yang sudah disiapkan. Gedung, ruangan dan rak hanya bila diperlukan.', target: _setupTourTargets.openingLocation),
        PosSetupTourStage(title: 'Isi jumlah stok awal', description: 'Masukkan barang yang sudah Anda miliki dan biaya per satuan. Untuk barang baru datang, gunakan Pembelian & Penerimaan.', target: _setupTourTargets.openingQuantity),
        PosSetupTourStage(title: 'Simpan stok awal', description: 'Periksa jumlah dan biaya, lalu simpan. Panduan ini tidak menyimpan stok secara otomatis.', target: _setupTourTargets.openingSave),
      ],
      'cash' => [
        PosSetupTourStage(title: 'Periksa toko kasir', description: 'Shift aktif dipakai kembali. Bila belum ada shift, pilih toko tempat Anda bertugas.', target: _setupTourTargets.shiftStore),
        PosSetupTourStage(title: 'Isi kas awal dan buka shift', description: 'Masukkan uang tunai di laci. Kas awal boleh nol sesuai pengaturan toko. Ketuk buka shift setelah isian benar.', target: _setupTourTargets.shiftOpen),
      ],
      _ => [PosSetupTourStage(title: 'Siap berjualan', description: 'Cari atau scan produk di sini, tambahkan ke keranjang lalu lanjutkan pembayaran.', target: _cashierTourTargets.search)],
    };
    return PosFirstSaleGuide(
      preferences: sl<SharedPreferences>(),
      scope: sl<GraphQLClientProvider>().subscriptionScope,
      stepId: step, title: 'Panduan penjualan pertama', stages: stages,
      enabled: setup['first_sale_pending'] == true && setup['can_manage'] == true &&
          runtime['_offline_snapshot'] != true && !_showUnlockLoading &&
          _selectedIndex == destination && (step != 'opening' || _inventoryActiveSection == 'opening') &&
          context.watch<AppLockCubit>().state.status == AppLockStatus.unlocked,
      child: page,
    );
  }

  Future<void> _afterFirstProduct(PosProduct product) async {
    if ((_posBloc.state.runtimeConfig['initial_setup'] as Map?)?['first_sale_pending'] != true) return;
    _openingProductId = product.tracksStock && product.compositionType != 'bom' ? product.id : null;
    await _advanceFirstSale();
  }

  Future<void> _advanceFirstSale() async {
    if (_advancingFirstSale) return;
    setState(() => _advancingFirstSale = true);
    try {
      final repository = sl<PosRepository>();
      final actor = repository.activeOperatorId, terminal = repository.terminalUserId;
      // Read authoritative readiness directly: RefreshProducts can emit success
      // while LoadPosData is still in flight, so a generic stream success is not
      // proof that the new product/opening balance has been observed.
      final runtime = await repository.getRuntimeConfig().timeout(const Duration(seconds: 20));
      if (!mounted || actor != repository.activeOperatorId || terminal != repository.terminalUserId) return;
      if (runtime['_offline_snapshot'] == true) throw StateError('Persiapan belum dapat diperiksa. Periksa koneksi lalu coba lagi.');
      _posBloc.add(LoadPosData());
      final state = _posBloc.state;
      final first = mobilePosFirstSaleDestination(runtime);
      if (first != null) { _navigateSetupTarget(first, first == 7 ? 'opening' : null); return; }
      if ((runtime['initial_setup'] as Map?)?['first_sale_pending'] == true) {
        final destination = mobilePosUnlockDestination(runtime, hasStore: state.checkoutStore != null, hasShift: state.activeShift != null, offline: false);
        _navigateSetupTarget(destination);
        _returnToCashierAfterShiftOpen = destination == 11;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally { if (mounted) setState(() => _advancingFirstSale = false); }
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
    setState(() {
      if (index >= 5) {
        _secondaryOriginIndex = _selectedIndex >= 5
            ? _secondaryOriginIndex
            : _selectedIndex;
      }
      _selectedIndex = index;
    });
  }

  void _showKeyboardHelp() {
    if (context.read<AppLockCubit>().state.status != AppLockStatus.unlocked) {
      return;
    }
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const PosText('Shortcut keyboard Pantoo POS'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              PosText(
                'Navigasi: Tab / Shift+Tab untuk berpindah, Enter atau Spasi untuk memilih.',
              ),
              SizedBox(height: 10),
              PosText(posLocale(context).posCashierNavigationShortcuts),
              PosText('Alt+4 Pesanan & Meja · Alt+5 Inventori · Alt+6 Riwayat'),
              SizedBox(height: 10),
              PosText(
                'Kasir: F2 cari produk · F3 scan barcode · F4 bayar/simpan meja',
              ),
              PosText('F6 keranjang · F7 diskon · F8 simpan pesanan'),
              PosText('F9 pesanan tersimpan · F10 pengaturan penjualan'),
              PosText('Ctrl+Delete kosongkan keranjang · F1 tampilkan bantuan'),
              SizedBox(height: 10),
              PosText(
                'Shortcut halaman hanya tersedia jika operator mempunyai izin. Saat mengetik di formulir, shortcut navigasi tidak dijalankan.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const PosText('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _withKeyboardNavigation(Widget child) => CallbackShortcuts(
    bindings: <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.digit1, alt: true): () =>
          _navigateWithKeyboard(1),
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

    return PopScope(
      canPop:
          !isMobile ||
          mobilePosBackDestination(
                _selectedIndex,
                _secondaryOriginIndex,
                primaryIndex: _mobilePrimaryIndex,
              ) ==
              null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isMobile) _backWithinMobileShell();
      },
      child: BlocProvider.value(
        value: _posBloc,
        child: Builder(
          builder: (_) {
            return BlocListener<AppLockCubit, AppLockState>(
              listenWhen: (previous, current) =>
                  previous.status != current.status ||
                  previous.activeEmployeeId != current.activeEmployeeId ||
                  previous.operatorSessionToken != current.operatorSessionToken,
              listener: (context, state) {
                if (state.status == AppLockStatus.unlocked) {
                  _posDataRequested = false;
                  final setupCompleted =
                      PosOnboardingPage.isOperationalSetupCompleted(
                        sl<SharedPreferences>(),
                      );
                  if (!setupCompleted) {
                    setState(() {
                      _setupCompleted = false;
                    });
                  }
                  _loadPOSAfterUnlock();
                  _loadNavbarNotifications();
                } else {
                  _posDataRequested = false;
                  if (_showUnlockLoading) {
                    setState(() => _showUnlockLoading = false);
                  }
                }
              },
              child: BlocListener<PosBloc, PosState>(
                listener: (context, state) {
                  _finishUnlockLoading(state);
                  if (_selectedIndex == 19 &&
                      state.runtimeConfig.isNotEmpty &&
                      state.runtimeConfig['permissions']?['view_receivables'] !=
                          true &&
                      state.runtimeConfig['permissions']?['view_payables'] !=
                          true) {
                    setState(() {
                      _selectedIndex = 4;
                      _secondaryOriginIndex = _mobilePrimaryIndex;
                    });
                  }
                },
                child: Stack(
                  children: [
                    Scaffold(
                      resizeToAvoidBottomInset: false,
                      backgroundColor: const Color(0xFFF7F8FA),
                      appBar: AppBar(
                        elevation: 0,
                        backgroundColor: AppColors.primary,
                        toolbarHeight: isSmallScreen ? 56 : 64,
                        // Di mobile navigasi sekunder berada di tab Lainnya.
                        // Tombol sidebar hanya dipertahankan pada layar lebar.
                        leadingWidth: isMobile
                            ? (_selectedIndex >= 5 ? 44 : 0)
                            : 72,
                        automaticallyImplyLeading: false,
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
                            ? (_selectedIndex >= 5
                                  ? IconButton(
                                      tooltip: ('Kembali').tr(context),
                                      icon: const Icon(Icons.arrow_back),
                                      onPressed: _backWithinMobileShell,
                                    )
                                  : null)
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
                                        left: isMobile ? 14 : 0,
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
                                                : _selectedIndex == 5
                                                ? PosOrderWorkspacePolicy(
                                                    _posBloc
                                                        .state
                                                        .runtimeConfig,
                                                  ).title.tr(context)
                                                : _destinations[_selectedIndex]
                                                      .label
                                                      .tr(context),
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
                                                  vertical: isSmallScreen
                                                      ? 1
                                                      : 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: AppColors
                                                                .success,
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
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          color: Colors.black87,
                                                          fontSize:
                                                              isSmallScreen
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
                          BlocBuilder<PosBloc, PosState>(
                            buildWhen: (previous, current) =>
                                previous.runtimeConfig != current.runtimeConfig,
                            builder: (context, state) {
                              final subscription =
                                  sl.isRegistered<PosSubscriptionService>()
                                  ? sl<PosSubscriptionService>()
                                  : null;
                              return AnimatedBuilder(
                                animation: Listenable.merge([
                                  if (subscription != null) subscription,
                                ]),
                                builder: (context, _) {
                                  final navbarPolicy = PosNavbarActionPolicy(
                                    state.runtimeConfig,
                                    page: _selectedIndex,
                                    inventorySection: _inventoryActiveSection,
                                    showSetupGuide: _showSetupGuide,
                                    locked:
                                        context
                                            .watch<AppLockCubit>()
                                            .state
                                            .status !=
                                        AppLockStatus.unlocked,
                                    pageBodyEnabled:
                                        subscription == null ||
                                        !subscription.required ||
                                        subscription.canSell ||
                                        const {
                                          3,
                                          4,
                                          11,
                                          12,
                                          14,
                                          15,
                                        }.contains(_selectedIndex),
                                  );
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PosNavbarContextActions(
                                        policy: navbarPolicy,
                                        compact: isSmallScreen,
                                        showKeyboardIcon: width >= 1200,
                                        notificationButton: _notificationButton(
                                          compact: isSmallScreen,
                                        ),
                                        onKeyboardHelp: _showKeyboardHelp,
                                        onToggleGuide: () => setState(
                                          () => _showSetupGuide =
                                              !_showSetupGuide,
                                        ),
                                        onLock: () =>
                                            context.read<AppLockCubit>().lock(),
                                        onCustomerDisplay: () =>
                                            showPosCustomerDisplayPairing(
                                              context,
                                            ),
                                        customerDisplayBuilder: (context) =>
                                            ValueListenableBuilder<
                                              PosCustomerDisplayState
                                            >(
                                              valueListenable:
                                                  sl<PosCustomerDisplayService>()
                                                      .state,
                                              builder: (context, displayState, _) => IconButton(
                                                tooltip:
                                                    (displayState.connection ==
                                                                PosCustomerDisplayConnection
                                                                    .connected
                                                            ? 'Layar pelanggan terhubung'
                                                            : 'Hubungkan layar pelanggan')
                                                        .tr(context),
                                                icon: Badge(
                                                  isLabelVisible:
                                                      displayState.connection ==
                                                      PosCustomerDisplayConnection
                                                          .connected,
                                                  smallSize: 8,
                                                  backgroundColor:
                                                      AppColors.success,
                                                  child: const Icon(
                                                    Icons.connected_tv_outlined,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                onPressed: () =>
                                                    showPosCustomerDisplayPairing(
                                                      context,
                                                    ),
                                              ),
                                            ),
                                      ),
                                      if (_selectedIndex == 1 &&
                                          navbarPolicy.layoutToggle) ...[
                                        BlocBuilder<PosBloc, PosState>(
                                          builder: (context, state) {
                                            return IconButton(
                                              style: isSmallScreen
                                                  ? IconButton.styleFrom(
                                                      fixedSize:
                                                          const Size.square(40),
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
                                                context.read<PosBloc>().add(
                                                  ToggleGridView(),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        if (!isSmallScreen &&
                                            navbarPolicy.orderDestination !=
                                                null)
                                          BlocBuilder<PosBloc, PosState>(
                                            builder: (context, state) => Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 10.0,
                                                    horizontal: 8.0,
                                                  ),
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedIndex =
                                                        PosOrderWorkspacePolicy(
                                                              state
                                                                  .runtimeConfig,
                                                            ).visible &&
                                                            (state.runtimeConfig['permissions']
                                                                    as Map?)?['view_tables'] ==
                                                                true
                                                        ? 5
                                                        : 3;
                                                  });
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors
                                                      .teal
                                                      .shade600, // A darker green for the button
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      PosOrderWorkspacePolicy(
                                                                state
                                                                    .runtimeConfig,
                                                              ).visible &&
                                                              (state.runtimeConfig['permissions']
                                                                      as Map?)?['view_tables'] ==
                                                                  true
                                                          ? PosOrderWorkspacePolicy(
                                                              state
                                                                  .runtimeConfig,
                                                            ).title
                                                          : ('Riwayat Transaksi')
                                                                .tr(context),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    const Icon(
                                                      Icons.chevron_right,
                                                      size: 16,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                      if (_selectedIndex == 2 &&
                                          navbarPolicy.layoutToggle)
                                        IconButton(
                                          style: isSmallScreen
                                              ? IconButton.styleFrom(
                                                  fixedSize: const Size.square(
                                                    40,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                )
                                              : null,
                                          tooltip: _productGridView
                                              ? ('Tampilkan sebagai tabel').tr(
                                                  context,
                                                )
                                              : ('Tampilkan sebagai grid').tr(
                                                  context,
                                                ),
                                          icon: Icon(
                                            _productGridView
                                                ? Icons.table_rows
                                                : Icons.grid_view,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            setState(
                                              () => _productGridView =
                                                  !_productGridView,
                                            );
                                          },
                                        ),
                                      if (_selectedIndex == 7 &&
                                          navbarPolicy.layoutToggle)
                                        IconButton(
                                          style: isSmallScreen
                                              ? IconButton.styleFrom(
                                                  fixedSize: const Size.square(
                                                    40,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                )
                                              : null,
                                          tooltip: _stockGridView
                                              ? ('Tampilkan sebagai tabel').tr(
                                                  context,
                                                )
                                              : ('Tampilkan sebagai grid').tr(
                                                  context,
                                                ),
                                          icon: Icon(
                                            _stockGridView
                                                ? Icons.table_rows
                                                : Icons.grid_view,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            setState(
                                              () => _stockGridView =
                                                  !_stockGridView,
                                            );
                                          },
                                        ),
                                      if (_selectedIndex == 3 &&
                                          navbarPolicy.layoutToggle)
                                        IconButton(
                                          style: isSmallScreen
                                              ? IconButton.styleFrom(
                                                  fixedSize: const Size.square(
                                                    40,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                )
                                              : null,
                                          tooltip: _useHistoryGridView
                                              ? ('Tampilkan sebagai tabel').tr(
                                                  context,
                                                )
                                              : ('Tampilkan sebagai kartu').tr(
                                                  context,
                                                ),
                                          icon: Icon(
                                            _useHistoryGridView
                                                ? Icons.table_rows
                                                : Icons.view_agenda,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            setState(
                                              () => _historyGridView =
                                                  !_useHistoryGridView,
                                            );
                                          },
                                        ),
                                      if ((_selectedIndex == 5 ||
                                              _selectedIndex == 6) &&
                                          navbarPolicy.layoutToggle)
                                        IconButton(
                                          style: isSmallScreen
                                              ? IconButton.styleFrom(
                                                  fixedSize: const Size.square(
                                                    40,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                )
                                              : null,
                                          tooltip: _useOrderTableGridView
                                              ? ('Tampilkan sebagai list').tr(
                                                  context,
                                                )
                                              : ('Tampilkan sebagai grid').tr(
                                                  context,
                                                ),
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
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
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
                            : _withKeyboardNavigation(
                                _buildShellBody(isMobile),
                              ),
                      ),
                      floatingActionButton:
                          isMobile &&
                              _mobilePrimaryIndex == 1 &&
                              MediaQuery.of(context).viewInsets.bottom == 0
                          ? PosCashierEntryButton(
                              onOpenCashier: _openCashierWorkspace,
                            )
                          : null,
                      floatingActionButtonLocation:
                          FloatingActionButtonLocation.centerDocked,
                      bottomNavigationBar: isMobile
                          ? BottomAppBar(
                              shape: const CircularNotchedRectangle(),
                              notchMargin: 4.0,
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
                                            icon: Icons.bar_chart_outlined,
                                            selectedIcon: Icons.bar_chart,
                                            label: ('Laporan').tr(context),
                                            index: 12,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildBottomNavItem(
                                            icon: Icons.inventory_2_outlined,
                                            selectedIcon: Icons.inventory_2,
                                            label: ('Katalog').tr(context),
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
                                            label: ('Transaksi').tr(context),
                                            index: 3,
                                          ),
                                        ),
                                        Expanded(
                                          child: _buildBottomNavItem(
                                            icon: Icons.menu_outlined,
                                            selectedIcon: Icons.menu,
                                            label: ('Lainnya').tr(context),
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
                                  PosText(
                                    posLocale(context).posPreparingSales,
                                    textScaler: TextScaler.noScaling,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const PosText(
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
                              PosText(
                                'Pantoo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              PosText(
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
      child: PosText(
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
      if (can('use_cashier')) _sidebarItem(1),
      // Order dan manajemen meja sudah dilebur dalam satu workspace. Tampilkan
      // satu menu bila pengguna memiliki salah satu hak akses terkait.
      if ((viewTables && PosOrderWorkspacePolicy(runtimeConfig).visible) ||
          (useTables && manageTables))
        _sidebarItem(5),
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
      if (can('view_receivables') || can('view_payables')) _sidebarItem(19),
      _sidebarSection('PENGATURAN'),
      if (can('view_settings')) _sidebarItem(17),
      if (can('view_receipt')) _sidebarItem(14),
      _sidebarItem(15),
      _sidebarSection('BANTUAN'),
      if (_railExpanded)
        Material(
          color: Colors.transparent,
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.help_outline),
            title: const PosText('Panduan POS'),
            onTap: () => _openSetupGuide(menuContext),
          ),
        )
      else
        IconButton(
          tooltip: ('Panduan POS').tr(menuContext),
          onPressed: () => _openSetupGuide(menuContext),
          icon: const Icon(Icons.help_outline),
        ),
      if (_railExpanded)
        Material(
          color: Colors.transparent,
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.keyboard_alt_outlined),
            title: const PosText('Shortcut keyboard'),
            subtitle: const PosText('F1 untuk melihat panduan'),
            onTap: _showKeyboardHelp,
          ),
        )
      else
        Tooltip(
          message: ('Shortcut keyboard (F1)').tr(menuContext),
          child: IconButton(
            onPressed: _showKeyboardHelp,
            icon: const Icon(Icons.keyboard_alt_outlined),
          ),
        ),
    ];
  }

  Widget _sidebarItem(int index) {
    final destination = _destinations[index];
    final label = index == 5
        ? PosOrderWorkspacePolicy(_posBloc.state.runtimeConfig).title
        : destination.label;
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
                    child: PosText(
                      label,
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
        : Tooltip(message: (label).tr(context), child: item);
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
        ? _selectedIndex == 4 || (_selectedIndex >= 5 && _selectedIndex != 12)
        : _selectedIndex == index;
    final color = isSelected ? AppColors.primary : Colors.black54;
    return MaterialButton(
      minWidth: 0,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      onPressed:
          index == 12 &&
              (_posBloc.state.runtimeConfig['permissions']
                      as Map?)?['view_reports'] !=
                  true
          ? null
          : () {
              if (index == 4) {
                _posBloc.add(
                  const RefreshPosRuntimeConfig(preserveCheckout: true),
                );
              }
              setState(() {
                _showSetupGuide = false;
                _selectedIndex = index;
              });
            },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSelected ? selectedIcon : icon, color: color, size: 19),
          const SizedBox(height: 2),
          PosText(
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
