import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/_core.dart';
import '../../../../injections.dart';
import '../../bloc/lock/lock_cubit.dart';
import '../../bloc/pos/pos_bloc.dart';
import '../../bloc/pos/pos_state.dart';

class PosSetupReadiness {
  final bool hasStore;
  final bool hasStockLocation;
  final bool hasProducts;
  final bool hasPin;
  final bool hasShift;
  final bool configurationHealthy;

  const PosSetupReadiness({
    required this.hasStore,
    required this.hasStockLocation,
    required this.hasProducts,
    required this.hasPin,
    required this.hasShift,
    required this.configurationHealthy,
  });

  bool get ready =>
      hasStore &&
      hasStockLocation &&
      hasProducts &&
      hasPin &&
      hasShift &&
      configurationHealthy;
}

class PosSetupGuidePage extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  final VoidCallback onStartCashier;

  const PosSetupGuidePage({
    super.key,
    required this.onNavigate,
    required this.onStartCashier,
  });

  static String tourPreferenceKey(SharedPreferences prefs) {
    final user = prefs.getString('user_id') ?? 'unknown-user';
    final tenant = prefs.getString('instansi_id') ?? 'unknown-instansi';
    return 'pos_cashier_tour_v1:$tenant:$user';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        final lock = context.watch<AppLockCubit>().state;
        final features = Map<String, dynamic>.from(
          state.runtimeConfig['features'] as Map? ?? const {},
        );
        final permissions = Map<String, dynamic>.from(
          state.runtimeConfig['permissions'] as Map? ?? const {},
        );
        final health = Map<String, dynamic>.from(
          state.runtimeConfig['configuration_health'] as Map? ?? const {},
        );
        final trackStock = features['track_stock'] != false;
        final activeStores = state.stores
            .where((store) => store.status.toLowerCase() == 'active')
            .toList();
        final hasStore = activeStores.isNotEmpty;
        final hasStockLocation =
            !trackStock ||
            activeStores.any((store) => store.branchId.trim().isNotEmpty);
        final hasProducts = state.products.isNotEmpty;
        final hasPin =
            lock.hasPinConfigured ||
            (lock.activeEmployeeId?.isNotEmpty == true &&
                lock.operatorSessionToken.isNotEmpty);
        final hasShift = state.activeShift != null;
        final healthy = health['valid'] != false;
        final readiness = PosSetupReadiness(
          hasStore: hasStore,
          hasStockLocation: hasStockLocation,
          hasProducts: hasProducts,
          hasPin: hasPin,
          hasShift: hasShift,
          configurationHealthy: healthy,
        );
        final ready = readiness.ready;

        final steps = <_SetupStep>[
          if (trackStock)
            _SetupStep(
              title: 'Lokasi stok siap',
              description: hasStockLocation
                  ? 'Toko aktif sudah terhubung ke lokasi inventori.'
                  : 'Buat warehouse/lokasi dan pastikan dapat digunakan untuk stok.',
              complete: hasStockLocation,
              icon: Icons.warehouse_outlined,
              actionLabel: permissions['view_warehouses'] == true
                  ? 'Kelola lokasi'
                  : null,
              destination: 7,
            ),
          _SetupStep(
            title: 'Toko POS aktif',
            description: hasStore
                ? '${activeStores.length} toko aktif tersedia.'
                : 'Buat toko POS dan hubungkan dengan lokasi stok.',
            complete: hasStore,
            icon: Icons.storefront_outlined,
            actionLabel: permissions['view_stores'] == true
                ? 'Kelola toko'
                : null,
            destination: 10,
          ),
          _SetupStep(
            title: 'Katalog penjualan',
            description: hasProducts
                ? '${state.products.length} produk/layanan siap dijual.'
                : 'Tambahkan minimal satu produk, layanan, atau paket aktif.',
            complete: hasProducts,
            icon: Icons.inventory_2_outlined,
            actionLabel: permissions['view_products'] == true
                ? 'Kelola katalog'
                : null,
            destination: 2,
          ),
          _SetupStep(
            title: 'PIN operator kasir',
            description: hasPin
                ? 'Operator kasir sudah terverifikasi.'
                : 'Pilih operator dan buat/masukkan PIN kasir.',
            complete: hasPin,
            icon: Icons.pin_outlined,
            actionLabel: 'Atur PIN',
            onAction: () => context.read<AppLockCubit>().lock(),
          ),
          _SetupStep(
            title: 'Konfigurasi inventory valid',
            description: healthy
                ? 'Profil inventory dan tracking stok sudah selaras.'
                : ((health['issues'] as List? ?? const [])
                      .map((value) => value.toString())
                      .join(' · ')),
            complete: healthy,
            icon: Icons.rule_folder_outlined,
            actionLabel: permissions['manage_settings'] == true
                ? 'Periksa pengaturan'
                : null,
            destination: 7,
          ),
          _SetupStep(
            title: 'Shift kasir dibuka',
            description: hasShift
                ? 'Shift aktif dan transaksi dapat dimulai.'
                : 'Pilih toko, masukkan modal awal, lalu buka shift.',
            complete: hasShift,
            icon: Icons.schedule_outlined,
            actionLabel: permissions['view_shifts'] == true
                ? 'Buka shift'
                : null,
            destination: 11,
          ),
        ];

        return ColoredBox(
          color: AppColors.bgPrimary,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: .1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    ready
                                        ? Icons.task_alt_rounded
                                        : Icons.fact_check_outlined,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ready
                                            ? 'POS siap digunakan'
                                            : 'Selesaikan setup POS',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        ready
                                            ? 'Semua kebutuhan utama sudah tersedia. Anda dapat mulai melayani transaksi.'
                                            : 'Selesaikan secara berurutan agar stok, toko, kasir, dan shift tetap selaras.',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value:
                                  steps.where((step) => step.complete).length /
                                  steps.length,
                              minHeight: 7,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${steps.where((step) => step.complete).length} dari ${steps.length} langkah selesai',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...steps.indexed.map(
                        (entry) => _SetupStepCard(
                          number: entry.$1 + 1,
                          step: entry.$2,
                          onNavigate: onNavigate,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: ready ? onStartCashier : null,
                          icon: const Icon(Icons.point_of_sale_outlined),
                          label: const Text('Mulai Berjualan'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                        ),
                      ),
                      if (!ready) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Tombol aktif setelah semua kebutuhan wajib selesai. Langkah tanpa akses harus diselesaikan admin POS.',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SetupStep {
  final String title;
  final String description;
  final bool complete;
  final IconData icon;
  final String? actionLabel;
  final int? destination;
  final VoidCallback? onAction;

  const _SetupStep({
    required this.title,
    required this.description,
    required this.complete,
    required this.icon,
    this.actionLabel,
    this.destination,
    this.onAction,
  });
}

class _SetupStepCard extends StatelessWidget {
  final int number;
  final _SetupStep step;
  final ValueChanged<int> onNavigate;

  const _SetupStepCard({
    required this.number,
    required this.step,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    elevation: 0,
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: Colors.grey.shade300),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        final leading = Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(step.icon, color: AppColors.primary),
        );
        final status = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: step.complete
                ? Colors.green.withValues(alpha: .1)
                : Colors.orange.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                step.complete
                    ? Icons.check_circle_outline
                    : Icons.schedule_outlined,
                size: 15,
                color: step.complete
                    ? Colors.green.shade700
                    : Colors.orange.shade800,
              ),
              const SizedBox(width: 5),
              Text(
                step.complete ? 'Selesai' : 'Perlu disiapkan',
                style: TextStyle(
                  color: step.complete
                      ? Colors.green.shade700
                      : Colors.orange.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Langkah $number',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              step.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              step.description,
              style: const TextStyle(color: Colors.black54, height: 1.3),
            ),
          ],
        );
        final action = !step.complete && step.actionLabel != null
            ? OutlinedButton.icon(
                onPressed:
                    step.onAction ??
                    (step.destination == null
                        ? null
                        : () => onNavigate(step.destination!)),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(step.actionLabel!),
              )
            : null;
        return Padding(
          padding: const EdgeInsets.all(14),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        leading,
                        const SizedBox(width: 12),
                        Expanded(child: info),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [status, if (action != null) action],
                    ),
                  ],
                )
              : Row(
                  children: [
                    leading,
                    const SizedBox(width: 14),
                    Expanded(child: info),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        status,
                        if (action != null) ...[
                          const SizedBox(height: 8),
                          action,
                        ],
                      ],
                    ),
                  ],
                ),
        );
      },
    ),
  );
}

