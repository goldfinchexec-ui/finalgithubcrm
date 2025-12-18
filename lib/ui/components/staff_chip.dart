import 'package:flutter/material.dart';

import 'package:goldfinch_crm/models/user_model.dart';
import 'package:goldfinch_crm/theme.dart';

class StaffChip extends StatelessWidget {
  final AppUser user;
  const StaffChip({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final initials = user.name.trim().isEmpty
        ? 'S'
        : user.name.trim().split(RegExp(r'\s+')).take(2).map((p) => p.isEmpty ? '' : p[0]).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border, width: 1)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.slate900, borderRadius: BorderRadius.circular(999)),
          child: Text(initials, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Text(user.name, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.slate900, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
