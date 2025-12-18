import 'package:flutter/material.dart';

import 'package:goldfinch_crm/theme.dart';

class ShadDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  // When compact, paddings are reduced to match small button height.
  final bool compact;
  // When true, the top label is hidden (useful for tight header toolbars).
  final bool hideLabel;

  const ShadDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.compact = false,
    this.hideLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final container = Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.shad),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 2 : 6),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, size: 18),
          isDense: compact,
          style: theme.textTheme.bodyMedium,
        ),
      ),
    );

    if (hideLabel) return container;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: AppColors.slate500, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        container,
      ],
    );
  }
}
