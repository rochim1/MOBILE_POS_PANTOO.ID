import 'package:flutter/material.dart';

import '../../core/_core.dart';

class PosCategoryItem<T> {
  final T value;
  final IconData icon;
  final String label;
  final String? group;

  const PosCategoryItem({
    required this.value,
    required this.icon,
    required this.label,
    this.group,
  });
}

class PosCategorySidebar<T> extends StatefulWidget {
  final String title;
  final List<PosCategoryItem<T>> items;
  final T selected;
  final ValueChanged<T> onSelected;
  final String? footer;
  final double expandedWidth;
  final double collapsedWidth;

  const PosCategorySidebar({
    super.key,
    required this.title,
    required this.items,
    required this.selected,
    required this.onSelected,
    this.footer,
    this.expandedWidth = 220,
    this.collapsedWidth = 68,
  });

  @override
  State<PosCategorySidebar<T>> createState() => _PosCategorySidebarState<T>();
}

class _PosCategorySidebarState<T> extends State<PosCategorySidebar<T>> {
  bool _collapsed = false;
  bool _showExpandedContent = true;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeInOut,
    width: _collapsed ? widget.collapsedWidth : widget.expandedWidth,
    child: Material(
      color: Colors.white,
      elevation: 1,
      child: ListView(
        children: [
          SizedBox(
            height: 58,
            child: !_showExpandedContent
                ? Center(
                    child: IconButton(
                      tooltip: 'Perluas ${widget.title.toLowerCase()}',
                      onPressed: _toggle,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.only(left: 18, right: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Ciutkan menjadi ikon',
                          onPressed: _toggle,
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                      ],
                    ),
                  ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...widget.items.indexed.expand((entry) {
            final index = entry.$1;
            final item = entry.$2;
            final showGroup =
                _showExpandedContent &&
                item.group != null &&
                (index == 0 || widget.items[index - 1].group != item.group);
            return [
              if (showGroup)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 12, 5),
                  child: Text(
                    item.group!.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Tooltip(
                  message: !_showExpandedContent ? item.label : '',
                  child: Material(
                    color: widget.selected == item.value
                        ? AppColors.primary.withValues(alpha: .09)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => widget.onSelected(item.value),
                      child: SizedBox(
                        height: 48,
                        child: Row(
                          mainAxisAlignment: !_showExpandedContent
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            if (_showExpandedContent) const SizedBox(width: 16),
                            Icon(
                              item.icon,
                              size: 20,
                              color: widget.selected == item.value
                                  ? AppColors.primary
                                  : null,
                            ),
                            if (_showExpandedContent) ...[
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  item.label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: widget.selected == item.value
                                        ? AppColors.primary
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ];
          }),
          if (_showExpandedContent && widget.footer != null)
            Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                widget.footer!,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
        ],
      ),
    ),
  );

  Future<void> _toggle() async {
    if (_collapsed) {
      setState(() => _collapsed = false);
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (mounted && !_collapsed) {
        setState(() => _showExpandedContent = true);
      }
      return;
    }
    setState(() {
      _showExpandedContent = false;
      _collapsed = true;
    });
  }
}

class PosCategoryDropdown<T> extends StatelessWidget {
  final String label;
  final List<PosCategoryItem<T>> items;
  final T selected;
  final ValueChanged<T> onSelected;

  const PosCategoryDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: selected,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.list_alt_outlined),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    items: items
        .map(
          (item) => DropdownMenuItem<T>(
            value: item.value,
            child: Row(
              children: [
                Icon(item.icon, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList(),
    onChanged: (value) {
      if (value != null) onSelected(value);
    },
  );
}
