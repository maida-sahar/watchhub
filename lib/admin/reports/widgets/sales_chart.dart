import 'package:flutter/material.dart';

/// A single labeled bucket for the daily sales bar chart (e.g. a day
/// or week label mapped to an order count).
class SalesBucket {
  const SalesBucket({required this.label, required this.count});
  final String label;
  final int count;
}

/// Displays the Daily Sales Chart (order count per day/period within
/// the selected range) and the Sales Comparison Chart (current period
/// vs. the immediately preceding equivalent period), as lightweight
/// dependency-free bar charts — this app has no charting package as a
/// dependency yet, and these two simple charts don't justify adding one.
///
/// Purely presentational — all bucketing/aggregation is done by
/// `SalesReportScreen` from the currently filtered orders.
class SalesChart extends StatelessWidget {
  const SalesChart({
    super.key,
    required this.dailyBuckets,
    required this.currentPeriodOrders,
    required this.previousPeriodOrders,
  });

  final List<SalesBucket> dailyBuckets;
  final int currentPeriodOrders;
  final int previousPeriodOrders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCount = dailyBuckets.isEmpty
        ? 0
        : dailyBuckets.map((b) => b.count).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Sales (Order Count)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (dailyBuckets.isEmpty || maxCount == 0)
              Text(
                'No orders in this period.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            else
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: dailyBuckets.map((bucket) {
                    final fraction = maxCount == 0 ? 0.0 : bucket.count / maxCount;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('${bucket.count}', style: theme.textTheme.labelSmall),
                            const SizedBox(height: 4),
                            Container(
                              height: 90 * fraction,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              bucket.label,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const Divider(height: 32),
            Text(
              'Sales Comparison (Orders)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _comparisonBars(theme),
          ],
        ),
      ),
    );
  }

  Widget _comparisonBars(ThemeData theme) {
    final maxValue = [currentPeriodOrders, previousPeriodOrders]
        .fold<int>(0, (max, v) => v > max ? v : max);

    return Row(
      children: [
        Expanded(
          child: _comparisonBar(
            theme,
            label: 'Previous Period',
            value: previousPeriodOrders,
            maxValue: maxValue,
            color: theme.colorScheme.outline,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _comparisonBar(
            theme,
            label: 'Current Period',
            value: currentPeriodOrders,
            maxValue: maxValue,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _comparisonBar(
    ThemeData theme, {
    required String label,
    required int value,
    required int maxValue,
    required Color color,
  }) {
    final fraction = maxValue == 0 ? 0.0 : value / maxValue;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$value', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Container(
          height: 80 * fraction,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}