import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:goldfinch_crm/ui/components/page_header.dart';
import 'package:goldfinch_crm/ui/components/notion_table.dart';
import 'package:goldfinch_crm/ui/components/driver_modal.dart';
import 'package:goldfinch_crm/ui/components/action_menu.dart';
import 'package:goldfinch_crm/ui/components/confirmation_dialog.dart';
import 'package:goldfinch_crm/ui/components/success_snackbar.dart';
import 'package:goldfinch_crm/ui/components/shad_button.dart';
import 'package:goldfinch_crm/ui/components/count_badge.dart';
import 'package:goldfinch_crm/ui/components/shad_text_field.dart';
import 'package:goldfinch_crm/state/providers.dart';
import 'package:goldfinch_crm/theme.dart';
import 'package:goldfinch_crm/models/driver.dart';
import 'package:goldfinch_crm/models/ledger_transaction.dart';

class DriversPage extends ConsumerStatefulWidget {
  const DriversPage({super.key});

  @override
  ConsumerState<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends ConsumerState<DriversPage> {
  final _searchCtrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(driversProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final searchWidth = screenWidth < 700
        ? 160.0
        : screenWidth < 1000
            ? 200.0
            : 260.0;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
        title: 'Drivers',
        subtitle: 'Manage drivers and related information.',
        actions: [
          SizedBox(
            width: searchWidth,
            child: ShadTextField(
              controller: _searchCtrl,
              label: 'Search drivers',
              hint: 'Search drivers',
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              compact: true,
              hideLabel: true,
              prefixIcon: Icons.search,
              showClearButton: true,
            ),
          ),
          ShadButton(
            label: 'Add Driver',
            icon: Icons.add,
            onPressed: () => DriverModal.show(context),
            variant: ShadButtonVariant.primary,
            compact: true,
          ),
        ],
      ),
      driversAsync.when(
        loading: () => const Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => Text('Error: $e'),
        data: (drivers) {
          if (drivers.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.shad), border: Border.all(color: AppColors.border, width: 1)),
              child: Text('No drivers yet.', style: Theme.of(context).textTheme.bodyMedium),
            );
          }

          // Apply search filter
          final filtered = (_q.isEmpty)
              ? drivers
              : drivers.where((d) {
                  final name = d.name.toLowerCase();
                  final code = d.code.toLowerCase();
                  final email = d.email.toLowerCase();
                  final vehicle = d.vehicleReg.toLowerCase();
                  return name.contains(_q) || code.contains(_q) || email.contains(_q) || vehicle.contains(_q);
                }).toList();

          return transactionsAsync.when(
            loading: () => const Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (e, _) => Text('Error: $e'),
            data: (transactions) {
              final invoiceCounts = <String, int>{};
              for (final tx in transactions.where((t) => t.category == TransactionCategory.driverPayout && t.relatedDriverId != null)) {
                invoiceCounts[tx.relatedDriverId!] = (invoiceCounts[tx.relatedDriverId!] ?? 0) + 1;
              }

              return NotionTable<Driver>(
                rows: filtered,
                columns: [
                  NotionColumn<Driver>(
                    label: 'Driver',
                    headerIcon: Icons.person_outline,
                    flex: 2,
                    sortBy: (d) => d.name.toLowerCase(),
                    cellBuilder: (context, d) => Text(d.name, overflow: TextOverflow.ellipsis),
                  ),
                  NotionColumn<Driver>(
                    label: 'Code',
                    headerIcon: Icons.tag,
                    sortBy: (d) => d.code.toLowerCase(),
                    cellBuilder: (context, d) => Text(d.code),
                    width: 120,
                  ),
                  NotionColumn<Driver>(
                    label: 'Email',
                    headerIcon: Icons.email_outlined,
                    flex: 2,
                    sortBy: (d) => d.email.toLowerCase(),
                    cellBuilder: (context, d) => Text(d.email, overflow: TextOverflow.ellipsis),
                  ),
                  NotionColumn<Driver>(
                    label: 'Vehicle',
                    headerIcon: Icons.local_shipping_outlined,
                    sortBy: (d) => d.vehicleReg.toLowerCase(),
                    cellBuilder: (context, d) => Text(d.vehicleReg),
                    width: 140,
                  ),
                  NotionColumn<Driver>(
                    label: 'Invoices',
                    headerIcon: Icons.receipt_long,
                    sortBy: (d) => invoiceCounts[d.id] ?? 0,
                    cellBuilder: (context, d) => CountBadge(count: invoiceCounts[d.id] ?? 0),
                    width: 100,
                  ),
                  NotionColumn<Driver>(
                    label: 'Actions',
                    headerIcon: Icons.more_horiz,
                    width: 140,
                    sortable: false,
                    resizable: false,
                    cellBuilder: (context, d) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          onPressed: () => context.push('/driver-invoices?driverId=${d.id}'),
                          visualDensity: VisualDensity.compact,
                        ),
                        ActionMenu(
                          onEdit: () => DriverModal.show(context, driver: d),
                          onDelete: () => _handleDelete(context, ref, d),
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

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Driver driver) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Driver',
      message: 'Are you sure you want to delete ${driver.name}? This action cannot be undone.',
    );

    if (confirmed && context.mounted) {
      await ref.read(driversProvider.notifier).delete(driver.id);
      if (context.mounted) {
        SuccessSnackbar.show(context, 'Driver deleted successfully');
      }
    }
  }
}
