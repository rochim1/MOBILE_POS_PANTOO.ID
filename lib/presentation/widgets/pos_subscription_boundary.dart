import '../../injections.dart';
import '../bloc/pos/pos_bloc.dart';
import '../bloc/pos/pos_event.dart';
import '../bloc/pos/pos_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/lock/lock_cubit.dart';
import '../bloc/lock/lock_state.dart';
import '../pages/common/pin_lock_screen.dart';
import '../pages/pos/pos_shift_page.dart';
import '../pages/pos/pos_offline_queue_page.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/subscription/pos_subscription_service.dart';
import '../pages/pos/pos_subscription_page.dart';

/// Receipt routes remain visible if access changes after the server accepted
/// payment. Other routes stay mounted under the boundary, preserving drafts.
class PosSubscriptionRouteObserver extends NavigatorObserver {
  final receiptVisible = ValueNotifier(false);
  final _routes = <Route<dynamic>>[];
  void _update() {
    final receipt = _routes.any(
      (r) => r.settings.name == 'pos_payment_success',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      receiptVisible.value = receipt;
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
    _update();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _update();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
    _update();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (i >= 0) {
      if (newRoute == null) {
        _routes.removeAt(i);
      } else {
        _routes[i] = newRoute;
      }
    }
    _update();
  }
}

class PosSubscriptionBoundary extends StatefulWidget {
  const PosSubscriptionBoundary({
    super.key,
    required this.service,
    required this.authenticated,
    required this.child,
    required this.onLogout,
    required this.navigatorKey,
    required this.receiptVisible,
    this.onRestricted,
  });
  final PosSubscriptionService service;
  final bool authenticated;
  final Widget child;
  final VoidCallback onLogout;
  final VoidCallback? onRestricted;
  final GlobalKey<NavigatorState> navigatorKey;
  final ValueNotifier<bool> receiptVisible;
  @override
  State<PosSubscriptionBoundary> createState() =>
      _PosSubscriptionBoundaryState();
}

class _PosSubscriptionBoundaryState extends State<PosSubscriptionBoundary>
    with WidgetsBindingObserver {
  Timer? _poll;
  bool _foreground = true;
  int? _recoveryDestination;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.service.addListener(_accessChanged);
    if (widget.authenticated) _scheduleActivate();
  }

  void _accessChanged() {
    if (mounted && widget.service.canSell && _recoveryDestination != null) {
      setState(() => _recoveryDestination = null);
    }
    if (widget.authenticated && !widget.service.canSell) {
      widget.onRestricted?.call();
    }
  }

