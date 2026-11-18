import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/_core.dart';
import '../../../../domain/repositories/pos_inventory_repository.dart';
import '../../../../injections.dart';
import '../../bloc/lock/lock_cubit.dart';
import '../../bloc/pos/pos_bloc.dart';
import '../../bloc/pos/pos_state.dart';
import 'pos_onboarding_page.dart';
import 'widgets/pos_setup_tour.dart';

class PosSetupReadiness {
  // IDs stay stable for walkthrough routing even when the compact UI hides
  // technical steps already completed by the server.
  static List<int> visibleStepIds({
    required bool automatic,
    required String inventoryProfile,
    required List<bool> completed,
  }) => [
    for (var id = 1; id <= completed.length; id++)
      if (!(automatic &&
          inventoryProfile == 'simple' &&
          const {1, 2, 4, 5}.contains(id) &&
          completed[id - 1]))
        id,
  ];
  final bool hasStore;
  final bool hasStockLocation;
  final bool hasProducts;
  final bool hasInitialStock;
  final bool hasPin;
  final bool hasShift;
  final bool configurationHealthy;

  const PosSetupReadiness({
    required this.hasStore,
    required this.hasStockLocation,
    required this.hasProducts,
    required this.hasInitialStock,
    required this.hasPin,
    required this.hasShift,
    required this.configurationHealthy,
  });

  bool get ready =>
      hasStore &&
      hasStockLocation &&
      hasProducts &&
      hasInitialStock &&
      hasPin &&
      hasShift &&
      configurationHealthy;
}

class PosSetupGuidePage extends StatefulWidget {
  final void Function(int destination, String? section) onNavigate;
  final VoidCallback onStartCashier;
  final Future<void> Function(
    int stepNumber,
    String title,
    int? destination,
    String? section,
    List<PosSetupTourStage> stages,
  )
  onStartWalkthrough;

  const PosSetupGuidePage({
    super.key,
    required this.onNavigate,
    required this.onStartCashier,
    required this.onStartWalkthrough,
  });

  static String tourPreferenceKey(SharedPreferences prefs) {
    return PosOnboardingPage.cashierTourPreferenceKey(prefs);
  }

  @override
  State<PosSetupGuidePage> createState() => _PosSetupGuidePageState();
}

class _PosSetupGuidePageState extends State<PosSetupGuidePage> {
  late Future<List<Map<String, dynamic>>> _warehouses;

  @override
  void initState() {
    super.initState();
    _warehouses = _loadWarehouses();
  }

