/// Server-owned subscription deadlines; never derive access from a device date
/// or the raw subscription_status alone.
class PosSubscription {
  const PosSubscription({
    required this.accessLevel,
    required this.effectiveState,
    required this.serverNow,
    required this.offlineValidUntil,
    this.expiresAt,
    this.operationalUntil,
    this.readOnlyUntil,
    this.isOwner = false,
    this.packageName = '',
    this.daysRemaining,
  });
  final String accessLevel, effectiveState, packageName;
  final DateTime serverNow, offlineValidUntil;
  final DateTime? expiresAt, operationalUntil, readOnlyUntil;
  final bool isOwner;
  final int? daysRemaining;

  factory PosSubscription.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) =>
        DateTime.tryParse(json[key]?.toString() ?? '')?.toUtc();
    final serverNow = date('server_now');
    final offlineUntil = date('offline_valid_until');
    final access = json['access_level'];
    if (serverNow == null ||
        offlineUntil == null ||
        !const [
          'full',
          'read_only',
          'billing_only',
          'blocked',
        ].contains(access)) {
      throw const FormatException('Status langganan server belum lengkap.');
    }
    return PosSubscription(
      accessLevel: access as String,
      effectiveState: json['effective_state']?.toString() ?? 'recovery',
      serverNow: serverNow,
      offlineValidUntil: offlineUntil,
      expiresAt: date('expires_at'),
      operationalUntil: date('operational_until'),
      readOnlyUntil: date('read_only_until'),
      isOwner: json['is_owner'] == true,
      packageName: json['package_name']?.toString() ?? '',
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
    );
  }

  String levelAt(DateTime now) {
    if (accessLevel == 'full' &&
        operationalUntil != null &&
        !now.isBefore(operationalUntil!)) {
      return readOnlyUntil != null && now.isBefore(readOnlyUntil!)
          ? 'read_only'
          : isOwner
          ? 'billing_only'
          : 'blocked';
    }
    if (accessLevel == 'read_only' &&
        readOnlyUntil != null &&
        !now.isBefore(readOnlyUntil!)) {
      return isOwner ? 'billing_only' : 'blocked';
    }
    return accessLevel;
  }

  bool warningAt(DateTime now) =>
      levelAt(now) != 'full' ||
      (expiresAt != null &&
          expiresAt!.difference(now) <= const Duration(days: 7));
}

const posSubscriptionRecoveryMutations = {
  'Login',
  'LoginWithGoogle',
  'RefreshMobileSession',
  'RevokeMobileSession',
  'Logout',
  'saveDeviceAppsID',
  'SetMyPOSPin',
  'VerifyMyPOSPin',
  'VerifyPOSUserPin',
  'ClosePOSKasirShift',
  'UpdateProfile',
  'UpdateMyPOSPersonalProfile',
  'RequestChangePassword',
  'CreateSupportTicket',
  'ReplySupportTicket',
  'UpdateMySupportTicket',
  'DeleteMySupportTicket',
};

const posSubscriptionBlockedMessage =
    'Penjualan dan perubahan data belum tersedia. Periksa status langganan; draft dan antrean transaksi tetap tersimpan.';
const posSubscriptionUnverifiedMessage =
    'Status langganan belum dapat diverifikasi. Sambungkan internet lalu cek status; draft dan antrean tetap tersimpan.';
