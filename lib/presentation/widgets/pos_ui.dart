import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';

class PosAppBarTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool online;

  const PosAppBarTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.online = true,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      const SizedBox(height: 2),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: online ? const Color(0xFF4ADE80) : AppColors.warning,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              subtitle ?? (online ? 'Status: Online' : 'Status: Offline'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class PosEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PosEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 54, color: AppColors.primary),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.grey.shade600, height: 1.45),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class PosStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const PosStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.grey.shade200),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A0F172A),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppColors.grey.shade600)),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class PosSearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final VoidCallback? onFilter;

  const PosSearchField({
    super.key,
    required this.hint,
    this.onChanged,
    this.controller,
    this.onFilter,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: const Icon(Icons.search_rounded),
          ),
        ),
      ),
      if (onFilter != null) ...[
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: onFilter,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Filter'),
        ),
      ],
    ],
  );
}

class PosSkeletonList extends StatelessWidget {
  final int count;
  const PosSkeletonList({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: count,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (_, __) => Container(
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 13, width: 160, color: AppColors.grey.shade100),
          const SizedBox(height: 12),
          Container(height: 11, width: 240, color: AppColors.grey.shade100),
          const SizedBox(height: 8),
          Container(height: 11, width: 100, color: AppColors.grey.shade100),
        ],
      ),
    ),
  );
}
