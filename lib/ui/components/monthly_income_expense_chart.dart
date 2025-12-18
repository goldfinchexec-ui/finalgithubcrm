import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:goldfinch_crm/theme.dart';

/// A compact bar chart showing Income vs Expenses per week bucket in a month.
///
/// Provide parallel [incomeByBucket] and [expenseByBucket] arrays (in pence),
/// with corresponding [labels] like ["W1","W2",...].
class MonthlyIncomeExpenseChart extends StatelessWidget {
  final List<int> incomeByBucket;
  final List<int> expenseByBucket;
  final List<String> labels;

  const MonthlyIncomeExpenseChart({
    super.key,
    required this.incomeByBucket,
    required this.expenseByBucket,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buckets = _zipBuckets();

    // Avoid crashing on empty
    if (buckets.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'No data for this period',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.slate500),
          ),
        ),
      );
    }

    final maxValue = buckets
        .map((b) => b.$1 + b.$2)
        .fold<int>(0, (p, c) => c > p ? c : p)
        .toDouble();
    // Nice headroom
    final yMax = (maxValue * 1.2).clamp(1.0, double.infinity);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          barGroups: List.generate(buckets.length, (i) {
            final (income, expense) = buckets[i];
            return BarChartGroupData(
              x: i,
              barsSpace: 6,
              barRods: [
                BarChartRodData(
                  toY: income / 100.0,
                  gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)]),
                  width: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
                BarChartRodData(
                  toY: expense / 100.0,
                  gradient: LinearGradient(colors: [AppColors.danger, AppColors.danger.withValues(alpha: 0.7)]),
                  width: 10,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1)),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (v, meta) {
                  // Values are shown in currency units (pounds) with no decimals for cleanliness
                  return Text('£${v.toInt()}', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.slate500));
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final idx = v.toInt();
                  final label = (idx >= 0 && idx < labels.length) ? labels[idx] : '';
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: AppColors.slate500)),
                  );
                },
              ),
            ),
          ),
          minY: 0,
          maxY: yMax / 100.0,
          barTouchData: BarTouchData(enabled: false),
        ),
      ),
    );
  }

  List<(int, int)> _zipBuckets() {
    final len = incomeByBucket.length;
    if (expenseByBucket.length != len || labels.length != len) {
      final minLen = [len, expenseByBucket.length, labels.length].reduce((a, b) => a < b ? a : b);
      return List.generate(minLen, (i) => (incomeByBucket[i], expenseByBucket[i]));
    }
    return List.generate(len, (i) => (incomeByBucket[i], expenseByBucket[i]));
  }
}
