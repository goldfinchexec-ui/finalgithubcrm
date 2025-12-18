import 'package:flutter/material.dart';

import 'package:goldfinch_crm/theme.dart';

class ShadCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const ShadCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpacing.lg), this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = Border.all(color: AppColors.border, width: 1);

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: padding,
      decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.shad), border: border),
      child: child,
    );

    if (onTap == null) return content;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 120),
        child: content,
      ),
    );
  }
}
