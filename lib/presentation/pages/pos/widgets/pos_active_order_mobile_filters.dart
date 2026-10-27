import 'package:flutter/material.dart';

import '../../../../core/_core.dart';

/// Filter ringkas untuk antrean pesanan di layar sempit.
class PosActiveOrderMobileFilters extends StatelessWidget {
  const PosActiveOrderMobileFilters({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.onOpenFilters,
    required this.activeLabels,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onOpenFilters;
  final List<String> activeLabels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Cari order / pelanggan',
                    prefixIcon: Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 44,
              height: 44,
              child: Tooltip(
                message: 'Filter pesanan aktif',
                child: OutlinedButton(
                  key: const ValueKey('active-order-mobile-filter'),
                  onPressed: onOpenFilters,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Badge.count(
                    count: activeLabels.length,
                    isLabelVisible: activeLabels.isNotEmpty,
                    child: const Icon(Icons.tune_rounded, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (activeLabels.isNotEmpty) ...[
          const SizedBox(height: 7),
          Text(
            'Filter aktif: ${activeLabels.join(' · ')}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
