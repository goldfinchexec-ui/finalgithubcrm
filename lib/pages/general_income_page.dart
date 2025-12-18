import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goldfinch_crm/ui/components/page_header.dart';
import 'package:goldfinch_crm/ui/components/ledger_table.dart';
import 'package:goldfinch_crm/ui/components/shad_button.dart';
import 'package:goldfinch_crm/ui/components/general_transaction_modal.dart';
import 'package:goldfinch_crm/ui/components/client_invoice_modal.dart';
import 'package:goldfinch_crm/state/providers.dart';
import 'package:goldfinch_crm/models/ledger_transaction.dart';

class GeneralIncomePage extends ConsumerWidget {
  const GeneralIncomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(
          title: 'Income',
          subtitle: 'All income, including client invoices and general entries.',
          actions: [
            ShadButton(
              label: 'Add Income',
              icon: Icons.add,
              onPressed: () => GeneralTransactionModal.show(
                context,
                type: TransactionType.income,
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
            // Show all income, including client invoices
            final items = txs.where((t) => t.type == TransactionType.income).toList();
            return LedgerTable(
              items: items,
              emptyTitle: 'No income yet',
              emptyMessage: 'Income (including client invoices) will appear here once recorded.',
              onEdit: (tx) {
                if (tx.category == TransactionCategory.clientInvoice) {
                  // Edit in the Client Invoice modal
                  ClientInvoiceModal.show(context, invoice: tx);
                } else {
                  // Edit general income entries in the General Transaction modal
                  GeneralTransactionModal.show(
                    context,
                    type: TransactionType.income,
                    transaction: tx,
                  );
                }
              },
            );
          },
        ),
      ]);
  }
}
