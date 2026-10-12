import 'package:flutter/material.dart';
import 'report_statistics_card.dart';

/// Headline cards for Customer Reports module.
class CustomerSummaryCard extends StatelessWidget {
  const CustomerSummaryCard({
    super.key,
    required this.currency,
    required this.totalCustomers,
    required this.activeCustomers,
    required this.newCustomers,
    required this.returningCustomers,
    required this.totalOrders,
    required this.averageSpending,
    required this.customerGrowthPercent,
  });

  final String currency;
  final int totalCustomers;
  final int activeCustomers;
  final int newCustomers;
  final int returningCustomers;
  final int totalOrders;
  final double averageSpending;
  final double? customerGrowthPercent;

  @override
  Widget build(BuildContext context) {
    final growth = customerGrowthPercent;
    final isGrowthPositive = (growth ?? 0) >= 0;

    return ReportStatisticsCard(
      title: 'Customer Summary',
      entries: [
        ReportStatEntry(
          label: 'Total Customers',
          value: '$totalCustomers',
          icon: Icons.people_outline,
          color: Colors.blue,
        ),
        ReportStatEntry(
          label: 'Active Customers',
          value: '$activeCustomers',
          icon: Icons.person_pin_outlined,
          color: Colors.green,
        ),
        ReportStatEntry(
          label: 'New Customers',
          value: '$newCustomers',
          icon: Icons.person_add_outlined,
          color: Colors.teal,
        ),
        ReportStatEntry(
          label: 'Returning Customers',
          value: '$returningCustomers',
          icon: Icons.assignment_ind_outlined,
          color: Colors.indigo,
        ),
        ReportStatEntry(
          label: 'Total Orders',
          value: '$totalOrders',
          icon: Icons.shopping_cart_outlined,
          color: Colors.amber[800],
        ),
        ReportStatEntry(
          label: 'Avg Cust Spending',
          value: '$currency ${averageSpending.toStringAsFixed(2)}',
          icon: Icons.analytics_outlined,
          color: Colors.purple,
        ),
        ReportStatEntry(
          label: 'New Customer Growth',
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
