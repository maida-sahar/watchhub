import 'package:flutter/material.dart';

/// The date-based filter presets an admin can apply to a report,
/// shared by both the Sales Report and Revenue Report screens.
enum ReportDateFilter { today, yesterday, thisWeek, thisMonth, thisYear, custom }

extension ReportDateFilterX on ReportDateFilter {
  String get label {
    switch (this) {
      case ReportDateFilter.today:
        return 'Today';
      case ReportDateFilter.yesterday:
        return 'Yesterday';
      case ReportDateFilter.thisWeek:
        return 'This Week';
      case ReportDateFilter.thisMonth:
        return 'This Month';
      case ReportDateFilter.thisYear:
        return 'This Year';
      case ReportDateFilter.custom:
        return 'Custom Range';
    }
  }

  /// Resolves this preset into a concrete `[start, end)` range. For
  /// [ReportDateFilter.custom], [customRange] must be provided.
  DateTimeRange resolve({DateTimeRange? customRange}) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    switch (this) {
      case ReportDateFilter.today:
        return DateTimeRange(start: startOfToday, end: startOfToday.add(const Duration(days: 1)));
      case ReportDateFilter.yesterday:
        final yesterday = startOfToday.subtract(const Duration(days: 1));
        return DateTimeRange(start: yesterday, end: startOfToday);
      case ReportDateFilter.thisWeek:
        final startOfWeek = startOfToday.subtract(Duration(days: startOfToday.weekday - 1));
        return DateTimeRange(start: startOfWeek, end: startOfToday.add(const Duration(days: 1)));
      case ReportDateFilter.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: startOfMonth, end: startOfToday.add(const Duration(days: 1)));
      case ReportDateFilter.thisYear:
        final startOfYear = DateTime(now.year, 1, 1);
        return DateTimeRange(start: startOfYear, end: startOfToday.add(const Duration(days: 1)));
      case ReportDateFilter.custom:
        if (customRange == null) {
          throw ArgumentError('customRange is required for ReportDateFilter.custom');
        }
        // Normalize to whole days, end exclusive (so the end date itself is included).
        final start = DateTime(customRange.start.year, customRange.start.month, customRange.start.day);
        final end = DateTime(customRange.end.year, customRange.end.month, customRange.end.day)
            .add(const Duration(days: 1));
        return DateTimeRange(start: start, end: end);
    }
  }

  /// The equivalent range immediately preceding this one, of the same
  /// duration — used to compute revenue growth (current vs previous
  /// period).
  DateTimeRange previousRange({DateTimeRange? customRange}) {
    final current = resolve(customRange: customRange);
    final duration = current.end.difference(current.start);
    return DateTimeRange(
      start: current.start.subtract(duration),
      end: current.start,
    );
  }
}

/// The result of the report filter dialog: which preset was chosen,
/// and (only for [ReportDateFilter.custom]) the selected range.
class ReportDateFilterResult {
  const ReportDateFilterResult(this.filter, [this.customRange]);

  final ReportDateFilter filter;
  final DateTimeRange? customRange;

  DateTimeRange resolve() => filter.resolve(customRange: customRange);
  DateTimeRange resolvePrevious() => filter.previousRange(customRange: customRange);

  String get label {
    if (filter != ReportDateFilter.custom) return filter.label;
    final range = customRange;
    if (range == null) return filter.label;
    return '${range.start.day} ${_shortMonth(range.start)} - ${range.end.day} ${_shortMonth(range.end)}';
  }

  static String _shortMonth(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[date.month - 1];
  }
}

/// A compact chip-style control showing the currently selected date
/// range/preset, tappable to open the full filter dialog.
///
/// This widget is purely a trigger + display — it never resolves
/// dates or applies filtering itself; the parent screen owns the
/// actual [ReportDateFilterResult] state and passes it back in here,
/// wiring [onTap] to open `ReportFilterDialog` (in
/// `report_filter_dialog.dart`) and apply whatever comes back.
class DateRangeSelector extends StatelessWidget {
  const DateRangeSelector({
    super.key,
    required this.current,
    required this.onTap,
  });

  final ReportDateFilterResult current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 8),
            Text(
              current.label,
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: theme.colorScheme.onPrimaryContainer),
          ],
        ),
      ),
    );
  }
}