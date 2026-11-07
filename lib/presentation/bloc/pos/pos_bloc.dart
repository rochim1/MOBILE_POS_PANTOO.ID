import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:uuid/uuid.dart';
import 'pos_event.dart';
import 'pos_state.dart';
import '../../../domain/repositories/pos_repository.dart';
import '../../../domain/models/hold_order.dart';
import '../../../domain/models/pos_order.dart';
import '../../../domain/models/pos_customer.dart';
import '../../../domain/models/pos_product.dart';
import '../../../domain/services/pos_shift_sync.dart';
import '../../../core/network/offline_network_failure.dart';
import '../../../core/utils/logger.dart';

String _dashboardLoadError(Object error) {
  if (error is OperationException) {
    final serverErrors = error.linkException is ServerException
        ? (error.linkException as ServerException).parsedResponse?.errors
        : null;
    final graphQLError =
        error.graphqlErrors.firstOrNull ?? serverErrors?.firstOrNull;
    if (graphQLError == null) {
      return 'Dashboard gagal dimuat. Periksa layanan server, lalu coba lagi.';
    }
    final code = graphQLError.extensions?['code']?.toString();
    if (code == 'UNAUTHORIZED') {
      return 'Sesi telah berakhir. Silakan login kembali.';
    }
    if (code == 'FORBIDDEN') {
      return graphQLError.message.toLowerCase().contains('shift')
          ? 'Buka shift kasir untuk melihat dashboard toko ini.'
          : 'Akun ini belum memiliki izin melihat dashboard POS.';
    }
  }
  return 'Dashboard gagal dimuat. Periksa layanan server, lalu coba lagi.';
}

String _defaultOrderType(Map<String, dynamic> config) {
  var value = config['default_order_type']?.toString() ?? 'take_away';
  if (value == 'online_delivery') value = 'delivery';
  final profile = config['business_profile']?.toString() ?? 'retail';
  final features = config['features'] as Map? ?? const {};
  final supported = <String>{'take_away'};
  if (features['use_tables'] == true) supported.add('dine_in');
  if (profile == 'restoran') {
    supported.addAll({'free_table', 'quick_service'});
  }
  if (features['use_delivery'] == true) supported.add('delivery');
  if (features['use_appointments'] == true) supported.add('reservation');
  return supported.contains(value) ? value : 'take_away';
}

class PosBloc extends Bloc<PosEvent, PosState> {
  final PosRepository posRepository;
  int _requestedDashboardDays = 7;
  String? _loadedOperatorId;
  String? _loadedTerminalUserId;
  int _loadVersion = 0;

  PosBloc({required this.posRepository}) : super(const PosState()) {
    on<LoadPosData>(_onLoadPosData);
    on<RefreshPosRuntimeConfig>(_onRefreshPosRuntimeConfig);
    on<RefreshProducts>(_onRefreshProducts);
    on<UpsertProductLocally>(_onUpsertProductLocally);
    on<RemoveProductLocally>(_onRemoveProductLocally);
    on<RefreshOrders>(_onRefreshOrders);
    on<LoadMoreOrders>(_onLoadMoreOrders);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<RemoveCartItem>(_onRemoveCartItem);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<UpdateCartUnitPrice>(_onUpdateCartUnitPrice);
    on<UpdateCartUnit>(_onUpdateCartUnit);
    on<ClearCart>(_onClearCart);
    on<EditActiveOrder>(_onEditActiveOrder);
    on<SelectCustomer>(_onSelectCustomer);
    on<HoldCurrentOrder>(_onHoldCurrentOrder);
    on<RestoreHeldOrder>(_onRestoreHeldOrder);
    on<RemoveHeldOrder>(_onRemoveHeldOrder);
    on<UpdateDiscount>(_onUpdateDiscount);
    on<SubmitPayment>(_onSubmitPayment);
    on<ToggleGridView>(_onToggleGridView);
    on<LoadDashboardData>(_onLoadDashboardData);
    on<LoadDashboardSnapshot>(_onLoadDashboardSnapshot);
    on<RefreshPricingPreview>(_onRefreshPricingPreview);
    on<UpdateOrderType>(_onUpdateOrderType);
    on<SelectOrderTable>(_onSelectOrderTable);
    on<UpdateSalesContext>(_onUpdateSalesContext);
    on<ToggleFavoriteProduct>(_onToggleFavoriteProduct);
  }

