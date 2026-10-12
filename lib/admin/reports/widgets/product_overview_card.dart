import 'package:flutter/material.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';
import 'report_statistics_card.dart';

class ProductOverviewCard extends StatelessWidget {
  final List<ProductModel> products;
  final List<OrderModel> orders;

  const ProductOverviewCard({
    super.key,
    required this.products,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate metrics
    final totalProducts = products.length;
    final activeProducts = products.where((p) => p.isActive).length;
    final inactiveProducts = totalProducts - activeProducts;

    // Calculate best sellers using order lines if possible, or from product soldCount
    // The requirement says "Best Selling Products". We can look at `products`' `soldCount` field which is tracked,
    // or calculate it dynamically from the orders. Let's do it using `soldCount` of `ProductModel` first, or aggregate
    // orders. Aggregating `soldCount` is extremely fast and acts as the denormalized database source of truth.
    // Let's sort products by soldCount in descending order.
    final bestSellers = List<ProductModel>.from(products)
      ..sort((a, b) => b.soldCount.compareTo(a.soldCount));

    // Calculate average rating. No reviews at all should read as "no
    // data" (0.0), not a fabricated perfect score.
    final ratedProducts = products.where((p) => p.totalReviews > 0).toList();
    final avgRating = ratedProducts.isEmpty
        ? 0.0
        : ratedProducts.fold<double>(0.0, (sum, p) => sum + p.averageRating) / ratedProducts.length;

    final stats = [
      ReportStatEntry(
        label: 'Total Products',
        value: totalProducts.toString(),
        icon: Icons.watch_rounded,
        color: Colors.teal,
      ),
      ReportStatEntry(
        label: 'Active Listed',
        value: activeProducts.toString(),
        icon: Icons.check_circle_rounded,
        color: Colors.green,
      ),
      ReportStatEntry(
        label: 'Inactive / Hidden',
        value: inactiveProducts.toString(),
        icon: Icons.visibility_off_rounded,
        color: Colors.grey,
      ),
      ReportStatEntry(
        label: 'Average Rating',
        value: '${avgRating.toStringAsFixed(1)} ★',
        icon: Icons.star_rounded,
        color: Colors.amber[700],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReportStatisticsCard(
          title: 'Catalog & Performance',
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
                Text(
                  'Best Sellers',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (bestSellers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Center(
                      child: Text(
                        'No product performance data available.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: bestSellers.take(3).length,
                    itemBuilder: (context, index) {
                      final item = bestSellers[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.emoji_events_rounded,
                                color: Colors.amber[800],
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'SKU: ${item.sku} • Price: \$${item.price.toStringAsFixed(0)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${item.soldCount} sold',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
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
