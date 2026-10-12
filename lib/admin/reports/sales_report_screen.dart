import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import 'reports_dashboard_screen.dart';
import 'revenue_report_screen.dart';
import 'inventory_report_screen.dart';
import 'customer_report_screen.dart';
import 'product_report_screen.dart';
import 'export_report_screen.dart';
import 'widgets/date_range_picker.dart';
import 'widgets/report_filter_dialog.dart';
import 'widgets/sales_chart.dart';
import 'widgets/sales_summary_card.dart';

/// Admin Sales Report screen: totals, order-outcome breakdown, best
/// sellers, and top customers — all computed client-side from
/// `OrderProvider.allOrders` (already a real-time Firestore stream),
/// filtered by an admin-selected date range.
///
/// This screen talks ONLY to `OrderProvider` — it never imports or
/// calls Firebase, `OrderService`, or `OrderRepository` directly.
class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  ReportDateFilterResult _dateFilter = const ReportDateFilterResult(ReportDateFilter.thisMonth);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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

  List<SalesBucket> _buildDailyBuckets(List<OrderModel> ordersInPeriod, DateTimeRange range) {
    final totalDays = range.end.difference(range.start).inDays;
    final byDay = <String, int>{};

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    if (totalDays <= 31) {
      // Bucket by day.
      for (var i = 0; i < totalDays; i++) {
        final day = range.start.add(Duration(days: i));
        byDay['${day.day} ${months[day.month - 1]}'] = 0;
      }
      for (final order in ordersInPeriod) {
        final key = '${order.createdAt.day} ${months[order.createdAt.month - 1]}';
        if (byDay.containsKey(key)) {
          byDay[key] = (byDay[key] ?? 0) + 1;
        }
      }
    } else {
      // Range longer than a month: bucket by calendar month instead,
      // so the chart doesn't render an unreadable number of bars.
      var cursor = DateTime(range.start.year, range.start.month, 1);
      while (cursor.isBefore(range.end)) {
        byDay['${months[cursor.month - 1]} ${cursor.year}'] = 0;
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }
      for (final order in ordersInPeriod) {
        final key = '${months[order.createdAt.month - 1]} ${order.createdAt.year}';
        if (byDay.containsKey(key)) {
          byDay[key] = (byDay[key] ?? 0) + 1;
        }
      }
    }

    return byDay.entries.map((e) => SalesBucket(label: e.key, count: e.value)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
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
        child: Consumer<OrderProvider>(
          builder: (context, provider, _) {
            if (provider.isLoadingAllOrders && provider.allOrders.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.allOrdersError != null && provider.allOrders.isEmpty) {
              return _buildErrorState(provider.allOrdersError!);
            }

            final range = _dateFilter.resolve();
            final previousRange = _dateFilter.resolvePrevious();
            final ordersInPeriod = _ordersInRange(provider.allOrders, range);
            final ordersInPreviousPeriod = _ordersInRange(provider.allOrders, previousRange);

            if (ordersInPeriod.isEmpty && provider.allOrders.isNotEmpty) {
              return _buildEmptyState();
            }
            if (provider.allOrders.isEmpty) {
              return _buildEmptyState();
            }

            final currency = ordersInPeriod.isNotEmpty
                ? ordersInPeriod.first.currency
                : (provider.allOrders.isNotEmpty ? provider.allOrders.first.currency : '');

            final validOrders =
                ordersInPeriod.where((o) => o.orderStatus.trim().toLowerCase() != 'cancelled').toList();
            final totalSales = validOrders.fold<double>(0, (sum, o) => sum + o.grandTotal);
            final completedOrders =
                ordersInPeriod.where((o) => o.orderStatus.trim().toLowerCase() == 'delivered').length;
            final cancelledOrders =
                ordersInPeriod.where((o) => o.orderStatus.trim().toLowerCase() == 'cancelled').length;
            final returnedOrders =
                ordersInPeriod.where((o) => o.orderStatus.trim().toLowerCase() == 'returned').length;
            final pendingOrders =
                ordersInPeriod.length - completedOrders - cancelledOrders - returnedOrders;
            final averageOrderValue = validOrders.isEmpty ? 0.0 : totalSales / validOrders.length;

            return RefreshIndicator(
              onRefresh: () async => context.read<OrderProvider>().watchAllOrders(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SalesSummaryCard(
                      currency: currency,
                      totalSales: totalSales,
                      totalOrders: ordersInPeriod.length,
                      completedOrders: completedOrders,
                      pendingOrders: pendingOrders < 0 ? 0 : pendingOrders,
                      cancelledOrders: cancelledOrders,
                      returnedOrders: returnedOrders,
                      averageOrderValue: averageOrderValue,
                    ),
                    const SizedBox(height: 16),
                    SalesChart(
                      dailyBuckets: _buildDailyBuckets(ordersInPeriod, range),
                      currentPeriodOrders: ordersInPeriod.length,
                      previousPeriodOrders: ordersInPreviousPeriod.length,
                    ),
                    const SizedBox(height: 16),
                    _buildBestSellingProducts(context, validOrders, currency),
                    const SizedBox(height: 16),
                    _buildBestSellingCategories(context, validOrders, currency),
                    const SizedBox(height: 16),
                    _buildTopCustomers(context, provider, validOrders, currency),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBestSellingProducts(BuildContext context, List<OrderModel> orders, String currency) {
    final theme = Theme.of(context);
    final Map<String, _ProductAggregate> byProduct = {};

    for (final order in orders) {
      for (final item in order.items) {
        final existing = byProduct[item.productId];
        final revenue = (item.discountPrice > 0 ? item.discountPrice : item.price) * item.quantity;
        if (existing == null) {
          byProduct[item.productId] = _ProductAggregate(
            name: item.productName,
            quantity: item.quantity,
            revenue: revenue,
          );
        } else {
          byProduct[item.productId] = _ProductAggregate(
            name: existing.name,
            quantity: existing.quantity + item.quantity,
            revenue: existing.revenue + revenue,
          );
        }
      }
    }

    final sorted = byProduct.values.toList()..sort((a, b) => b.quantity.compareTo(a.quantity));
    final top = sorted.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Best Selling Products', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (top.isEmpty)
              Text('No product sales in this period.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
            else
              ...top.asMap().entries.map((e) {
                final rank = e.key + 1;
                final product = e.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 12, child: Text('$rank', style: theme.textTheme.labelSmall)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(product.name,
                            style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Text('${product.quantity} sold', style: theme.textTheme.bodySmall),
                      const SizedBox(width: 10),
                      Text('$currency ${product.revenue.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBestSellingCategories(BuildContext context, List<OrderModel> orders, String currency) {
    final theme = Theme.of(context);
    final Map<String, _CategoryAggregate> byCategory = {};

    for (final order in orders) {
      for (final item in order.items) {
        if (item.categoryId.isEmpty) continue;
        final revenue = (item.discountPrice > 0 ? item.discountPrice : item.price) * item.quantity;
        final existing = byCategory[item.categoryId];
        if (existing == null) {
          byCategory[item.categoryId] =
              _CategoryAggregate(name: item.categoryName, quantity: item.quantity, revenue: revenue);
        } else {
          byCategory[item.categoryId] = _CategoryAggregate(
            name: existing.name,
            quantity: existing.quantity + item.quantity,
            revenue: existing.revenue + revenue,
          );
        }
      }
    }

    final sorted = byCategory.values.toList()..sort((a, b) => b.quantity.compareTo(a.quantity));
    final top = sorted.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Best Selling Categories', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (top.isEmpty)
              Text('No category sales in this period.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
            else
              ...top.map((category) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(category.name,
                            style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Text('${category.quantity} sold', style: theme.textTheme.bodySmall),
                      const SizedBox(width: 10),
                      Text('$currency ${category.revenue.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCustomers(
    BuildContext context,
    OrderProvider provider,
    List<OrderModel> orders,
    String currency,
  ) {
    final theme = Theme.of(context);
    final Map<String, double> spendByUser = {};
    final Map<String, int> ordersByUser = {};

    for (final order in orders) {
      if (order.userId.isEmpty) continue;
      spendByUser[order.userId] = (spendByUser[order.userId] ?? 0) + order.grandTotal;
      ordersByUser[order.userId] = (ordersByUser[order.userId] ?? 0) + 1;
    }

    final sortedUserIds = spendByUser.keys.toList()
      ..sort((a, b) => spendByUser[b]!.compareTo(spendByUser[a]!));
    final topUserIds = sortedUserIds.take(5).toList();
    final profiles = provider.customerProfilesByUserId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Customers', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (topUserIds.isEmpty)
              Text('No customer data in this period.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
            else
              ...topUserIds.asMap().entries.map((e) {
                final rank = e.key + 1;
                final userId = e.value;
                final name = profiles[userId]?.name ?? 'Customer $userId';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 12, child: Text('$rank', style: theme.textTheme.labelSmall)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(name, style: theme.textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Text('${ordersByUser[userId]} orders', style: theme.textTheme.bodySmall),
                      const SizedBox(width: 10),
                      Text('$currency ${spendByUser[userId]!.toStringAsFixed(2)}',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              }),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart_outlined, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('No orders in the selected period.', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.read<OrderProvider>().watchAllOrders(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductAggregate {
  const _ProductAggregate({required this.name, required this.quantity, required this.revenue});
  final String name;
  final int quantity;
  final double revenue;
}

class _CategoryAggregate {
  const _CategoryAggregate({required this.name, required this.quantity, required this.revenue});
  final String name;
  final int quantity;
  final double revenue;
}