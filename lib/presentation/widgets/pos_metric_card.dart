import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Shared visual language for POS statistics and period comparisons.
class PosMetricCard extends StatelessWidget {
  const PosMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.description = '',
    this.isLoading = false,
    this.growth,
    this.compact = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final String description;
  final double? growth;
  final bool isLoading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final change = growth;
    final hasChange = change != null && change.isFinite;
    final trendColor = !hasChange || change == 0
        ? const Color(0xFF667085)
        : change > 0
        ? const Color(0xFF087F75)
        : const Color(0xFFB42318);
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    )..maximumFractionDigits = 1;

    return Container(
      constraints: BoxConstraints(minHeight: compact ? 92 : 180),
      padding: EdgeInsets.all(compact ? 12 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475467),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, size: 18, color: const Color(0xFF98A2B3)),
            ],
          ),
          SizedBox(height: compact ? 8 : 16),
          // Preserve the full amount on narrow phones instead of truncating it.
          if (isLoading)
            const _MetricPlaceholder(width: 100, height: 26)
          else
            Semantics(
              label: '$title, $value',
              excludeSemantics: true,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: compact ? 22 : 26,
                    height: 1.2,
                    letterSpacing: -.6,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF182230),
                  ),
                ),
              ),
            ),
          if (description.isNotEmpty || hasChange) const SizedBox(height: 14),
          if (hasChange) ...[
            Row(
              children: [
                Icon(
                  change == 0
                      ? Icons.remove_rounded
                      : change > 0
                      ? Icons.north_east_rounded
                      : Icons.south_east_rounded,
                  size: 14,
                  color: trendColor,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${change > 0 ? '+' : ''}${number.format(change)}%',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: trendColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
          ],
          if (description.isNotEmpty)
            Text(
              description,
              style: const TextStyle(
                fontSize: 11,
                height: 1.5,
                color: Color(0xFF667085),
              ),
            ),
        ],
      ),
    );
  }
}

/// All summary sections use the same breakpoints and gutters.
class PosMetricGrid extends StatelessWidget {
  const PosMetricGrid({
    super.key,
    required this.children,
    this.compact = false,
  });
  final List<Widget> children;
  final bool compact;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (children.isEmpty) return const SizedBox.shrink();
      final availableColumns = constraints.maxWidth >= (compact ? 800 : 1000)
          ? 4
          : constraints.maxWidth >= (compact ? 280 : 340)
          ? 2
          : 1;
      final columns = children.length < availableColumns
          ? children.length
          : availableColumns;
      const spacing = 12.0;
      final width = (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}

class PosMetricCardSkeleton extends StatelessWidget {
  const PosMetricCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 180),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE4E7EC)),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _MetricPlaceholder(height: 12)),
            SizedBox(width: 16),
            _MetricPlaceholder(width: 18, height: 18),
          ],
        ),
        SizedBox(height: 16),
        _MetricPlaceholder(width: 100, height: 26),
        SizedBox(height: 14),
        _MetricPlaceholder(width: 80, height: 12),
      ],
    ),
  );
}

class _MetricPlaceholder extends StatelessWidget {
  const _MetricPlaceholder({this.width, required this.height});
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFFEEF0F3),
      borderRadius: BorderRadius.circular(4),
    ),
  );
}
