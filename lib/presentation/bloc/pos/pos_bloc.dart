import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'pos_event.dart';
import 'pos_state.dart';
import '../../../domain/repositories/pos_repository.dart';
import '../../../domain/models/hold_order.dart';
import '../../../domain/models/pos_order.dart';

class PosBloc extends Bloc<PosEvent, PosState> {
  final PosRepository posRepository;

  PosBloc({required this.posRepository}) : super(const PosState()) {
    on<LoadPosData>(_onLoadPosData);
    on<RefreshOrders>(_onRefreshOrders);
    on<LoadMoreOrders>(_onLoadMoreOrders);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<RemoveCartItem>(_onRemoveCartItem);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
    on<SelectCustomer>(_onSelectCustomer);
    on<HoldCurrentOrder>(_onHoldCurrentOrder);
    on<RestoreHeldOrder>(_onRestoreHeldOrder);
    on<RemoveHeldOrder>(_onRemoveHeldOrder);
    on<UpdateDiscount>(_onUpdateDiscount);
    on<SubmitPayment>(_onSubmitPayment);
    on<ToggleGridView>(_onToggleGridView);
    on<LoadDashboardData>(_onLoadDashboardData);
    on<RefreshPricingPreview>(_onRefreshPricingPreview);
    on<UpdateOrderType>(_onUpdateOrderType);
    on<UpdateSalesContext>(_onUpdateSalesContext);
    on<ToggleFavoriteProduct>(_onToggleFavoriteProduct);
  }

  Future<void> _onRefreshOrders(
    RefreshOrders event,
    Emitter<PosState> emit,
  ) async {
    try {
      final page = await posRepository.getOrdersPage();
      emit(
        state.copyWith(
          orders: page.items,
          ordersPage: 0,
          ordersHasMore: page.hasMore,
          ordersLoadingMore: false,
          errorMessage: '',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          errorMessage:
              'Gagal memuat riwayat transaksi. Tarik untuk mencoba lagi.',
        ),
      );
    }
  }

  Future<void> _onLoadMoreOrders(
    LoadMoreOrders event,
    Emitter<PosState> emit,
  ) async {
    if (!state.ordersHasMore || state.ordersLoadingMore) return;
    emit(state.copyWith(ordersLoadingMore: true));
    try {
      final nextPage = state.ordersPage + 1;
      final page = await posRepository.getOrdersPage(page: nextPage);
      final merged = <String, PosOrder>{
        for (final order in [...state.orders, ...page.items])
          '${order.isInvoice}:${order.id}:${order.invoice}': order,
      }.values.toList();
      merged.sort((a, b) => b.date.compareTo(a.date));
      emit(
        state.copyWith(
          orders: merged,
          ordersPage: nextPage,
          ordersHasMore: page.hasMore,
          ordersLoadingMore: false,
          errorMessage: '',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          ordersLoadingMore: false,
          errorMessage: 'Gagal memuat transaksi berikutnya.',
        ),
      );
    }
  }

