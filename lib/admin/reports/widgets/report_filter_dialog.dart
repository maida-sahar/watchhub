import 'package:flutter/material.dart';

import 'date_range_picker.dart';

/// Modal dialog letting an admin pick a date filter for a report:
/// Today, Yesterday, This Week, This Month, This Year, or a custom
/// date range.
///
/// Purely a picker — it never touches `OrderProvider` or computes
/// report data itself. The parent report screen applies the returned
/// [ReportDateFilterResult] to whatever orders are already loaded (no
/// new Firestore query is made for date filtering; it's applied
/// client-side on top of the existing real-time `allOrders` stream).
class ReportFilterDialog extends StatelessWidget {
  const ReportFilterDialog({super.key, required this.current});

  final ReportDateFilterResult current;

  Future<void> _pickCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: current.filter == ReportDateFilter.custom && current.customRange != null
          ? current.customRange
          : DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );
    if (range != null && context.mounted) {
      Navigator.of(context).pop(ReportDateFilterResult(ReportDateFilter.custom, range));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Report'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: ReportDateFilter.values.map((filter) {
          return RadioListTile<ReportDateFilter>(
            title: Text(filter.label),
            value: filter,
            groupValue: current.filter,
            onChanged: (selected) {
              if (selected == null) return;
              if (selected == ReportDateFilter.custom) {
                _pickCustomRange(context);
              } else {
                Navigator.of(context).pop(ReportDateFilterResult(selected));
              }
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}