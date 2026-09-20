import 'package:flutter/material.dart';

import '../../core/_core.dart';

class PosFullWidthTab {
  final IconData icon;
  final String label;

  const PosFullWidthTab({required this.icon, required this.label});
}

class PosFullWidthTabs extends StatelessWidget {
  final List<PosFullWidthTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final double? height;

  const PosFullWidthTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return SizedBox(
      height: height ?? (compact ? 48 : 58),
      child: Material(
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < tabs.length; index++) ...[
              if (index > 0) const VerticalDivider(width: 1, thickness: 1),
              Expanded(
                child: _TabSurface(
                  tab: tabs[index],
                  selected: selectedIndex == index,
                  onTap: () => onSelected(index),
                  compact: compact,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabSurface extends StatelessWidget {
  final PosFullWidthTab tab;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  const _TabSurface({
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.primary.withValues(alpha: .09) : Colors.white,
    child: InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: compact ? 18 : 20,
                color: selected ? AppColors.primary : Colors.black54,
              ),
              SizedBox(width: compact ? 7 : 9),
              Flexible(
                child: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 13 : null,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? AppColors.primary : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class PosFullWidthTabBar extends StatelessWidget {
  final List<PosFullWidthTab> tabs;
  final double? height;

  const PosFullWidthTabBar({super.key, required this.tabs, this.height});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return SizedBox(
      height: height ?? (compact ? 48 : 58),
      child: Material(
        color: Colors.white,
        child: TabBar(
          indicatorSize: TabBarIndicatorSize.tab,
          dividerHeight: 1,
          indicator: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .09),
            border: const Border(
              bottom: BorderSide(color: AppColors.primary, width: 3),
            ),
          ),
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.black54,
          labelStyle: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: compact ? 13 : null,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: compact ? 13 : null,
          ),
          tabs: tabs
              .map(
                (tab) => Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(tab.icon, size: compact ? 18 : 20),
                      SizedBox(width: compact ? 7 : 9),
                      Flexible(
                        child: Text(
                          tab.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
