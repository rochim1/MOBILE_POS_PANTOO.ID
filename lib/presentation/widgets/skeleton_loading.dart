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
            Color(0xFFE8E8E8),
            Color(0xFFF5F5F5),
            Color(0xFFE8E8E8),
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
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const SkeletonBox(width: 52, height: 52, borderRadius: 14),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SkeletonBox(width: 80, height: 12),
                SizedBox(height: 10),
                SkeletonBox(width: 100, height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
              SkeletonBox(width: 60, height: 14),
              SkeletonBox(width: 80, height: 36, borderRadius: 8),
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

/// Full POS page skeleton (header cards + product grid area)
class PosPageSkeleton extends StatelessWidget {
  const PosPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary cards skeleton
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, __) => const SkeletonSummaryCard(),
          ),
        ),
        const SizedBox(height: 16),
        // Search bar skeleton
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonBox(width: 80, height: 22),
              const SizedBox(height: 12),
              const SkeletonBox(height: 48, borderRadius: 14),
              const SizedBox(height: 12),
              Row(
                children: List.generate(
                  4,
                  (_) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SkeletonBox(width: 70, height: 32, borderRadius: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Product list skeleton
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 120, height: 20),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, __) => const SkeletonProductListItem(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
