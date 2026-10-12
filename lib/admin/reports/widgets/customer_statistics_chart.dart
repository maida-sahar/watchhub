import 'package:flutter/material.dart';

/// Helper bucket representing a count of signups or orders for a date label.
class CustomerChartBucket {
  const CustomerChartBucket({required this.label, required this.value});
  final String label;
  final double value;
}

/// Renders the Customer Growth Chart (registrations over time) and the
/// Customer Spending Chart (purchase/revenue trends over time) as clean bar charts.
class CustomerStatisticsChart extends StatelessWidget {
  const CustomerStatisticsChart({
    super.key,
    required this.growthBuckets,
    required this.spendingBuckets,
    required this.currency,
  });

  final List<CustomerChartBucket> growthBuckets;
  final List<CustomerChartBucket> spendingBuckets;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Growth (New Registrations)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _renderBarChart(
              context,
              buckets: growthBuckets,
              color: Colors.blue,
              isCurrency: false,
              emptyMsg: 'No customer signups in this period.',
            ),
            const Divider(height: 32),
            Text(
              'Customer Spending Trends (Revenue)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _renderBarChart(
              context,
              buckets: spendingBuckets,
              color: Colors.purple,
              isCurrency: true,
              emptyMsg: 'No spending data in this period.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _renderBarChart(
    BuildContext context, {
    required List<CustomerChartBucket> buckets,
    required Color color,
    required bool isCurrency,
    required String emptyMsg,
  }) {
    final theme = Theme.of(context);

    if (buckets.isEmpty) {
      return Text(
        emptyMsg,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }

    final maxVal = buckets.map((b) => b.value).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: buckets.map((bucket) {
          final fraction = maxVal <= 0 ? 0.0 : bucket.value / maxVal;
          final valueText = isCurrency
              ? (bucket.value >= 1000
                  ? '${(bucket.value / 1000).toStringAsFixed(1)}k'
                  : bucket.value.toStringAsFixed(0))
              : bucket.value.toStringAsFixed(0);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    valueText,
                    style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 100 * fraction,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bucket.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 8,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
