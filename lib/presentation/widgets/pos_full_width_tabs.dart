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
  final double height;

  const PosFullWidthTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.height = 58,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
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
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _TabSurface extends StatelessWidget {
  final PosFullWidthTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _TabSurface({
    required this.tab,
    required this.selected,
    required this.onTap,
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
                size: 20,
                color: selected ? AppColors.primary : Colors.black54,
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
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
  final double height;

  const PosFullWidthTabBar({super.key, required this.tabs, this.height = 58});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
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
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        tabs: tabs
            .map(
              (tab) => Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tab.icon, size: 20),
                    const SizedBox(width: 9),
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
