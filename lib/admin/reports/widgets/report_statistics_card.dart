import 'package:flutter/material.dart';

/// A single stat to display within a [ReportStatisticsCard].
class ReportStatEntry {
  const ReportStatEntry({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
}

/// A reusable card that renders a titled grid of [ReportStatEntry]
/// tiles. Used by both `SalesSummaryCard` and `RevenueSummaryCard` so
/// their headline numbers share one consistent layout, rather than
/// each screen reimplementing its own stat grid.
class ReportStatisticsCard extends StatelessWidget {
  const ReportStatisticsCard({
    super.key,
    required this.title,
    required this.entries,
  });

  final String title;
  final List<ReportStatEntry> entries;

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
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: entries.map((entry) {
                final tileColor = entry.color ?? theme.colorScheme.primary;
                return Container(
                  width: 160,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: tileColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tileColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(entry.icon, size: 22, color: tileColor),
                      const SizedBox(height: 10),
                      Text(
                        entry.value,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.label,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}