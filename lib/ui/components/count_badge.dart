import 'package:flutter/material.dart';
import 'package:goldfinch_crm/theme.dart';

/// A small badge showing a count (e.g., invoice count)
class CountBadge extends StatelessWidget {
  final int count;
  final Color? backgroundColor;
  final Color? textColor;

  const CountBadge({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (backgroundColor ?? AppColors.primary).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Text(
        count.toString(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: textColor ?? AppColors.primary,
            ),
      ),
    );
  }
}
