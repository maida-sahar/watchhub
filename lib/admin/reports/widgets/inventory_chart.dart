import 'package:flutter/material.dart';
import '../../../models/product_model.dart';

/// Renders the Inventory Status Chart (segmented bar with percentages)
/// and the Product Stock Chart (visualizing stock levels of key products).
class InventoryChart extends StatelessWidget {
  const InventoryChart({
    super.key,
    required this.products,
  });

  final List<ProductModel> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Compute status stats
    final total = products.length;
    final inStock = products.where((p) => p.stock > p.minimumStock).length;
    final lowStock = products.where((p) => p.stock > 0 && p.stock <= p.minimumStock).length;
    final outOfStock = products.where((p) => p.stock == 0).length;

    final inStockPct = total > 0 ? (inStock / total) : 0.0;
    final lowStockPct = total > 0 ? (lowStock / total) : 0.0;
    final outOfStockPct = total > 0 ? (outOfStock / total) : 0.0;

    // Get top 6 products with lowest stock (excluding out of stock first, or just sorted by stock ascending)
    final sortedByStock = List<ProductModel>.from(products)
      ..sort((a, b) => a.stock.compareTo(b.stock));
    final keyProducts = sortedByStock.take(6).toList();
    final maxStockVal = keyProducts.isEmpty
        ? 0
        : keyProducts.map((p) => p.stock).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Status Distribution',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (total == 0)
              Text(
                'No products available.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            else ...[
              // Segmented Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 24,
                  child: Row(
                    children: [
                      if (inStockPct > 0)
                        Expanded(
                          // `flex` must be a positive integer — a small
                          // percentage (e.g. 0.4%) rounds to 0, which
                          // trips Flutter's `flex > 0` assertion on
                          // Expanded and crashes the report screen.
                          flex: (inStockPct * 100).round().clamp(1, 100),
                          child: Container(
                            color: Colors.teal,
                            alignment: Alignment.center,
                            child: Text(
                              '${(inStockPct * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      if (lowStockPct > 0)
                        Expanded(
                          flex: (lowStockPct * 100).round().clamp(1, 100),
                          child: Container(
                            color: Colors.orange,
                            alignment: Alignment.center,
                            child: Text(
                              '${(lowStockPct * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      if (outOfStockPct > 0)
                        Expanded(
                          flex: (outOfStockPct * 100).round().clamp(1, 100),
                          child: Container(
                            color: Colors.red,
                            alignment: Alignment.center,
                            child: Text(
                              '${(outOfStockPct * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _legendItem('In Stock ($inStock)', Colors.teal),
                  _legendItem('Low Stock ($lowStock)', Colors.orange),
                  _legendItem('Out of Stock ($outOfStock)', Colors.red),
                ],
              ),
            ],
            const Divider(height: 32),
            Text(
              'Critical Stock Levels (Lowest Stock)',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (keyProducts.isEmpty)
              Text(
                'No product stock data.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              )
            else
              SizedBox(
                height: 140,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: keyProducts.map((p) {
                    final fraction = maxStockVal == 0 ? 0.0 : p.stock / maxStockVal;
                    final isLow = p.stock <= p.minimumStock;
                    final isOut = p.stock == 0;
                    final barColor = isOut
                        ? Colors.red
                        : (isLow ? Colors.orange : theme.colorScheme.primary);

                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${p.stock}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: barColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 80 * fraction + 4, // Ensure at least a tiny sliver is shown
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              p.name,
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
