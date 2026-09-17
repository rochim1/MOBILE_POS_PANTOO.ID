import 'package:flutter/material.dart';

import '../../../../../core/_core.dart';

final posPinSetupTourTarget = GlobalKey(debugLabel: 'setup-pin');
final posPinOperatorTourTarget = GlobalKey(debugLabel: 'setup-pin-operator');
final posPinEntryTourTarget = GlobalKey(debugLabel: 'setup-pin-entry');
final posPinSubmitTourTarget = GlobalKey(debugLabel: 'setup-pin-submit');

class PosSetupTourTargets {
  final warehouseAdd = GlobalKey(debugLabel: 'setup-warehouse-add');
  final warehouseName = GlobalKey(debugLabel: 'setup-warehouse-name');
  final warehouseType = GlobalKey(debugLabel: 'setup-warehouse-type');
  final warehouseSellable = GlobalKey(debugLabel: 'setup-warehouse-sellable');
  final warehouseSave = GlobalKey(debugLabel: 'setup-warehouse-save');
  final stockLocation = GlobalKey(debugLabel: 'setup-stock-location');
  final productAdd = GlobalKey(debugLabel: 'setup-product-add');
  final outletAdd = GlobalKey(debugLabel: 'setup-outlet-add');
  final outletName = GlobalKey(debugLabel: 'setup-outlet-name');
  final outletWarehouse = GlobalKey(debugLabel: 'setup-outlet-warehouse');
  final outletSave = GlobalKey(debugLabel: 'setup-outlet-save');
  final productName = GlobalKey(debugLabel: 'setup-product-name');
  final productPrice = GlobalKey(debugLabel: 'setup-product-price');
  final productType = GlobalKey(debugLabel: 'setup-product-type');
  final productCategory = GlobalKey(debugLabel: 'setup-product-category');
  final productStockTab = GlobalKey(debugLabel: 'setup-product-stock-tab');
  final productBaseUnit = GlobalKey(debugLabel: 'setup-product-base-unit');
  final productSave = GlobalKey(debugLabel: 'setup-product-save');
  final settingsSave = GlobalKey(debugLabel: 'setup-settings-save');
  final settingsProfile = GlobalKey(debugLabel: 'setup-settings-profile');
  final settingsStock = GlobalKey(debugLabel: 'setup-settings-stock');
  final stockContent = GlobalKey(debugLabel: 'setup-stock-content');
  final stockAdjust = GlobalKey(debugLabel: 'setup-stock-adjust');
  final pinManage = GlobalKey(debugLabel: 'setup-pin-manage');
  final pinEmployee = GlobalKey(debugLabel: 'setup-pin-employee');
  final pinValue = GlobalKey(debugLabel: 'setup-pin-value');
  final pinSave = GlobalKey(debugLabel: 'setup-pin-save');
  final shiftStore = GlobalKey(debugLabel: 'setup-shift-store');
  final shiftForm = GlobalKey(debugLabel: 'setup-shift-form');
  final shiftOpen = GlobalKey(debugLabel: 'setup-shift-open');
}

class PosSetupActionController {
  Future<void> Function()? _action;

  void attach(Future<void> Function() callback) => _action = callback;
  void detach(Future<void> Function() callback) {
    if (identical(_action, callback)) _action = null;
  }

  Future<bool> run({Duration timeout = const Duration(seconds: 2)}) async {
    final deadline = DateTime.now().add(timeout);
    while (_action == null && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    final action = _action;
    if (action == null) return false;
    await action();
    return true;
  }
}

class PosWarehouseTourController {
  Future<void> Function()? _openGuidedCreate;

  void attach(Future<void> Function() callback) => _openGuidedCreate = callback;
  void detach(Future<void> Function() callback) {
    if (identical(_openGuidedCreate, callback)) _openGuidedCreate = null;
  }

