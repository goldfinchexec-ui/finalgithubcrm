import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goldfinch_crm/ui/components/page_header.dart';
import 'package:goldfinch_crm/ui/components/driver_invoice_table.dart';
import 'package:goldfinch_crm/ui/components/driver_invoice_modal.dart';
import 'package:goldfinch_crm/ui/components/shad_button.dart';
import 'package:goldfinch_crm/ui/components/shad_dropdown.dart';
import 'package:goldfinch_crm/state/providers.dart';
import 'package:goldfinch_crm/models/ledger_transaction.dart';
import 'package:go_router/go_router.dart';

class DriverInvoicesPage extends ConsumerStatefulWidget {
  const DriverInvoicesPage({super.key});

  @override
  ConsumerState<DriverInvoicesPage> createState() => _DriverInvoicesPageState();
}

class _DriverInvoicesPageState extends ConsumerState<DriverInvoicesPage> {
  // 0 = All
  int _month = 0;
  int _year = 0;
  DateTimeRange? _range;

  static const _months = <int, String>{
    1: 'Jan', 2: 'Feb', 3: 'Mar', 4: 'Apr', 5: 'May', 6: 'Jun',
    7: 'Jul', 8: 'Aug', 9: 'Sep', 10: 'Oct', 11: 'Nov', 12: 'Dec',
  };

  List<DropdownMenuItem<int>> _monthItems() => [
        const DropdownMenuItem<int>(value: 0, child: Text('All months')),
        ..._months.entries.map((e) => DropdownMenuItem<int>(value: e.key, child: Text(e.value))),
      ];

  List<DropdownMenuItem<int>> _yearItems() {
    final now = DateTime.now().year;
    final years = List.generate(7, (i) => now - i); // current year and last 6
    return [
      const DropdownMenuItem<int>(value: 0, child: Text('All years')),
      ...years.map((y) => DropdownMenuItem<int>(value: y, child: Text(y.toString()))),
    ];
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select date range',
      initialDateRange: _range,
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _range = picked;
        // When range is set, ignore month/year filters for clarity
      });
    }
  }

  bool _overlaps(LedgerTransaction t, DateTimeRange r) {
    final start = t.startDate;
    final end = t.endDate ?? t.startDate;
    return !(end.isBefore(r.start) || start.isAfter(r.end));
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionsProvider);
    final driversAsync = ref.watch(driversProvider);
    final qp = GoRouterState.of(context).uri.queryParameters;
    final filterDriverId = qp['driverId'];
    // Build header subtitle based on driver filter
    String? headerSubtitle = driversAsync.when(
      loading: () => 'Generate and track driver invoices.',
      error: (e, _) => 'Generate and track driver invoices.',
      data: (drivers) {
        if (filterDriverId != null) {
          final match = drivers.where((dr) => dr.id == filterDriverId).toList();
          final name = match.isNotEmpty ? match.first.name : 'Selected Driver';
          return 'Showing invoices for $name';
        }
        return 'Generate and track driver invoices.';
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PageHeader(
          title: 'Driver Invoices',
          subtitle: headerSubtitle,
          actions: [
            if (filterDriverId != null)
              ShadButton(
                label: 'Back',
                icon: Icons.arrow_back,
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    context.pop();
                  } else {
                    context.go('/drivers');
                  }
                },
                variant: ShadButtonVariant.ghost,
                compact: true,
              ),
            SizedBox(
              width: 140,
              child: ShadDropdown<int>(
                label: 'Month',
                value: _month,
                items: _monthItems(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _range = null;
                    _month = v;
                  });
                },
                compact: true,
                hideLabel: true,
              ),
            ),
            SizedBox(
              width: 110,
              child: ShadDropdown<int>(
                label: 'Year',
                value: _year,
                items: _yearItems(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _range = null;
                    _year = v;
                  });
                },
                compact: true,
                hideLabel: true,
              ),
            ),
            ShadButton(
              label: _range == null ? 'Date range' : 'Change range',
              icon: Icons.calendar_today_outlined,
              onPressed: _pickRange,
              variant: ShadButtonVariant.secondary,
              compact: true,
            ),
            if (_range != null)
              ShadButton(
                label: 'Clear',
                icon: Icons.close,
                onPressed: () => setState(() => _range = null),
                variant: ShadButtonVariant.ghost,
                compact: true,
              ),
            ShadButton(
              label: 'Add Invoice',
              icon: Icons.add_rounded,
              onPressed: () => DriverInvoiceModal.show(context),
              variant: ShadButtonVariant.primary,
              compact: true,
            ),
          ],
        ),
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
            var items = txs.where((t) => t.category == TransactionCategory.driverPayout).toList();
            if (filterDriverId != null) {
              items = items.where((t) => t.relatedDriverId == filterDriverId).toList();
            }

            // Apply date filters
            if (_range != null) {
              final r = _range!;
              items = items.where((t) => _overlaps(t, r)).toList();
            } else {
              final month = _month;
              final year = _year;
              if (month != 0 && year != 0) {
                final start = DateTime(year, month, 1);
                final end = DateTime(year, month + 1, 0, 23, 59, 59, 999);
                final r = DateTimeRange(start: start, end: end);
                items = items.where((t) => _overlaps(t, r)).toList();
              } else if (month != 0 && year == 0) {
                items = items.where((t) => (t.startDate.month == month) || ((t.endDate?.month) == month)).toList();
              } else if (month == 0 && year != 0) {
                items = items.where((t) => (t.startDate.year == year) || ((t.endDate?.year) == year)).toList();
              }
            }

            return DriverInvoiceTable(
              items: items,
              onEdit: (invoice) => DriverInvoiceModal.show(context, invoice: invoice),
              emptyTitle: 'No driver invoices yet',
              emptyMessage: 'Driver payouts will appear here once created.',
            );
          },
        ),
      ],
    );
  }
}
