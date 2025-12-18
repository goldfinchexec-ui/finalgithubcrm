import 'package:flutter/material.dart';

import 'package:goldfinch_crm/theme.dart';

enum ShadButtonVariant { primary, secondary, ghost, danger }

class ShadButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ShadButtonVariant variant;
  final bool compact;

  const ShadButton({super.key, required this.label, required this.onPressed, this.icon, this.variant = ShadButtonVariant.primary, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onPressed == null;

    final bg = switch (variant) {
      ShadButtonVariant.primary => AppColors.slate900,
      ShadButtonVariant.secondary => theme.colorScheme.surface,
      ShadButtonVariant.ghost => Colors.transparent,
      ShadButtonVariant.danger => AppColors.danger,
    };
    final fg = switch (variant) {
      ShadButtonVariant.primary => Colors.white,
      ShadButtonVariant.secondary => AppColors.slate900,
      ShadButtonVariant.ghost => AppColors.slate900,
      ShadButtonVariant.danger => Colors.white,
    };
    final border = switch (variant) {
      ShadButtonVariant.primary => BorderSide.none,
      ShadButtonVariant.secondary => const BorderSide(color: AppColors.border, width: 1),
      ShadButtonVariant.ghost => const BorderSide(color: Colors.transparent, width: 1),
      ShadButtonVariant.danger => BorderSide.none,
    };

    final pad = compact ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10) : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 140),
      opacity: disabled ? 0.5 : 1,
      child: TextButton(
        onPressed: onPressed,
        style: ButtonStyle(
          padding: WidgetStatePropertyAll(pad),
          // No hover-based styling. Background is static for accessibility and
          // to avoid any hover interactions on web.
          backgroundColor: WidgetStatePropertyAll(variant == ShadButtonVariant.ghost ? Colors.transparent : bg),
          foregroundColor: WidgetStatePropertyAll(fg),
          overlayColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.08)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.shad), side: border)),
          textStyle: WidgetStatePropertyAll(theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 10),
          ],
          Text(label),
        ]),
      ),
    );
  }
}
