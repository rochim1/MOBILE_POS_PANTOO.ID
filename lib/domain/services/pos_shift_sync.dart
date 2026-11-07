import '../models/pos_store.dart';

List<PosStore> checkoutStores(
  List<PosStore> stores,
  Map<String, dynamic> runtimeConfig,
) {
  final policy = runtimeConfig['inventory_policy'] as Map? ?? const {};
  final profile =
      policy['inventory_profile'] ?? runtimeConfig['inventory_profile'];
  final location =
      policy['default_receiving_location_id']?.toString().trim() ?? '';
  return stores
      .where(
        (store) =>
            store.id.isNotEmpty &&
            store.status.toLowerCase() == 'active' &&
            store.branchId.isNotEmpty &&
            (profile != 'simple' ||
                location.isEmpty ||
                store.branchId == location),
      )
      .toList(growable: false);
}

/// Resolve an existing shift before offering a store or opening-cash form.
/// Each request retains store-mode ownership; an unscoped "latest" is ambiguous.
Future<Map<String, dynamic>?> discoverCheckoutShift({
  required List<PosStore> stores,
  required Map<String, dynamic> runtimeConfig,
  required String operatorId,
  required String terminalUserId,
  required Future<Map<String, dynamic>?> Function(String) readShift,
  required bool Function() isCurrent,
  String? preferredStoreId,
}) async {
  final available = checkoutStores(stores, runtimeConfig);
  final preferred = available
      .where((store) => store.id == preferredStoreId)
      .firstOrNull;
  final candidates = <PosStore>[
    if (preferred != null) preferred,
    ...available.where((store) => store.id != preferred?.id),
  ];
  final checkedModes = <String>{};
  for (final store in candidates) {
    if (!const {'per_operator', 'shared_register'}.contains(store.shiftMode)) {
      throw StateError(
        'Mode shift toko belum tersimpan. Hubungkan internet dan muat ulang toko sekali sebelum melanjutkan offline.',
      );
    }
    final mode = store.shiftMode == 'per_operator'
        ? 'per_operator'
        : 'shared_register';
    if (!checkedModes.add(mode)) continue;
    if (mode == 'per_operator' && operatorId.isEmpty) {
      throw StateError('Masukkan PIN kasir sebelum memeriksa shift.');
    }
    final shift = await readShift(store.id);
    if (!isCurrent()) throw StateError('Sesi kasir berubah. Muat ulang shift.');
    if (shift == null) continue;
    if (shift['_offline_snapshot'] == true) {
      final savedMode =
          shift['shift_mode']?.toString() ??
          available
              .where(
                (candidate) => candidate.id == shift['toko_id']?.toString(),
              )
              .firstOrNull
              ?.shiftMode;
      if (!const {'per_operator', 'shared_register'}.contains(savedMode)) {
        throw StateError(
          'Mode snapshot shift belum tersedia. Verifikasi shift saat online terlebih dahulu.',
        );
      }
      // A single cached active shift can be returned for a cross-outlet probe.
      // Continue to the candidate of its own ownership mode, never reinterpret
      // a PIN-owned shift as a terminal-owned shared register (or vice versa).
      if (savedMode != mode) continue;
    }
    final expectedOwner = mode == 'per_operator' ? operatorId : terminalUserId;
    if (expectedOwner.isEmpty ||
        shift['kasir_user_id']?.toString() != expectedOwner) {
      throw StateError(
        'Shift tidak sesuai dengan sesi kasir. Hubungkan kembali untuk memeriksa shift.',
      );
    }
    final target = available
        .where((item) => item.id == shift['toko_id']?.toString())
        .firstOrNull;
    if (shift['status'] != 'open' || target == null) {
      throw StateError(
        'Outlet shift aktif belum tersedia untuk penjualan. Minta supervisor memeriksa akses dan lokasi stok.',
      );
    }
    return shift;
  }
  return null;
}
