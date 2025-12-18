import 'package:flutter/material.dart';

import 'package:goldfinch_crm/theme.dart';

class ShadTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? minLines;
  final bool autofocus;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  // Compact reduces height to match small buttons in header toolbars.
  final bool compact;
  // Hides the label above the input, useful for tight header rows.
  final bool hideLabel;
  // Optional leading icon inside the field (e.g., search)
  final IconData? prefixIcon;
  // Shows an interactive clear (X) button when there is text
  final bool showClearButton;

  const ShadTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.autofocus = false,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.compact = false,
    this.hideLabel = false,
    this.prefixIcon,
    this.showClearButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildField() {
      return ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final hasText = value.text.isNotEmpty;
          return TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            minLines: minLines,
            autofocus: autofocus,
            obscureText: obscureText,
            validator: validator,
            onChanged: onChanged,
            style: compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: theme.colorScheme.surface,
              isDense: compact,
              // Slightly larger vertical padding to visually align with compact buttons
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: compact ? 10 : 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.shad),
                borderSide: const BorderSide(color: AppColors.border, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.shad),
                borderSide: const BorderSide(color: AppColors.border, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.shad),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 1),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.shad),
                borderSide: const BorderSide(color: AppColors.danger, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.shad),
                borderSide: const BorderSide(color: AppColors.danger, width: 2),
              ),
              // Icons
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: AppColors.slate500) : null,
              prefixIconConstraints: prefixIcon != null
                  ? const BoxConstraints(minWidth: 32, minHeight: 32)
                  : null,
              suffixIcon: (showClearButton && hasText)
                  ? IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.slate500),
                      onPressed: () {
                        controller.clear();
                        // Propagate empty change so external filters update immediately
                        onChanged?.call('');
                      },
                      splashRadius: 18,
                    )
                  : null,
              suffixIconConstraints: showClearButton
                  ? const BoxConstraints(minWidth: 32, minHeight: 32)
                  : null,
            ),
          );
        },
      );
    }

    final field = buildField();

    if (hideLabel) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: AppColors.slate500, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}