  Future<void> _onRefreshProducts(
    RefreshProducts event,
    Emitter<PosState> emit,
  ) async {
    emit(
      state.copyWith(
        productsRefreshing: true,
        errorMessage: '',
        status: state.status == PosStatus.paymentSuccess
            ? PosStatus.success
            : state.status,
      ),
    );
    try {
      final activeStore = state.checkoutStore;
      if (activeStore == null) {
        emit(
          state.copyWith(
            productsRefreshing: false,
            errorMessage: 'Toko belum terhubung ke lokasi penjualan aktif',
          ),
        );
        return;
      }
      final products = await posRepository.getProducts(
        branchId: activeStore.branchId,
      );
      emit(
        state.copyWith(
          products: products,
          productsRefreshing: false,
          errorMessage: '',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          productsRefreshing: false,
          errorMessage: 'Katalog gagal dimuat ulang',
        ),
      );
    }
  }

  void _onUpsertProductLocally(
    UpsertProductLocally event,
    Emitter<PosState> emit,
  ) {
    final products = [...state.products];
    final index = products.indexWhere((item) => item.id == event.product.id);
    if (index >= 0) {
      final current = products[index];
      // Mutation update inventaris hanya mengembalikan field master dasar. Jangan
      // menimpa stok outlet dan metadata POS yang berasal dari query katalog.
      products[index] = PosProduct(
        id: event.product.id,
        code: event.product.code,
        name: event.product.name,
        category: event.product.category,
        productType: current.productType,
        promoEligible: current.promoEligible,
        tracksStock: current.tracksStock,
        price: event.product.price,
        stock: current.stock,
        sku: current.sku,
        barcode: current.barcode,
        imageUrl: current.imageUrl,
        baseUnit: current.baseUnit,
        unitConversions: current.unitConversions,
      );
    } else {
      products.insert(0, event.product);
    }
    emit(state.copyWith(products: products));
  }

