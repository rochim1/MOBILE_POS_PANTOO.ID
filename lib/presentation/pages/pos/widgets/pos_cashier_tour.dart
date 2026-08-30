import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/_core.dart';
import '../../../../../injections.dart';
import '../pos_onboarding_page.dart';

class PosCashierTourTargets {
  final search = GlobalKey(debugLabel: 'tour-search');
  final salesContext = GlobalKey(debugLabel: 'tour-sales-context');
  final saveOrder = GlobalKey(debugLabel: 'tour-save-order');
  final payment = GlobalKey(debugLabel: 'tour-payment');
}

class _TourStep {
  final GlobalKey target;
  final String title;
  final String description;

  const _TourStep(this.target, this.title, this.description);
}

Future<void> showInteractivePosCashierTour(
  BuildContext context,
  PosCashierTourTargets targets,
) async {
  final prefs = sl<SharedPreferences>();
  final steps = [
    _TourStep(
      targets.search,
      'Cari atau scan produk',
      'Ketuk kolom ini untuk mencari nama, SKU, kode, atau memindai barcode.',
    ),
    _TourStep(
      targets.salesContext,
      'Atur konteks penjualan',
      'Ketuk untuk memilih channel, level harga, pajak, jenis order, dan promo.',
    ),
    _TourStep(
      targets.saveOrder,
      'Simpan order sementara',
      'Ketuk Simpan jika pelanggan belum siap membayar. Order dapat dilanjutkan kembali.',
    ),
    _TourStep(
      targets.payment,
      'Lanjutkan pembayaran',
      'Setelah keranjang terisi, ketuk Bayar untuk memilih metode pembayaran dan invoice.',
    ),
  ];
  var index = 0;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    pageBuilder: (dialogContext, _, __) => StatefulBuilder(
      builder: (context, setState) {
        Rect? targetRect() {
          final targetContext = steps[index].target.currentContext;
          final render = targetContext?.findRenderObject();
          if (render is! RenderBox || !render.hasSize) return null;
          final topLeft = render.localToGlobal(Offset.zero);
          return (topLeft & render.size).inflate(7);
        }

        Future<void> advance() async {
          if (index < steps.length - 1) {
            setState(() => index++);
            return;
          }
          await PosOnboardingPage.markOperationalSetupCompleted(prefs);
          if (dialogContext.mounted) Navigator.pop(dialogContext);
        }

        final media = MediaQuery.of(context);
        final screen = Offset.zero & media.size;
        final rect =
            targetRect() ??
            Rect.fromCenter(
              center: screen.center,
              width: media.size.width.clamp(240, 520),
              height: 70,
            );
        final safeRect = Rect.fromLTRB(
          rect.left.clamp(8, media.size.width - 8),
          rect.top.clamp(media.padding.top + 8, media.size.height - 8),
          rect.right.clamp(8, media.size.width - 8),
          rect.bottom.clamp(media.padding.top + 8, media.size.height - 8),
        );
        final showBelow = safeRect.center.dy < media.size.height * .55;
        final cardTop = showBelow
            ? (safeRect.bottom + 14).clamp(
                media.padding.top + 12,
                media.size.height - 210,
              )
            : null;
        final cardBottom = showBelow
            ? null
            : (media.size.height - safeRect.top + 14).clamp(
                media.padding.bottom + 12,
                media.size.height - 210,
              );

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _SpotlightPainter(safeRect)),
              ),
              Positioned.fromRect(
                rect: safeRect,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: advance,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                top: cardTop?.toDouble(),
                bottom: cardBottom?.toDouble(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: .1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${index + 1} / ${steps.length}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () async {
                                    await PosOnboardingPage.markOperationalSetupCompleted(
                                      prefs,
                                    );
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }
                                  },
                                  child: const Text('Lewati'),
                                ),
                              ],
                            ),
                            Text(
                              steps[index].title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              steps[index].description,
                              style: const TextStyle(
                                color: Colors.black54,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.touch_app_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 6),
                                const Expanded(
                                  child: Text(
                                    'Ketuk area yang disorot untuk melanjutkan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _SpotlightPainter extends CustomPainter {
  final Rect target;
  const _SpotlightPainter(this.target);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(target, const Radius.circular(12)));
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: .72));
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      oldDelegate.target != target;
}
