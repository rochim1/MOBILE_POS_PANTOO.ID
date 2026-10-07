import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/_core.dart';
import '../../core/customer_display/pos_customer_display_service.dart';
import '../../injections.dart';

Future<void> showPosCustomerDisplayPairing(BuildContext context) async {
  final service = sl<PosCustomerDisplayService>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: ValueListenableBuilder<PosCustomerDisplayState>(
            valueListenable: service.state,
            builder: (context, state, _) {
              final isWaiting =
                  state.connection == PosCustomerDisplayConnection.connecting ||
                  state.connection == PosCustomerDisplayConnection.waiting;
              final isConnected =
                  state.connection == PosCustomerDisplayConnection.connected;
              final hasPairingSession =
                  state.pairingUrl.isNotEmpty && (isWaiting || isConnected);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.connected_tv_outlined,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Hubungkan Layar Pelanggan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.heading,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Buka tautan ini pada tablet/monitor pelanggan. Layar tersebut hanya menampilkan keranjang dan total, tanpa akses akun POS.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PairingGuide(hasLink: state.pairingUrl.isNotEmpty),
                  const SizedBox(height: 18),
                  if (state.pairingUrl.isNotEmpty) ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: QrImageView(
                          data: state.pairingUrl,
                          size: 148,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: AppColors.primary,
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.successBorder),
                      ),
                      child: SelectableText(
                        state.pairingUrl,
                        style: const TextStyle(
                          color: AppColors.body,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: state.pairingUrl),
                        );
                        if (sheetContext.mounted) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(
                              content: Text('Tautan layar pelanggan disalin'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Salin tautan'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (state.message.isNotEmpty) ...[
                    Text(
                      state.message,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isWaiting || isConnected
                              ? null
                              : () => service.beginPairing(),
                          icon: isWaiting
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.link_outlined),
                          label: Text(
                            isWaiting
                                ? 'Menunggu perangkat…'
                                : isConnected
                                ? 'Layar terhubung'
                                : 'Buat tautan pairing',
                          ),
                        ),
                      ),
                      if (hasPairingSession) ...[
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: service.disconnect,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                          ),
                          child: const Text('Putuskan'),
                        ),
                      ],
                    ],
                  ),
                  if (isConnected) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Terhubung · perubahan keranjang akan tampil otomatis.',
                      style: TextStyle(color: AppColors.success, fontSize: 12),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class _PairingGuide extends StatelessWidget {
  final bool hasLink;

  const _PairingGuide({required this.hasLink});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        border: Border.all(color: AppColors.info.withValues(alpha: .35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cara menyambungkan',
            style: TextStyle(
              color: AppColors.heading,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 9),
          _GuideStep(
            number: '1',
            text: hasLink
                ? 'Tautan pairing sudah dibuat di bawah.'
                : 'Tekan “Buat tautan pairing” di bawah.',
          ),
          const SizedBox(height: 7),
          const _GuideStep(
            number: '2',
            text:
                'Di tablet atau monitor pelanggan, pindai QR atau buka tautan yang disalin. Tidak perlu login.',
          ),
          const SizedBox(height: 7),
          const _GuideStep(
            number: '3',
            text:
                'Tunggu status “Layar terhubung”, lalu tambahkan produk ke keranjang untuk memastikan layar ikut berubah.',
          ),
          const SizedBox(height: 7),
          const _GuideStep(
            number: '4',
            text:
                'Tekan “Putuskan” setelah kasir selesai atau sebelum berganti operator. Tautan akan dinonaktifkan.',
          ),
          const SizedBox(height: 9),
          const Text(
            'Kedua perangkat memerlukan koneksi internet. Layar pelanggan tidak dapat mengakses data akun atau mengubah transaksi.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String number;
  final String text;

  const _GuideStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.body,
              fontSize: 12,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
