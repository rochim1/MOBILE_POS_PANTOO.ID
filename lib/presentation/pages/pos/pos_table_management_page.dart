import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_table.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_table/pos_table_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_table/pos_table_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_table/pos_table_state.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/app_toast.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_ui.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';

class PosTableManagementPage extends StatelessWidget {
  const PosTableManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.read<PosBloc>().state.runtimeConfig;
    final useTables = (config['features'] as Map?)?['use_tables'] == true;
    final canManage = (config['permissions'] as Map?)?['manage_tables'] == true;
    final storeId =
        context.read<PosBloc>().state.activeShift?['toko_id']?.toString() ?? '';
    if (!useTables || !canManage || storeId.isEmpty) {
      return _TableAccessMessage(
        title: !useTables
            ? 'Fitur meja nonaktif'
            : !canManage
            ? 'Akses manajemen meja ditolak'
            : 'Shift kasir belum dibuka',
        message: !useTables
            ? 'Aktifkan fitur Meja / Ruangan melalui Pengaturan POS terlebih dahulu.'
            : !canManage
            ? 'Hubungi admin untuk mendapatkan izin mengelola meja.'
            : 'Buka shift pada toko yang akan dikelola agar meja tidak tercampur antar toko.',
      );
    }
    return BlocProvider(
      create: (_) =>
          PosTableBloc(repository: sl())..add(LoadTables(storeId: storeId)),
      child: _PosTableManagementView(storeId: storeId),
    );
  }
}

class _TableAccessMessage extends StatelessWidget {
  final String title;
  final String message;

  const _TableAccessMessage({required this.title, required this.message});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.table_restaurant_outlined,
            size: 52,
            color: Colors.grey,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}

class _PosTableManagementView extends StatefulWidget {
  final String storeId;

  const _PosTableManagementView({required this.storeId});

  @override
  State<_PosTableManagementView> createState() =>
      _PosTableManagementViewState();
}