  Future<bool> openGuidedCreate({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (_openGuidedCreate == null && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
    final action = _openGuidedCreate;
    if (action == null) return false;
    await action();
    return true;
  }
}

class PosSetupTourStage {
  final String title;
  final String description;
  final GlobalKey? target;
  final Future<void> Function()? onTargetTap;
  final bool continueAfterTargetTap;

  const PosSetupTourStage({
    required this.title,
    required this.description,
    this.target,
    this.onTargetTap,
    this.continueAfterTargetTap = false,
  });

  PosSetupTourStage withTarget(
    GlobalKey value, {
    Future<void> Function()? onTargetTap,
    bool? continueAfterTargetTap,
  }) => PosSetupTourStage(
    title: title,
    description: description,
    target: value,
    onTargetTap: onTargetTap ?? this.onTargetTap,
    continueAfterTargetTap:
        continueAfterTargetTap ?? this.continueAfterTargetTap,
  );
}

Future<void> showInteractivePosSetupTour(
  BuildContext context, {
  required GlobalKey fallbackTarget,
  required String stepTitle,
  required List<PosSetupTourStage> stages,
  int stageNumberOffset = 0,
  int? totalStageCount,
}) async {
  if (stages.isEmpty) return;
  var index = 0;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    pageBuilder: (dialogContext, _, __) => StatefulBuilder(
      builder: (context, setState) {
        final stage = stages[index];
        final target = stage.target ?? fallbackTarget;
        Rect targetRect() {
          Rect? resolve(GlobalKey key) {
            final render = key.currentContext?.findRenderObject();
            if (render is RenderBox && render.hasSize) {
              return (render.localToGlobal(Offset.zero) & render.size).inflate(
                7,
              );
            }
            return null;
          }

          final resolved = resolve(target) ?? resolve(fallbackTarget);
          if (resolved != null) return resolved;
          final media = MediaQuery.of(context);
          return Rect.fromCenter(
            center: media.size.center(Offset.zero),
            width: media.size.width.clamp(240, 640),
            height: media.size.height.clamp(180, 420),
          );
        }

        final media = MediaQuery.of(context);
        final rawRect = targetRect();
        final rect = Rect.fromLTRB(
          rawRect.left.clamp(8, media.size.width - 8),
          rawRect.top.clamp(media.padding.top + 8, media.size.height - 8),
          rawRect.right.clamp(8, media.size.width - 8),
          rawRect.bottom.clamp(media.padding.top + 8, media.size.height - 8),
        );
        final showBelow = rect.center.dy < media.size.height * .52;
        final last = index == stages.length - 1;

        Future<void> advance() async {
          if (stage.onTargetTap != null) {
            if (!stage.continueAfterTargetTap) {
              Navigator.pop(dialogContext);
              await stage.onTargetTap!();
              return;
            }
            await stage.onTargetTap!();
            if (!dialogContext.mounted) return;
          }
          if (last) {
            Navigator.pop(dialogContext);
          } else {
            setState(() => index++);
            await WidgetsBinding.instance.endOfFrame;
            if (!dialogContext.mounted) return;
            final nextTarget = stages[index].target ?? fallbackTarget;
            final nextContext = nextTarget.currentContext;
            if (nextContext != null) {
              await Scrollable.ensureVisible(
                nextContext,
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                alignment: .5,
              );
              if (dialogContext.mounted) setState(() {});
            }
          }
        }

        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _SetupSpotlightPainter(rect)),
              ),
              Positioned.fromRect(
                rect: rect,
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
                top: showBelow
                    ? (rect.bottom + 14).clamp(
                        media.padding.top + 12,
                        media.size.height - 260,
                      )
                    : null,
                bottom: showBelow
                    ? null
                    : (media.size.height - rect.top + 14).clamp(
                        media.padding.bottom + 12,
                        media.size.height - 260,
                      ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Card(
                      elevation: 14,
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
                                    '${stageNumberOffset + index + 1} / ${totalStageCount ?? stages.length}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    stepTitle,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Tutup panduan',
                                  onPressed: () => Navigator.pop(dialogContext),
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                            Text(
                              stage.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              stage.description,
                              style: const TextStyle(
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Row(
                              children: [
                                Icon(
                                  Icons.touch_app_outlined,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    'Ketuk elemen yang disorot untuk melanjutkan.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                if (index > 0)
                                  TextButton(
                                    onPressed: () => setState(() => index--),
                                    child: const Text('Kembali'),
                                  ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Lewati'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: () => advance(),
                                  icon: Icon(
                                    last
                                        ? Icons.check_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 17,
                                  ),
                                  label: Text(last ? 'Mengerti' : 'Berikutnya'),
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

class _SetupSpotlightPainter extends CustomPainter {
  final Rect target;

  const _SetupSpotlightPainter(this.target);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(target, const Radius.circular(12)));
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: .72));
  }

  @override
  bool shouldRepaint(_SetupSpotlightPainter oldDelegate) =>
      oldDelegate.target != target;
}
