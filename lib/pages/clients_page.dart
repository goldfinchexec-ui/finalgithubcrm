import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:goldfinch_crm/ui/components/page_header.dart';
import 'package:goldfinch_crm/ui/components/notion_table.dart';
import 'package:goldfinch_crm/ui/components/client_modal.dart';
import 'package:goldfinch_crm/ui/components/action_menu.dart';
import 'package:goldfinch_crm/ui/components/confirmation_dialog.dart';
import 'package:goldfinch_crm/ui/components/success_snackbar.dart';
import 'package:goldfinch_crm/ui/components/shad_button.dart';
import 'package:goldfinch_crm/ui/components/count_badge.dart';
import 'package:goldfinch_crm/state/providers.dart';
import 'package:goldfinch_crm/theme.dart';
import 'package:goldfinch_crm/models/client.dart';
import 'package:goldfinch_crm/models/ledger_transaction.dart';

class ClientsPage extends ConsumerWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(
          title: 'Clients',
          subtitle: 'Manage clients and their details.',
          actions: [
            ShadButton(
              label: 'Add Client',
              icon: Icons.add,
              onPressed: () => ClientModal.show(context),
              variant: ShadButtonVariant.primary,
            ),
          ],
        ),
        clientsAsync.when(
          loading: () => const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (clients) {
            if (clients.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.shad), border: Border.all(color: AppColors.border, width: 1)),
                child: Text('No clients yet.', style: Theme.of(context).textTheme.bodyMedium),
              );
            }

            return transactionsAsync.when(
              loading: () => const Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (e, _) => Text('Error: $e'),
              data: (transactions) {
                final invoiceCounts = <String, int>{};
                for (final tx in transactions.where((t) => t.category == TransactionCategory.clientInvoice && t.relatedClientId != null)) {
                  invoiceCounts[tx.relatedClientId!] = (invoiceCounts[tx.relatedClientId!] ?? 0) + 1;
                }

                return NotionTable<Client>(
                  rows: clients,
                  columns: [
                    NotionColumn<Client>(
                      label: 'Client',
                      headerIcon: Icons.business_outlined,
                      flex: 2,
                      sortBy: (c) => c.name.toLowerCase(),
                      cellBuilder: (context, c) => Text(c.name, overflow: TextOverflow.ellipsis),
                    ),
                    NotionColumn<Client>(
                      label: 'Email',
                      headerIcon: Icons.email_outlined,
                      flex: 2,
                      sortBy: (c) => c.email.toLowerCase(),
                      cellBuilder: (context, c) => Text(c.email, overflow: TextOverflow.ellipsis),
                    ),
                    NotionColumn<Client>(
                      label: 'Address',
                      headerIcon: Icons.location_on_outlined,
                      flex: 3,
                      sortBy: (c) => c.address.toLowerCase(),
                      cellBuilder: (context, c) => Text(c.address, overflow: TextOverflow.ellipsis),
                    ),
                    NotionColumn<Client>(
                      label: 'Invoices',
                      headerIcon: Icons.receipt_long,
                      sortBy: (c) => invoiceCounts[c.id] ?? 0,
                      cellBuilder: (context, c) => CountBadge(count: invoiceCounts[c.id] ?? 0),
                      width: 100,
                    ),
                    NotionColumn<Client>(
                      label: 'Actions',
                      headerIcon: Icons.more_horiz,
                      width: 140,
                      sortable: false,
                      resizable: false,
                      cellBuilder: (context, c) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                            onPressed: () => context.push('/client-invoices?clientId=${c.id}'),
                            visualDensity: VisualDensity.compact,
                          ),
                          ActionMenu(
                            onEdit: () => ClientModal.show(context, client: c),
                            onDelete: () => _handleDelete(context, ref, c),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ]);
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Client client) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Client',
      message: 'Are you sure you want to delete ${client.name}? This action cannot be undone.',
    );

    if (confirmed && context.mounted) {
      await ref.read(clientsProvider.notifier).delete(client.id);
      if (context.mounted) {
        SuccessSnackbar.show(context, 'Client deleted successfully');
      }
    }
  }
}
