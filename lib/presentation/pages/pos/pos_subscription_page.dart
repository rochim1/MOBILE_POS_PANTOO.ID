import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/subscription/pos_subscription_service.dart';
import '../../../core/_core.dart';

final pantooBillingWebUri = Uri.parse('https://app.pantoo.id/hrms/billing');
String subscriptionText(BuildContext context, String id, String en) =>
    Localizations.localeOf(context).languageCode == 'en' ? en : id;
String subscriptionDate(BuildContext context, DateTime? value) => value == null
    ? '—'
    : DateFormat(
        'dd MMM yyyy, HH:mm',
        Localizations.localeOf(context).languageCode,
      ).format(value.toLocal());

class PosSubscriptionPage extends StatefulWidget {
  const PosSubscriptionPage({
    super.key,
    required this.service,
    this.embedded = false,
    this.onLogout,
    this.openWeb,
    this.onCloseShift,
    this.onViewQueue,
  });
  final PosSubscriptionService service;
  final bool embedded;
  final VoidCallback? onLogout;
  final VoidCallback? onCloseShift, onViewQueue;
  final Future<bool> Function(Uri)? openWeb;
  @override
  State<PosSubscriptionPage> createState() => _PosSubscriptionPageState();
}

class _PosSubscriptionPageState extends State<PosSubscriptionPage> {
  bool _opening = false;
  String? _launchError;
  Future<void> _openBilling() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _launchError = null;
    });
    try {
      // Browser owns its own authenticated web session. No POS tokens in URL.
      final opened =
          await (widget.openWeb?.call(pantooBillingWebUri) ??
              launchUrl(
                pantooBillingWebUri,
                mode: LaunchMode.externalApplication,
              ));
      if (!opened && mounted) {
        setState(
          () => _launchError = subscriptionText(
            context,
            'Web admin belum dapat dibuka. Coba lagi.',
            'Could not open web admin. Try again.',
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _launchError = subscriptionText(
            context,
            'Web admin belum dapat dibuka. Periksa browser perangkat.',
            'Could not open web admin. Check the device browser.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.service,
    builder: (context, _) {
      final service = widget.service;
      final value = service.snapshot;
      String t(String id, String en) => subscriptionText(context, id, en);
      final unknown =
          service.accessLevel == 'unknown' ||
          (service.accessLevel == 'full' && !service.canSell);
      final title = unknown
          ? t('Periksa status langganan', 'Check subscription status')
          : service.accessLevel == 'read_only'
          ? t('Mode baca saja', 'Read-only mode')
          : service.recoveryOnly
          ? t('Langganan perlu diaktifkan', 'Subscription needs activation')
          : t('Langganan Pantoo', 'Pantoo subscription');
      final content = SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    service.canSell
                        ? Icons.verified_outlined
                        : Icons.event_busy_outlined,
                    size: 40,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    unknown
                        ? t(
                            'Status belum dapat dipastikan. Periksa koneksi lalu cek kembali; Anda tidak perlu keluar dari akun.',
                            'Status could not be confirmed. Check your connection and retry; you do not need to sign out.',
                          )
                        : service.canSell
                        ? t(
                            'Perpanjangan dan pembayaran paket tetap dikelola melalui web admin Pantoo.',
                            'Renewals and subscription payments are managed in Pantoo web admin.',
                          )
                        : t(
                            'Penjualan baru dan perubahan data dibatasi. Draft dan antrean transaksi tetap tersimpan.',
                            'New sales and data changes are restricted. Drafts and queued transactions are preserved.',
                          ),
                  ),
                  const SizedBox(height: 24),
                  if (value != null) ...[
                    if (value.packageName.isNotEmpty)
                      _detail(t('Paket', 'Plan'), value.packageName),
                    _detail(
                      t('Berlaku sampai', 'Valid until'),
                      subscriptionDate(context, value.expiresAt),
                    ),
                    if (value.effectiveState == 'grace' ||
                        (value.expiresAt != null &&
                            !service.serverNow.isBefore(value.expiresAt!)))
                      _detail(
                        t('Batas penjualan', 'Sales cutoff'),
                        subscriptionDate(context, value.operationalUntil),
                      ),
                    if (service.accessLevel == 'read_only')
                      _detail(
                        t('Akses baca sampai', 'Read access until'),
                        subscriptionDate(context, value.readOnlyUntil),
                      ),
                    const Divider(height: 28),
                  ],
                  if (service.offline) ...[
                    Text(
                      t(
                        'Menampilkan status terakhir. Pemeriksaan terbaru belum berhasil.',
                        'Showing the last known status. The latest check was unsuccessful.',
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    service.isOwner || value == null
                        ? t(
                            'Login sebagai pemilik di web admin untuk memperpanjang. Pembayaran yang masih menunggu verifikasi belum mengaktifkan paket.',
                            'Sign in as the owner in web admin to renew. A payment awaiting verification does not activate the plan.',
                          )
                        : t(
                            'Hubungi pemilik untuk memperpanjang langganan. Setelah diperpanjang, tekan Cek Status.',
                            'Contact the owner to renew the subscription. After renewal, tap Check Status.',
                          ),
                  ),
                  const SizedBox(height: 20),
                  if (service.isOwner || value == null) ...[
                    FilledButton.icon(
                      key: const Key('subscription_open_web'),
                      onPressed: _opening ? null : _openBilling,
                      icon: const Icon(Icons.open_in_new),
                      label: Text(
                        t('Perpanjang di Web Admin', 'Renew in Web Admin'),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    key: const Key('subscription_refresh'),
                    onPressed: service.checking ? null : service.refresh,
                    icon: service.checking
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(
                      service.checking
                          ? t('Memeriksa…', 'Checking…')
                          : t('Cek Status', 'Check Status'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t(
                      'Status diperiksa otomatis saat Anda kembali dari web admin.',
                      'Status is checked automatically when you return from web admin.',
                    ),
                  ),
                  if (_launchError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _launchError!,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ),
                  if (widget.onCloseShift != null) ...[
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: widget.onCloseShift,
                      icon: const Icon(Icons.lock_clock_outlined),
                      label: Text(t('Tutup shift aktif', 'Close active shift')),
                    ),
                  ],
                  if (widget.onViewQueue != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: widget.onViewQueue,
                      icon: const Icon(Icons.cloud_sync_outlined),
                      label: Text(
                        t('Periksa antrean tersimpan', 'View saved queue'),
                      ),
                    ),
                  ],
                  if (widget.onLogout != null) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: widget.onLogout,
                      child: Text(
                        t('Ganti akun / Keluar', 'Switch account / Sign out'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
      return widget.embedded
          ? content
          : Scaffold(
              backgroundColor: AppColors.bgPrimary,
              appBar: AppBar(title: Text(t('Langganan', 'Subscription'))),
              body: content,
            );
    },
  );

  Widget _detail(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