  Future<void> _onLoadPosData(LoadPosData event, Emitter<PosState> emit) async {
    emit(state.copyWith(status: PosStatus.loading));
    try {
      final customers = await posRepository.getCustomers();
      final runtimeConfig = await posRepository.getRuntimeConfig();
      final stores = await posRepository.getStores();
      final ordersPage = await posRepository.getOrdersPage();
      final orders = ordersPage.items;

      Map<String, dynamic>? activeShift;
      if (stores.isNotEmpty) {
        activeShift = await posRepository.getActiveShift(stores.first.id);
      }
      if (activeShift == null) {
        emit(
          state.copyWith(
            status: PosStatus.failure,
            customers: customers,
            runtimeConfig: runtimeConfig,
            stores: stores,
            orders: orders,
            ordersPage: 0,
            ordersHasMore: ordersPage.hasMore,
            errorMessage: 'Buka shift kasir sebelum memuat produk',
          ),
        );
        return;
      }
      final activeStore = stores
          .where((store) => store.id == activeShift!['toko_id']?.toString())
          .firstOrNull;
      if (activeStore == null || activeStore.branchId.isEmpty) {
        emit(
          state.copyWith(
            status: PosStatus.failure,
            customers: customers,
            runtimeConfig: runtimeConfig,
            stores: stores,
            orders: orders,
            ordersPage: 0,
            ordersHasMore: ordersPage.hasMore,
            activeShift: activeShift,
            errorMessage: 'Toko shift belum terhubung ke warehouse aktif',
          ),
        );
        return;
      }
      final products = await posRepository.getProducts(
        branchId: activeStore.branchId,
      );
      final favoriteProductIds = await posRepository.getFavoriteProductIds();
      final heldOrders = await posRepository.getHeldOrders(
        storeId: activeStore.id,
        shiftId: activeShift['_id']?.toString() ?? '',
      );

      emit(
        state.copyWith(
          status: PosStatus.success,
          products: products,
          heldOrders: heldOrders,
          customers: customers,
          stores: stores,
          orders: orders,
          ordersPage: 0,
          ordersHasMore: ordersPage.hasMore,
          activeShift: activeShift,
          runtimeConfig: runtimeConfig,
          orderType:
              runtimeConfig['default_order_type']?.toString() ?? 'take_away',
          salesChannel:
              runtimeConfig['default_sales_channel']?.toString() ?? 'retail',
          customerSegment:
              runtimeConfig['default_customer_segment']?.toString() ??
              'regular',
          priceLevel:
              runtimeConfig['default_price_level']?.toString() ?? 'retail',
          taxPercent: (runtimeConfig['tax_percent'] as num?)?.toDouble() ?? 0,
          favoriteProductIds: favoriteProductIds,
        ),
      );

      // Also load dashboard data
      add(LoadDashboardData());
    } catch (e) {
      emit(
        state.copyWith(
          status: PosStatus.failure,
          errorMessage: 'Gagal memuat data master',
        ),
      );
    }
  }

  void _onAddToCart(AddToCart event, Emitter<PosState> emit) {
    final newCart = Map.of(state.cart);
    final current = newCart[event.product] ?? 0;
    final features = state.runtimeConfig['features'] as Map?;
    final trackStock = features?['track_stock'] != false;
    if (trackStock &&
        event.product.tracksStock &&
        current + 1 > event.product.stock) {
      emit(
        state.copyWith(
          status: PosStatus.failure,
          errorMessage: 'Stok ${event.product.name} tidak mencukupi',
        ),
      );
      return;
    }
    newCart[event.product] = current + 1;
    emit(
      state.copyWith(
        cart: newCart,
        status: PosStatus.success,
        clearPricingPreview: true,
      ),
    );
    add(RefreshPricingPreview());
  }

  void _onRemoveFromCart(RemoveFromCart event, Emitter<PosState> emit) {
    final newCart = Map.of(state.cart);
    final currentQty = newCart[event.product] ?? 0;
    if (currentQty <= 1) {
      newCart.remove(event.product);
    } else {
      newCart[event.product] = currentQty - 1;
    }
    emit(
      state.copyWith(
        cart: newCart,
        status: PosStatus.success,
        clearPricingPreview: true,
      ),
    );
    add(RefreshPricingPreview());
  }

  void _onRemoveCartItem(RemoveCartItem event, Emitter<PosState> emit) {
    final newCart = Map.of(state.cart)..remove(event.product);
    emit(
      state.copyWith(
        cart: newCart,
        status: PosStatus.success,
        clearPricingPreview: true,
      ),
    );
    add(RefreshPricingPreview());
  }

