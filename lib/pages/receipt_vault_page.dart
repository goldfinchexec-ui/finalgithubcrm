import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goldfinch_crm/ui/components/page_header.dart';
import 'package:goldfinch_crm/ui/components/notion_table.dart';
import 'package:goldfinch_crm/ui/components/shad_button.dart';
import 'package:goldfinch_crm/ui/components/general_transaction_modal.dart';
import 'package:goldfinch_crm/ui/components/action_menu.dart';
import 'package:goldfinch_crm/ui/components/confirmation_dialog.dart';
import 'package:goldfinch_crm/ui/components/success_snackbar.dart';
import 'package:goldfinch_crm/ui/components/user_capsule.dart';
import 'package:goldfinch_crm/state/providers.dart';
import 'package:goldfinch_crm/models/ledger_transaction.dart';
import 'package:goldfinch_crm/services/attachment_service.dart';
import 'package:goldfinch_crm/utils/formatters.dart';
import 'package:goldfinch_crm/theme.dart';

class ReceiptVaultPage extends ConsumerWidget {
  const ReceiptVaultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final auth = ref.watch(authStateProvider);
    final currentUser = auth.asData?.value;
    final attachments = ref.read(attachmentServiceProvider);
    
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(
          title: 'Receipt Vault',
            subtitle: 'Store and search receipts with attachments.',
          actions: [
            ShadButton(
              label: 'Add Receipt',
              icon: Icons.add,
              onPressed: () => GeneralTransactionModal.show(
                context,
                type: TransactionType.expense,
              ),
              variant: ShadButtonVariant.primary,
            ),
          ],
        ),
        txAsync.when(
          loading: () => const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (txs) {
              // Flatten: one row per attachment
              final rows = <_ReceiptRow>[];
              for (final t in txs.where((x) => x.type == TransactionType.expense && x.attachments.isNotEmpty)) {
                for (final a in t.attachments) {
                  rows.add(_ReceiptRow(tx: t, dataUrl: a));
                }
              }

              return NotionTable<_ReceiptRow>(
                rows: rows,
                // Receipts are expenses → soft red tint
                rowBackgroundColor: (r) => AppColors.roseSoft.withValues(alpha: 0.35),
                columns: [
                  NotionColumn(
                    label: 'Title',
                    headerIcon: Icons.text_fields,
                    flex: 2,
                    cellBuilder: (c, r) => Text(r.tx.title, style: Theme.of(c).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    sortBy: (r) => r.tx.title,
                  ),
                  NotionColumn(
                    label: 'Date',
                    headerIcon: Icons.calendar_today,
                    flex: 1,
                    cellBuilder: (c, r) => Text(AppFormatters.date.format(r.tx.startDate), style: Theme.of(c).textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                    sortBy: (r) => r.tx.startDate,
                  ),
                  NotionColumn(
                    label: 'Amount',
                    headerIcon: Icons.attach_money,
                    flex: 1,
                    cellBuilder: (c, r) => Text(AppFormatters.moneyFromPence(r.tx.amountPence), style: Theme.of(c).textTheme.bodyMedium?.copyWith(color: AppColors.danger, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    sortBy: (r) => r.tx.amountPence,
                  ),
                  NotionColumn(
                    label: 'Repeats',
                    headerIcon: Icons.autorenew_rounded,
                    width: 120,
                    sortable: true,
                    resizable: false,
                    cellBuilder: (c, r) {
                      final f = r.tx.frequency;
                      String label;
                      IconData icon;
                      switch (f) {
                        case TransactionFrequency.monthly:
                          label = 'Monthly';
                          icon = Icons.repeat_rounded;
                          break;
                        case TransactionFrequency.weekly:
                          label = 'Weekly';
                          icon = Icons.calendar_view_week_rounded;
                          break;
                        default:
                          label = 'One-time';
                          icon = Icons.radio_button_unchecked_rounded;
                      }
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(icon, size: 14, color: AppColors.slate600),
                          const SizedBox(width: 6),
                          Text(label, style: Theme.of(c).textTheme.labelSmall?.copyWith(color: AppColors.slate600, fontWeight: FontWeight.w600)),
                        ]),
                      );
                    },
                    sortBy: (r) => r.tx.frequency?.index ?? 0,
                  ),
                  // Linked indicator: show if this receipt belongs to a Driver Invoice
                  NotionColumn(
                    label: 'Linked',
                    headerIcon: Icons.link_rounded,
                    width: 160,
                    sortable: true,
                    resizable: false,
                    cellBuilder: (c, r) {
                      final linkedToDriverInvoice = r.tx.category == TransactionCategory.driverPayout && r.tx.relatedDriverId != null;
                      if (!linkedToDriverInvoice) {
                        return const SizedBox.shrink();
                      }
                      return Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.directions_car_filled_rounded, size: 16, color: AppColors.slate500),
                        const SizedBox(width: 6),
                        Text('Driver Invoice', style: Theme.of(c).textTheme.bodySmall?.copyWith(color: AppColors.slate600)),
                      ]);
                    },
                    sortBy: (r) => (r.tx.category == TransactionCategory.driverPayout && r.tx.relatedDriverId != null) ? 1 : 0,
                  ),
                  NotionColumn(
                    label: 'Created By',
                    headerIcon: Icons.person_outline_rounded,
                    width: 160,
                    cellBuilder: (c, r) => UserCapsule(
                      name: _createdByLabel(r.tx, currentUser),
                      size: 24,
                    ),
                    sortBy: (r) => _createdByLabel(r.tx, currentUser),
                  ),
                  NotionColumn(
                    label: 'Actions',
                    headerIcon: Icons.more_horiz,
                    width: 140,
                    resizable: false,
                    sortable: false,
                    cellBuilder: (c, r) => Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        onPressed: () => attachments.openInBrowser(r.dataUrl),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.download_outlined, size: 18),
                        onPressed: () => attachments.openForDownload(r.dataUrl),
                        visualDensity: VisualDensity.compact,
                      ),
                      ActionMenu(
                        onEdit: () => GeneralTransactionModal.show(
                          c,
                          type: TransactionType.expense,
                          transaction: r.tx,
                        ),
                        onDelete: () => _handleDelete(c, ref, r.tx),
                      ),
                    ]),
                  ),
                ],
                emptyTitle: 'No receipts yet',
                emptyMessage: 'Add an attachment to an expense to see it here.',
                initialSortColumnIndex: 1,
                initialSortAscending: false,
              );
            },
        ),
      ]);
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, LedgerTransaction tx) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Receipt',
      message: 'Are you sure you want to delete this receipt? This action cannot be undone.',
    );

    if (confirmed && context.mounted) {
      await ref.read(transactionsProvider.notifier).delete(tx.id);
      if (context.mounted) {
        SuccessSnackbar.show(context, 'Receipt deleted successfully');
      }
    }
  }
}

class _ReceiptRow {
  final LedgerTransaction tx;
  final String dataUrl;
  const _ReceiptRow({required this.tx, required this.dataUrl});
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

