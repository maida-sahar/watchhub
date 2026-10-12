import 'package:flutter/material.dart';
import '../../../models/order_model.dart';
import 'report_statistics_card.dart';

class RevenueOverviewCard extends StatelessWidget {
  final List<OrderModel> orders;

  const RevenueOverviewCard({
    super.key,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    // Computations
    final totalRevenue = orders
        .where((o) => o.orderStatus.toLowerCase() != 'cancelled' && o.orderStatus.toLowerCase() != 'returned')
        .fold<double>(0.0, (sum, o) => sum + o.grandTotal);

    final completedRevenue = orders
        .where((o) => o.orderStatus.toLowerCase() == 'completed' || o.orderStatus.toLowerCase() == 'delivered')
        .fold<double>(0.0, (sum, o) => sum + o.grandTotal);

    final refundedAmount = orders
        .where((o) => o.orderStatus.toLowerCase() == 'refunded' || o.orderStatus.toLowerCase() == 'returned')
        .fold<double>(0.0, (sum, o) => sum + o.grandTotal);

    final activeOrdersCount = orders.where((o) => o.orderStatus.toLowerCase() != 'cancelled').length;
    final avgRevenuePerActiveOrder = activeOrdersCount == 0 ? 0.0 : totalRevenue / activeOrdersCount;

    final stats = [
      ReportStatEntry(
        label: 'Gross Revenue',
        value: '\$${totalRevenue.toStringAsFixed(0)}',
        icon: Icons.monetization_on_rounded,
        color: Colors.green,
      ),
      ReportStatEntry(
        label: 'Net Revenue',
        value: '\$${completedRevenue.toStringAsFixed(0)}',
        icon: Icons.account_balance_wallet_rounded,
        color: Colors.teal,
      ),
      ReportStatEntry(
        label: 'Refunds / Returns',
        value: '\$${refundedAmount.toStringAsFixed(0)}',
        icon: Icons.assignment_return_rounded,
        color: Colors.red,
      ),
      ReportStatEntry(
        label: 'Avg Rev / Order',
        value: '\$${avgRevenuePerActiveOrder.toStringAsFixed(1)}',
        icon: Icons.trending_up_rounded,
        color: Colors.amber[800],
      ),
    ];

    return ReportStatisticsCard(
      title: 'Revenue & Volume Breakdown',
      entries: stats,
    );
  }
}
