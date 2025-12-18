import 'package:flutter/material.dart';

import 'package:goldfinch_crm/models/ledger_transaction.dart';
import 'package:goldfinch_crm/theme.dart';

class StatusBadge extends StatelessWidget {
  final TransactionStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      TransactionStatus.paid => 'Paid',
      TransactionStatus.pending => 'Pending',
      TransactionStatus.received => 'Received',
      TransactionStatus.outstanding => 'Outstanding',
    };

    final bg = switch (status) {
      TransactionStatus.paid => AppColors.slate100,
      TransactionStatus.pending => AppColors.amberSoft,
      TransactionStatus.received => AppColors.emeraldSoft,
      TransactionStatus.outstanding => AppColors.roseSoft,
    };

    final fg = AppColors.slate900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.border, width: 1)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}
