import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import 'reports_dashboard_screen.dart';
import 'sales_report_screen.dart';
import 'revenue_report_screen.dart';
import 'customer_report_screen.dart';
import 'product_report_screen.dart';
import 'export_report_screen.dart';
import 'widgets/date_range_picker.dart';
import 'widgets/report_filter_dialog.dart';
import 'widgets/inventory_summary_card.dart';
import 'widgets/inventory_chart.dart';
import 'widgets/low_stock_card.dart';
import 'widgets/out_of_stock_card.dart';

/// Admin Inventory Report screen: a real-time inventory dashboard
/// showing stock levels, valuation, low/out-of-stock items, best/worst
/// sellers, and stock movement trends in the selected date range.
class InventoryReportScreen extends StatefulWidget {
  const InventoryReportScreen({super.key});

  @override
  State<InventoryReportScreen> createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Report'),
        actions: [
          PopupMenuButton<Widget>(
            tooltip: 'Navigate Reports',
            icon: const Icon(Icons.analytics_outlined),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Reports Dashboard'),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ReportsDashboardScreen()),
                ),
              ),
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
                child: const Text('Customer Report'),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const CustomerReportScreen()),
                ),
              ),
              PopupMenuItem(
                child: const Text('Product Performance'),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ProductReportScreen()),
                ),
              ),
              PopupMenuItem(
                child: const Text('Export Reports'),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ExportReportScreen()),
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
            // Show loading if either provider is loading and has empty list
            if ((productProv.isLoading && productProv.products.isEmpty) ||
                (orderProv.isLoadingAllOrders && orderProv.allOrders.isEmpty)) {
              return const Center(child: CircularProgressIndicator());
            }

            // Show error state if either has error
            if (productProv.errorMessage != null && productProv.products.isEmpty) {
              return _buildErrorState(productProv.errorMessage!);
            }
            if (orderProv.allOrdersError != null && orderProv.allOrders.isEmpty) {
              return _buildErrorState(orderProv.allOrdersError!);
            }

            // Show empty state if products list is empty
            if (productProv.products.isEmpty) {
              return _buildEmptyState();
            }

            final products = productProv.products;
            final allOrders = orderProv.allOrders;
            final currency = allOrders.isNotEmpty ? allOrders.first.currency : 'USD';

            // Calculate Inventory snapshot stats (Overall snapshot)
            final totalProducts = products.length;
            final activeProducts = products.where((p) => p.isActive).length;
            final inactiveProducts = products.where((p) => !p.isActive).length;
            final inStockProducts = products.where((p) => p.stock > p.minimumStock).length;
            final lowStockProducts = products.where((p) => p.stock > 0 && p.stock <= p.minimumStock).length;
            final outOfStockProducts = products.where((p) => p.stock == 0).length;

            final inventoryValue = products.fold<double>(
              0.0,
              (sum, p) => sum + (p.price * p.stock),
            );

            // Scoped stats based on the selected date filter range
            final range = _dateFilter.resolve();
            final ordersInPeriod = _ordersInRange(allOrders, range);

            // Build map of units sold per product in selected period
            final soldQuantities = <String, int>{};
            for (final order in ordersInPeriod) {
              final status = order.orderStatus.trim().toLowerCase();
              if (status == 'cancelled' || status == 'returned') continue;

              for (final item in order.items) {
                soldQuantities[item.productId] = (soldQuantities[item.productId] ?? 0) + item.quantity;
              }
            }

            // Map all products to their sales during this period (including 0 sales)
            final productSales = products.map((p) {
              return _ProductPeriodSales(
                product: p,
                soldCount: soldQuantities[p.id] ?? 0,
              );
            }).toList();

            // Rank Best / Worst Selling Products for this period
            final bestSelling = List<_ProductPeriodSales>.from(productSales)
              ..sort((a, b) => b.soldCount.compareTo(a.soldCount));
            final bestSellersSubset = bestSelling.take(5).where((ps) => ps.soldCount > 0).toList();

            final worstSelling = List<_ProductPeriodSales>.from(productSales)
              ..sort((a, b) => a.soldCount.compareTo(b.soldCount));
            final worstSellersSubset = worstSelling.take(5).toList();

            // Stock Movement Summary for the selected period
            final totalUnitsSoldInPeriod = soldQuantities.values.fold<int>(0, (sum, val) => sum + val);

            return RefreshIndicator(
              onRefresh: () async {
                context.read<ProductProvider>().watchAllProducts();
                context.read<OrderProvider>().watchAllOrders();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InventorySummaryCard(
                      currency: currency,
                      totalProducts: totalProducts,
                      activeProducts: activeProducts,
                      inactiveProducts: inactiveProducts,
                      inStockProducts: inStockProducts,
                      lowStockProducts: lowStockProducts,
                      outOfStockProducts: outOfStockProducts,
                      inventoryValue: inventoryValue,
                    ),
                    const SizedBox(height: 16),
                    // Stock Movement summary card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.swap_horiz,
                                color: theme.colorScheme.onPrimaryContainer,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stock Movement Summary',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'During this period, $totalUnitsSoldInPeriod units were sold out of inventory.',
                                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InventoryChart(products: products),
                    const SizedBox(height: 16),
                    _buildBestWorstSellers(context, bestSellersSubset, worstSellersSubset, currency),
                    const SizedBox(height: 16),
                    LowStockCard(products: products),
                    const SizedBox(height: 16),
                    OutOfStockCard(products: products),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBestWorstSellers(
    BuildContext context,
    List<_ProductPeriodSales> best,
    List<_ProductPeriodSales> worst,
    String currency,
  ) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Trends (Selected Period)',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TabBar(
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.outline,
                indicatorColor: theme.colorScheme.primary,
                tabs: const [
                  Tab(text: 'Best Selling'),
                  Tab(text: 'Worst Selling'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 250,
                child: TabBarView(
                  children: [
                    _buildSalesList(context, best, currency, isBest: true),
                    _buildSalesList(context, worst, currency, isBest: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesList(
    BuildContext context,
    List<_ProductPeriodSales> list,
    String currency, {
    required bool isBest,
  }) {
    final theme = Theme.of(context);

    if (list.isEmpty) {
      return Center(
        child: Text(
          isBest ? 'No product sales recorded in this period.' : 'No products found.',
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => const Divider(height: 12),
      itemBuilder: (context, index) {
        final item = list[index];
        final rank = index + 1;

        return Row(
          children: [
            // Rank Number
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isBest && rank <= 3
                    ? (rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey[400] : Colors.brown[300]))
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rank',
                style: TextStyle(
                  color: isBest && rank <= 3 ? Colors.white : theme.colorScheme.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Product Thumbnail
            if (item.product.thumbnail.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  item.product.thumbnail,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 36,
                    height: 36,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.image, size: 18),
                  ),
                ),
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.image, size: 18),
              ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Price: $currency ${item.product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Sales Units
            Text(
              '${item.soldCount} sold',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isBest ? Colors.teal : Colors.red[400],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading report',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Products Found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have not added any products to your catalog yet.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPeriodSales {
  final ProductModel product;
  final int soldCount;

  _ProductPeriodSales({required this.product, required this.soldCount});
}
