import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import '../../widgets/pos_ui.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_customer.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import '../../widgets/app_toast.dart';
import 'widgets/pos_quick_customer_dialog.dart';

class PosCustomerPage extends StatefulWidget {
  const PosCustomerPage({super.key});

  @override
  State<PosCustomerPage> createState() => _PosCustomerPageState();
}

class _PosCustomerPageState extends State<PosCustomerPage> {
  final PosRepository _repository = sl<PosRepository>();
  final _searchController = TextEditingController();
  List<PosCustomer> _customers = const [];
  bool _loading = true;
  String _priceLevelFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final customers = await _repository.getCustomers();
    if (!mounted) return;
    setState(() {
      _customers = customers;
      _loading = false;
    });
  }

  List<PosCustomer> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _customers
        .where(
          (item) =>
              (query.isEmpty ||
                  item.name.toLowerCase().contains(query) ||
                  item.phone.toLowerCase().contains(query)) &&
              (_priceLevelFilter == 'all' ||
                  item.priceLevel == _priceLevelFilter),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final content = ColoredBox(
      color: AppColors.bgPrimary,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Cari nama atau telepon...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: 'Filter pelanggan',
                  initialValue: _priceLevelFilter,
                  onSelected: (value) =>
                      setState(() => _priceLevelFilter = value),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'all',
                      child: Text('Semua Level Harga'),
                    ),
                    ..._customers
                        .map((item) => item.priceLevel)
                        .where((level) => level.isNotEmpty)
                        .toSet()
                        .map(
                          (level) =>
                              PopupMenuItem(value: level, child: Text(level)),
                        ),
                  ],
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _priceLevelFilter == 'all'
                          ? Colors.white
                          : AppColors.primary.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.filter_list_rounded),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : () => _showForm(),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Tambah'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              ...List.generate(6, (_) => const _CustomerSkeleton())
            else if (_filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: PosEmptyState(
                  icon: Icons.people_outline,
                  title: 'Pelanggan tidak ditemukan',
                  message: 'Ubah kata pencarian atau tambahkan pelanggan baru.',
                ),
              )
            else
              ..._filtered.map(_customerCard),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
    return content;
  }

  Widget _customerCard(PosCustomer customer) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: CircleAvatar(
        child: Text(
          customer.name.isEmpty ? '?' : customer.name[0].toUpperCase(),
        ),
      ),
      title: Text(
        customer.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        customer.phone.isEmpty ? 'Tanpa nomor telepon' : customer.phone,
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (action) =>
            action == 'edit' ? _showForm(customer) : _delete(customer),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('Edit')),
          PopupMenuItem(value: 'delete', child: Text('Hapus')),
        ],
      ),
    ),
  );

  Future<void> _showForm([PosCustomer? customer]) async {
    if (customer == null) {
      final created = await showPosQuickCustomerDialog(context);
      if (!mounted || created == null) return;
      AppToast.success(context, 'Pelanggan berhasil ditambahkan');
      await _load();
      return;
    }
    final runtimeConfig = await _repository.getRuntimeConfig();
    if (!mounted) return;
    final priceLevelOptions = <String>{
      'retail',
      ...((runtimeConfig['price_level_options'] as List?) ?? const [])
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty),
      customer.priceLevel,
    }.toList();
    final name = TextEditingController(text: customer.name);
    final phone = TextEditingController(text: customer.phone);
    final email = TextEditingController(text: customer.email);
    final address = TextEditingController(text: customer.address);
    final note = TextEditingController(text: customer.note);
    final key = GlobalKey<FormState>();
    var saving = false;
    var membershipStatus = customer.membershipStatus;
    var membershipTier = customer.membershipTier;
    var customerType = customer.customerType;
    var priceLevel = customer.priceLevel;
    if (!priceLevelOptions.contains(priceLevel)) priceLevel = 'retail';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: SafeArea(
            child: Form(
              key: key,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Edit Pelanggan',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Nama'),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nomor telepon',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (opsional)',
                      ),
                      validator: (value) {
                        final input = (value ?? '').trim();
                        if (input.isEmpty) return null;
                        return RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(input)
                            ? null
                            : 'Format email tidak valid';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: address,
                      minLines: 2,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Alamat'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: note,
                      minLines: 2,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(labelText: 'Catatan'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: membershipStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status keanggotaan',
                      ),
                      items:
                          const {'non_member': 'Non Member', 'member': 'Member'}
                              .entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                              )
                              .toList(),
                      onChanged: saving
                          ? null
                          : (value) => setSheetState(() {
                              membershipStatus = value ?? 'non_member';
                              if (membershipStatus == 'non_member') {
                                membershipTier = 'regular';
                              }
                            }),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: membershipTier,
                      decoration: InputDecoration(
                        labelText: 'Tier member',
                        helperText: membershipStatus == 'member'
                            ? null
                            : 'Aktif setelah status diubah menjadi Member',
                      ),
                      items:
                          const {
                                'regular': 'Regular',
                                'silver': 'Silver',
                                'gold': 'Gold',
                                'vip': 'VIP',
                              }.entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                              )
                              .toList(),
                      onChanged: saving || membershipStatus != 'member'
                          ? null
                          : (value) => setSheetState(
                              () => membershipTier = value ?? 'regular',
                            ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: customerType,
                      decoration: const InputDecoration(
                        labelText: 'Tipe pelanggan',
                      ),
                      items:
                          const {
                                'personal': 'Personal',
                                'reseller': 'Reseller',
                                'corporate': 'Corporate',
                              }.entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                              )
                              .toList(),
                      onChanged: saving
                          ? null
                          : (value) => setSheetState(
                              () => customerType = value ?? 'personal',
                            ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: priceLevel,
                      decoration: const InputDecoration(
                        labelText: 'Level harga',
                        helperText:
                            'Menentukan harga produk untuk pelanggan ini',
                      ),
                      items: priceLevelOptions
                          .map(
                            (level) => DropdownMenuItem(
                              value: level,
                              child: Text(_priceLevelLabel(level)),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) => setSheetState(
                              () => priceLevel = value ?? 'retail',
                            ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!key.currentState!.validate()) return;
                                setSheetState(() => saving = true);
                                final input = {
                                  'name': name.text.trim(),
                                  'phone': phone.text.trim(),
                                  'email': email.text.trim(),
                                  'address': address.text.trim(),
                                  'catatan': note.text.trim(),
                                  'type': 'Customer',
                                  'sumber_kontak': 'mobile_pos',
                                  'price_level': priceLevel,
                                  'customer_segment': 'regular',
                                  'membership_status': membershipStatus,
                                  'membership_tier': membershipTier,
                                  'customer_type': customerType,
                                };
                                final result = await _repository.updateCustomer(
                                  customer.id,
                                  input,
                                );
                                if (!sheetContext.mounted) return;
                                result.fold(
                                  (failure) {
                                    setSheetState(() => saving = false);
                                    AppToast.error(
                                      sheetContext,
                                      failure.message,
                                    );
                                  },
                                  (_) {
                                    Navigator.pop(sheetContext);
                                    AppToast.success(
                                      this.context,
                                      'Pelanggan berhasil disimpan',
                                    );
                                  },
                                );
                              },
                        child: Text(saving ? 'Menyimpan...' : 'Simpan'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    name.dispose();
    phone.dispose();
    email.dispose();
    address.dispose();
    note.dispose();
    await _load();
  }

  String _priceLevelLabel(String value) => value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  Future<void> _delete(PosCustomer customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus pelanggan?'),
        content: Text(customer.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await _repository.deleteCustomer(customer.id);
    if (!mounted) return;
    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (_) => AppToast.success(context, 'Pelanggan berhasil dihapus'),
    );
    await _load();
  }
}

class _CustomerSkeleton extends StatelessWidget {
  const _CustomerSkeleton();
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: CircleAvatar(backgroundColor: Colors.grey.shade200),
      title: Container(height: 14, color: Colors.grey.shade200),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(height: 10, width: 100, color: Colors.grey.shade200),
      ),
    ),
  );
}
