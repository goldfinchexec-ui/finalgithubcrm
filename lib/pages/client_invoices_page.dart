import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goldfinch_crm/ui/components/page_header.dart';
import 'package:goldfinch_crm/ui/components/client_invoice_table.dart';
import 'package:goldfinch_crm/ui/components/client_invoice_modal.dart';
import 'package:goldfinch_crm/ui/components/shad_button.dart';
import 'package:goldfinch_crm/state/providers.dart';
import 'package:goldfinch_crm/models/ledger_transaction.dart';
import 'package:go_router/go_router.dart';

class ClientInvoicesPage extends ConsumerWidget {
  const ClientInvoicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionsProvider);
    final clientsAsync = ref.watch(clientsProvider);
    final qp = GoRouterState.of(context).uri.queryParameters;
    final filterClientId = qp['clientId'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: clientsAsync.when(
                loading: () => const PageHeader(title: 'Client Invoices', subtitle: 'Create and manage client invoices.'),
                error: (e, _) => const PageHeader(title: 'Client Invoices', subtitle: 'Create and manage client invoices.'),
                data: (clients) {
                  String? subtitle;
                  if (filterClientId != null) {
                    final name = clients.where((c) => c.id == filterClientId).map((c) => c.name).firstOrNull ?? 'Selected Client';
                    subtitle = 'Showing invoices for $name';
                  } else {
                    subtitle = 'Create and manage client invoices.';
                  }
                  return PageHeader(title: 'Client Invoices', subtitle: subtitle);
                },
              ),
            ),
            if (filterClientId != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ShadButton(
                  label: 'Back',
                  icon: Icons.arrow_back,
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      context.pop();
                    } else {
                      context.go('/clients');
                    }
                  },
                  variant: ShadButtonVariant.ghost,
                ),
              ),
            ShadButton(
              label: 'Add Invoice',
              icon: Icons.add_rounded,
              onPressed: () => ClientInvoiceModal.show(context),
              variant: ShadButtonVariant.primary,
            ),
          ],
        ),
        const SizedBox(height: 16),
        txAsync.when(
          loading: () => const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (txs) {
            var items = txs.where((t) => t.category == TransactionCategory.clientInvoice).toList();
            if (filterClientId != null) {
              items = items.where((t) => t.relatedClientId == filterClientId).toList();
            }
            return ClientInvoiceTable(
              items: items,
              onEdit: (invoice) => ClientInvoiceModal.show(context, invoice: invoice),
              emptyTitle: 'No client invoices yet',
              emptyMessage: 'Client invoices will appear here once created.',
            );
          },
        ),
      ],
    );
  }
}