Future<void> showPosCashierTour(BuildContext context) async {
  final prefs = sl<SharedPreferences>();
  final key = PosSetupGuidePage.tourPreferenceKey(prefs);
  const steps = [
    (
      'Cari atau scan produk',
      'Gunakan pencarian, kategori, favorit, atau pemindai barcode.',
    ),
    (
      'Pilih konteks order',
      'Atur jenis order, meja, channel penjualan, pelanggan, dan level harga.',
    ),
    (
      'Periksa harga',
      'Promo, diskon, pajak, dan biaya diringkas sebelum pembayaran.',
    ),
    (
      'Simpan jika belum selesai',
      'Order tersimpan dapat dilanjutkan dari Daftar Order atau Riwayat.',
    ),
    (
      'Proses pembayaran',
      'Pilih metode bayar, split payment, catatan, dan invoice bila diperlukan.',
    ),
    (
      'Pantau transaksi',
      'Gunakan Riwayat untuk cetak ulang, melanjutkan invoice, atau retur.',
    ),
    (
      'Akhiri operasional',
      'Rekonsiliasi kas lalu tutup shift setelah pekerjaan selesai.',
    ),
  ];
  var index = 0;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        icon: Icon(Icons.explore_outlined, color: AppColors.primary),
        title: Text(steps[index].$1),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(steps[index].$2, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            LinearProgressIndicator(value: (index + 1) / steps.length),
            const SizedBox(height: 6),
            Text('${index + 1} dari ${steps.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await prefs.setBool(key, true);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Lewati'),
          ),
          if (index > 0)
            TextButton(
              onPressed: () => setState(() => index--),
              child: const Text('Kembali'),
            ),
          FilledButton(
            onPressed: () async {
              if (index < steps.length - 1) {
                setState(() => index++);
                return;
              }
              await prefs.setBool(key, true);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(index == steps.length - 1 ? 'Selesai' : 'Berikutnya'),
          ),
        ],
      ),
    ),
  );
}
