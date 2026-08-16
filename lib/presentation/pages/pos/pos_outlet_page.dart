import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import '../../widgets/pos_ui.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import '../../bloc/pos/pos_bloc.dart';
import '../../bloc/pos/pos_event.dart';
import '../../bloc/pos/pos_state.dart';
import '../../widgets/app_toast.dart';

class PosOutletPage extends StatefulWidget {
  const PosOutletPage({super.key});
  @override
  State<PosOutletPage> createState() => _PosOutletPageState();
}

class _PosOutletPageState extends State<PosOutletPage> {
  final PosRepository _repository = sl<PosRepository>();
  String _search = '';
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.bgPrimary,
    child: BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        final stores = state.stores.where((item) {
          final q = _search.toLowerCase();
          return (q.isEmpty ||
                  item.name.toLowerCase().contains(q) ||
                  item.code.toLowerCase().contains(q)) &&
              (_statusFilter == 'all' || item.status == _statusFilter);
        }).toList();
        return RefreshIndicator(
          onRefresh: () async => context.read<PosBloc>().add(LoadPosData()),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final search = SizedBox(
                    height: 48,
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'Cari nama atau kode toko...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  );
                  final filter = PopupMenuButton<String>(
                    tooltip: 'Filter status toko',
                    initialValue: _statusFilter,
                    onSelected: (value) =>
                        setState(() => _statusFilter = value),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'all', child: Text('Semua Status')),
                      PopupMenuItem(value: 'active', child: Text('Aktif')),
                      PopupMenuItem(value: 'inactive', child: Text('Nonaktif')),
                    ],
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _statusFilter == 'all'
                            ? Colors.white
                            : AppColors.primary.withValues(alpha: 0.1),
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.filter_list_rounded),
                    ),
                  );
                  final add = SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _form(),
                      icon: const Icon(Icons.add_business),
                      label: const Text('Tambah'),
                    ),
                  );
                  if (constraints.maxWidth < 420) {
                    return Column(
                      children: [
                        search,
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [filter, const SizedBox(width: 8), add],
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: search),
                      const SizedBox(width: 8),
                      filter,
                      const SizedBox(width: 8),
                      add,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              if (stores.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: PosEmptyState(
                    icon: Icons.storefront_outlined,
                    title: 'Outlet tidak ditemukan',
                    message:
                        'Tambahkan outlet dan hubungkan ke lokasi inventory agar kasir dapat beroperasi.',
                  ),
                ),
              ...stores.map(
                (store) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.storefront)),
                    title: Text(
                      store.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${store.code.isEmpty ? '-' : store.code}\n${store.branchName.isEmpty ? 'Lokasi cabang belum diatur' : store.branchName}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) =>
                          value == 'edit' ? _form(store) : _delete(store),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _form([PosStore? store]) async {
    final name = TextEditingController(text: store?.name ?? '');
    final code = TextEditingController(text: store?.code ?? '');
    final address = TextEditingController(text: store?.address ?? '');
    final phone = TextEditingController(text: store?.phone ?? '');
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                store == null ? 'Tambah Outlet' : 'Edit Outlet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nama outlet'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: code,
                decoration: const InputDecoration(labelText: 'Kode outlet'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Alamat'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telepon'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (name.text.trim().isEmpty ||
                              code.text.trim().isEmpty) {
                            AppToast.error(
                              sheetContext,
                              'Nama dan kode outlet wajib diisi',
                            );
                            return;
                          }
                          setSheetState(() => saving = true);
                          final input = {
                            'kode_toko': code.text.trim().toUpperCase(),
                            'nama_toko': name.text.trim(),
                            'alamat': address.text.trim(),
                            'telepon': phone.text.trim(),
                            'status': store?.status ?? 'active',
                            'mode_stok': 'stok_sendiri',
                            if (store != null && store.branchId.isNotEmpty)
                              'lokasi_cabang_id': store.branchId,
                            if (store != null && store.branchName.isNotEmpty)
                              'lokasi_cabang_nama': store.branchName,
                          };
                          final result = store == null
                              ? await _repository.createStore(input)
                              : await _repository.updateStore(store.id, input);
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
                                'Outlet berhasil disimpan',
                              );
                              this.context.read<PosBloc>().add(LoadPosData());
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
    );
    name.dispose();
    code.dispose();
    address.dispose();
    phone.dispose();
  }

  Future<void> _delete(PosStore store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus outlet?'),
        content: Text(store.name),
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
    final result = await _repository.deleteStore(store.id);
    if (!mounted) return;
    result.fold((failure) => AppToast.error(context, failure.message), (_) {
      AppToast.success(context, 'Outlet berhasil dihapus');
      context.read<PosBloc>().add(LoadPosData());
    });
  }
}
