import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:intl/intl.dart';
import '../../../injections.dart';
import '../../bloc/pos_promo/pos_promo_bloc.dart';
import '../../bloc/pos_promo/pos_promo_event.dart';
import '../../bloc/pos_promo/pos_promo_state.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_ui.dart';
import '../../../domain/models/pos_promo.dart';

class PosPromoPage extends StatelessWidget {
  const PosPromoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PosPromoBloc>()..add(const LoadPromos()),
      child: const _PosPromoView(),
    );
  }
}

class _PosPromoView extends StatefulWidget {
  const _PosPromoView();

  @override
  State<_PosPromoView> createState() => _PosPromoViewState();
}

class _PosPromoViewState extends State<_PosPromoView> {
  final TextEditingController _searchController = TextEditingController();
  // null = semua, true = aktif, false = nonaktif
  bool? _filterIsActive;

  String _formatCurrency(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp',
      decimalDigits: 0,
    ).format(value);
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  bool _isExpired(PosPromo promo) {
    if (promo.endDate.isEmpty) return false;
    try {
      final end = DateTime.parse(promo.endDate);
      return end.isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Color _getStatusColor(PosPromo promo) {
    if (_isExpired(promo)) return Colors.grey;
    if (promo.isActive) return Colors.green;
    return Colors.red;
  }

  String _getStatusText(PosPromo promo) {
    if (_isExpired(promo)) return 'Expired';
    if (promo.isActive) return 'Aktif';
    return 'Nonaktif';
  }

  void _loadWithFilters() {
    context.read<PosPromoBloc>().add(
      LoadPromos(
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        isActive: _filterIsActive,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const PosAppBarTitle(
          title: 'Promo & Voucher',
          subtitle: 'Program penjualan aktif',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_promo_fab',
        onPressed: () => _showPromoForm(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Promo',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari kode atau nama promo...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _loadWithFilters();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onChanged: (_) => _loadWithFilters(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip('Semua', _filterIsActive == null),
                    const SizedBox(width: 8),
                    _buildFilterChip('Aktif', _filterIsActive == true),
                    const SizedBox(width: 8),
                    _buildFilterChip('Nonaktif', _filterIsActive == false),
                  ],
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: BlocConsumer<PosPromoBloc, PosPromoState>(
              listener: (context, state) {
                if (state.status == PosPromoStatus.failure &&
                    state.errorMessage.isNotEmpty) {
                  AppToast.error(context, state.errorMessage);
                }
                if (state.status == PosPromoStatus.actionSuccess &&
                    state.successMessage.isNotEmpty) {
                  AppToast.success(context, state.successMessage);
                }
              },
              builder: (context, state) {
                if (state.status == PosPromoStatus.loading &&
                    state.promos.isEmpty) {
                  return const PosSkeletonList();
                }

                if (state.promos.isEmpty) {
                  return const PosEmptyState(
                    icon: Icons.local_offer_outlined,
                    title: 'Belum ada promo',
                    message:
                        'Buat promo atau voucher untuk meningkatkan penjualan dan loyalitas pelanggan.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _loadWithFilters(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.promos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final promo = state.promos[index];
                      return _buildPromoCard(context, promo);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (label == 'Semua') {
            _filterIsActive = null;
          } else if (label == 'Aktif') {
            _filterIsActive = true;
          } else {
            _filterIsActive = false;
          }
        });
        _loadWithFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildPromoCard(BuildContext context, PosPromo promo) {
    final statusColor = _getStatusColor(promo);
    final statusText = _getStatusText(promo);
    final isExpired = _isExpired(promo);
    final discountDisplay = promo.valueType == 'percentage'
        ? '${promo.discountValue.toStringAsFixed(0)}%'
        : _formatCurrency(promo.discountValue);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showPromoForm(context, promo: promo),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Code + Status badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              promo.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              promo.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Discount info
                Row(
                  children: [
                    Icon(
                      promo.valueType == 'percentage'
                          ? Icons.percent
                          : Icons.attach_money,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Diskon: $discountDisplay',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (promo.valueType == 'percentage' &&
                        promo.maxDiscountAmount > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(Maks ${_formatCurrency(promo.maxDiscountAmount)})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),

                // Period
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_formatDate(promo.startDate)} - ${_formatDate(promo.endDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                if (promo.minPurchaseAmount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Min. belanja ${_formatCurrency(promo.minPurchaseAmount)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Bottom row: toggle + delete
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Usage info
                    Text(
                      'Pemakaian: ${promo.currentUsageCount}/${promo.usageLimit > 0 ? promo.usageLimit : '∞'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Delete button
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _confirmDelete(context, promo),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Hapus',
                        ),
                        const SizedBox(width: 8),
                        // Toggle active/inactive
                        SizedBox(
                          height: 24,
                          child: Switch(
                            value: promo.isActive,
                            onChanged: isExpired
                                ? null
                                : (val) {
                                    context.read<PosPromoBloc>().add(
                                      TogglePromoStatus(promo.id),
                                    );
                                  },
                            activeThumbColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PosPromo promo) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Promo'),
        content: Text(
          'Apakah Anda yakin ingin menghapus promo "${promo.name}" (${promo.code})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<PosPromoBloc>().add(DeletePromo(promo.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPromoForm(BuildContext context, {PosPromo? promo}) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final bloc = context.read<PosPromoBloc>();

    if (isTablet) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: 500,
            child: _PromoFormContent(bloc: bloc, promo: promo),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: _PromoFormContent(
              bloc: bloc,
              promo: promo,
              scrollController: scrollController,
            ),
          ),
        ),
      );
    }
  }
}

// ─── Form Content Widget ─────────────────────────────────────────────────────

class _PromoFormContent extends StatefulWidget {
  final PosPromoBloc bloc;
  final PosPromo? promo;
  final ScrollController? scrollController;

  const _PromoFormContent({
    required this.bloc,
    this.promo,
    this.scrollController,
  });

  @override
  State<_PromoFormContent> createState() => _PromoFormContentState();
}

class _PromoFormContentState extends State<_PromoFormContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _valueCtrl;
  late final TextEditingController _maxDiscountCtrl;
  late final TextEditingController _usageLimitCtrl;
  late final TextEditingController _minPurchaseCtrl;

  String _discountType = 'promo';
  String _valueType = 'percentage';
  DateTime? _startDate;
  DateTime? _endDate;

  bool get isEdit => widget.promo != null;

  @override
  void initState() {
    super.initState();
    final p = widget.promo;
    _codeCtrl = TextEditingController(text: p?.code ?? '');
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _valueCtrl = TextEditingController(
      text: p != null
          ? (p.valueType == 'fixed'
                ? formatRupiahInput(p.discountValue)
                : p.discountValue.toStringAsFixed(0))
          : '',
    );
    _maxDiscountCtrl = TextEditingController(
      text: p != null && p.maxDiscountAmount > 0
          ? formatRupiahInput(p.maxDiscountAmount)
          : '',
    );
    _usageLimitCtrl = TextEditingController(
      text: p != null && p.usageLimit > 0 ? p.usageLimit.toString() : '',
    );
    _minPurchaseCtrl = TextEditingController(
      text: p != null && p.minPurchaseAmount > 0
          ? formatRupiahInput(p.minPurchaseAmount)
          : '',
    );

    if (p != null) {
      _discountType = p.discountType;
      _valueType = p.valueType;
      if (p.startDate.isNotEmpty) {
        try {
          _startDate = DateTime.parse(p.startDate);
        } catch (_) {}
      }
      if (p.endDate.isNotEmpty) {
        try {
          _endDate = DateTime.parse(p.endDate);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _valueCtrl.dispose();
    _maxDiscountCtrl.dispose();
    _usageLimitCtrl.dispose();
    _minPurchaseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? now) : (_endDate ?? now),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final input = <String, dynamic>{
      'code': _codeCtrl.text.trim(),
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'discount_type': _discountType,
      'value_type': _valueType,
      'discount_value': _valueType == 'fixed'
          ? parseRupiah(_valueCtrl.text)
          : (double.tryParse(_valueCtrl.text) ?? 0),
    };

    if (_maxDiscountCtrl.text.isNotEmpty) {
      input['max_discount_amount'] = parseRupiah(_maxDiscountCtrl.text);
    }
    if (_usageLimitCtrl.text.isNotEmpty) {
      input['usage_limit'] = int.tryParse(_usageLimitCtrl.text) ?? 0;
    }
    if (_minPurchaseCtrl.text.isNotEmpty) {
      input['min_purchase_amount'] = parseRupiah(_minPurchaseCtrl.text);
    }
    if (_startDate != null) {
      input['start_date'] = _startDate!.toIso8601String();
    }
    if (_endDate != null) {
      input['end_date'] = _endDate!.toIso8601String();
    }

    if (isEdit) {
      widget.bloc.add(UpdatePromo(widget.promo!.id, input));
    } else {
      widget.bloc.add(CreatePromo(input));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    return Form(
      key: _formKey,
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          // Handle bar (mobile only)
          if (widget.scrollController != null)
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          Text(
            isEdit ? 'Edit Promo' : 'Tambah Promo Baru',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Code
          TextFormField(
            controller: _codeCtrl,
            decoration: _inputDecoration(
              'Kode Promo',
              Icons.confirmation_number_outlined,
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Kode wajib diisi' : null,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 14),

          // Name
          TextFormField(
            controller: _nameCtrl,
            decoration: _inputDecoration(
              'Nama Promo',
              Icons.local_offer_outlined,
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 14),

          // Description
          TextFormField(
            controller: _descCtrl,
            decoration: _inputDecoration(
              'Deskripsi',
              Icons.description_outlined,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 14),

          // Discount type
          DropdownButtonFormField<String>(
            initialValue: _discountType,
            decoration: _inputDecoration(
              'Tipe Diskon',
              Icons.category_outlined,
            ),
            items: const [
              DropdownMenuItem(value: 'promo', child: Text('Promo')),
              DropdownMenuItem(value: 'voucher', child: Text('Voucher')),
              DropdownMenuItem(value: 'coupon', child: Text('Kupon')),
            ],
            onChanged: (v) => setState(() => _discountType = v ?? 'promo'),
          ),
          const SizedBox(height: 14),

          // Value type
          DropdownButtonFormField<String>(
            initialValue: _valueType,
            decoration: _inputDecoration('Jenis Nilai', Icons.tune_outlined),
            items: const [
              DropdownMenuItem(
                value: 'percentage',
                child: Text('Persentase (%)'),
              ),
              DropdownMenuItem(
                value: 'fixed',
                child: Text('Nominal Tetap (Rp)'),
              ),
            ],
            onChanged: (v) => setState(() => _valueType = v ?? 'percentage'),
          ),
          const SizedBox(height: 14),

          // Discount value
          TextFormField(
            controller: _valueCtrl,
            decoration: _inputDecoration(
              _valueType == 'percentage'
                  ? 'Nilai Diskon (%)'
                  : 'Nilai Diskon (Rp)',
              _valueType == 'percentage' ? Icons.percent : Icons.attach_money,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: _valueType == 'fixed'
                ? const [RupiahInputFormatter()]
                : null,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Nilai diskon wajib diisi';
              }
              if (_valueType == 'fixed'
                  ? parseRupiah(v) <= 0
                  : double.tryParse(v) == null) {
                return 'Masukkan angka valid';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Max discount (only for percentage)
          if (_valueType == 'percentage') ...[
            TextFormField(
              controller: _maxDiscountCtrl,
              decoration: _inputDecoration(
                'Maks. Diskon (Rp)',
                Icons.vertical_align_top_outlined,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: const [RupiahInputFormatter()],
            ),
            const SizedBox(height: 14),
          ],

          // Usage limit
          TextFormField(
            controller: _usageLimitCtrl,
            decoration: _inputDecoration(
              'Batas Pemakaian',
              Icons.repeat_outlined,
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),

          // Min purchase
          TextFormField(
            controller: _minPurchaseCtrl,
            decoration: _inputDecoration(
              'Min. Pembelian (Rp)',
              Icons.shopping_cart_outlined,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: const [RupiahInputFormatter()],
          ),
          const SizedBox(height: 14),

          // Date pickers
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(true),
                  child: InputDecorator(
                    decoration: _inputDecoration(
                      'Tanggal Mulai',
                      Icons.calendar_today_outlined,
                    ),
                    child: Text(
                      _startDate != null
                          ? dateFormat.format(_startDate!)
                          : 'Pilih tanggal',
                      style: TextStyle(
                        color: _startDate != null
                            ? Colors.black87
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _pickDate(false),
                  child: InputDecorator(
                    decoration: _inputDecoration(
                      'Tanggal Berakhir',
                      Icons.event_outlined,
                    ),
                    child: Text(
                      _endDate != null
                          ? dateFormat.format(_endDate!)
                          : 'Pilih tanggal',
                      style: TextStyle(
                        color: _endDate != null ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isEdit ? 'Simpan Perubahan' : 'Buat Promo',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
