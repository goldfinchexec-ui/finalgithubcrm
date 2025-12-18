import 'package:flutter/material.dart';

import 'package:goldfinch_crm/theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accent;

  const StatCard({super.key, required this.label, required this.value, required this.icon, this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipBg = (accent ?? AppColors.slate900).withValues(alpha: 0.07);
    final chipFg = AppColors.slate900;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.shad),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 1)),
          child: Icon(icon, color: chipFg, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.slate500, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.slate900, letterSpacing: -0.3)),
          ]),
        ),
      ]),
    );
  }
}
