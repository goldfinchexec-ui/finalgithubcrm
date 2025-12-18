import 'package:flutter/material.dart';

import 'package:goldfinch_crm/theme.dart';

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const EmptyState({super.key, required this.title, required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.shad), border: Border.all(color: AppColors.border, width: 1)),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 1)),
          child: Icon(icon, color: AppColors.slate900, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.slate900)),
            const SizedBox(height: 6),
            Text(message, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.slate500, height: 1.45)),
          ]),
        ),
      ]),
    );
  }
}
