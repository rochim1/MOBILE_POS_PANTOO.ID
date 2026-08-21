import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/pos/pos_bloc.dart';
import '../../../bloc/pos/pos_event.dart';
import '../../../bloc/pos/pos_state.dart';
import '../../../../domain/models/pos_customer.dart';
import '../../../../domain/repositories/pos_repository.dart';
import '../../../../injections.dart';
import 'pos_quick_customer_dialog.dart';

class PosInfoPanel extends StatefulWidget {
  final bool isMobile;
  const PosInfoPanel({super.key, required this.isMobile});

  @override
  State<PosInfoPanel> createState() => _PosInfoPanelState();
}

class _CustomerPickerSheet extends StatefulWidget {
  final PosCustomer? selected;

  const _CustomerPickerSheet({this.selected});

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final PosRepository _repository = sl<PosRepository>();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<PosCustomer> _items = [];
  Timer? _debounce;
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 240) _load();
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _load(reset: true),
    );
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading && !reset) return;
    if (!_hasMore && !reset) return;
    final version = reset ? ++_requestVersion : _requestVersion;
    if (reset) {
      _page = 1;
      _hasMore = true;
    }
    setState(() => _loading = true);
    final result = await _repository.getCustomersPage(
      page: _page,
      limit: 20,
      search: _searchController.text,
    );
    if (!mounted || version != _requestVersion) return;
    setState(() {
      if (reset) _items.clear();
      final knownIds = _items.map((item) => item.id).toSet();
      _items.addAll(result.items.where((item) => knownIds.add(item.id)));
      _hasMore = result.hasMore;
      if (_hasMore) _page++;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pilih Pelanggan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama atau nomor telepon...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final customer = await showPosQuickCustomerDialog(context);
                  if (!context.mounted || customer == null) return;
                  Navigator.pop(context, customer);
                },
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Tambah pelanggan baru'),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _items.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_off)),
                    title: const Text('Tanpa pelanggan'),
                    trailing: widget.selected == null
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.pop(
                      context,
                      const PosCustomer(
                        id: '',
                        name: '',
                        phone: '',
                        priceLevel: 'retail',
                      ),
                    ),
                  );
                }
                if (index > _items.length) {
                  if (_loading) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (_items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('Pelanggan tidak ditemukan')),
                    );
                  }
                  return const SizedBox(height: 24);
                }
                final customer = _items[index - 1];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      customer.name.isEmpty
                          ? '?'
                          : customer.name[0].toUpperCase(),
                    ),
                  ),
                  title: Text(customer.name),
                  subtitle: Text(
                    '${customer.phone.isEmpty ? 'Tanpa nomor telepon' : customer.phone} · ${customer.priceLevel}',
                  ),
                  trailing: widget.selected?.id == customer.id
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.pop(context, customer),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PosInfoPanelState extends State<PosInfoPanel> {
  String _activeInfoTab = 'utama';
  final TextEditingController _promoController = TextEditingController();
  String _lastSyncedPromoCode = '';

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        if (state.promoCode != _lastSyncedPromoCode) {
          _lastSyncedPromoCode = state.promoCode;
          _promoController.value = TextEditingValue(
            text: state.promoCode,
            selection: TextSelection.collapsed(offset: state.promoCode.length),
          );
        }
        return _buildTransactionContext(state);
      },
    );
  }

  Widget _buildTransactionContext(PosState state) {
    final permissions = state.runtimeConfig['permissions'] as Map?;
    final canOverridePricing = permissions?['manage_settings'] == true;
    final promoMessage = state.pricingPreview?['promo_message']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detail Transaksi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _buildCustomerField(state),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.sell_outlined, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Konteks harga',
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    Text(
                      '${_labelForChannel(state.salesChannel)} · ${_labelForPrice(state.priceLevel)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (canOverridePricing)
                TextButton(
                  onPressed: () => _showAdvancedPricing(state),
                  child: const Text('Ubah'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _fieldLabel('Promo & Diskon', 'Terapkan kode setelah selesai diketik'),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promoController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Kode promo',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => context.read<PosBloc>().add(
                UpdateDiscount(
                  manualDiscountPercent: state.manualDiscountPercent,
                  promoCode: _promoController.text.trim().toUpperCase(),
                  discountPolicy: state.discountPolicy,
                ),
              ),
              child: const Text('Terapkan'),
            ),
          ],
        ),
        if (state.promoCode.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                state.promoApplied ? Icons.check_circle : Icons.info_outline,
                size: 18,
                color: state.promoApplied ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  promoMessage ??
                      (state.promoApplied
                          ? 'Promo berhasil diterapkan'
                          : 'Promo belum memenuhi ketentuan'),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () {
                  _promoController.clear();
                  context.read<PosBloc>().add(
                    UpdateDiscount(
                      manualDiscountPercent: state.manualDiscountPercent,
                      promoCode: '',
                      discountPolicy: state.discountPolicy,
                    ),
                  );
                },
                child: const Text('Hapus'),
              ),
            ],
          ),
        ],
        if (canOverridePricing) ...[
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'Diskon manual (otorisasi)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            children: [
              TextFormField(
                initialValue: state.manualDiscountPercent.toStringAsFixed(0),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Diskon manual',
                  suffixText: '%',
                  helperText: 'Perubahan tercatat sebagai override transaksi',
                ),
                onChanged: (value) => context.read<PosBloc>().add(
                  UpdateDiscount(
                    manualDiscountPercent: (double.tryParse(value) ?? 0).clamp(
                      0,
                      100,
                    ),
                    promoCode: state.promoCode,
                    discountPolicy: state.discountPolicy,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // Legacy tab builders are kept temporarily for backward-compatible layout
  // references while the streamlined transaction panel is rolled out.
  // ignore: unused_element
  Widget _buildInfoTabs() {
    return Row(
      children: [
        Expanded(child: _buildInfoTab('utama', 'Utama', Icons.settings)),
        const SizedBox(width: 8),
        Expanded(child: _buildInfoTab('promo', 'Promo', Icons.local_offer)),
        const SizedBox(width: 8),
        Expanded(
          child: _buildInfoTab('harga', 'Harga', Icons.price_change_outlined),
        ),
      ],
    );
  }

  Widget _buildInfoTab(String key, String label, IconData icon) {
    final isActive = _activeInfoTab == key;
    return GestureDetector(
      onTap: () => setState(() => _activeInfoTab = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildInfoContent(PosState state) {
    if (_activeInfoTab == 'utama') return _buildMainInfoTab(state);
    if (_activeInfoTab == 'promo') return _buildPromoTab(state);
    if (_activeInfoTab == 'harga') return _buildPricingTab(state);
    return const SizedBox();
  }

  Widget _buildMainInfoTab(PosState state) {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: widget.isMobile ? double.infinity : 320,
              child: _buildCustomerField(state),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomerField(PosState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(
          'Pelanggan Transaksi',
          'Pilih pelanggan untuk poin, promo, dan riwayat pembelian',
        ),
        const SizedBox(height: 7),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showCustomerPicker(state.selectedCustomer),
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              prefixIcon: const Icon(Icons.search, color: Colors.black54),
              suffixIcon: const Icon(Icons.keyboard_arrow_down),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            child: Text(
              state.selectedCustomer == null
                  ? 'Tanpa pelanggan'
                  : '${state.selectedCustomer!.name}${state.selectedCustomer!.phone.isEmpty ? '' : ' • ${state.selectedCustomer!.phone}'}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCustomerPicker(PosCustomer? selected) async {
    final customer = await showModalBottomSheet<PosCustomer?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CustomerPickerSheet(selected: selected),
    );
    if (!mounted) return;
    if (customer != null) {
      context.read<PosBloc>().add(
        SelectCustomer(customer.id.isEmpty ? null : customer),
      );
    }
  }

  Future<void> _showAdvancedPricing(PosState state) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: context.read<PosBloc>(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Konteks Transaksi & Harga',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Channel mencatat asal transaksi; level harga menentukan daftar harga produk.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              _buildPricingTab(state),
            ],
          ),
        ),
      ),
    );
  }

  String _labelForChannel(String value) =>
      const {
        'retail': 'Retail',
        'member': 'Member',
        'non_member': 'Non Member',
        'reseller': 'Reseller',
        'marketplace': 'Marketplace',
        'offline': 'Offline',
      }[value] ??
      value;

  String _labelForPrice(String value) =>
      const {
        'retail': 'Harga Eceran',
        'member': 'Harga Member',
        'reseller': 'Harga Reseller',
        'grosir': 'Harga Grosir',
        'vip': 'Harga VIP',
        'corporate': 'Harga Corporate',
        'distributor': 'Harga Distributor',
      }[value] ??
      value;

  Widget _buildPromoTab(PosState state) {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: widget.isMobile ? double.infinity : 240,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel(
                    'Kode Promo',
                    'Masukkan kode voucher atau promo yang digunakan',
                  ),
                  const SizedBox(height: 7),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Contoh: HEMAT10',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      context.read<PosBloc>().add(
                        UpdateDiscount(
                          manualDiscountPercent: state.manualDiscountPercent,
                          promoCode: value,
                          discountPolicy: state.discountPolicy,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(
              width: widget.isMobile ? double.infinity : 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fieldLabel(
                    'Diskon Manual (%)',
                    'Potongan tambahan antara 0–100%',
                  ),
                  const SizedBox(height: 7),
                  TextFormField(
                    initialValue: state.manualDiscountPercent.toStringAsFixed(
                      state.manualDiscountPercent % 1 == 0 ? 0 : 2,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Contoh: 10',
                      suffixText: '%',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => context.read<PosBloc>().add(
                      UpdateDiscount(
                        manualDiscountPercent: (double.tryParse(value) ?? 0)
                            .clamp(0, 100),
                        promoCode: state.promoCode,
                        discountPolicy: state.discountPolicy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _pricingDropdown(
              label: 'Aturan Kombinasi Diskon',
              description: 'Tentukan cara promo dan diskon manual diterapkan',
              value: state.discountPolicy,
              width: widget.isMobile ? double.infinity : 240,
              items: const {
                'stack': 'Manual + Promo',
                'promo_only': 'Promo saja',
                'manual_only': 'Manual saja',
                'best_of_manual_or_promo': 'Diskon terbaik',
              },
              onChanged: (value) => context.read<PosBloc>().add(
                UpdateDiscount(
                  manualDiscountPercent: state.manualDiscountPercent,
                  promoCode: state.promoCode,
                  discountPolicy: value,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPricingTab(PosState state) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _pricingDropdown(
          label: 'Channel Penjualan',
          description: 'Asal transaksi; tidak menentukan cara pesanan dipenuhi',
          value: state.salesChannel,
          width: widget.isMobile ? double.infinity : 220,
          items: {
            for (final value in state.salesChannelOptions)
              value: _labelForChannel(value),
          },
          onChanged: (value) => _updateContext(state, salesChannel: value),
        ),
        _pricingDropdown(
          label: 'Level Harga',
          description: 'Daftar harga yang diterapkan pada produk',
          value: state.priceLevel,
          width: widget.isMobile ? double.infinity : 220,
          items: {
            for (final value in state.priceLevelOptions)
              value: _labelForPrice(value),
          },
          onChanged: (value) => _updateContext(state, priceLevel: value),
        ),
      ],
    );
  }

  Widget _pricingDropdown({
    required String label,
    String? description,
    required String value,
    required double width,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    final safeValue = items.containsKey(value) ? value : items.keys.first;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label, description),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            initialValue: safeValue,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            items: items.entries
                .map(
                  (item) => DropdownMenuItem(
                    value: item.key,
                    child: Text(item.value, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (next) {
              if (next != null) onChanged(next);
            },
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label, String? description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        if (description != null) ...[
          const SizedBox(height: 2),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ],
    );
  }

  void _updateContext(
    PosState state, {
    String? salesChannel,
    String? customerSegment,
    String? priceLevel,
    double? taxPercent,
  }) {
    context.read<PosBloc>().add(
      UpdateSalesContext(
        salesChannel: salesChannel ?? state.salesChannel,
        customerSegment: customerSegment ?? state.customerSegment,
        priceLevel: priceLevel ?? state.priceLevel,
        taxPercent: taxPercent ?? state.taxPercent,
      ),
    );
  }
}
