import 'package:flutter/material.dart';

import 'package:goldfinch_crm/theme.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  const PageHeader({super.key, required this.title, this.subtitle, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: AppColors.slate900, letterSpacing: -0.3)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.slate500, height: 1.45)),
            ],
          ]),
        ),
        const SizedBox(width: 12),
        Wrap(spacing: 10, runSpacing: 10, children: actions),
      ]),
    );
  }
}
