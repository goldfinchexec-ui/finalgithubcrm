import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goldfinch_crm/ui/components/page_header.dart';
import 'package:goldfinch_crm/ui/components/ledger_table.dart';
import 'package:goldfinch_crm/ui/components/shad_button.dart';
import 'package:goldfinch_crm/ui/components/general_transaction_modal.dart';
import 'package:goldfinch_crm/state/providers.dart';
import 'package:goldfinch_crm/models/ledger_transaction.dart';

class GeneralExpensesPage extends ConsumerWidget {
  const GeneralExpensesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(
          title: 'General Expenses',
          subtitle: 'Record and manage non-invoice expenses.',
          actions: [
            ShadButton(
              label: 'Add Expense',
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
            final items = txs.where((t) => t.type == TransactionType.expense && t.category == TransactionCategory.generalExpense).toList();
            return LedgerTable(
              items: items,
              emptyTitle: 'No expenses yet',
              emptyMessage: 'General expenses will appear here once recorded.',
              showTypeColumn: false,
              onEdit: (tx) => GeneralTransactionModal.show(
                context,
                type: TransactionType.expense,
                transaction: tx,
              ),
            );
          },
        ),
      ]);
  }
}