  void _onUpdateQuantity(UpdateQuantity event, Emitter<PosState> emit) {
    final newCart = Map.of(state.cart);
    final currentQty = newCart[event.product] ?? 0;
    final nextQty = currentQty + event.delta;

    final features = state.runtimeConfig['features'] as Map?;
    final trackStock = features?['track_stock'] != false;
    if (trackStock &&
        event.product.tracksStock &&
        nextQty > event.product.stock) {
      emit(
        state.copyWith(
          status: PosStatus.failure,
          errorMessage: 'Stok ${event.product.name} tidak mencukupi',
        ),
      );
      return;
    } else if (nextQty <= 0) {
      newCart.remove(event.product);
    } else {
      newCart[event.product] = nextQty;
    }
    emit(
      state.copyWith(
        cart: newCart,
        status: PosStatus.success,
        clearPricingPreview: true,
      ),
    );
    add(RefreshPricingPreview());
  }

  void _onClearCart(ClearCart event, Emitter<PosState> emit) {
    emit(
      state.copyWith(
        cart: const {},
        manualDiscountPercent: 0,
        promoCode: '',
        discountPolicy: 'stack',
        orderType:
            state.runtimeConfig['default_order_type']?.toString() ??
            'take_away',
        salesChannel: state.defaultSalesChannel,
        customerSegment: state.defaultCustomerSegment,
        priceLevel: state.defaultPriceLevel,
        taxPercent: state.configuredTaxPercent,
        clearSelectedCustomer: true,
        status: PosStatus.success,
        clearPricingPreview: true,
      ),
    );
  }

  Future<void> _onHoldCurrentOrder(
    HoldCurrentOrder event,
    Emitter<PosState> emit,
  ) async {
    if (state.cart.isEmpty) return;
    final activeStoreId = state.activeShift?['toko_id']?.toString();
    final activeStores = state.stores.where(
      (store) => store.id == activeStoreId,
    );
    if (activeStores.isEmpty) {
      emit(
        state.copyWith(
          status: PosStatus.failure,
          errorMessage: 'Toko shift aktif tidak ditemukan',
        ),
      );
      return;
    }

    final holdOrder = HoldOrder(
      id: 'HOLD-${const Uuid().v4().substring(0, 6).toUpperCase()}',
      time: DateTime.now(),
      cart: Map.of(state.cart),
      customer: state.selectedCustomer,
      store: activeStores.first,
      notes: event.notes,
      manualDiscountPercent: state.manualDiscountPercent,
      promoCode: state.promoCode,
      discountPolicy: state.discountPolicy,
      orderType: state.orderType,
      salesChannel: state.salesChannel,
      customerSegment: state.customerSegment,
      priceLevel: state.priceLevel,
    );

    final newHeldOrders = List.of(state.heldOrders)..add(holdOrder);
    try {
      await posRepository.saveHeldOrder(
        order: holdOrder,
        shiftId: state.activeShift?['_id']?.toString() ?? '',
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: PosStatus.failure,
          errorMessage: 'Pesanan belum dapat disimpan di perangkat',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        heldOrders: newHeldOrders,
        cart: const {},
        manualDiscountPercent: 0,
        promoCode: '',
        discountPolicy: 'stack',
        orderType:
            state.runtimeConfig['default_order_type']?.toString() ??
            'take_away',
        salesChannel: state.defaultSalesChannel,
        customerSegment: state.defaultCustomerSegment,
        priceLevel: state.defaultPriceLevel,
        taxPercent: state.configuredTaxPercent,
        status: PosStatus.success,
        clearPricingPreview: true,
      ),
    );
    add(RefreshPricingPreview());
  }

