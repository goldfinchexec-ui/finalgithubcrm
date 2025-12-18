import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goldfinch_crm/models/ledger_transaction.dart';
import 'package:goldfinch_crm/theme.dart';
import 'package:goldfinch_crm/ui/components/status_badge.dart';
import 'package:goldfinch_crm/ui/components/notion_table.dart';
import 'package:goldfinch_crm/ui/components/user_capsule.dart';
import 'package:goldfinch_crm/utils/formatters.dart';
import 'package:goldfinch_crm/ui/components/action_menu.dart';
import 'package:goldfinch_crm/ui/components/confirmation_dialog.dart';
import 'package:goldfinch_crm/ui/components/success_snackbar.dart';
import 'package:goldfinch_crm/state/providers.dart';

class LedgerTable extends ConsumerWidget {
  final List<LedgerTransaction> items;
  final String emptyTitle;
  final String emptyMessage;
  final Function(LedgerTransaction)? onEdit;
  // Controls whether to show the Transaction "Type" column (Income/Expense)
  final bool showTypeColumn;
  const LedgerTable({
    super.key,
    required this.items,
    required this.emptyTitle,
    required this.emptyMessage,
    this.onEdit,
    this.showTypeColumn = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.shad), border: Border.all(color: AppColors.border, width: 1)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(emptyTitle, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.slate900)),
          const SizedBox(height: 6),
          Text(emptyMessage, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.slate500, height: 1.45)),
        ]),
      );
    }

    final auth = ref.watch(authStateProvider);
    final currentUser = auth.asData?.value;

    return NotionTable<LedgerTransaction>(
        rows: items,
        emptyTitle: emptyTitle,
        emptyMessage: emptyMessage,
        rowBackgroundColor: (r) => r.type == TransactionType.expense
            ? AppColors.roseSoft.withValues(alpha: 0.35)
            : AppColors.emeraldSoft.withValues(alpha: 0.3),
        columns: [
          NotionColumn<LedgerTransaction>(
            label: 'Title',
            flex: 3,
            sortBy: (r) => r.title.toLowerCase(),
            cellBuilder: (context, r) => Text(r.title, overflow: TextOverflow.ellipsis),
            headerIcon: Icons.text_fields_rounded,
          ),
          if (showTypeColumn)
            NotionColumn<LedgerTransaction>(
              label: 'Type',
              sortBy: (r) => _typeLabel(r.type),
              cellBuilder: (context, r) => Text(_typeLabel(r.type)),
              headerIcon: Icons.category_rounded,
            ),
          NotionColumn<LedgerTransaction>(
            label: 'Category',
            sortBy: (r) => _categoryLabel(r.category),
            cellBuilder: (context, r) => Text(_categoryLabel(r.category), overflow: TextOverflow.ellipsis),
            headerIcon: Icons.sell_rounded,
          ),
          NotionColumn<LedgerTransaction>(
            label: 'Amount',
            sortBy: (r) => r.amountPence,
            cellBuilder: (context, r) => Text(AppFormatters.moneyFromPence(r.amountPence)),
            headerAlign: TextAlign.left,
            headerIcon: Icons.payments_rounded,
          ),
          NotionColumn<LedgerTransaction>(
            label: 'Status',
            sortBy: (r) => r.status.index,
            cellBuilder: (context, r) => Align(alignment: Alignment.centerLeft, child: StatusBadge(status: r.status)),
            width: 140,
            headerIcon: Icons.brightness_low_rounded,
          ),
          NotionColumn<LedgerTransaction>(
            label: 'Date',
            sortBy: (r) => r.startDate.millisecondsSinceEpoch,
            cellBuilder: (context, r) => Text(_dateRange(r)),
            width: 180,
            headerIcon: Icons.calendar_today_rounded,
          ),
          NotionColumn<LedgerTransaction>(
            label: 'Repeats',
            sortBy: (r) => _frequencyLabel(r.frequency).toLowerCase(),
            cellBuilder: (context, r) => _repeatPill(context, r.frequency),
            width: 120,
            headerIcon: Icons.autorenew_rounded,
          ),
          NotionColumn<LedgerTransaction>(
            label: 'Created By',
            sortBy: (r) => _createdByLabel(r, currentUser),
            cellBuilder: (context, r) => UserCapsule(
              name: _createdByLabel(r, currentUser),
              size: 24,
            ),
            width: 160,
            headerIcon: Icons.person_outline_rounded,
          ),
          NotionColumn<LedgerTransaction>(
            label: 'Actions',
            cellBuilder: (context, r) => ActionMenu(
              onEdit: onEdit != null ? () => onEdit!(r) : null,
              onDelete: () => _handleDelete(context, ref, r),
            ),
            width: 80,
            headerIcon: Icons.more_horiz_rounded,
            sortable: false,
            resizable: false,
          ),
        ],
      );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, LedgerTransaction tx) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete ${tx.type == TransactionType.income ? 'Income' : 'Expense'}',
      message: 'Are you sure you want to delete this record? This action cannot be undone.',
    );

    if (confirmed && context.mounted) {
      await ref.read(transactionsProvider.notifier).delete(tx.id);
      if (context.mounted) {
        SuccessSnackbar.show(context, 'Record deleted successfully');
      }
    }
  }

  String _dateRange(LedgerTransaction t) {
    final start = AppFormatters.date.format(t.startDate);
    if (t.endDate == null) return start;
    final end = AppFormatters.date.format(t.endDate!);
    return '$start → $end';
  }

  String _typeLabel(TransactionType t) => switch (t) { TransactionType.income => 'Income', TransactionType.expense => 'Expense' };

  String _categoryLabel(TransactionCategory c) => switch (c) {
        TransactionCategory.clientInvoice => 'Client Invoice',
        TransactionCategory.driverPayout => 'Driver Payout',
        TransactionCategory.generalExpense => 'General Expense',
        TransactionCategory.generalIncome => 'General Income',
      };

  String _frequencyLabel(TransactionFrequency? f) => switch (f) {
        TransactionFrequency.monthly => 'Monthly',
        TransactionFrequency.weekly => 'Weekly',
        _ => 'One-time',
      };

  Widget _repeatPill(BuildContext context, TransactionFrequency? f) {
    final label = _frequencyLabel(f);
    final isMonthly = f == TransactionFrequency.monthly;
    final isWeekly = f == TransactionFrequency.weekly;
    final icon = isMonthly
        ? Icons.repeat_rounded
        : (isWeekly ? Icons.calendar_view_week_rounded : Icons.radio_button_unchecked_rounded);
    final bg = AppColors.slate100;
    final fg = AppColors.slate600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: fg),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  String _createdByLabel(LedgerTransaction r, dynamic currentUser) {
    final stored = r.createdByUserName?.trim();
    if (stored != null && stored.isNotEmpty) return stored;
    final uid = (currentUser != null) ? (currentUser.uid as String?) : null;
    if (uid != null && uid.isNotEmpty && r.createdByUserId == uid) {
      final dn = (currentUser.displayName as String?)?.trim();
      if (dn != null && dn.isNotEmpty) return dn;
      final email = currentUser.email as String?;
      if (email != null && email.contains('@')) return email.split('@').first;
    }
    return 'Staff';
  }
}
