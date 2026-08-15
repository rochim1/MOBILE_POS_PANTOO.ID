import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import '../../widgets/pos_ui.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_customer.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import '../../widgets/app_toast.dart';

class PosCustomerPage extends StatefulWidget {
  final bool selectionMode;

  const PosCustomerPage({super.key, this.selectionMode = false});

  @override
  State<PosCustomerPage> createState() => _PosCustomerPageState();
}

class _PosCustomerPageState extends State<PosCustomerPage> {
  final PosRepository _repository = sl<PosRepository>();
  final _searchController = TextEditingController();
  List<PosCustomer> _customers = const [];
  bool _loading = true;

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
    if (query.isEmpty) return _customers;
    return _customers
        .where(
          (item) =>
              item.name.toLowerCase().contains(query) ||
              item.phone.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const PosAppBarTitle(
          title: 'Pelanggan',
          subtitle: 'Pilih atau kelola pelanggan POS',
        ),
      ),
      backgroundColor: AppColors.bgPrimary,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _showForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Cari nama atau nomor telepon...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _customerCard(PosCustomer customer) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: widget.selectionMode
          ? () => Navigator.pop(context, customer)
          : null,
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
      trailing: widget.selectionMode
          ? const Icon(Icons.chevron_right)
          : PopupMenuButton<String>(
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
