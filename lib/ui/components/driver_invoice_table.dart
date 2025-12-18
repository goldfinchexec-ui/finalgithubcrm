import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goldfinch_crm/models/ledger_transaction.dart';
import 'package:goldfinch_crm/models/driver.dart';
import 'package:goldfinch_crm/models/user_model.dart';
import 'package:goldfinch_crm/state/providers.dart';
import 'package:goldfinch_crm/theme.dart';
import 'package:goldfinch_crm/ui/components/status_badge.dart';
import 'package:goldfinch_crm/ui/components/notion_table.dart';
import 'package:goldfinch_crm/ui/components/user_capsule.dart';
import 'package:goldfinch_crm/ui/components/confirmation_dialog.dart';
import 'package:goldfinch_crm/ui/components/success_snackbar.dart';
import 'package:goldfinch_crm/ui/components/action_menu.dart';
import 'package:goldfinch_crm/utils/formatters.dart';

class DriverInvoiceTable extends ConsumerWidget {
  final List<LedgerTransaction> items;
  final Function(LedgerTransaction) onEdit;
  final String emptyTitle;
  final String emptyMessage;

  const DriverInvoiceTable({
    super.key,
    required this.items,
    required this.onEdit,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.shad),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              emptyTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.slate500,
                    height: 1.45,
                  ),
            ),
          ],
        ),
      );
    }

    final driversAsync = ref.watch(driversProvider);
    final auth = ref.watch(authStateProvider);
    final currentUser = auth.asData?.value;

    return driversAsync.when(
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Error loading drivers: $e'),
      data: (drivers) => NotionTable<LedgerTransaction>(
          rows: items,
          emptyTitle: emptyTitle,
          emptyMessage: emptyMessage,
          // Driver payouts are expenses → soft red tint
          rowBackgroundColor: (r) => AppColors.roseSoft.withValues(alpha: 0.35),
          columns: [
            NotionColumn<LedgerTransaction>(
              label: 'Driver Name',
              flex: 2,
              sortBy: (r) => _getDriverName(r, drivers).toLowerCase(),
              cellBuilder: (context, r) => Text(
                _getDriverName(r, drivers),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              headerIcon: Icons.person_rounded,
            ),
            NotionColumn<LedgerTransaction>(
              label: 'Files',
              headerIcon: Icons.attach_file,
              width: 64,
              sortable: false,
              resizable: false,
              cellBuilder: (context, r) => r.attachments.isNotEmpty
                  ? const Icon(Icons.attach_file, size: 16, color: AppColors.slate500)
                  : const SizedBox.shrink(),
            ),
            NotionColumn<LedgerTransaction>(
              label: 'Amount',
              sortBy: (r) => r.amountPence,
              cellBuilder: (context, r) => Text(
                AppFormatters.moneyFromPence(r.amountPence),
              ),
              headerIcon: Icons.payments_rounded,
            ),
            NotionColumn<LedgerTransaction>(
              label: 'Status',
              sortBy: (r) => r.status.index,
              cellBuilder: (context, r) => Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(status: r.status),
              ),
              width: 140,
              headerIcon: Icons.brightness_low_rounded,
            ),
            NotionColumn<LedgerTransaction>(
              label: 'Date',
              sortBy: (r) => r.startDate.millisecondsSinceEpoch,
              cellBuilder: (context, r) => Text(_dateRange(r)),
              width: 200,
              headerIcon: Icons.calendar_today_rounded,
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
                onEdit: () => onEdit(r),
                onDelete: () => _handleDelete(context, ref, r),
              ),
              width: 80,
              headerIcon: Icons.more_horiz_rounded,
              sortable: false,
              resizable: false,
            ),
          ],
        ),
      );
  }

  String _getDriverName(LedgerTransaction tx, List<Driver> drivers) {
    if (tx.relatedDriverId == null) return 'Unknown Driver';
    final driver = drivers.where((d) => d.id == tx.relatedDriverId).firstOrNull;
    return driver?.name ?? 'Unknown Driver';
  }

  String _dateRange(LedgerTransaction t) {
    final start = AppFormatters.date.format(t.startDate);
    if (t.endDate == null) return start;
    final end = AppFormatters.date.format(t.endDate!);
    return '$start → $end';
  }

  Future<void> _handleDelete(
      BuildContext context, WidgetRef ref, LedgerTransaction tx) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Invoice',
      message: 'Are you sure you want to delete this invoice? This action cannot be undone.',
    );

    if (confirmed && context.mounted) {
      await ref.read(transactionsProvider.notifier).delete(tx.id);
      if (context.mounted) {
        SuccessSnackbar.show(context, 'Invoice deleted successfully');
      }
    }
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