  Future<void> _onRefreshPricingPreview(
    RefreshPricingPreview event,
    Emitter<PosState> emit,
  ) async {
    if (state.cart.isEmpty || state.activeShift == null) {
      emit(state.copyWith(clearPricingPreview: true));
      return;
    }
    final requestedSubtotal = state.subTotal;
    final result = await posRepository.previewPricing(
      cart: state.cart,
      tokoId: state.activeShift!['toko_id'].toString(),
      promoCode: state.promoCode,
      discountPolicy: state.discountPolicy,
      manualDiscount: state.manualDiscount,
      salesChannel: state.salesChannel,
      customerSegment: state.customerSegment,
      priceLevel: state.priceLevel,
      customerId: state.selectedCustomer?.id,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosStatus.failure,
          errorMessage: failure.message,
          clearPricingPreview: true,
        ),
      ),
      (preview) {
        final serverSubtotal = (preview['subtotal'] as num?)?.toDouble();
        emit(state.copyWith(pricingPreview: preview));
        if (state.manualDiscountPercent > 0 &&
            serverSubtotal != null &&
            (serverSubtotal - requestedSubtotal).abs() > 0.5) {
          add(RefreshPricingPreview());
        }
      },
    );
  }

  Future<void> _onRestoreHeldOrder(
    RestoreHeldOrder event,
    Emitter<PosState> emit,
  ) async {
    final newHeldOrders = List.of(state.heldOrders)..remove(event.order);
    await posRepository.deleteHeldOrder(event.order.id);
    emit(
      state.copyWith(
        cart: event.order.cart,
        manualDiscountPercent: event.order.manualDiscountPercent,
        promoCode: event.order.promoCode,
        discountPolicy: event.order.discountPolicy,
        orderType: event.order.orderType,
        salesChannel: event.order.salesChannel,
        customerSegment: event.order.customerSegment,
        priceLevel: event.order.priceLevel,
        selectedCustomer: event.order.customer,
        heldOrders: newHeldOrders,
        status: PosStatus.success,
        clearPricingPreview: true,
      ),
    );
    add(RefreshPricingPreview());
  }

  Future<void> _onRemoveHeldOrder(
    RemoveHeldOrder event,
    Emitter<PosState> emit,
  ) async {
    await posRepository.deleteHeldOrder(event.order.id);
    emit(
      state.copyWith(
        heldOrders: List<HoldOrder>.of(state.heldOrders)..remove(event.order),
      ),
    );
  }

  void _onUpdateDiscount(UpdateDiscount event, Emitter<PosState> emit) {
    emit(
      state.copyWith(
        manualDiscountPercent: event.manualDiscountPercent,
        promoCode: event.promoCode,
        discountPolicy: event.discountPolicy,
        status: PosStatus.success,
      ),
    );
    add(RefreshPricingPreview());
  }

  Future<void> _onSubmitPayment(
    SubmitPayment event,
    Emitter<PosState> emit,
  ) async {
    if (state.cart.isEmpty) return;
    final features = state.runtimeConfig['features'] as Map?;
    if (features?['require_customer'] == true &&
        state.selectedCustomer == null) {
      emit(
        state.copyWith(
          status: PosStatus.failure,
          errorMessage: 'Pelanggan wajib dipilih untuk profil POS ini',
        ),
      );
      return;
    }

    emit(state.copyWith(status: PosStatus.loading));
    try {
      final tokoId = state.activeShift != null
          ? state.activeShift!['toko_id']
          : (state.stores.isNotEmpty ? state.stores.first.id : '');

      final result = await posRepository.submitTransaction(
        cart: state.cart,
        total: state.grandTotal,
        paymentMethod: event.paymentMethod,
        tokoId: tokoId,
        shiftId: state.activeShift!['_id'].toString(),
        cashReceived: event.cashReceived,
        payments: event.payments,
        promoCode: state.promoCode.isNotEmpty ? state.promoCode : null,
        discountPolicy: state.discountPolicy,
        diskon: state.manualDiscount,
        catatan: event.note.trim().isEmpty
            ? 'Mobile POS Payment'
            : event.note.trim(),
        expiredSaleReason: event.expiredSaleReason,
        expiredSaleAuthorizerUsername: event.expiredSaleAuthorizerUsername,
        expiredSaleAuthorizerPin: event.expiredSaleAuthorizerPin,
        orderType: state.orderType,
        salesChannel: state.salesChannel,
        customerSegment: state.customerSegment,
        priceLevel: state.priceLevel,
        pajak: state.taxAmount,
        pelangganId: state.selectedCustomer?.id,
        pelangganName: state.selectedCustomer?.name,
        pelangganPhone: state.selectedCustomer?.phone,
        pelangganEmail: state.selectedCustomer?.email,
      );

      result.fold(
        (failure) => emit(
          state.copyWith(
            status: PosStatus.failure,
            errorMessage: failure.message,
          ),
        ),
        (transaction) => emit(
          state.copyWith(
            status: PosStatus.paymentSuccess,
            cart: const {},
            manualDiscountPercent: 0,
            promoCode: '',
            discountPolicy: 'stack',
            orderType:
                state.runtimeConfig['default_order_type']?.toString() ??
                'take_away',
            salesChannel: state.defaultSalesChannel,
            customerSegment: state.defaultCustomerSegment,
            priceLevel: state.defaultPriceLevel,
            taxPercent: state.configuredTaxPercent,
            lastTransaction: transaction,
            clearSelectedCustomer: true,
            clearPricingPreview: true,
          ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PosStatus.failure,
          errorMessage: 'Terjadi kesalahan sistem',
        ),
      );
    }
  }

  void _onToggleGridView(ToggleGridView event, Emitter<PosState> emit) {
    emit(state.copyWith(isGridView: !state.isGridView));
  }

  void _onUpdateOrderType(UpdateOrderType event, Emitter<PosState> emit) {
    const supported = {
      'take_away',
      'dine_in',
      'free_table',
      'delivery',
      'online_delivery',
      'quick_service',
      'reservation',
    };
    if (supported.contains(event.orderType)) {
      emit(state.copyWith(orderType: event.orderType));
    }
  }

  void _onSelectCustomer(SelectCustomer event, Emitter<PosState> emit) {
    final customerLevel = event.customer?.priceLevel.trim();
    final level = customerLevel != null && customerLevel.isNotEmpty
        ? customerLevel
        : state.defaultPriceLevel;
    final segment = _segmentForPriceLevel(level);
    emit(
      state.copyWith(
        selectedCustomer: event.customer,
        clearSelectedCustomer: event.customer == null,
        priceLevel: level,
        customerSegment: segment,
        clearPricingPreview: true,
      ),
    );
    add(RefreshPricingPreview());
  }

  void _onUpdateSalesContext(UpdateSalesContext event, Emitter<PosState> emit) {
    emit(
      state.copyWith(
        salesChannel: event.salesChannel,
        customerSegment: event.customerSegment,
        priceLevel: event.priceLevel,
        taxPercent: event.taxPercent.clamp(0, 100),
        clearPricingPreview: true,
      ),
    );
    add(RefreshPricingPreview());
  }

  String _segmentForPriceLevel(String level) {
    if (level == 'grosir' || level == 'distributor') return 'reseller';
    return level == 'retail' ? 'regular' : level;
  }

  Future<void> _onToggleFavoriteProduct(
    ToggleFavoriteProduct event,
    Emitter<PosState> emit,
  ) async {
    final favorites = Set<String>.from(state.favoriteProductIds);
    if (favorites.contains(event.productId)) {
      favorites.remove(event.productId);
    } else {
      favorites.add(event.productId);
    }
    emit(state.copyWith(favoriteProductIds: favorites));
    await posRepository.saveFavoriteProductIds(favorites);
  }

  Future<void> _onLoadDashboardData(
    LoadDashboardData event,
    Emitter<PosState> emit,
  ) async {
    // Agregasi server adalah sumber utama agar dashboard tidak bergantung
    // pada jumlah halaman riwayat yang sudah dimuat di perangkat.
    try {
      final dashboardData = await posRepository.getDashboardData(days: 7);
      emit(state.copyWith(dashboardData: dashboardData));
      return;
    } catch (_) {
      // Data lokal hanya menjadi fallback saat perangkat benar-benar offline.
    }
    try {
      final now = DateTime.now();

      // Calculate daily sales for the last 7 days
      final List<Map<String, dynamic>> dailySales = [];
      for (int i = 6; i >= 0; i--) {
        final d = now.subtract(Duration(days: i));
        final label = '${d.day}/${d.month}';

        final dayOrders = state.orders.where((o) {
          try {
            final date = DateTime.parse(o.date);
            return date.year == d.year &&
                date.month == d.month &&
                date.day == d.day;
          } catch (_) {
            return false;
          }
        }).toList();

        final revenue = dayOrders.fold(0.0, (sum, o) => sum + o.total);
        dailySales.add({
          'date': d.toIso8601String(),
          'label': label,
          'revenue': revenue,
          'transactions': dayOrders.length,
        });
      }

      // Today vs Yesterday
      final todayOrders = state.orders.where((o) {
        try {
          final date = DateTime.parse(o.date);
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        } catch (_) {
          return false;
        }
      }).toList();

      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayOrders = state.orders.where((o) {
        try {
          final date = DateTime.parse(o.date);
          return date.year == yesterday.year &&
              date.month == yesterday.month &&
              date.day == yesterday.day;
        } catch (_) {
          return false;
        }
      }).toList();

      final todayRevenue = todayOrders.fold(0.0, (sum, o) => sum + o.total);
      final yesterdayRevenue = yesterdayOrders.fold(
        0.0,
        (sum, o) => sum + o.total,
      );
      final todayTransactions = todayOrders.length;
      final yesterdayTransactions = yesterdayOrders.length;

      final revenueGrowth = yesterdayRevenue == 0
          ? 0.0
          : ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100;
      final transactionGrowth = yesterdayTransactions == 0
          ? 0.0
          : ((todayTransactions - yesterdayTransactions) /
                    yesterdayTransactions) *
                100;
      final todayAvgOrder = todayTransactions == 0
          ? 0.0
          : todayRevenue / todayTransactions;

      // Payment Breakdown
      final Map<String, double> paymentTotals = {};
      final Map<String, int> paymentCounts = {};
      for (var o in state.orders) {
        final method = o.paymentMethod.isNotEmpty ? o.paymentMethod : 'tunai';
        paymentTotals[method] = (paymentTotals[method] ?? 0) + o.total;
        paymentCounts[method] = (paymentCounts[method] ?? 0) + 1;
      }

      final totalRevenueAllTime = paymentTotals.values.fold(
        0.0,
        (sum, t) => sum + t,
      );
      final paymentBreakdown = paymentTotals.keys.map((method) {
        final total = paymentTotals[method]!;
        final count = paymentCounts[method]!;
        final percentage = totalRevenueAllTime == 0
            ? 0.0
            : (total / totalRevenueAllTime) * 100;
        return {
          'method': method,
          'label': method[0].toUpperCase() + method.substring(1),
          'count': count,
          'total': total,
          'percentage': percentage,
        };
      }).toList();

      final dashboardData = {
        'stats': {
          'today_revenue': todayRevenue,
          'today_transactions': todayTransactions,
          'today_avg_order': todayAvgOrder,
          'yesterday_revenue': yesterdayRevenue,
          'yesterday_transactions': yesterdayTransactions,
          'revenue_growth': revenueGrowth,
          'transaction_growth': transactionGrowth,
        },
        'daily_sales': dailySales,
        'payment_breakdown': paymentBreakdown,
        'top_products':
            [], // Simplified as orders don't store items locally yet
      };

      emit(state.copyWith(dashboardData: dashboardData));
    } catch (e) {
      // Silently fail
    }
  }
}