  void _onRemoveProductLocally(
    RemoveProductLocally event,
    Emitter<PosState> emit,
  ) {
    emit(
      state.copyWith(
        products: state.products
            .where((item) => item.id != event.productId)
            .toList(),
        cart: Map<PosProduct, double>.fromEntries(
          state.cart.entries.where((entry) => entry.key.id != event.productId),
        ),
        selectedUnits: Map<String, String>.of(state.selectedUnits)
          ..remove(event.productId),
        manualUnitPrices: Map<String, double>.of(state.manualUnitPrices)
          ..remove(event.productId),
      ),
    );
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
    final request = ++_loadVersion;
    final operatorId = posRepository.activeOperatorId;
    final terminalUserId = posRepository.terminalUserId;
    final previousStoreId = state.checkoutStore?.id;
    bool isCurrent() =>
        request == _loadVersion &&
        operatorId == posRepository.activeOperatorId &&
        terminalUserId == posRepository.terminalUserId;
    if (_loadedOperatorId != operatorId ||
        _loadedTerminalUserId != terminalUserId) {
      // Keep a locked terminal's previous operator data out of the next
      // operator's cart, dashboard, permissions, and offline history.
      _loadedOperatorId = operatorId;
      _loadedTerminalUserId = terminalUserId;
      emit(PosState(status: PosStatus.loading, isGridView: state.isGridView));
    } else {
      emit(
        state.copyWith(status: PosStatus.loading, checkoutSyncFailed: false),
      );
    }
    try {
      final runtimeConfig = await posRepository.getRuntimeConfig();
      if (!isCurrent()) return;
      // Navigation authorization is independently useful to approvers/Finance.
      // A store/shift failure must block checkout, not erase permitted modules.
      emit(
        state.copyWith(runtimeConfig: runtimeConfig, status: PosStatus.loading),
      );
      final stores = await posRepository.getStores();
      if (!isCurrent()) return;
      final permissions =
          runtimeConfig['permissions'] as Map<String, dynamic>? ??
          const <String, dynamic>{};
      final activeShift = permissions['view_shifts'] == true
          ? await discoverCheckoutShift(
              stores: stores,
              runtimeConfig: runtimeConfig,
              operatorId: operatorId,
              terminalUserId: terminalUserId,
              preferredStoreId: previousStoreId,
              readShift: posRepository.getActiveShiftForStore,
              isCurrent: isCurrent,
            )
          : null;
      if (!isCurrent()) return;
      if (state.cart.isNotEmpty &&
          previousStoreId != null &&
          activeShift != null &&
          previousStoreId != activeShift['toko_id']?.toString()) {
        throw StateError(
          'Shift aktif berada di toko lain. Keranjang tidak dipindahkan. Kosongkan keranjang untuk menyelaraskan toko.',
        );
      }
      final canOperateWithoutShift =
          runtimeConfig['allow_out_of_shift'] == true;
      final customers =
          (activeShift == null && !canOperateWithoutShift) ||
              permissions['view_customers'] != true
          ? <PosCustomer>[]
          : await posRepository.getCustomers();
      final ordersPage =
          activeShift == null || permissions['view_transactions'] != true
          ? (items: <PosOrder>[], hasMore: false)
          : await posRepository.getOrdersPage();
      if (!isCurrent()) return;
      final orders = ordersPage.items;
      final activeStore = PosState(
        stores: stores,
        activeShift: activeShift,
        runtimeConfig: runtimeConfig,
      ).checkoutStore;
      if (activeStore == null || activeStore.branchId.isEmpty) {
        emit(
          state.copyWith(
            status: PosStatus.success,
            customers: customers,
            runtimeConfig: runtimeConfig,
            stores: stores,
            orders: orders,
            ordersPage: 0,
            ordersHasMore: ordersPage.hasMore,
            activeShift: activeShift,
            clearActiveShift: activeShift == null,
            errorMessage: 'Toko shift belum terhubung ke warehouse aktif',
          ),
        );
        return;
      }
      // Keep verified store/permission context even if a later catalog request
      // fails. Otherwise a restricted operator appears to have no store at all.
      emit(
        state.copyWith(
          customers: customers,
          stores: stores,
          runtimeConfig: runtimeConfig,
          activeShift: activeShift,
          clearActiveShift: activeShift == null,
        ),
      );
      final products =
          // POS stock is scoped to a verified active shift. Do not turn a
          // correctly denied pre-shift catalog read into a shift-sync failure.
          (activeShift != null || canOperateWithoutShift) &&
              (permissions['view_products'] == true ||
                  permissions['use_cashier'] == true)
          ? await posRepository.getProducts(branchId: activeStore.branchId)
          : <PosProduct>[];
      final favoriteProductIds = products.isNotEmpty
          ? await posRepository.getFavoriteProductIds()
          : <String>{};
      final heldOrders =
          activeShift != null && permissions['use_cashier'] == true
          ? await posRepository.getHeldOrders(
              storeId: activeStore.id,
              shiftId: activeShift['_id']?.toString() ?? '',
            )
          : <HoldOrder>[];
      if (!isCurrent()) return;

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
          clearActiveShift: activeShift == null,
          runtimeConfig: runtimeConfig,
          orderType: _defaultOrderType(runtimeConfig),
          salesChannel:
              runtimeConfig['default_sales_channel']?.toString() ?? 'retail',
          customerSegment: 'regular',
          priceLevel:
              runtimeConfig['default_price_level']?.toString() ?? 'retail',
          taxPercent: (runtimeConfig['tax_percent'] as num?)?.toDouble() ?? 0,
          discountPolicy:
              runtimeConfig['default_discount_policy']?.toString() ?? 'stack',
          favoriteProductIds: favoriteProductIds,
          errorMessage: '',
        ),
      );

