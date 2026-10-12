import 'package:flutter/material.dart';
import '../../../models/order_model.dart';
import 'report_statistics_card.dart';

class SalesOverviewCard extends StatelessWidget {
  final List<OrderModel> orders;

  const SalesOverviewCard({
    super.key,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate metrics
    final completedOrders = orders.where((o) => o.orderStatus.toLowerCase() == 'completed' || o.orderStatus.toLowerCase() == 'delivered').toList();
    final totalSalesCount = orders.length;
    final totalCompletedCount = completedOrders.length;
    final totalSalesVolume = orders.fold<double>(0.0, (sum, o) => sum + o.grandTotal);
    final averageOrderValue = totalSalesCount == 0 ? 0.0 : totalSalesVolume / totalSalesCount;

    final stats = [
      ReportStatEntry(
        label: 'Total Orders',
        value: totalSalesCount.toString(),
        icon: Icons.receipt_long_rounded,
        color: Colors.blue,
      ),
      ReportStatEntry(
        label: 'Completed Orders',
        value: totalCompletedCount.toString(),
        icon: Icons.check_circle_outline_rounded,
        color: Colors.green,
      ),
      ReportStatEntry(
        label: 'Sales Volume',
        value: '\$${totalSalesVolume.toStringAsFixed(0)}',
        icon: Icons.analytics_rounded,
        color: Colors.purple,
      ),
      ReportStatEntry(
        label: 'Avg Order Value',
        value: '\$${averageOrderValue.toStringAsFixed(1)}',
        icon: Icons.shopping_bag_outlined,
        color: Colors.indigo,
      ),
    ];

    return ReportStatisticsCard(
      title: 'Sales Overview',
      entries: stats,
    );
  }
}
