import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:goldfinch_crm/ui/components/page_header.dart';
import 'package:goldfinch_crm/ui/components/stat_card.dart';
// import 'package:goldfinch_crm/ui/components/ledger_table.dart';
import 'package:goldfinch_crm/state/providers.dart';
import 'package:goldfinch_crm/models/ledger_transaction.dart';
import 'package:goldfinch_crm/utils/formatters.dart';
import 'package:goldfinch_crm/theme.dart';
import 'package:goldfinch_crm/ui/components/shad_dropdown.dart';
import 'package:goldfinch_crm/ui/components/monthly_income_expense_chart.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  late int _selectedMonth; // 1..12
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionsProvider);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      PageHeader(
        title: 'Dashboard',
        subtitle: 'Month overview and financial insights.',
        actions: [
          // Month and Year filters moved to the header row
          SizedBox(
            width: 140,
            child: ShadDropdown<int>(
              label: 'Month',
              value: _selectedMonth,
              onChanged: (v) => setState(() => _selectedMonth = v ?? _selectedMonth),
              items: [
                for (final m in List.generate(12, (i) => i + 1))
                  DropdownMenuItem(value: m, child: Text(_monthLabel(m), overflow: TextOverflow.ellipsis)),
              ],
              compact: true,
              hideLabel: true,
            ),
          ),
          SizedBox(
            width: 110,
            child: ShadDropdown<int>(
              label: 'Year',
              value: _selectedYear,
              onChanged: (v) => setState(() => _selectedYear = v ?? _selectedYear),
              items: [
                for (final y in List.generate(5, (i) => DateTime.now().year - i))
                  DropdownMenuItem(value: y, child: Text(y.toString(), overflow: TextOverflow.ellipsis)),
              ],
              compact: true,
              hideLabel: true,
            ),
          ),
        ],
      ),

      const SizedBox(height: 4),

      txAsync.when(
        loading: () => const Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => Text('Error: $e'),
        data: (txs) {
          final periodStart = DateTime(_selectedYear, _selectedMonth, 1);
          final periodEnd = DateTime(_selectedYear, _selectedMonth + 1, 0);
          // Materialize monthly recurring transactions so they appear in any future month too
          final inPeriod = _materializeForMonth(txs, periodStart, periodEnd);

          final income = inPeriod.where((t) => t.type == TransactionType.income).fold<int>(0, (a, b) => a + b.amountPence);
          final expenses = inPeriod.where((t) => t.type == TransactionType.expense).fold<int>(0, (a, b) => a + b.amountPence);
          final net = income - expenses;

          // Due KPIs
          final isDue = (TransactionStatus s) => s == TransactionStatus.outstanding || s == TransactionStatus.pending;
          final payoutsDue = inPeriod
              .where((t) => t.category == TransactionCategory.driverPayout && isDue(t.status))
              .fold<int>(0, (a, b) => a + b.amountPence);
          final receivablesDue = inPeriod
              .where((t) => t.category == TransactionCategory.clientInvoice && isDue(t.status))
              .fold<int>(0, (a, b) => a + b.amountPence);

          // Weekly buckets for chart (W1..W5)
          final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
          final bucketCount = ((daysInMonth + 6) ~/ 7); // 4 or 5
          final incomeBuckets = List<int>.filled(bucketCount, 0);
          final expenseBuckets = List<int>.filled(bucketCount, 0);
          for (final t in inPeriod) {
            final day = t.startDate.day;
            final idx = ((day - 1) / 7).floor();
            if (idx >= 0 && idx < bucketCount) {
              if (t.type == TransactionType.income) {
                incomeBuckets[idx] += t.amountPence;
              } else {
                expenseBuckets[idx] += t.amountPence;
              }
            }
          }
          final labels = List.generate(bucketCount, (i) => 'W${i + 1}');

          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Stat cards
            LayoutBuilder(builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 1020;
              final colW = isNarrow ? constraints.maxWidth : (constraints.maxWidth - 36) / 4; // show 4 per row if wide
              return Wrap(spacing: 12, runSpacing: 12, children: [
                SizedBox(width: colW, child: StatCard(label: 'Income (${_shortMonthYear()})', value: AppFormatters.moneyFromPence(income), icon: Icons.trending_up)),
                SizedBox(width: colW, child: StatCard(label: 'Expenses (${_shortMonthYear()})', value: AppFormatters.moneyFromPence(expenses), icon: Icons.trending_down)),
                SizedBox(width: colW, child: StatCard(label: 'Net (${_shortMonthYear()})', value: AppFormatters.moneyFromPence(net), icon: Icons.stacked_line_chart)),
                SizedBox(width: colW, child: StatCard(label: 'Payouts Due', value: AppFormatters.moneyFromPence(payoutsDue), icon: Icons.payments_outlined)),
                SizedBox(width: colW, child: StatCard(label: 'Receivables Due', value: AppFormatters.moneyFromPence(receivablesDue), icon: Icons.request_quote_outlined)),
              ]);
            }),

            const SizedBox(height: 16),

            // Chart panel
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.shad),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Monthly breakdown', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: AppColors.slate900)),
                const SizedBox(height: 10),
                MonthlyIncomeExpenseChart(incomeByBucket: incomeBuckets, expenseByBucket: expenseBuckets, labels: labels),
                const SizedBox(height: 8),
                Row(children: [
                  _LegendDot(color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('Income', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.slate500)),
                  const SizedBox(width: 16),
                  _LegendDot(color: AppColors.danger),
                  const SizedBox(width: 6),
                  Text('Expenses', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.slate500)),
                ]),
              ]),
            ),

            // Removed demo-only tip since app now uses real-time Firebase data
          ]);
        },
      ),
    ]);
  }

  List<LedgerTransaction> _materializeForMonth(List<LedgerTransaction> all, DateTime periodStart, DateTime periodEnd) {
    final selectedY = periodStart.year;
    final selectedM = periodStart.month;
    final daysInSelected = DateTime(selectedY, selectedM + 1, 0).day;
    final List<LedgerTransaction> out = [];
    for (final t in all) {
      final isInPeriod = !t.startDate.isBefore(periodStart) && !t.startDate.isAfter(periodEnd);
      if (t.frequency == TransactionFrequency.monthly) {
        // If the base record falls in this month, keep it
        if (isInPeriod) {
          out.add(t);
          continue;
        }
        // If the recurring started before or on this month, add a materialized copy
        final started = DateTime(t.startDate.year, t.startDate.month);
        final thisMonth = DateTime(selectedY, selectedM);
        if (!started.isAfter(thisMonth)) {
          final day = t.startDate.day.clamp(1, daysInSelected);
          out.add(
            t.copyWith(
              startDate: DateTime(selectedY, selectedM, day),
              endDate: null,
            ),
          );
        }
      } else {
        if (isInPeriod) out.add(t);
      }
    }
    return out;
  }

  String _monthLabel(int m) {
    const names = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return names[m - 1];
  }

  String _shortMonthYear() {
    const short = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${short[_selectedMonth - 1]} ${_selectedYear.toString()}';
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3), border: Border.all(color: AppColors.border, width: 1)));
  }
}