      // Also load dashboard data
      add(LoadDashboardData(days: _requestedDashboardDays));
    } catch (e) {
      if (!isCurrent()) return;
      emit(
        state.copyWith(
          status: PosStatus.failure,
          clearActiveShift: true,
          checkoutSyncFailed: true,
          errorMessage: e is StateError
              ? e.message.toString()
              : 'Data toko dan shift belum dapat diperiksa. Periksa koneksi atau PIN, lalu coba lagi.',
        ),
      );
    }
  }

  Future<void> _onRefreshPosRuntimeConfig(
    RefreshPosRuntimeConfig event,
    Emitter<PosState> emit,
  ) async {
    final runtimeConfig = await posRepository.getRuntimeConfig();
    if (event.preserveCheckout) {
      emit(state.copyWith(runtimeConfig: runtimeConfig));
      return;
    }
    emit(
      state.copyWith(
        runtimeConfig: runtimeConfig,
        orderType: _defaultOrderType(runtimeConfig),
        salesChannel:
            runtimeConfig['default_sales_channel']?.toString() ?? 'retail',
        priceLevel:
            runtimeConfig['default_price_level']?.toString() ?? 'retail',
        taxPercent: (runtimeConfig['tax_percent'] as num?)?.toDouble() ?? 0,
        discountPolicy:
            runtimeConfig['default_discount_policy']?.toString() ?? 'stack',
        errorMessage: '',
      ),
    );
  }

  void _onAddToCart(AddToCart event, Emitter<PosState> emit) {
    final newCart = Map.of(state.cart);
    final current = newCart[event.product] ?? 0.0;
    final features = state.runtimeConfig['features'] as Map?;
    final trackStock = features?['track_stock'] != false;
    if (trackStock &&
        event.product.tracksStock &&
        state.baseQuantityFor(event.product, current + 1.0) >
            event.product.stock) {
      emit(
        state.copyWith(
          status: PosStatus.failure,
          errorMessage: 'Stok ${event.product.name} tidak mencukupi',
        ),
      );
      return;
    }
    newCart[event.product] = current + 1.0;
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
    final prices = Map<String, double>.of(state.manualUnitPrices);
    final units = Map<String, String>.of(state.selectedUnits);
    final currentQty = newCart[event.product] ?? 0.0;
    if (currentQty <= 1) {
      newCart.remove(event.product);
      prices.remove(event.product.id);
      units.remove(event.product.id);
    } else {
      newCart[event.product] = currentQty - 1.0;
    }
    emit(
      state.copyWith(
        cart: newCart,
        manualUnitPrices: prices,
        selectedUnits: units,
        status: PosStatus.success,
        clearPricingPreview: true,
      ),
    );
    add(RefreshPricingPreview());
  }

  void _onRemoveCartItem(RemoveCartItem event, Emitter<PosState> emit) {
    final newCart = Map.of(state.cart)..remove(event.product);
    final prices = Map<String, double>.of(state.manualUnitPrices)
      ..remove(event.product.id);
    final units = Map<String, String>.of(state.selectedUnits)
      ..remove(event.product.id);
    emit(
      state.copyWith(
        cart: newCart,
        manualUnitPrices: prices,
        selectedUnits: units,
        status: PosStatus.success,
        clearPricingPreview: true,
      ),
    );
    add(RefreshPricingPreview());
  }

  void _onUpdateCartUnitPrice(
    UpdateCartUnitPrice event,
    Emitter<PosState> emit,
  ) {
    if (state.runtimeConfig['allow_cashier_price_edit'] != true ||
        event.price <= 0 ||
        !state.cart.containsKey(event.product)) {
      return;
    }
    emit(
      state.copyWith(
        manualUnitPrices: {
          ...state.manualUnitPrices,
          event.product.id: event.price,
        },
        status: PosStatus.success,
        clearPricingPreview: true,
      ),
    );
    add(RefreshPricingPreview());
  }

  void _onUpdateCartUnit(UpdateCartUnit event, Emitter<PosState> emit) {
    if (!state.cart.containsKey(event.product)) return;
    final unit = event.unit.trim().toLowerCase();
    if (!event.product.saleUnits.contains(unit)) return;
    final quantity = state.cart[event.product] ?? 0;
    if ((state.runtimeConfig['features'] as Map?)?['track_stock'] != false &&
        event.product.tracksStock &&
        quantity * event.product.factorForUnit(unit) > event.product.stock) {
      emit(
        state.copyWith(
          status: PosStatus.failure,
          errorMessage:
              'Stok ${event.product.name} tidak mencukupi untuk satuan $unit',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        selectedUnits: {...state.selectedUnits, event.product.id: unit},
        manualUnitPrices: Map<String, double>.of(state.manualUnitPrices)
          ..remove(event.product.id),
        status: PosStatus.success,
        clearPricingPreview: true,
      ),
    );
    add(RefreshPricingPreview());
  }

  void _onUpdateQuantity(UpdateQuantity event, Emitter<PosState> emit) {
    final newCart = Map.of(state.cart);
    final prices = Map<String, double>.of(state.manualUnitPrices);
    final units = Map<String, String>.of(state.selectedUnits);
    final currentQty = newCart[event.product] ?? 0.0;
    final nextQty = currentQty + event.delta;

    final features = state.runtimeConfig['features'] as Map?;
    final trackStock = features?['track_stock'] != false;
    if (trackStock &&
        event.product.tracksStock &&
        state.baseQuantityFor(event.product, nextQty) > event.product.stock) {
      emit(
        state.copyWith(
          status: PosStatus.failure,
          errorMessage: 'Stok ${event.product.name} tidak mencukupi',
        ),
      );
      return;
    } else if (nextQty <= 0) {
      newCart.remove(event.product);
      prices.remove(event.product.id);
      units.remove(event.product.id);
    } else {
      newCart[event.product] = nextQty;
    }
    emit(
      state.copyWith(
        cart: newCart,
        manualUnitPrices: prices,
        selectedUnits: units,
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
        manualUnitPrices: const {},
        selectedUnits: const {},
        manualDiscountPercent: 0,
        promoCode: '',
        discountPolicy: state.defaultDiscountPolicy,
        orderType: _defaultOrderType(state.runtimeConfig),
        clearSelectedTable: true,
        salesChannel: state.defaultSalesChannel,
        customerSegment: state.defaultCustomerSegment,
        priceLevel: state.defaultPriceLevel,
        taxPercent: state.configuredTaxPercent,
        clearSelectedCustomer: true,
        clearEditingOrder: true,
        status: PosStatus.success,
        clearPricingPreview: true,
      ),
    );
  }

  void _onEditActiveOrder(EditActiveOrder event, Emitter<PosState> emit) {
    final order = event.order;
    final productsById = {
      for (final product in state.products) product.id: product,
    };
    final cart = <PosProduct, double>{};
    final selectedUnits = <String, String>{};
    for (final item in order.items) {
      final product =
          productsById[item.productId] ??
          ((item.productId ?? '').isEmpty
              ? null
              : PosProduct(
                  id: item.productId!,
                  code: item.productCode ?? '',
                  name: item.productName ?? 'Produk',
                  category: 'Pesanan aktif',
                  price: item.price ?? 0,
                  stock: 0,
                  tracksStock: false,
                  baseUnit: item.unit ?? 'unit',
                ));
      final quantity = item.quantity ?? 0.0;
      if (product != null && quantity > 0) {
        cart[product] = quantity;
        final unit = item.unit?.trim().toLowerCase();
        if (unit != null && product.saleUnits.contains(unit)) {
          selectedUnits[product.id] = unit;
        }
      }
    }
    final matchingCustomers = state.customers.where(
      (customer) => customer.id == order.customerId,
    );
    emit(
      state.copyWith(
        cart: cart,
        selectedUnits: selectedUnits,
        orderType: 'dine_in',
        selectedTableId: order.tableId,
        selectedTableName: order.tableName,
        selectedCustomer: matchingCustomers.firstOrNull,
        clearSelectedCustomer: matchingCustomers.isEmpty,
        editingOrderId: order.id,
        editingOrderNumber: order.orderNumber,
        status: PosStatus.success,
        clearPricingPreview: true,
      ),
    );
    add(RefreshPricingPreview());
  }

  Future<void> _onHoldCurrentOrder(
    HoldCurrentOrder event,
    Emitter<PosState> emit,
  ) async {
    if (state.cart.isEmpty) return;
    final activeStoreId = state.activeShift?['toko_id']?.toString();
    final activeStores = state.stores.where(
      (store) => activeStoreId != null
          ? store.id == activeStoreId
          : store.status.toLowerCase() == 'active',
    );
    if (activeStores.isEmpty) {
      emit(
        state.copyWith(
          status: PosStatus.failure,
          errorMessage: 'Toko aktif tidak ditemukan',
        ),
      );
      return;
    }

    final holdOrder = HoldOrder(
      id: 'HOLD-${const Uuid().v4().substring(0, 6).toUpperCase()}',
      time: DateTime.now(),
      cart: Map.of(state.cart),
      manualUnitPrices: Map.of(state.manualUnitPrices),
      selectedUnits: Map.of(state.selectedUnits),
      customer: state.selectedCustomer,
      store: activeStores.first,
      notes: event.notes,
      manualDiscountPercent: state.manualDiscountPercent,
      promoCode: state.promoCode,
      discountPolicy: state.discountPolicy,
      orderType: state.orderType,
      tableId: state.selectedTableId,
      tableName: state.selectedTableName,
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
        manualUnitPrices: const {},
        selectedUnits: const {},
        manualDiscountPercent: 0,
        promoCode: '',
        discountPolicy: state.defaultDiscountPolicy,
        orderType: _defaultOrderType(state.runtimeConfig),
        clearSelectedTable: true,
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
    if (state.cart.isEmpty) {
      emit(state.copyWith(clearPricingPreview: true));
      return;
    }
    final storeId = state.checkoutStore?.id ?? '';
    if (storeId.isEmpty) {
      emit(state.copyWith(clearPricingPreview: true));
      return;
    }
    final requestedSubtotal = state.subTotal;
    final result = await posRepository.previewPricing(
      cart: state.cart,
      tokoId: storeId,
      unitPrices: state.manualUnitPrices,
      selectedUnits: state.selectedUnits,
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
          // Preview harga membutuhkan server, tetapi kegagalannya tidak boleh
          // memblokir transaksi offline. Harga cache/produk tetap digunakan.
          status: PosStatus.success,
          errorMessage: '',
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
        manualUnitPrices: event.order.manualUnitPrices,
        selectedUnits: event.order.selectedUnits,
        manualDiscountPercent: event.order.manualDiscountPercent,
        promoCode: event.order.promoCode,
        discountPolicy: event.order.discountPolicy,
        orderType: event.order.orderType,
        selectedTableId: event.order.tableId,
        selectedTableName: event.order.tableName,
        clearSelectedTable: event.order.tableId == null,
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
    if (state.promoCode.trim().isNotEmpty && !state.promoApplied) {
      emit(
        state.copyWith(
          status: PosStatus.failure,
          errorMessage:
              state.pricingPreview?['promo_message']?.toString().isNotEmpty ==
                  true
              ? state.pricingPreview!['promo_message'].toString()
              : 'Kode promo belum terverifikasi. Sambungkan internet atau hapus promo.',
        ),
      );
      return;
    }
    final stateCustomer = state.selectedCustomer;
    final selectedCustomer =
        stateCustomer != null && stateCustomer.id.trim().isNotEmpty
        ? stateCustomer
        : event.customerOverride;
    final features = state.runtimeConfig['features'] as Map?;
    final fulfillmentRequiresCustomer = const {
      'delivery',
      'online_delivery',
      'reservation',
    }.contains(state.orderType);
    if ((features?['require_customer'] == true ||
            fulfillmentRequiresCustomer) &&
        (selectedCustomer == null || selectedCustomer.id.trim().isEmpty)) {
      emit(
        state.copyWith(
          status: PosStatus.failure,
          errorMessage: fulfillmentRequiresCustomer
              ? 'Pelanggan wajib dipilih untuk tipe pemenuhan ini'
              : 'Pelanggan wajib dipilih untuk profil POS ini',
        ),
      );
      return;
    }

    emit(state.copyWith(status: PosStatus.loading));
    try {
      final tokoId = state.checkoutStore?.id ?? '';
      if (tokoId.isEmpty) {
        emit(
          state.copyWith(
            status: PosStatus.failure,
            errorMessage: 'Toko aktif belum tersedia untuk transaksi',
          ),
        );
        return;
      }

      final result = await posRepository.submitTransaction(
        cart: state.cart,
        total: state.grandTotal,
        paymentMethod: event.paymentMethod,
        tokoId: tokoId,
        shiftId: state.activeShift?['_id']?.toString() ?? '',
        unitPrices: state.manualUnitPrices,
        selectedUnits: state.selectedUnits,
        receiptUnitPrices: {
          for (final product in state.cart.keys)
            product.id: state.unitPriceFor(product),
        },
        // Cash is stored in whole rupiah. Round here as a final guard against
        // floating-point artefacts from discounts/tax calculations.
        cashReceived: event.cashReceived.roundToDouble(),
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
        tableId: state.selectedTableId,
        salesChannel: state.salesChannel,
        customerSegment: state.customerSegment,
        priceLevel: state.priceLevel,
        pajak: state.taxAmount,
        pelangganId: selectedCustomer?.id,
        pelangganName: selectedCustomer?.name,
        pelangganPhone: selectedCustomer?.phone,
        pelangganEmail: selectedCustomer?.email,
        serviceOrder: event.serviceOrder,
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
            manualUnitPrices: const {},
            selectedUnits: const {},
            manualDiscountPercent: 0,
            promoCode: '',
            discountPolicy: state.defaultDiscountPolicy,
            orderType: _defaultOrderType(state.runtimeConfig),
            clearSelectedTable: true,
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
          errorMessage: e is StateError
              ? e.message.toString()
              : 'Terjadi kesalahan sistem',
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
      emit(
        state.copyWith(
          orderType: event.orderType,
          clearSelectedTable: !{
            'dine_in',
            'reservation',
          }.contains(event.orderType),
        ),
      );
    }
  }

  void _onSelectOrderTable(SelectOrderTable event, Emitter<PosState> emit) {
    final hasTable = event.tableId != null && event.tableId!.trim().isNotEmpty;
    emit(
      state.copyWith(
        orderType: hasTable && state.orderType != 'reservation'
            ? 'dine_in'
            : state.orderType,
        selectedTableId: event.tableId,
        selectedTableName: event.tableName,
        clearSelectedTable: !hasTable,
      ),
    );
  }

  void _onSelectCustomer(SelectCustomer event, Emitter<PosState> emit) {
    final customerLevel = event.customer?.priceLevel.trim();
    final level = customerLevel != null && customerLevel.isNotEmpty
        ? customerLevel
        : state.defaultPriceLevel;
    emit(
      state.copyWith(
        selectedCustomer: event.customer,
        clearSelectedCustomer: event.customer == null,
        priceLevel: level,
        customerSegment: 'regular',
        clearPricingPreview: true,
        status: PosStatus.success,
        errorMessage: '',
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
    _requestedDashboardDays = event.days;
    if (state.runtimeConfig.isNotEmpty && state.activeShift == null) {
      emit(
        state.copyWith(
          dashboardData: const {
            '_dashboard_error':
                'Buka shift kasir untuk melihat dashboard toko ini.',
          },
        ),
      );
      return;
    }
    // Agregasi server adalah sumber utama agar dashboard tidak bergantung
    // pada jumlah halaman riwayat yang sudah dimuat di perangkat.
    try {
      final dashboardData = await posRepository.getDashboardData(
        days: event.days,
      );
      if (_requestedDashboardDays != event.days) return;
      emit(state.copyWith(dashboardData: dashboardData));
      return;
    } catch (error) {
      if (_requestedDashboardDays != event.days) return;
      final offline =
          error is OfflineReadUnavailable || isOfflineReadFailure(error);
      if (!offline) {
        appLogger.w('[POS] Dashboard gagal dimuat', error: error);
      }
      final failureMessage = _dashboardLoadError(error);
      if (state.dashboardData != null &&
          state.dashboardData?['_dashboard_days'] == event.days &&
          state.dashboardData?['_offline_unavailable'] != true &&
          state.dashboardData?['_dashboard_error'] == null) {
        if (!offline) {
          emit(
            state.copyWith(
              dashboardData: {
                ...state.dashboardData!,
                '_refresh_error':
                    '$failureMessage Data terakhir tetap ditampilkan.',
              },
            ),
          );
        }
        return;
      }
      if (!offline) {
        emit(
          state.copyWith(dashboardData: {'_dashboard_error': failureMessage}),
        );
        return;
      }
      if (state.orders.isEmpty) {
        emit(
          state.copyWith(dashboardData: const {'_offline_unavailable': true}),
        );
        return;
      }
    }
    try {
      final now = DateTime.now();

      // Calculate daily sales for the selected period.
      final List<Map<String, dynamic>> dailySales = [];
      for (int i = event.days - 1; i >= 0; i--) {
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

      final currentStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: event.days - 1));
      final currentOrders = state.orders.where((o) {
        try {
          final date = DateTime.parse(o.date);
          return !date.isBefore(currentStart);
        } catch (_) {
          return false;
        }
      }).toList();

      final previousEnd = currentStart.subtract(
        const Duration(microseconds: 1),
      );
      final previousStart = DateTime(
        previousEnd.year,
        previousEnd.month,
        previousEnd.day,
      ).subtract(Duration(days: event.days - 1));
      final previousOrders = state.orders.where((o) {
        try {
          final date = DateTime.parse(o.date);
          return !date.isBefore(previousStart) && !date.isAfter(previousEnd);
        } catch (_) {
          return false;
        }
      }).toList();

      final todayRevenue = currentOrders.fold(0.0, (sum, o) => sum + o.total);
      final yesterdayRevenue = previousOrders.fold(
        0.0,
        (sum, o) => sum + o.total,
      );
      final todayTransactions = currentOrders.length;
      final yesterdayTransactions = previousOrders.length;

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
      for (final o in currentOrders) {
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
        '_dashboard_days': event.days,
        '_offline_snapshot': true,
        '_offline_estimate': true,
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
      emit(state.copyWith(dashboardData: const {'_offline_unavailable': true}));
    }
  }

  Future<void> _onLoadDashboardSnapshot(
    LoadDashboardSnapshot event,
    Emitter<PosState> emit,
  ) async {
    _requestedDashboardDays = event.days;
    final snapshot = await posRepository.getDashboardSnapshot(days: event.days);
    if (_requestedDashboardDays != event.days) return;
    if (snapshot == null) return;
    // A slower local read must not overwrite an already-refreshed server view.
    if (state.dashboardData?['_offline_snapshot'] == false &&
        state.dashboardData?['_dashboard_days'] == event.days) {
      return;
    }
    emit(state.copyWith(dashboardData: snapshot));
  }
}
