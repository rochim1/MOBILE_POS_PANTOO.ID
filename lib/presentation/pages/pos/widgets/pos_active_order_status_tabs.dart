import 'package:flutter/material.dart';

import '../../../../core/_core.dart';

class PosActiveOrderStatusTabs extends StatelessWidget {
  const PosActiveOrderStatusTabs({
    super.key,
    required this.selectedStatus,
    required this.counts,
    required this.onSelected,
  });

  final String selectedStatus;
  final Map<String, int> counts;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const statuses = <(String, String)>[
      ('', 'Semua'),
      ('Baru', 'Baru'),
      ('Diproses', 'Diproses'),
      ('Siap', 'Siap'),
      ('Disajikan', 'Diserahkan'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final (status, label) in statuses)
            ChoiceChip(
              key: ValueKey('order-status-${status.isEmpty ? 'all' : status}'),
              label: Text('$label ${counts[status] ?? 0}'),
              selected: selectedStatus == status,
              onSelected: (_) => onSelected(status),
              materialTapTargetSize: MaterialTapTargetSize.padded,
              selectedColor: AppColors.primaryLight,
              labelStyle: TextStyle(
                color: selectedStatus == status
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: selectedStatus == status
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
