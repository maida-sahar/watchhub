import 'package:flutter/material.dart';
import '../../../models/product_model.dart';
import 'report_statistics_card.dart';

class InventoryOverviewCard extends StatelessWidget {
  final List<ProductModel> products;

  const InventoryOverviewCard({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculations
    final totalItems = products.fold<int>(0, (sum, p) => sum + p.stock);
    final outOfStockCount = products.where((p) => p.stock == 0).length;
    final lowStockCount = products.where((p) => p.stock > 0 && p.stock <= p.minimumStock).length;
    final totalValuation = products.fold<double>(0.0, (sum, p) => sum + (p.stock * p.price));

    final stats = [
      ReportStatEntry(
        label: 'Total Stocked Items',
        value: totalItems.toString(),
        icon: Icons.inventory_rounded,
        color: Colors.blue,
      ),
      ReportStatEntry(
        label: 'Low Stock Items',
        value: lowStockCount.toString(),
        icon: Icons.warning_amber_rounded,
        color: Colors.orange,
      ),
      ReportStatEntry(
        label: 'Out of Stock Items',
        value: outOfStockCount.toString(),
        icon: Icons.error_outline_rounded,
        color: Colors.red,
      ),
      ReportStatEntry(
        label: 'Inventory Valuation',
        value: '\$${totalValuation.toStringAsFixed(0)}',
        icon: Icons.monetization_on_rounded,
        color: Colors.green,
      ),
    ];

    // Get list of low stock items to display inside card
    final lowStockItems = products
        .where((p) => p.stock <= p.minimumStock)
        .toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReportStatisticsCard(
          title: 'Inventory Valuation & Levels',
          entries: stats,
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.white10 : Colors.grey[200]!,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stock Alerts',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (lowStockCount + outOfStockCount) > 0
                            ? Colors.red.withValues(alpha: 0.12)
                            : Colors.green.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (lowStockCount + outOfStockCount) > 0
                            ? '${lowStockCount + outOfStockCount} Actions Required'
                            : 'Healthy Status',
                        style: TextStyle(
                          color: (lowStockCount + outOfStockCount) > 0
                              ? Colors.red
                              : Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (lowStockItems.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'All items are in healthy supply levels.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: lowStockItems.take(5).length,
                    itemBuilder: (context, index) {
                      final item = lowStockItems[index];
                      final isOutOfStock = item.stock == 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              isOutOfStock ? Icons.cancel_rounded : Icons.warning_rounded,
                              color: isOutOfStock ? Colors.red : Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              isOutOfStock ? 'Out of Stock' : '${item.stock} left (Min: ${item.minimumStock})',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isOutOfStock ? Colors.red : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
