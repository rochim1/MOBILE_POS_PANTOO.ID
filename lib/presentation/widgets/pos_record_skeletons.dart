import 'package:flutter/material.dart';
import 'skeleton_loading.dart';
import 'pos_metric_card.dart';

enum PosRecordSkeletonKind {
  transaction,
  promo,
  salesReturn,
  offlineQueue,
  trade,
  notification,
  purchaseAdvance,
}

/// Uses each document's header, metadata and action layout. No fake data/labels.
class PosRecordCardSkeleton extends StatelessWidget {
  const PosRecordCardSkeleton({super.key, required this.kind});
  final PosRecordSkeletonKind kind;
  @override
  Widget build(BuildContext context) {
    final tile =
        kind == PosRecordSkeletonKind.trade ||
        kind == PosRecordSkeletonKind.notification;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            kind == PosRecordSkeletonKind.promo ? 12 : 16,
          ),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: tile
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kind == PosRecordSkeletonKind.notification) ...[
                    const SkeletonBox(width: 40, height: 40, borderRadius: 12),
                    const SizedBox(width: 12),
                  ],
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 16, borderRadius: 4),
                        SizedBox(height: 10),
                        SkeletonBox(height: 12, borderRadius: 4),
                        SizedBox(height: 8),
                        SkeletonBox(width: 120, height: 12, borderRadius: 4),
                      ],
                    ),
                  ),
                  if (kind == PosRecordSkeletonKind.trade)
                    const Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: SkeletonBox(
                        width: 20,
                        height: 20,
                        borderRadius: 4,
                      ),
                    ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(child: SkeletonBox(height: 16, borderRadius: 4)),
                      SizedBox(width: 20),
                      SkeletonBox(width: 64, height: 24, borderRadius: 8),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (kind == PosRecordSkeletonKind.salesReturn)
                    const Row(
                      children: [
                        Expanded(child: _RecordValue()),
                        SizedBox(width: 24),
                        Expanded(child: _RecordValue()),
                      ],
                    )
                  else ...[
                    const SkeletonBox(width: 170, height: 12, borderRadius: 4),
                    const SizedBox(height: 10),
                    SkeletonBox(
                      height: kind == PosRecordSkeletonKind.promo ? 22 : 14,
                      width: kind == PosRecordSkeletonKind.promo ? 130 : 210,
                      borderRadius: 4,
                    ),
                  ],
                  const SizedBox(height: 14),
                  if (kind == PosRecordSkeletonKind.offlineQueue) ...[
                    const SkeletonBox(height: 12, borderRadius: 4),
                    const SizedBox(height: 10),
                    const SkeletonBox(width: 140, height: 12, borderRadius: 4),
                    const SizedBox(height: 14),
                  ],
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(child: SkeletonBox(height: 12, borderRadius: 4)),
                      SizedBox(width: 20),
                      SkeletonBox(width: 88, height: 32, borderRadius: 8),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _RecordValue extends StatelessWidget {
  const _RecordValue();
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SkeletonBox(height: 10, width: 80, borderRadius: 4),
      SizedBox(height: 8),
      SkeletonBox(height: 16, borderRadius: 4),
    ],
  );
}

class PosRecordListSkeleton extends StatelessWidget {
  const PosRecordListSkeleton({
    super.key,
    required this.kind,
    this.embedded = false,
    this.padding = const EdgeInsets.all(16),
    this.count = 5,
  });
  final PosRecordSkeletonKind kind;
  final bool embedded;
  final EdgeInsetsGeometry padding;
  final int count;
  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return Padding(
        padding: padding,
        child: Column(
          children: List.generate(
            count,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: index == count - 1 ? 0 : 12),
              child: PosRecordCardSkeleton(kind: kind),
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: padding,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (_, index) => PosRecordCardSkeleton(kind: kind),
    );
  }
}

/// Fits within the finance page's existing scroll view; detail and list differ.
class PosTradeContentSkeleton extends StatelessWidget {
  const PosTradeContentSkeleton({
    super.key,
    required this.detail,
    this.showSummary = true,
  });
  final bool detail, showSummary;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (detail) ...[
        const PosRecordCardSkeleton(kind: PosRecordSkeletonKind.salesReturn),
        const SizedBox(height: 16),
        const PosRecordCardSkeleton(kind: PosRecordSkeletonKind.trade),
        const SizedBox(height: 16),
        const SkeletonBox(height: 48, borderRadius: 8),
      ] else ...[
        const SkeletonBox(height: 56, borderRadius: 8),
        const SizedBox(height: 16),
        if (showSummary) ...[
          PosMetricGrid(
            children: List.generate(2, (_) => const PosMetricCardSkeleton()),
          ),
          const SizedBox(height: 16),
        ],
        const PosRecordListSkeleton(
          kind: PosRecordSkeletonKind.trade,
          embedded: true,
          padding: EdgeInsets.zero,
          count: 4,
        ),
      ],
    ],
  );
}
