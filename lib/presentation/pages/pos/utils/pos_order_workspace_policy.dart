import '../../../../domain/models/pos_order_detail.dart';

class PosOrderWorkspacePolicy {
  const PosOrderWorkspacePolicy(this.runtime);
  final Map<String, dynamic> runtime;
  Map get features => runtime['features'] as Map? ?? const {};
  String get profile => runtime['business_profile']?.toString() ?? 'retail';
  bool get service =>
      const ['laundry', 'bengkel', 'salon', 'jasa'].contains(profile) ||
      (features['use_service_order'] == true &&
          profile != 'restoran' &&
          !kitchen &&
          features['use_tables'] != true);
  bool get kitchen => features['use_kitchen_flow'] == true;
  bool get visible =>
      runtime['has_open_orders'] == true ||
      service ||
      const [
        'use_order_queue',
        'use_tables',
        'use_kitchen_flow',
        'use_delivery',
        'use_appointments',
      ].any((key) => features[key] == true);
  String get title => features['use_tables'] == true
      ? 'Pesanan & Meja'
      : const {
              'laundry': 'Pesanan Laundry',
              'bengkel': 'Pekerjaan Bengkel',
              'salon': 'Reservasi & Layanan',
              'jasa': 'Pesanan Layanan',
            }[profile] ??
            (service ? 'Pesanan Layanan' : 'Pesanan');

  bool isServiceOrder(PosOrderDetail order) {
    final s = order.serviceOrder;
    return s != null &&
        ((s['service_lines'] as List?)?.isNotEmpty == true ||
            (s['vehicle_no']?.toString() ?? '').isNotEmpty ||
            (s['service_mode']?.toString() ?? '').isNotEmpty ||
            (s['complaint']?.toString() ?? '').isNotEmpty ||
            (s['bag_tag']?.toString() ?? '').isNotEmpty ||
            (num.tryParse('${s['weight_kg']}') ?? 0) > 0 ||
            (num.tryParse('${s['item_count']}') ?? 0) > 0 ||
            const [
              'laundry',
              'bengkel',
              'salon',
              'jasa',
            ].contains(s['service_type']) ||
            service);
  }

  String stageLabel(String status, [PosOrderDetail? order]) {
    final isService = order?.serviceOrder != null
        ? isServiceOrder(order!)
        : service;
    final type = order?.orderType;
    final delivery = const ['delivery', 'online_delivery'].contains(type);
    return switch (status) {
      'Baru' => isService ? 'Diterima' : 'Pesanan Baru',
      'Diproses' =>
        isService
            ? 'Dikerjakan'
            : kitchen
            ? 'Sedang Dibuat'
            : 'Disiapkan',
      'Siap' =>
        isService
            ? 'Siap Diambil'
            : delivery
            ? 'Siap Dikirim'
            : kitchen
            ? 'Siap Disajikan'
            : type != null
            ? 'Siap Diambil'
            : 'Siap Diambil / Dikirim',
      'Disajikan' =>
        delivery
            ? 'Dikirim'
            : kitchen && const ['dine_in', 'free_table'].contains(type)
            ? 'Disajikan'
            : 'Diserahkan',
      'Selesai' => 'Selesai',
      'Batal' => 'Dibatalkan',
      _ => status,
    };
  }

  String actionLabel(String target, [PosOrderDetail? order]) {
    if (order != null && isServiceOrder(order)) return 'Kelola layanan';
    final delivery = const [
      'delivery',
      'online_delivery',
    ].contains(order?.orderType);
    return switch (target) {
      'Diproses' => kitchen ? 'Mulai proses' : 'Siapkan pesanan',
      'Siap' =>
        delivery
            ? 'Tandai siap dikirim'
            : kitchen
            ? 'Tandai siap disajikan'
            : 'Tandai siap diambil',
      'Disajikan' =>
        delivery
            ? 'Konfirmasi sudah dikirim'
            : kitchen &&
                  const ['dine_in', 'free_table'].contains(order?.orderType)
            ? 'Konfirmasi sudah disajikan'
            : 'Konfirmasi sudah diserahkan',
      _ =>
        delivery
            ? 'Konfirmasi diterima pelanggan'
            : order?.orderType == 'dine_in'
            ? 'Tutup & kosongkan meja'
            : 'Selesaikan pesanan',
    };
  }
}
