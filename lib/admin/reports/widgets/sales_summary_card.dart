import 'package:flutter/material.dart';

import 'report_statistics_card.dart';

/// Displays the Sales Report's headline numbers: total sales, order
/// counts by outcome, and average order value.
///
/// Purely presentational — all values are computed by
/// `SalesReportScreen` from the currently filtered orders.
class SalesSummaryCard extends StatelessWidget {
  const SalesSummaryCard({
    super.key,
    required this.currency,
    required this.totalSales,
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.cancelledOrders,
    required this.returnedOrders,
    required this.averageOrderValue,
  });

  final String currency;
  final double totalSales;
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final int cancelledOrders;
  final int returnedOrders;
  final double averageOrderValue;

  @override
  Widget build(BuildContext context) {
    return ReportStatisticsCard(
      title: 'Sales Summary',
      entries: [
        ReportStatEntry(
          label: 'Total Sales',
          value: '$currency ${totalSales.toStringAsFixed(2)}',
          icon: Icons.point_of_sale_outlined,
          color: Colors.green,
        ),
        ReportStatEntry(
          label: 'Total Orders',
          value: '$totalOrders',
          icon: Icons.receipt_long_outlined,
        ),
        ReportStatEntry(
          label: 'Completed Orders',
          value: '$completedOrders',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        ReportStatEntry(
          label: 'Pending Orders',
          value: '$pendingOrders',
          icon: Icons.hourglass_empty,
          color: Colors.orange,
        ),
        ReportStatEntry(
          label: 'Cancelled Orders',
          value: '$cancelledOrders',
          icon: Icons.cancel_outlined,
          color: Colors.red,
        ),
        ReportStatEntry(
          label: 'Returned Orders',
          value: '$returnedOrders',
          icon: Icons.assignment_return_outlined,
          color: Colors.deepOrange,
        ),
        ReportStatEntry(
          label: 'Avg. Order Value',
          value: '$currency ${averageOrderValue.toStringAsFixed(2)}',
          icon: Icons.trending_up_outlined,
          color: Colors.indigo,
        ),
      ],
    );
  }
}