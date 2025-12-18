import 'package:flutter/material.dart';

import 'package:goldfinch_crm/theme.dart';

class ShadTableHeaderRow extends StatelessWidget {
  final List<Widget> children;
  const ShadTableHeaderRow({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(color: AppColors.slate50, border: Border.all(color: AppColors.border, width: 1), borderRadius: BorderRadius.circular(AppRadius.shad)),
    child: DefaultTextStyle(style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppColors.slate500, fontWeight: FontWeight.w700), child: Row(children: children)),
  );
}

class ShadTableDataRow extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ShadTableDataRow({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final base = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: AppColors.border, width: 1), borderRadius: BorderRadius.circular(AppRadius.shad)),
      child: child,
    );

    if (onTap == null) return base;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: base,
      ),
    );
  }
}
