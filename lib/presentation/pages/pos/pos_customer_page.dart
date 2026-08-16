import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import '../../widgets/pos_ui.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_customer.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import '../../widgets/app_toast.dart';

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
    final name = TextEditingController(text: customer?.name ?? '');
    final phone = TextEditingController(text: customer?.phone ?? '');
    final email = TextEditingController();
    final key = GlobalKey<FormState>();
    var saving = false;
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
          child: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  customer == null ? 'Tambah Pelanggan' : 'Edit Pelanggan',
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
                  decoration: const InputDecoration(labelText: 'Nomor telepon'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (opsional)',
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
                              if (email.text.trim().isNotEmpty)
                                'email': email.text.trim(),
                              'type': 'customer',
                              'sumber_kontak': 'mobile_pos',
                              'price_level': customer?.priceLevel ?? 'retail',
                            };
                            final result = customer == null
                                ? await _repository.createCustomer(input)
                                : await _repository.updateCustomer(
                                    customer.id,
                                    input,
                                  );
                            if (!sheetContext.mounted) return;
                            result.fold(
                              (failure) {
                                setSheetState(() => saving = false);
                                AppToast.error(sheetContext, failure.message);
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
    );
    name.dispose();
    phone.dispose();
    email.dispose();
    await _load();
  }

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
