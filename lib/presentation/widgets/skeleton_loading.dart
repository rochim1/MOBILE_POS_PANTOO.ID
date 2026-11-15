import 'pos_metric_card.dart';
import 'package:flutter/material.dart';

/// A shimmering skeleton box used as a placeholder while content loads.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

/// Placeholder shared by the kitchen board and active-order kanban so loading
/// keeps the final three-column geometry instead of replacing it with a spinner.
class PosOrderBoardSkeleton extends StatelessWidget {
  final int columns;
  final int cardsPerColumn;

  const PosOrderBoardSkeleton({
    super.key,
    this.columns = 3,
    this.cardsPerColumn = 2,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final boardWidth = constraints.maxWidth < 840
          ? 840.0
          : constraints.maxWidth;
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: boardWidth,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                columns,
                (_) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE1E5E9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SkeletonBox(height: 38, borderRadius: 8),
                          const SizedBox(height: 10),
                          ...List.generate(
                            cardsPerColumn,
                            (_) => const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: PosOrderTicketSkeleton(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class PosOrderTicketSkeleton extends StatelessWidget {
  const PosOrderTicketSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SkeletonBox(height: 16, borderRadius: 4)),
            SizedBox(width: 12),
            SkeletonBox(width: 58, height: 22, borderRadius: 8),
          ],
        ),
        SizedBox(height: 14),
        SkeletonBox(width: 140, height: 12, borderRadius: 4),
        SizedBox(height: 9),
        SkeletonBox(height: 12, borderRadius: 4),
        SizedBox(height: 7),
        SkeletonBox(width: 180, height: 12, borderRadius: 4),
        SizedBox(height: 14),
        SkeletonBox(height: 34, borderRadius: 8),
      ],
    ),
  );
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + _animation.value, 0),
          end: Alignment(_animation.value, 0),
          colors: const [
            Color(0xFFE8EBEE),
            Color(0xFFF3F5F6),
            Color(0xFFE8EBEE),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for a single summary card
class SkeletonSummaryCard extends StatelessWidget {
  const SkeletonSummaryCard({super.key});

  @override
  Widget build(BuildContext context) =>
      const SizedBox(width: 260, child: PosMetricCardSkeleton());
}

/// Skeleton for a product card in grid view
class SkeletonProductCard extends StatelessWidget {
  const SkeletonProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(child: SkeletonBox(height: 16)),
              SizedBox(width: 12),
              SkeletonBox(width: 60, height: 24, borderRadius: 12),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonBox(width: 100, height: 18),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Flexible(child: SkeletonBox(width: 60, height: 14)),
              SizedBox(width: 8),
              Flexible(
                child: SkeletonBox(width: 80, height: 36, borderRadius: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton for a product list item
class SkeletonProductListItem extends StatelessWidget {
  const SkeletonProductListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 150, height: 16),
                SizedBox(height: 6),
                SkeletonBox(width: 80, height: 12),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              SkeletonBox(width: 90, height: 16),
              SizedBox(height: 6),
              SkeletonBox(width: 60, height: 12),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cashier placeholders follow the same mobile tabs and wide split layout.
class PosPageSkeleton extends StatelessWidget {
  const PosPageSkeleton({super.key, this.isGridView = true});
  final bool isGridView;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 900;
    final catalog = Column(
      children: [
        Padding(
          padding: EdgeInsets.all(mobile ? 10 : 16),
          child: Row(
            children: [
              Expanded(
                child: SkeletonBox(height: mobile ? 40 : 48, borderRadius: 8),
              ),
              ...List.generate(
                mobile ? 3 : 2,
                (_) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SkeletonBox(
                    width: mobile ? 40 : 48,
                    height: mobile ? 40 : 48,
                    borderRadius: 8,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              PosCashierProductSliverSkeleton(
                isMobile: mobile,
                isGridView: isGridView,
              ),
            ],
          ),
        ),
      ],
    );
    return ExcludeSemantics(
      child: mobile
          ? Column(
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).width < 600 ? 44 : 52,
                  child: const Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: SkeletonBox(
                            width: 110,
                            height: 16,
                            borderRadius: 4,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: SkeletonBox(
                            width: 85,
                            height: 16,
                            borderRadius: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: catalog),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 88,
                  child: ListView.builder(
                    itemCount: 7,
                    itemBuilder: (_, index) => const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: SkeletonBox(height: 40, borderRadius: 8),
                    ),
                  ),
                ),
                Expanded(flex: 5, child: catalog),
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: SkeletonBox(height: 40, borderRadius: 8),
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: 3,
                            itemBuilder: (_, index) => const Padding(
                              padding: EdgeInsets.all(16),
                              child: SkeletonBox(height: 56, borderRadius: 8),
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: SkeletonBox(height: 48, borderRadius: 8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Shared by the full refresh and catalog requests to keep grid/list geometry.
class PosCashierProductSliverSkeleton extends StatelessWidget {
  const PosCashierProductSliverSkeleton({
    super.key,
    required this.isMobile,
    required this.isGridView,
  });
  final bool isMobile, isGridView;

  @override
  Widget build(BuildContext context) {
    if (!isGridView) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, index) => Container(
            height: isMobile ? 82 : 72,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 20,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 160, height: 14, borderRadius: 4),
                      SizedBox(height: 8),
                      SkeletonBox(width: 100, height: 10, borderRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(child: SkeletonBox(height: 14, borderRadius: 4)),
                if (isMobile)
                  const Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: SkeletonBox(width: 36, height: 36, borderRadius: 8),
                  ),
              ],
            ),
          ),
          childCount: 8,
        ),
      );
    }
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = isMobile
            ? (constraints.crossAxisExtent < 280 ? 2 : 3)
            : (constraints.crossAxisExtent / 180).floor().clamp(3, 6);
        return SliverPadding(
          padding: EdgeInsets.all(isMobile ? 8 : 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: isMobile ? 8 : 16,
              crossAxisSpacing: isMobile ? 8 : 16,
              mainAxisExtent: isMobile ? (columns == 2 ? 144 : 118) : null,
              childAspectRatio: isMobile ? 1 : .8,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, index) => Container(
                padding: EdgeInsets.all(isMobile ? 10 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14, borderRadius: 4),
                    SizedBox(height: 8),
                    SkeletonBox(width: 60, height: 10, borderRadius: 4),
                    Spacer(),
                    SkeletonBox(width: 80, height: 16, borderRadius: 4),
                  ],
                ),
              ),
              childCount: columns * 4,
            ),
          ),
        );
      },
    );
  }
}

/// Login skeleton
class LoginSkeleton extends StatelessWidget {
  const LoginSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SkeletonBox(width: 80, height: 80, borderRadius: 20),
            SizedBox(height: 24),
            SkeletonBox(width: 200, height: 24),
            SizedBox(height: 32),
            SkeletonBox(height: 48, borderRadius: 14),
            SizedBox(height: 16),
            SkeletonBox(height: 48, borderRadius: 14),
            SizedBox(height: 24),
            SkeletonBox(height: 48, borderRadius: 14),
          ],
        ),
      ),
    );
  }
}
