import 'package:flutter/material.dart';
import 'skeleton_loading.dart';

/// Form loading must retain a form layout, rather than the cashier workspace.
class PosDocumentFormSkeleton extends StatelessWidget {
  const PosDocumentFormSkeleton({
    super.key,
    this.fieldGroups = const [3, 4],
    this.maxWidth = 1000,
    this.showItems = true,
  });
  final bool showItems;
  final List<int> fieldGroups;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final fields in fieldGroups)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: 160, height: 18, borderRadius: 4),
                    for (var i = 0; i < fields; i++)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: SkeletonBox(height: 56, borderRadius: 8),
                      ),
                  ],
                ),
              ),
            if (showItems) ...[
              const SkeletonBox(width: 160, height: 18, borderRadius: 4),
              const SizedBox(height: 16),
              ...List.generate(
                2,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: SkeletonBox(height: 112, borderRadius: 12),
                ),
              ),
            ],
            const SkeletonBox(height: 48, borderRadius: 8),
          ],
        ),
      ),
    ),
  );
}

/// Matches the catalog's image cards or its horizontally scrollable data table.
class PosCatalogContentSkeleton extends StatelessWidget {
  const PosCatalogContentSkeleton({
    super.key,
    required this.isMobile,
    required this.isGridView,
    required this.gridDelegate,
  });
  final bool isMobile, isGridView;
  final SliverGridDelegate gridDelegate;
  @override
  Widget build(BuildContext context) {
    if (!isGridView) {
      return const PosDataTableSkeleton(
        columns: 7,
        minWidth: 1000,
        padding: 20,
      );
    }
    if (isMobile) {
      return ExcludeSemantics(
        child: ListView.separated(
          itemCount: 6,
          separatorBuilder: (_, index) => const SizedBox(height: 16),
          itemBuilder: (_, index) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 72, height: 72, borderRadius: 8),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(height: 16, borderRadius: 4),
                      SizedBox(height: 10),
                      SkeletonBox(width: 100, height: 12, borderRadius: 4),
                      SizedBox(height: 10),
                      SkeletonBox(width: 120, height: 12, borderRadius: 4),
                      SizedBox(height: 12),
                      SkeletonBox(width: 90, height: 16, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return ExcludeSemantics(
      child: GridView.builder(
        gridDelegate: gridDelegate,
        itemCount: 12,
        itemBuilder: (_, index) => Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SkeletonBox(height: 100, borderRadius: 0),
              Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 16, borderRadius: 4),
                    SizedBox(height: 8),
                    SkeletonBox(width: 90, height: 12, borderRadius: 4),
                    SizedBox(height: 12),
                    SkeletonBox(width: 80, height: 16, borderRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PosDataTableSkeleton extends StatelessWidget {
  const PosDataTableSkeleton({
    super.key,
    this.columns = 5,
    this.minWidth = 720,
    this.padding = 16,
  });
  final int columns;
  final double minWidth, padding;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (context, constraints) => Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: (constraints.maxWidth - padding * 2).clamp(
                minWidth,
                double.infinity,
              ),
              child: Column(
                children: [
                  for (var row = 0; row < 8; row++)
                    Container(
                      height: row == 0 ? 56 : 60,
                      decoration: BoxDecoration(
                        color: row == 0 ? Colors.grey.shade50 : null,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: List.generate(
                          columns,
                          (column) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: SkeletonBox(
                                height: row == 0 ? 12 : 14,
                                borderRadius: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class PosTableContentSkeleton extends StatelessWidget {
  const PosTableContentSkeleton({super.key, required this.isGridView});
  final bool isGridView;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (context, constraints) {
        Widget card(bool grid) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(grid ? 10 : 12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: grid
              ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SkeletonBox(width: 24, height: 24, borderRadius: 4),
                        Spacer(),
                        SkeletonBox(width: 50, height: 22, borderRadius: 8),
                      ],
                    ),
                    SizedBox(height: 16),
                    SkeletonBox(height: 16, borderRadius: 4),
                    SizedBox(height: 10),
                    SkeletonBox(width: 80, height: 12, borderRadius: 4),
                    Spacer(),
                    SkeletonBox(height: 28, borderRadius: 6),
                  ],
                )
              : const Row(
                  children: [
                    SkeletonBox(width: 40, height: 40, borderRadius: 20),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SkeletonBox(height: 16, borderRadius: 4),
                          SizedBox(height: 8),
                          SkeletonBox(width: 100, height: 12, borderRadius: 4),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    SkeletonBox(width: 64, height: 24, borderRadius: 8),
                  ],
                ),
        );
        if (isGridView) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: (constraints.maxWidth / 170).floor().clamp(2, 6),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 184,
            ),
            itemCount: 12,
            itemBuilder: (_, index) => card(true),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 8,
          separatorBuilder: (_, index) => const SizedBox(height: 8),
          itemBuilder: (_, index) => SizedBox(height: 88, child: card(false)),
        );
      },
    ),
  );
}

/// Embedded in the report's own scroll view, without a competing viewport.
class PosReportRowsSkeleton extends StatelessWidget {
  const PosReportRowsSkeleton({super.key});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 160, height: 18, borderRadius: 4),
          const SizedBox(height: 16),
          for (var row = 0; row < 6; row++)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SkeletonBox(height: 14, borderRadius: 4),
                  ),
                  SizedBox(width: 24),
                  Expanded(child: SkeletonBox(height: 14, borderRadius: 4)),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
