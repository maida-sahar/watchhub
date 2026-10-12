import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../providers/product_provider.dart';
import '../../providers/order_provider.dart';
import 'widgets/date_range_picker.dart';
import 'widgets/report_filter_dialog.dart';
import 'sales_report_screen.dart';
import 'revenue_report_screen.dart';
import 'inventory_report_screen.dart';
import 'customer_report_screen.dart';

class ProductReportScreen extends StatefulWidget {
  const ProductReportScreen({super.key});

  @override
  State<ProductReportScreen> createState() => _ProductReportScreenState();
}

class _ProductReportScreenState extends State<ProductReportScreen> {
  ReportDateFilterResult _dateFilter = const ReportDateFilterResult(ReportDateFilter.thisMonth);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().watchAllProducts();
      context.read<OrderProvider>().watchAllOrders();
    });
  }

  Future<void> _openFilterDialog() async {
    final result = await showDialog<ReportDateFilterResult>(
      context: context,
      builder: (_) => ReportFilterDialog(current: _dateFilter),
    );
    if (result != null) {
      setState(() => _dateFilter = result);
    }
  }

  List<OrderModel> _ordersInRange(List<OrderModel> source, DateTimeRange range) {
    return source
        .where((o) => !o.createdAt.isBefore(range.start) && o.createdAt.isBefore(range.end))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Performance'),
        actions: [
          PopupMenuButton<Widget>(
            tooltip: 'Navigate Reports',
            icon: const Icon(Icons.analytics_outlined),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Sales Report'),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SalesReportScreen()),
                ),
              ),
              PopupMenuItem(
                child: const Text('Revenue Report'),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const RevenueReportScreen()),
                ),
              ),
              PopupMenuItem(
                child: const Text('Inventory Report'),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const InventoryReportScreen()),
                ),
              ),
              PopupMenuItem(
                child: const Text('Customer Report'),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const CustomerReportScreen()),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: DateRangeSelector(current: _dateFilter, onTap: _openFilterDialog),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer2<ProductProvider, OrderProvider>(
          builder: (context, productProv, orderProv, _) {
            final isLoading = (productProv.isLoading && productProv.products.isEmpty) ||
                (orderProv.isLoadingAllOrders && orderProv.allOrders.isEmpty);

            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final hasError = productProv.errorMessage != null || orderProv.allOrdersError != null;
            final error = productProv.errorMessage ?? orderProv.allOrdersError;
            if (hasError && productProv.products.isEmpty && orderProv.allOrders.isEmpty) {
              return _buildErrorState(error ?? 'Failed to load report data.');
            }

            final range = _dateFilter.resolve();
            final rangeOrders = _ordersInRange(orderProv.allOrders, range);
            final products = productProv.products;

            if (products.isEmpty) {
              return _buildEmptyState();
            }

            return _buildReportContent(products, rangeOrders);
          },
        ),
      ),
    );
  }

  Widget _buildReportContent(List<ProductModel> products, List<OrderModel> rangeOrders) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Count best sellers
    final sortedProducts = List<ProductModel>.from(products)
      ..sort((a, b) => b.soldCount.compareTo(a.soldCount));

    // Calculate rating aggregates
    final activeProducts = products.where((p) => p.isActive).toList();
    final inactiveProducts = products.where((p) => !p.isActive).toList();

    return Scrollbar(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // KPI statistics grid
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            children: [
              _buildStatTile('Total Watches', products.length.toString(), Icons.watch_rounded, Colors.teal),
              _buildStatTile('Active Listings', activeProducts.length.toString(), Icons.check_circle_rounded, Colors.green),
              _buildStatTile('Hidden/Inactive', inactiveProducts.length.toString(), Icons.visibility_off_rounded, Colors.grey),
              _buildStatTile('Avg rating', _computeAvgRating(products), Icons.star_rounded, Colors.amber[700]!),
            ],
          ),
          const SizedBox(height: 16),

          // Leaderboard card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Best Selling Watches',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedProducts.take(5).length,
                    separatorBuilder: (context, index) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final item = sortedProducts[index];
                      return Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '#${index + 1}',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'SKU: ${item.sku} • Brand: ${item.brandName}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item.soldCount} Units',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                '\$${(item.soldCount * item.price).toStringAsFixed(0)} volume',
                                style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Rating performance breakdown
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rating Breakdown',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildRatingProgressRow('5 ★', _getRatingCount(products, 4.5, 5.1), products.length),
                  _buildRatingProgressRow('4 ★', _getRatingCount(products, 3.5, 4.5), products.length),
                  _buildRatingProgressRow('3 ★', _getRatingCount(products, 2.5, 3.5), products.length),
                  _buildRatingProgressRow('2 ★', _getRatingCount(products, 1.5, 2.5), products.length),
                  _buildRatingProgressRow('1 ★', _getRatingCount(products, 0.0, 1.5), products.length),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingProgressRow(String starLabel, int count, int total) {
    final theme = Theme.of(context);
    final percent = total == 0 ? 0.0 : count / total;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              starLabel,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[700]!),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 32,
            child: Text(
              count.toString(),
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  String _computeAvgRating(List<ProductModel> products) {
    final rated = products.where((p) => p.totalReviews > 0).toList();
    // No reviews at all should read as "no data" (0.0), not a fabricated
    // perfect score — showing 5.0 here previously misrepresented products
    // that have never been reviewed as flawlessly rated.
    if (rated.isEmpty) return '0.0';
    final sum = rated.fold<double>(0.0, (acc, p) => acc + p.averageRating);
    return (sum / rated.length).toStringAsFixed(1);
  }

  int _getRatingCount(List<ProductModel> products, double min, double max) {
    return products.where((p) => p.averageRating >= min && p.averageRating < max).length;
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 64),
            const SizedBox(height: 16),
            Text(
              'Error Loading Report',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.watch_rounded, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4), size: 64),
            const SizedBox(height: 16),
            Text(
              'No Products Found',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please add watches to the catalog first to generate performance metrics.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
