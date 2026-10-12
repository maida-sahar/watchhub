import 'package:flutter/material.dart';

/// A single labeled bucket for a revenue bar chart (e.g. a month or
/// day label mapped to a revenue amount).
class RevenueBucket {
  const RevenueBucket({required this.label, required this.amount});
  final String label;
  final double amount;
}

/// Displays the Monthly Revenue Chart (last 12 calendar months,
/// independent of the report's active date filter) and the Revenue
/// Trend Chart (revenue per day within the currently selected date
/// range), as lightweight dependency-free bar charts — this app has no
/// charting package as a dependency yet, and these two simple charts
/// don't justify adding one.
///
/// Purely presentational — all bucketing/aggregation is done by
/// `RevenueReportScreen` from the currently filtered orders.
class RevenueChart extends StatelessWidget {
  const RevenueChart({
    super.key,
    required this.currency,
    required this.monthlyBuckets,
    required this.trendBuckets,
  });

  final String currency;
  final List<RevenueBucket> monthlyBuckets;
  final List<RevenueBucket> trendBuckets;

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
              'Monthly Revenue (Last 12 Months)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _barRow(theme, monthlyBuckets, theme.colorScheme.primary),
            const Divider(height: 32),
            Text(
              'Revenue Trend (Selected Period)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _barRow(theme, trendBuckets, Colors.teal),
          ],
        ),
      ),
    );
  }

  Widget _barRow(ThemeData theme, List<RevenueBucket> buckets, Color color) {
    if (buckets.isEmpty) {
      return Text(
        'No revenue data for this period.',
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      );
    }

    final maxAmount = buckets.map((b) => b.amount).reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: buckets.map((bucket) {
          final fraction = maxAmount <= 0 ? 0.0 : bucket.amount / maxAmount;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    bucket.amount >= 1000
                        ? '$currency ${(bucket.amount / 1000).toStringAsFixed(1)}k'
                        : '$currency ${bucket.amount.toStringAsFixed(0)}',
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 95 * fraction,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bucket.label,
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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