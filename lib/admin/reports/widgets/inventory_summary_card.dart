import 'package:flutter/material.dart';
import 'report_statistics_card.dart';

/// Renders the Inventory summary metrics in a clean, consistent grid.
class InventorySummaryCard extends StatelessWidget {
  const InventorySummaryCard({
    super.key,
    required this.currency,
    required this.totalProducts,
    required this.activeProducts,
    required this.inactiveProducts,
    required this.inStockProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.inventoryValue,
  });

  final String currency;
  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final int inStockProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final double inventoryValue;

  @override
  Widget build(BuildContext context) {
    return ReportStatisticsCard(
      title: 'Inventory Summary',
      entries: [
        ReportStatEntry(
          label: 'Total Products',
          value: '$totalProducts',
          icon: Icons.inventory_2_outlined,
          color: Colors.blue,
        ),
        ReportStatEntry(
          label: 'Active Products',
          value: '$activeProducts',
          icon: Icons.check_circle_outline,
          color: Colors.green,
        ),
        ReportStatEntry(
          label: 'Inactive Products',
          value: '$inactiveProducts',
          icon: Icons.cancel_outlined,
          color: Colors.grey,
        ),
        ReportStatEntry(
          label: 'In Stock Products',
          value: '$inStockProducts',
          icon: Icons.shopping_bag_outlined,
          color: Colors.teal,
        ),
        ReportStatEntry(
          label: 'Low Stock Products',
          value: '$lowStockProducts',
          icon: Icons.warning_amber_outlined,
          color: Colors.orange,
        ),
        ReportStatEntry(
          label: 'Out Of Stock Products',
          value: '$outOfStockProducts',
          icon: Icons.error_outline,
          color: Colors.red,
        ),
        ReportStatEntry(
          label: 'Inventory Value',
          value: '$currency ${inventoryValue.toStringAsFixed(2)}',
          icon: Icons.monetization_on_outlined,
          color: Colors.purple,
        ),
      ],
    );
  }
}