class _PosTableManagementViewState extends State<_PosTableManagementView> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;
  int? _selectedCapacity;

  bool get _isTablet => MediaQuery.of(context).size.width >= 600;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    context.read<PosTableBloc>().add(
      LoadTables(storeId: widget.storeId, search: value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: BlocConsumer<PosTableBloc, PosTableState>(
        listener: (context, state) {
          if (state.status == PosTableStatus.actionSuccess) {
            AppToast.success(context, state.successMessage);
          } else if (state.status == PosTableStatus.failure) {
            AppToast.error(context, state.errorMessage);
          }
        },
        builder: (context, state) {
          final capacities = state.tables.map((table) => table.capacity).toSet()
            ..removeWhere((capacity) => capacity <= 0);
          final sortedCapacities = capacities.toList()..sort();
          final activeCapacity = sortedCapacities.contains(_selectedCapacity)
              ? _selectedCapacity
              : null;
          final visibleTables = activeCapacity == null
              ? state.tables
              : state.tables
                    .where((table) => table.capacity == activeCapacity)
                    .toList();
          return Column(
            children: [
              _buildSearchBar(),
              if (state.tables.isNotEmpty)
                _buildCapacityTabs(
                  sortedCapacities,
                  activeCapacity,
                  state.tables.length,
                ),
              Expanded(child: _buildBody(state, visibleTables)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTableForm(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCapacityTabs(
    List<int> capacities,
    int? activeCapacity,
    int totalTables,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _capacityChip('Semua ($totalTables)', null, activeCapacity),
            for (final capacity in capacities) ...[
              const SizedBox(width: 8),
              _capacityChip('$capacity kursi', capacity, activeCapacity),
            ],
          ],
        ),
      ),
    );
  }

  Widget _capacityChip(String label, int? capacity, int? activeCapacity) {
    final selected = capacity == activeCapacity;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _selectedCapacity = capacity),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.bgPrimary,
      side: BorderSide(
        color: selected ? AppColors.primary : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontSize: 12,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Cari meja...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.bgSecondary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () => setState(() => _isGridView = !_isGridView),
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
            ),
            tooltip: _isGridView ? 'Tampilan List' : 'Tampilan Grid',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(PosTableState state, List<PosTableModel> visibleTables) {
    if (state.status == PosTableStatus.loading && state.tables.isEmpty) {
      return const PosSkeletonList();
    }

    if (state.tables.isEmpty && state.status == PosTableStatus.success) {
      return PosEmptyState(
        icon: Icons.table_restaurant_outlined,
        title: 'Belum ada meja',
        message:
            'Tambahkan meja beserta kapasitas kursinya untuk mulai menerima order dine-in.',
        actionLabel: 'Tambah Meja',
        onAction: () => _showTableForm(context),
      );
    }

    if (visibleTables.isEmpty && state.tables.isNotEmpty) {
      return const Center(
        child: Text(
          'Tidak ada meja dengan kapasitas ini.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_isGridView) {
      return _buildGridView(visibleTables);
    }
    return _buildListView(visibleTables);
  }

  Widget _buildGridView(List<PosTableModel> tables) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<PosTableBloc>().add(
          LoadTables(storeId: widget.storeId, search: _searchController.text),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) => GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (constraints.maxWidth / 170).floor().clamp(2, 6),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.35,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) => _buildGridCard(tables[index]),
        ),
      ),
    );
  }

  Widget _buildGridCard(PosTableModel table) {
    final isAvailable = table.status.toLowerCase() != 'terisi';
    final accent = isAvailable ? AppColors.primary : Colors.orange.shade700;

    return Material(
      color: isAvailable ? Colors.white : Colors.orange.shade50,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _showTableForm(context, table: table),
        onLongPress: () => _showTableActions(context, table),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isAvailable
                  ? Colors.grey.shade200
                  : Colors.orange.shade300,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.table_restaurant, size: 23, color: accent),
                  const Spacer(),
                  _buildStatusBadge(table.status, compact: true),
                ],
              ),
              const Spacer(),
              Text(
                table.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.chair_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${table.capacity} kursi',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListView(List<PosTableModel> tables) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        context.read<PosTableBloc>().add(
          LoadTables(storeId: widget.storeId, search: _searchController.text),
        );
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tables.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _buildListTile(tables[index]),
      ),
    );
  }

  Widget _buildListTile(PosTableModel table) {
    final isAvailable = table.status == 'Tersedia';
    return Dismissible(
      key: Key(table.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) => _confirmDelete(context, table),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: isAvailable
                ? AppColors.primary.withValues(alpha: 0.1)
                : AppColors.danger.withValues(alpha: 0.1),
            child: Icon(
              Icons.table_restaurant_rounded,
              color: isAvailable ? AppColors.primary : AppColors.danger,
            ),
          ),
          title: Text(
            table.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            'Kapasitas: ${table.capacity} kursi',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusBadge(table.status),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                onSelected: (value) => _handleMenuAction(value, table),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Hapus', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          onTap: () => _showTableForm(context, table: table),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, {bool compact = false}) {
    final isAvailable = status.toLowerCase() != 'terisi';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
      ),
      child: Text(
        isAvailable ? 'Tersedia' : 'Terisi',
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 9 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  void _handleMenuAction(String action, PosTableModel table) {
    switch (action) {
      case 'edit':
        _showTableForm(context, table: table);
        break;
      case 'delete':
        _confirmDelete(context, table);
        break;
    }
  }

  void _showTableActions(BuildContext context, PosTableModel table) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Edit Meja'),
              onTap: () {
                Navigator.pop(context);
                _showTableForm(context, table: table);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
              ),
              title: const Text(
                'Hapus Meja',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, table);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(
    BuildContext context,
    PosTableModel table,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Meja'),
        content: Text('Apakah Anda yakin ingin menghapus "${table.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<PosTableBloc>().add(DeleteTable(id: table.id));
    }
    return confirmed;
  }

  void _showTableForm(BuildContext context, {PosTableModel? table}) {
    final bloc = context.read<PosTableBloc>();
    if (_isTablet) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: 420,
            child: _TableFormContent(table: table, bloc: bloc),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _TableFormContent(table: table, bloc: bloc),
        ),
      );
    }
  }
}

class _TableFormContent extends StatefulWidget {
  final PosTableModel? table;
  final PosTableBloc bloc;

  const _TableFormContent({this.table, required this.bloc});

  @override
  State<_TableFormContent> createState() => _TableFormContentState();
}

class _TableFormContentState extends State<_TableFormContent> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late int _selectedCapacity;
  bool get _isEditing => widget.table != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.table?.name ?? '');
    _selectedCapacity = widget.table?.capacity ?? 4;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    if (_isEditing) {
      widget.bloc.add(
        UpdateTable(
          id: widget.table!.id,
          name: name,
          capacity: _selectedCapacity,
        ),
      );
    } else {
      widget.bloc.add(CreateTable(name: name, capacity: _selectedCapacity));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle (for bottom sheet)
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

              // Title
              Text(
                _isEditing ? 'Edit Meja' : 'Tambah Meja Baru',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Name field
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Nama Meja',
                  hintText: 'Contoh: Meja 1',
                  prefixIcon: const Icon(Icons.table_restaurant_outlined),
                  filled: true,
                  fillColor: AppColors.bgSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama meja wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Capacity dropdown
              DropdownButtonFormField<int>(
                initialValue: _selectedCapacity,
                decoration: InputDecoration(
                  labelText: 'Kapasitas Kursi',
                  prefixIcon: const Icon(Icons.people_outline),
                  filled: true,
                  fillColor: AppColors.bgSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                ),
                items: List.generate(20, (i) => i + 1)
                    .map(
                      (n) =>
                          DropdownMenuItem(value: n, child: Text('$n kursi')),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCapacity = value);
                  }
                },
              ),
              const SizedBox(height: 28),

              // Submit button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _isEditing ? 'Simpan Perubahan' : 'Tambah Meja',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
