import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/pos/pos_bloc.dart';
import '../../../bloc/pos/pos_event.dart';
import '../../../bloc/pos/pos_state.dart';

class PosInfoPanel extends StatefulWidget {
  final bool isMobile;
  const PosInfoPanel({super.key, required this.isMobile});

  @override
  State<PosInfoPanel> createState() => _PosInfoPanelState();
}

class _PosInfoPanelState extends State<PosInfoPanel> {
  String _activeInfoTab = 'utama';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        return Column(
          children: [
            _buildInfoTabs(),
            const SizedBox(height: 16),
            _buildInfoContent(state),
          ],
        );
      },
    );
  }

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
        const Text(
          'Pelanggan',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          initialValue: state.selectedCustomer?.id,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: 'Pilih pelanggan...',
            filled: true,
            fillColor: Colors.grey.shade100,
            prefixIcon: const Icon(Icons.search, color: Colors.black54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Tanpa pelanggan'),
            ),
            ...state.customers.map(
              (customer) => DropdownMenuItem<String?>(
                value: customer.id,
                child: Text(
                  '${customer.name}${customer.phone.isEmpty ? '' : ' • ${customer.phone}'}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: (id) {
            final customer = id == null
                ? null
                : state.customers.firstWhere((item) => item.id == id);
            context.read<PosBloc>().add(SelectCustomer(customer));
          },
        ),
      ],
    );
  }

  Widget _buildPromoTab(PosState state) {
    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: widget.isMobile ? double.infinity : 240,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Kode promo',
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
            ),
            SizedBox(
              width: widget.isMobile ? double.infinity : 180,
              child: TextFormField(
                initialValue: state.manualDiscountPercent.toStringAsFixed(
                  state.manualDiscountPercent % 1 == 0 ? 0 : 2,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Diskon manual (%)',
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
                    manualDiscountPercent: (double.tryParse(value) ?? 0).clamp(
                      0,
                      100,
                    ),
                    promoCode: state.promoCode,
                    discountPolicy: state.discountPolicy,
                  ),
                ),
              ),
            ),
            _pricingDropdown(
              label: 'Policy diskon',
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
          label: 'Channel penjualan',
          value: state.salesChannel,
          width: widget.isMobile ? double.infinity : 220,
          items: const {
            'retail': 'Retail',
            'member': 'Member',
            'non_member': 'Non Member',
            'reseller': 'Reseller',
            'marketplace': 'Marketplace',
            'offline': 'Offline',
          },
          onChanged: (value) => _updateContext(state, salesChannel: value),
        ),
        _pricingDropdown(
          label: 'Level harga',
          value: state.priceLevel,
          width: widget.isMobile ? double.infinity : 220,
          items: const {
            'retail': 'Retail (Eceran)',
            'member': 'Member',
            'reseller': 'Reseller',
            'grosir': 'Grosir',
            'vip': 'VIP',
            'corporate': 'Corporate',
            'distributor': 'Distributor',
          },
          onChanged: (value) {
            final segment = switch (value) {
              'grosir' || 'distributor' => 'reseller',
              'retail' => 'regular',
              _ => value,
            };
            _updateContext(state, priceLevel: value, customerSegment: segment);
          },
        ),
        _pricingDropdown(
          label: 'Segmen pelanggan',
          value: state.customerSegment,
          width: widget.isMobile ? double.infinity : 220,
          items: const {
            'regular': 'Reguler',
            'member': 'Member',
            'non_member': 'Non Member',
            'reseller': 'Reseller',
            'vip': 'VIP',
            'corporate': 'Corporate',
          },
          onChanged: (value) => _updateContext(state, customerSegment: value),
        ),
        SizedBox(
          width: widget.isMobile ? double.infinity : 180,
          child: TextFormField(
            initialValue: state.taxPercent.toStringAsFixed(
              state.taxPercent % 1 == 0 ? 0 : 2,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Pajak penjualan',
              suffixText: '%',
              helperText: state.configuredTaxPercent > 0
                  ? 'Default ${state.configuredTaxPercent.toStringAsFixed(2)}%'
                  : '0–100%',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => _updateContext(
              state,
              taxPercent: (double.tryParse(value) ?? 0).clamp(0, 100),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pricingDropdown({
    required String label,
    required String value,
    required double width,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    final safeValue = items.containsKey(value) ? value : items.keys.first;
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        initialValue: safeValue,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
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