  void _scheduleActivate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.authenticated) _activate();
    });
  }

  void _activate() {
    unawaited(widget.service.activate());
    _poll?.cancel();
    if (_foreground) {
      _poll = Timer.periodic(
        const Duration(minutes: 5),
        (_) => widget.service.refresh(),
      );
    }
  }

  @override
  void didUpdateWidget(covariant PosSubscriptionBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authenticated == widget.authenticated) return;
    if (widget.authenticated) {
      _scheduleActivate();
    } else {
      _poll?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.authenticated) widget.service.deactivate();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!widget.authenticated) return;
    if (_foreground) {
      _activate();
    } else {
      _poll?.cancel();
      widget.service.pause();
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    widget.service.removeListener(_accessChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _openDetails() {
    widget.navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'pos_subscription'),
        builder: (_) => PosSubscriptionPage(service: widget.service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([widget.service, widget.receiptVisible]),
    builder: (context, _) {
      final pinLocked = context.select<AppLockCubit?, bool>(
        (lock) => lock?.state.status == AppLockStatus.locked,
      );
      final service = widget.service;
      if (!widget.authenticated || !service.required) return widget.child;
      // Locking clears the operator scope before its replacement is checked.
      // Keep the independent PIN gate usable instead of covering it with an
      // unknown-subscription recovery page. Write guards still deny access.
      final verifyingLockedOperator =
          pinLocked && service.accessLevel == 'unknown';
      final blocked =
          !service.canSell &&
          service.accessLevel != 'read_only' &&
          !verifyingLockedOperator &&
          !widget.receiptVisible.value;
      // Presentation only: PIN must not show subscription details, while
      // polling, write guards and the restriction overlay remain unchanged.
      final showBanner = service.showWarning && !blocked && !pinLocked;
      return Stack(
        children: [
          Column(
            children: [
              if (showBanner)
                Material(
                  color: const Color(0xFFFFF8E8),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Color(0xFF795A14),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              service.offline
                                  ? subscriptionText(
                                      context,
                                      'Status langganan terakhir · periksa koneksi',
                                      'Last known subscription status · check connection',
                                    )
                                  : service.accessLevel == 'read_only'
                                  ? subscriptionText(
                                      context,
                                      'Mode baca saja · penjualan baru dinonaktifkan',
                                      'Read-only mode · new sales disabled',
                                    )
                                  : service.snapshot?.effectiveState == 'grace'
                                  ? subscriptionText(
                                          context,
                                          'Masa tenggang · batas penjualan ',
                                          'Grace period · sales cutoff ',
                                        ) +
                                        subscriptionDate(
                                          context,
                                          service.snapshot?.operationalUntil,
                                        )
                                  : subscriptionText(
                                          context,
                                          'Langganan berakhir ',
                                          'Subscription expires ',
                                        ) +
                                        subscriptionDate(
                                          context,
                                          service.snapshot?.expiresAt,
                                        ),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: _openDetails,
                            child: Text(
                              subscriptionText(context, 'Detail', 'Details'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: showBanner,
                    child: widget.child,
                  ),
                ),
              ),
            ],
          ),
          if (blocked)
            Positioned.fill(
              child: Material(
                child: HeroControllerScope.none(
                  child: Navigator(
                    key: ValueKey((
                      _recoveryDestination,
                      _recoveryDestination == null &&
                          !service.canRead &&
                          !service.recoveryOnly,
                    )),
                    onGenerateRoute: (_) => MaterialPageRoute<void>(
                      builder: (_) => _recoveryDestination != null
                          ? _SubscriptionRecoveryTools(
                              destination: _recoveryDestination!,
                              onBack: () =>
                                  setState(() => _recoveryDestination = null),
                            )
                          : !service.canRead && !service.recoveryOnly
                          ? _SubscriptionVerification(
                              service: service,
                              onLogout: widget.onLogout,
                              onCloseShift: () =>
                                  setState(() => _recoveryDestination = 11),
                              onViewQueue: () =>
                                  setState(() => _recoveryDestination = 15),
                            )
                          : PosSubscriptionPage(
                              service: service,
                              onLogout: widget.onLogout,
                              onCloseShift: () =>
                                  setState(() => _recoveryDestination = 11),
                              onViewQueue: () =>
                                  setState(() => _recoveryDestination = 15),
                            ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// A verification failure is not a billing decision. Keep writes blocked.
class _SubscriptionVerification extends StatelessWidget {
  const _SubscriptionVerification({
    required this.service,
    required this.onLogout,
    required this.onCloseShift,
    required this.onViewQueue,
  });
  final PosSubscriptionService service;
  final VoidCallback onLogout, onCloseShift, onViewQueue;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: service,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/pantoo_pos_icon.png',
                  width: 96,
                  height: 96,
                ),
                const SizedBox(height: 20),
                Text(
                  subscriptionText(
                    context,
                    'Menyiapkan akses POS',
                    'Preparing POS access',
                  ),
                ),
                const SizedBox(height: 12),
                if (service.checking || !service.initialized)
                  CircularProgressIndicator(
                    semanticsLabel: subscriptionText(
                      context,
                      'Menyiapkan akses POS',
                      'Preparing POS access',
                    ),
                  )
                else ...[
                  Text(
                    subscriptionText(
                      context,
                      'Status akses belum dapat dipastikan. Periksa koneksi lalu coba lagi.',
                      'Access has not been confirmed. Check your connection and try again.',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => service.refresh(),
                    child: Text(
                      subscriptionText(context, 'Coba lagi', 'Retry'),
                    ),
                  ),
                  TextButton(
                    onPressed: onCloseShift,
                    child: Text(
                      subscriptionText(context, 'Tutup shift', 'Close shift'),
                    ),
                  ),
                  TextButton(
                    onPressed: onViewQueue,
                    child: Text(
                      subscriptionText(
                        context,
                        'Lihat antrean offline',
                        'View offline queue',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onLogout,
                    child: Text(
                      subscriptionText(context, 'Keluar akun', 'Sign out'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _SubscriptionRecoveryTools extends StatelessWidget {
  const _SubscriptionRecoveryTools({
    required this.destination,
    required this.onBack,
  });
  final int destination;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back),
      ),
      title: Text(
        subscriptionText(
          context,
          'Pemulihan operasional',
          'Operational recovery',
        ),
      ),
    ),
    body: BlocBuilder<AppLockCubit, AppLockState>(
      builder: (context, lock) {
        if (lock.status != AppLockStatus.unlocked) return const PinLockScreen();
        if (destination != 11) {
          return const PosOfflineQueuePage(allowSync: false);
        }
        return BlocProvider(
          create: (_) => sl<PosBloc>()..add(const RefreshPosAccess()),
          child: BlocBuilder<PosBloc, PosState>(
            builder: (context, state) {
              if (state.status == PosStatus.initial ||
                  state.status == PosStatus.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state.stores.isEmpty || state.checkoutSyncFailed) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          subscriptionText(
                            context,
                            'Data shift belum dapat dimuat.',
                            'Shift data could not be loaded.',
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.read<PosBloc>().add(
                            const RefreshPosAccess(),
                          ),
                          child: Text(
                            subscriptionText(context, 'Coba lagi', 'Retry'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const PosShiftPage();
            },
          ),
        );
      },
    ),
  );
}