  Future<List<Map<String, dynamic>>> _loadWarehouses() async {
    final result = await sl<PosInventoryRepository>().getWarehouses();
    return result.fold((_) => const [], (items) => items);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _warehouses,
      builder: (context, warehouseSnapshot) => BlocBuilder<PosBloc, PosState>(
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
          final sharedReadiness = Map<String, dynamic>.from(
            state.runtimeConfig['operational_readiness'] as Map? ?? const {},
          );
          final trackStock = features['track_stock'] != false;
          final activeStores = state.stores
              .where((store) => store.status.toLowerCase() == 'active')
              .toList();
          final hasStore = sharedReadiness.isNotEmpty
              ? sharedReadiness['has_linked_store'] == true
              : activeStores.isNotEmpty;
          final warehouses = warehouseSnapshot.data ?? const [];
          final hasStockLocation = sharedReadiness.isNotEmpty
              ? sharedReadiness['has_sellable_warehouse'] == true
              : (!trackStock || warehouses.isNotEmpty);
          final hasProducts = sharedReadiness.isNotEmpty
              ? sharedReadiness['has_products'] == true
              : state.products.isNotEmpty;
          final stockTrackedProducts = state.products
              .where((product) => product.tracksStock)
              .toList();
          final hasInitialStock = sharedReadiness.isNotEmpty
              ? sharedReadiness['has_initial_stock'] == true
              : (!trackStock ||
                    stockTrackedProducts.isEmpty ||
                    stockTrackedProducts.any((product) => product.stock > 0));
          final hasPin = sharedReadiness.isNotEmpty
              ? (sharedReadiness['pin_ready'] ??
                        sharedReadiness['has_pin_operator']) ==
                    true
              : (lock.hasPinConfigured ||
                    state.runtimeConfig['pos_lock_enabled'] == false ||
                    (lock.activeEmployeeId?.isNotEmpty == true &&
                        lock.operatorSessionToken.isNotEmpty));
          final hasShift = sharedReadiness.isNotEmpty
              ? (sharedReadiness['shift_ready'] ??
                        sharedReadiness['has_open_shift']) ==
                    true
              : (state.activeShift != null ||
                    state.runtimeConfig['allow_out_of_shift'] == true);
          final pinRequired =
              sharedReadiness['pin_required'] != false &&
              state.runtimeConfig['pos_lock_enabled'] != false;
          final shiftRequired =
              sharedReadiness['shift_required'] != false &&
              state.runtimeConfig['allow_out_of_shift'] != true;
          final warehouseCount =
              sharedReadiness['sellable_warehouse_count'] as int? ??
              warehouses.length;
          final linkedStoreCount =
              sharedReadiness['linked_store_count'] as int? ??
              activeStores.length;
          final productCount =
              sharedReadiness['product_count'] as int? ?? state.products.length;
          final healthy = health['valid'] != false;
          final needsDisplayPair = (health['issues'] as List? ?? const []).any(
            (issue) => issue.toString().contains('Isi Rak Display'),
          );
          final needsTransitLocation = (health['issues'] as List? ?? const [])
              .any((issue) => issue.toString().contains('Lokasi Transit'));
          final readiness = PosSetupReadiness(
            hasStore: hasStore,
            hasStockLocation: hasStockLocation,
            hasProducts: hasProducts,
            hasInitialStock: hasInitialStock,
            hasPin: hasPin,
            hasShift: hasShift,
            configurationHealthy: healthy,
          );
          final ready = readiness.ready;
          final setupCompleted = PosOnboardingPage.isOperationalSetupCompleted(
            sl<SharedPreferences>(),
          );

          final steps = <_SetupStep>[
            _SetupStep(
              title: ('Lokasi stok siap').tr(context),
              description: hasStockLocation
                  ? posLocale(
                      context,
                    ).pose02d08abae0b((warehouseCount).toString())
                  : trackStock
                  ? ('Buat warehouse/lokasi dan pastikan dapat digunakan untuk stok.')
                        .tr(context)
                  : ('Buat lokasi penjualan aktif untuk dihubungkan ke toko POS.')
                        .tr(context),
              complete: hasStockLocation,
              icon: Icons.warehouse_outlined,
              actionLabel: permissions['view_warehouses'] == true
                  ? 'Kelola lokasi'
                  : null,
              destination: 7,
              section: 'warehouse',
              walkthrough: [
                _WalkthroughStage(
                  title: ('Buat lokasi operasional').tr(context),
                  description:
                      ('Tambahkan cabang atau warehouse yang benar-benar menyimpan stok usaha.')
                          .tr(context),
                ),
                _WalkthroughStage(
                  title: ('Lengkapi hierarki lokasi').tr(context),
                  description:
                      ('Gedung, ruangan, dan rak bersifat opsional, tetapi membantu pelacakan saldo yang lebih presisi.')
                          .tr(context),
                ),
                _WalkthroughStage(
                  title: ('Aktifkan untuk penjualan').tr(context),
                  description:
                      ('Pastikan lokasi penjualan aktif agar dapat dihubungkan ke toko POS.')
                          .tr(context),
                ),
              ],
            ),
            _SetupStep(
              title: ('Toko POS aktif').tr(context),
              description: hasStore
                  ? posLocale(
                      context,
                    ).pos1c13a6636001((linkedStoreCount).toString())
                  : ('Buat toko POS dan hubungkan dengan lokasi stok.').tr(
                      context,
                    ),
              complete: hasStore,
              icon: Icons.storefront_outlined,
              actionLabel: permissions['view_stores'] == true
                  ? 'Kelola toko'
                  : null,
              destination: 10,
              walkthrough: [
                _WalkthroughStage(
                  title: ('Buat toko POS').tr(context),
                  description:
                      ('Isi nama toko dan identitas yang akan tampil pada transaksi serta struk.')
                          .tr(context),
                ),
                _WalkthroughStage(
                  title: ('Hubungkan lokasi stok').tr(context),
                  description:
                      ('Pilih warehouse/lokasi penjualan aktif sebagai sumber stok toko.')
                          .tr(context),
                ),
                _WalkthroughStage(
                  title: ('Periksa status toko').tr(context),
                  description:
                      ('Aktifkan toko dan pastikan profil POS yang benar digunakan oleh kasir.')
                          .tr(context),
                ),
              ],
            ),
            _SetupStep(
              title: ('Katalog penjualan').tr(context),
              description: hasProducts
                  ? posLocale(
                      context,
                    ).pos9511cddc9569((productCount).toString())
                  : ('Tambahkan minimal satu produk, layanan, atau paket aktif.')
                        .tr(context),
              complete: hasProducts,
              icon: Icons.inventory_2_outlined,
              actionLabel: permissions['view_products'] == true
                  ? 'Kelola katalog'
                  : null,
              destination: 2,
              walkthrough: [
                _WalkthroughStage(
                  title: ('Pilih jenis produk').tr(context),
                  description:
                      ('Gunakan produk stok, layanan, atau paket sesuai cara item dijual.')
                          .tr(context),
                ),
                _WalkthroughStage(
                  title: ('Lengkapi informasi jual').tr(context),
                  description:
                      ('Isi nama, kategori, satuan, harga, SKU/barcode, dan foto bila diperlukan.')
                          .tr(context),
                ),
                _WalkthroughStage(
                  title: ('Aktifkan di POS').tr(context),
                  description:
                      ('Pastikan produk aktif dan ditampilkan pada katalog penjualan.')
                          .tr(context),
                ),
              ],
            ),
            _SetupStep(
              title: ('Konfigurasi operasional').tr(context),
              description: healthy
                  ? ('Profil inventory dan aturan stok POS sudah konsisten.')
                        .tr(context)
                  : ((health['issues'] as List? ?? const [])
                        .map((value) => value.toString())
                        .join(' · ')),
              complete: healthy,
              icon: Icons.tune_outlined,
              actionLabel:
                  !healthy &&
                      needsDisplayPair &&
                      permissions['view_warehouses'] == true
                  ? 'Atur lokasi display'
                  : !healthy && needsTransitLocation
                  ? null
                  : !healthy && permissions['manage_settings'] == true
                  ? 'Periksa pengaturan'
                  : null,
              destination: needsDisplayPair ? 7 : 17,
              section: needsDisplayPair ? 'warehouse' : null,
              walkthrough: [
                _WalkthroughStage(
                  title: ('Periksa profil transaksi').tr(context),
                  description:
                      ('Atur pelanggan wajib, pajak, biaya, pembulatan, dan aturan penjualan sesuai kebutuhan usaha.')
                          .tr(context),
                ),
                _WalkthroughStage(
                  title: ('Selaraskan aturan stok').tr(context),
                  description:
                      ('Pastikan produk yang melacak stok memakai lokasi dan satuan yang konsisten.')
                          .tr(context),
                ),
                _WalkthroughStage(
                  title: ('Simpan dan validasi').tr(context),
                  description:
                      ('Simpan perubahan lalu kembali ke ringkasan untuk melihat hasil pemeriksaan terbaru.')
                          .tr(context),
                ),
              ],
            ),
            _SetupStep(
              title: ('Stok awal produk').tr(context),
              description: hasInitialStock
                  ? ('Stok awal produk sudah tersedia untuk mulai berjualan.')
                        .tr(context)
                  : ('Isi stok awal setelah produk selesai dibuat.').tr(
                      context,
                    ),
              complete: hasInitialStock,
              icon: Icons.inventory_outlined,
              actionLabel:
                  (permissions['view_stock'] == true ||
                      permissions['adjust_stock'] == true)
                  ? 'Isi stok awal'
                  : null,
              destination: 7,
              section: 'stock',
              walkthrough: [
                _WalkthroughStage(
                  title: ('Pilih lokasi saldo').tr(context),
                  description:
                      ('Pilih cabang hingga rak yang benar agar stok awal tercatat di lokasi fisiknya.')
                          .tr(context),
                ),
                _WalkthroughStage(
                  title: ('Masukkan stok melalui alur yang tepat').tr(context),
                  description:
                      ('Gunakan penerimaan pembelian untuk barang datang atau stok awal/koreksi untuk saldo pembukaan.')
                          .tr(context),
                ),
                _WalkthroughStage(
                  title: ('Verifikasi rincian saldo').tr(context),
                  description:
                      ('Buka detail produk dan pastikan jumlah serta hierarki lokasinya sudah sesuai.')
                          .tr(context),
                ),
              ],
            ),
            _SetupStep(
              title: ('PIN operator kasir').tr(context),
              description: hasPin
                  ? pinRequired
                        ? ('Operator kasir sudah terverifikasi.').tr(context)
                        : ('Kunci PIN dinonaktifkan sesuai kebijakan POS.').tr(
                            context,
                          )
                  : ('Pilih operator dan buat/masukkan PIN kasir.').tr(context),
              complete: hasPin,
              icon: Icons.pin_outlined,
              actionLabel: permissions['manage_settings'] == true
                  ? 'Atur PIN'
                  : null,
              destination: permissions['manage_settings'] == true ? 17 : null,
              walkthrough: [
                _WalkthroughStage(
                  title: ('Pilih operator kasir').tr(context),
                  description:
                      ('Hanya pengguna yang berwenang dan memiliki PIN yang dapat membuka sesi kasir.')
                          .tr(context),
                ),
                _WalkthroughStage(
                  title: ('Buat PIN aman').tr(context),
                  description:
                      ('Gunakan 4–6 digit angka yang mudah diingat operator tetapi tidak mudah ditebak.')
                          .tr(context),
                ),
                _WalkthroughStage(
                  title: ('Verifikasi akses').tr(context),
                  description:
                      ('Kunci layar lalu masuk kembali dengan operator dan PIN yang sudah dibuat.')
                          .tr(context),
                ),
              ],
            ),
            _SetupStep(
              title: ('Shift kasir dibuka').tr(context),
              description: hasShift
                  ? shiftRequired
                        ? ('Shift aktif dan transaksi dapat dimulai.').tr(
                            context,
                          )
                        : ('Penjualan tanpa shift diizinkan oleh kebijakan POS.')
                              .tr(context)
                  : ('Pilih toko, masukkan modal awal, lalu buka shift.').tr(
                      context,
                    ),
              complete: hasShift,
              icon: Icons.schedule_outlined,
              actionLabel: permissions['view_shifts'] == true
                  ? 'Buka shift'
                  : null,
              destination: 11,
              walkthrough: [
                _WalkthroughStage(
                  title: ('Pilih toko operasional').tr(context),
                  description:
                      ('Pastikan shift dibuka pada toko yang akan melayani transaksi hari ini.')
                          .tr(context),
                ),
                _WalkthroughStage(
                  title: ('Catat modal awal').tr(context),
                  description:
                      ('Masukkan kas awal sesuai uang fisik di laci untuk memudahkan rekonsiliasi.')
                          .tr(context),
                ),
                _WalkthroughStage(
                  title: ('Buka dan pantau shift').tr(context),
                  description:
                      ('Setelah aktif, transaksi dapat dimulai dan shift ditutup setelah rekonsiliasi.')
                          .tr(context),
                ),
              ],
            ),
            _SetupStep(
              title: ('Panduan transaksi kasir').tr(context),
              description: setupCompleted
                  ? ('Panduan kasir sudah dijalankan dan POS siap digunakan.')
                        .tr(context)
                  : ready
                  ? ('Semua prasyarat siap. Ikuti highlight interaktif di halaman kasir.')
                        .tr(context)
                  : ('Lengkapi langkah wajib yang belum selesai.').tr(context),
              complete: setupCompleted,
              icon: Icons.explore_outlined,
              actionLabel: ready ? 'Mulai panduan kasir' : null,
              onAction: ready ? widget.onStartCashier : null,
              walkthrough: [
                _WalkthroughStage(
                  title: ('Kenali area kasir').tr(context),
                  description:
                      ('Panduan interaktif akan menyorot pencarian produk, keranjang, pelanggan, dan tipe pemenuhan.')
                          .tr(context),
                ),
                _WalkthroughStage(
                  title: ('Simulasikan pesanan').tr(context),
                  description:
                      ('Ikuti sorotan untuk menambah item, mengatur konteks order, lalu memeriksa total.')
                          .tr(context),
                ),
                _WalkthroughStage(
                  title: ('Simpan atau bayar').tr(context),
                  description:
                      ('Pelajari cara menyimpan pesanan aktif serta melanjutkan ke pembayaran dan struk.')
                          .tr(context),
                ),
              ],
            ),
          ];

          final initial = state.runtimeConfig['initial_setup'];
          final visibleIds = PosSetupReadiness.visibleStepIds(
            automatic:
                initial is Map &&
                initial['automatic'] == true &&
                initial['status'] == 'ready',
            inventoryProfile:
                state.runtimeConfig['inventory_profile']?.toString() ??
                'simple',
            completed: steps.map((step) => step.complete).toList(),
          );

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
                                              ? ('POS siap digunakan').tr(
                                                  context,
                                                )
                                              : ('Selesaikan setup POS').tr(
                                                  context,
                                                ),
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
                                              ? ('Semua kebutuhan utama sudah tersedia. Anda dapat mulai melayani transaksi.')
                                                    .tr(context)
                                              : ('Selesaikan secara berurutan agar stok, toko, kasir, dan shift tetap selaras.')
                                                    .tr(context),
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
                                    steps
                                        .where((step) => step.complete)
                                        .length /
                                    steps.length,
                                minHeight: 7,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                posLocale(context).posf627ed309787(
                                  (steps.where((step) => step.complete).length)
                                      .toString(),
                                  (steps.length).toString(),
                                ),
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
                        ...visibleIds.indexed.map(
                          (entry) => _SetupStepCard(
                            number: entry.$1 + 1,
                            walkthroughNumber: entry.$2,
                            step: steps[entry.$2 - 1],
                            onNavigate: widget.onNavigate,
                            onStartWalkthrough: widget.onStartWalkthrough,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: ready ? widget.onStartCashier : null,
                            icon: const Icon(Icons.point_of_sale_outlined),
                            label: const PosText('Mulai Berjualan'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                          ),
                        ),
                        if (!ready) ...[
                          const SizedBox(height: 8),
                          const PosText(
                            'Tombol aktif setelah semua kebutuhan wajib selesai. Langkah tanpa akses harus diselesaikan admin POS.',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
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
      ),
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
  final String? section;
  final VoidCallback? onAction;
  final List<_WalkthroughStage> walkthrough;

  const _SetupStep({
    required this.title,
    required this.description,
    required this.complete,
    required this.icon,
    this.actionLabel,
    this.destination,
    this.section,
    this.onAction,
    required this.walkthrough,
  });
}

class _WalkthroughStage {
  final String title;
  final String description;

  const _WalkthroughStage({required this.title, required this.description});
}

class _SetupStepCard extends StatelessWidget {
  final int number;
  final int walkthroughNumber;
  final _SetupStep step;
  final void Function(int destination, String? section) onNavigate;
  final Future<void> Function(
    int stepNumber,
    String title,
    int? destination,
    String? section,
    List<PosSetupTourStage> stages,
  )
  onStartWalkthrough;

  const _SetupStepCard({
    required this.number,
    required this.walkthroughNumber,
    required this.step,
    required this.onNavigate,
    required this.onStartWalkthrough,
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
                ? AppColors.success.withValues(alpha: .1)
                : AppColors.warning.withValues(alpha: .1),
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
                color: step.complete ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 5),
              Text(
                step.complete
                    ? ('Selesai').tr(context)
                    : ('Perlu disiapkan').tr(context),
                style: TextStyle(
                  color: step.complete ? AppColors.success : AppColors.warning,
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
              posLocale(context).pos73c8c1400ddb((number).toString()),
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            PosText(
              step.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 4),
            PosText(
              step.description,
              style: const TextStyle(color: Colors.black54, height: 1.3),
            ),
          ],
        );
        final action = OutlinedButton.icon(
          onPressed: () {
            if (walkthroughNumber == 8 && step.onAction != null) {
              step.onAction!();
              return;
            }
            onStartWalkthrough(
              walkthroughNumber,
              step.title,
              step.destination,
              step.section,
              step.walkthrough
                  .map(
                    (stage) => PosSetupTourStage(
                      title: stage.title,
                      description: stage.description,
                    ),
                  )
                  .toList(growable: false),
            );
          },
          icon: Icon(
            step.complete ? Icons.replay_rounded : Icons.play_arrow_rounded,
            size: 17,
          ),
          label: Text(
            step.complete
                ? ('Ulangi panduan').tr(context)
                : ('Mulai panduan').tr(context),
          ),
        );
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
                      children: [status, action],
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
                      children: [status, const SizedBox(height: 8), action],
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
        title: PosText(steps[index].$1),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PosText(steps[index].$2, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            LinearProgressIndicator(value: (index + 1) / steps.length),
            const SizedBox(height: 6),
            Text(
              posLocale(context).pos9074e3322f20(
                (index + 1).toString(),
                (steps.length).toString(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await prefs.setBool(key, true);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const PosText('Lewati'),
          ),
          if (index > 0)
            TextButton(
              onPressed: () => setState(() => index--),
              child: const PosText('Kembali'),
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
            child: Text(
              index == steps.length - 1
                  ? ('Selesai').tr(context)
                  : ('Berikutnya').tr(context),
            ),
          ),
        ],
      ),
    ),
  );
}
