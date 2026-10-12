import 'package:flutter/material.dart';

import 'report_statistics_card.dart';

/// Displays the Revenue Report's headline numbers: revenue across
/// several fixed windows, plus period-over-period growth.
///
/// Purely presentational — all values are computed by
/// `RevenueReportScreen` from the currently filtered orders.
class RevenueSummaryCard extends StatelessWidget {
  const RevenueSummaryCard({
    super.key,
    required this.currency,
    required this.todayRevenue,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
    required this.yearlyRevenue,
    required this.totalRevenue,
    required this.revenueGrowthPercent,
  });

  final String currency;
  final double todayRevenue;
  final double weeklyRevenue;
  final double monthlyRevenue;
  final double yearlyRevenue;
  final double totalRevenue;

  /// Percentage change vs. the immediately preceding equivalent
  /// period, for the currently selected report filter. Positive means
  /// growth, negative means decline.
  final double? revenueGrowthPercent;

  @override
  Widget build(BuildContext context) {
    final growth = revenueGrowthPercent;
    final isGrowthPositive = (growth ?? 0) >= 0;

    return ReportStatisticsCard(
      title: 'Revenue Summary',
      entries: [
        ReportStatEntry(
          label: "Today's Revenue",
          value: '$currency ${todayRevenue.toStringAsFixed(2)}',
          icon: Icons.today_outlined,
          color: Colors.teal,
        ),
        ReportStatEntry(
          label: 'Weekly Revenue',
          value: '$currency ${weeklyRevenue.toStringAsFixed(2)}',
          icon: Icons.view_week_outlined,
          color: Colors.blue,
        ),
        ReportStatEntry(
          label: 'Monthly Revenue',
          value: '$currency ${monthlyRevenue.toStringAsFixed(2)}',
          icon: Icons.calendar_month_outlined,
          color: Colors.indigo,
        ),
        ReportStatEntry(
          label: 'Yearly Revenue',
          value: '$currency ${yearlyRevenue.toStringAsFixed(2)}',
          icon: Icons.calendar_view_month_outlined,
          color: Colors.deepPurple,
        ),
        ReportStatEntry(
          label: 'Total Revenue',
          value: '$currency ${totalRevenue.toStringAsFixed(2)}',
          icon: Icons.account_balance_wallet_outlined,
          color: Colors.green,
        ),
        ReportStatEntry(
          label: 'Revenue Growth',
          value: growth == null ? 'N/A' : '${isGrowthPositive ? '+' : ''}${growth.toStringAsFixed(1)}%',
          icon: isGrowthPositive ? Icons.trending_up : Icons.trending_down,
          color: growth == null
              ? Colors.grey
              : (isGrowthPositive ? Colors.green : Colors.red),
        ),
      ],
    );
  }
}