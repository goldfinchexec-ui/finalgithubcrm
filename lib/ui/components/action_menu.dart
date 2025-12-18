import 'package:flutter/material.dart';
import 'package:goldfinch_crm/theme.dart';

/// Compact 3‑dot action menu that opens a small anchored context menu.
///
/// No hover or pointer-tracking is used. Interactions are click/tap only.
class ActionMenu extends StatefulWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ActionMenu({
    super.key,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ActionMenu> createState() => _ActionMenuState();
}

class _ActionMenuState extends State<ActionMenu> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _entry;

  void _hideMenu({VoidCallback? afterClose}) {
    if (_entry != null) {
      _entry!.remove();
      _entry = null;
    }
    // Run the action after closing to avoid overlay conflicts
    if (afterClose != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => afterClose());
    }
  }

  void _showMenu() {
    if (_entry != null) return; // already open
    final theme = Theme.of(context);
    _entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Tapping outside closes the menu
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _hideMenu(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 36), // below the button
              child: _ContextMenu(
                onEdit: widget.onEdit == null
                    ? null
                    : () => _hideMenu(afterClose: widget.onEdit),
                onDelete: widget.onDelete == null
                    ? null
                    : () => _hideMenu(afterClose: widget.onDelete),
                theme: theme,
              ),
            ),
          ],
        );
      },
    );

    final overlay = Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;
    overlay.insert(_entry!);
  }

  @override
  void dispose() {
    _hideMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        width: 40,
        height: 40,
        child: IconButton(
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.slate700),
          onPressed: () {
            // Defer to next frame to avoid web mouse tracker assertion when
            // opening overlays during the same pointer event.
            FocusScope.of(context).unfocus();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showMenu();
            });
          },
        ),
      ),
    );
  }
}

class _ContextMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ThemeData theme;

  const _ContextMenu({
    required this.onEdit,
    required this.onDelete,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final surface = theme.colorScheme.surface;
    final border = theme.dividerColor.withValues(alpha: 0.12);

    return Material(
      color: Colors.transparent,
      child: Container
        (
        constraints: const BoxConstraints(minWidth: 180),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppRadius.shad),
          border: Border.all(color: border, width: 0.8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (onEdit != null)
              _MenuItem(
                icon: Icons.edit_rounded,
                label: 'Edit',
                iconColor: AppColors.slate700,
                onTap: onEdit!,
              ),
            if (onDelete != null)
              _MenuItem(
                icon: Icons.delete_rounded,
                label: 'Delete',
                iconColor: AppColors.danger,
                labelStyle: const TextStyle(color: AppColors.danger),
                onTap: onDelete!,
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final TextStyle? labelStyle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
    this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: labelStyle ?? const TextStyle(color: AppColors.slate900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
