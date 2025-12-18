import 'package:flutter/material.dart';
import 'package:goldfinch_crm/theme.dart';

/// A compact user display widget showing avatar + name
class UserCapsule extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double size;

  const UserCapsule({
    super.key,
    required this.name,
    this.avatarUrl,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Text(
                    initials,
                    style: TextStyle(
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate700,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
