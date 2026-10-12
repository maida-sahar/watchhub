import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import 'reports_dashboard_screen.dart';
import 'sales_report_screen.dart';
import 'inventory_report_screen.dart';
import 'customer_report_screen.dart';
import 'product_report_screen.dart';
import 'export_report_screen.dart';
import 'widgets/date_range_picker.dart';
import 'widgets/report_filter_dialog.dart';
import 'widgets/revenue_chart.dart';
import 'widgets/revenue_summary_card.dart';

/// Admin Revenue Report screen: a fixed-window revenue dashboard
/// (today/week/month/year/total, always shown regardless of the active
/// filter), plus growth, trend, and category/brand breakdowns scoped to
/// an admin-selected date range.
///
/// All figures are computed client-side from `OrderProvider.allOrders`
/// (already a real-time Firestore stream) — no new Firestore query is
/// made for any of this screen's reporting.
///
/// This screen talks ONLY to `OrderProvider` — it never imports or
/// calls Firebase, `OrderService`, or `OrderRepository` directly.
class RevenueReportScreen extends StatefulWidget {
  const RevenueReportScreen({super.key});

  @override
  State<RevenueReportScreen> createState() => _RevenueReportScreenState();
}

class _RevenueReportScreenState extends State<RevenueReportScreen> {
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

  double _sumValidRevenue(List<OrderModel> orders) {
    return orders
        .where((o) => o.orderStatus.trim().toLowerCase() != 'cancelled' &&
            o.orderStatus.trim().toLowerCase() != 'returned')
        .fold<double>(0, (sum, o) => sum + o.grandTotal);
  }

  List<RevenueBucket> _buildMonthlyBuckets(List<OrderModel> allOrders) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    final buckets = <String, double>{};
    final labels = <String>[];

    for (var i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${months[month.month - 1]} ${month.year}';
      buckets[key] = 0;
      labels.add(key);
    }

    for (final order in allOrders) {
      final status = order.orderStatus.trim().toLowerCase();
      if (status == 'cancelled' || status == 'returned') continue;
      final key = '${months[order.createdAt.month - 1]} ${order.createdAt.year}';
      if (buckets.containsKey(key)) {
        buckets[key] = (buckets[key] ?? 0) + order.grandTotal;
      }
    }

    return labels.map((label) => RevenueBucket(label: label, amount: buckets[label] ?? 0)).toList();
  }

  List<RevenueBucket> _buildTrendBuckets(List<OrderModel> ordersInPeriod, DateTimeRange range) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final totalDays = range.end.difference(range.start).inDays;
    final buckets = <String, double>{};

    if (totalDays <= 31) {
      for (var i = 0; i < totalDays; i++) {
        final day = range.start.add(Duration(days: i));
        buckets['${day.day} ${months[day.month - 1]}'] = 0;
      }
      for (final order in ordersInPeriod) {
        final status = order.orderStatus.trim().toLowerCase();
        if (status == 'cancelled' || status == 'returned') continue;
        final key = '${order.createdAt.day} ${months[order.createdAt.month - 1]}';
        if (buckets.containsKey(key)) {
          buckets[key] = (buckets[key] ?? 0) + order.grandTotal;
        }
      }
    } else {
      var cursor = DateTime(range.start.year, range.start.month, 1);
      while (cursor.isBefore(range.end)) {
        buckets['${months[cursor.month - 1]} ${cursor.year}'] = 0;
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }
      for (final order in ordersInPeriod) {
        final status = order.orderStatus.trim().toLowerCase();
        if (status == 'cancelled' || status == 'returned') continue;
        final key = '${months[order.createdAt.month - 1]} ${order.createdAt.year}';
        if (buckets.containsKey(key)) {
          buckets[key] = (buckets[key] ?? 0) + order.grandTotal;
        }
      }
    }

    return buckets.entries.map((e) => RevenueBucket(label: e.key, amount: e.value)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue Report'),
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

            if (provider.allOrders.isEmpty) {
              return _buildEmptyState();
            }

            final currency = provider.allOrders.first.currency;
            final allOrders = provider.allOrders;

            // Fixed windows — always shown regardless of the active filter.
            final todayRevenue = _sumValidRevenue(_ordersInRange(allOrders, ReportDateFilter.today.resolve()));
            final weeklyRevenue = _sumValidRevenue(_ordersInRange(allOrders, ReportDateFilter.thisWeek.resolve()));
            final monthlyRevenue = _sumValidRevenue(_ordersInRange(allOrders, ReportDateFilter.thisMonth.resolve()));
            final yearlyRevenue = _sumValidRevenue(_ordersInRange(allOrders, ReportDateFilter.thisYear.resolve()));
            final totalRevenue = _sumValidRevenue(allOrders);

            // Filter-scoped figures.
            final range = _dateFilter.resolve();
            final previousRange = _dateFilter.resolvePrevious();
            final ordersInPeriod = _ordersInRange(allOrders, range);
            final ordersInPreviousPeriod = _ordersInRange(allOrders, previousRange);
            final currentPeriodRevenue = _sumValidRevenue(ordersInPeriod);
            final previousPeriodRevenue = _sumValidRevenue(ordersInPreviousPeriod);
            final growthPercent = previousPeriodRevenue == 0
                ? null
                : ((currentPeriodRevenue - previousPeriodRevenue) / previousPeriodRevenue) * 100;

            return RefreshIndicator(
              onRefresh: () async => context.read<OrderProvider>().watchAllOrders(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RevenueSummaryCard(
                      currency: currency,
                      todayRevenue: todayRevenue,
                      weeklyRevenue: weeklyRevenue,
                      monthlyRevenue: monthlyRevenue,
                      yearlyRevenue: yearlyRevenue,
                      totalRevenue: totalRevenue,
                      revenueGrowthPercent: growthPercent,
                    ),
                    const SizedBox(height: 16),
                    RevenueChart(
                      currency: currency,
                      monthlyBuckets: _buildMonthlyBuckets(allOrders),
                      trendBuckets: _buildTrendBuckets(ordersInPeriod, range),
                    ),
                    const SizedBox(height: 16),
                    _buildRevenueByCategory(context, ordersInPeriod, currency),
                    const SizedBox(height: 16),
                    _buildRevenueByBrand(context, ordersInPeriod, currency),
                    const SizedBox(height: 16),
                    _buildProfitSummary(context),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRevenueByCategory(BuildContext context, List<OrderModel> orders, String currency) {
    final theme = Theme.of(context);
    final Map<String, double> byCategory = {};

    for (final order in orders) {
      if (order.orderStatus.trim().toLowerCase() == 'cancelled') continue;
      for (final item in order.items) {
        if (item.categoryName.isEmpty) continue;
        final revenue = (item.discountPrice > 0 ? item.discountPrice : item.price) * item.quantity;
        byCategory[item.categoryName] = (byCategory[item.categoryName] ?? 0) + revenue;
      }
    }

    return _buildBreakdownCard(context, title: 'Revenue by Category', data: byCategory, currency: currency);
  }

  Widget _buildRevenueByBrand(BuildContext context, List<OrderModel> orders, String currency) {
    final Map<String, double> byBrand = {};

    for (final order in orders) {
      if (order.orderStatus.trim().toLowerCase() == 'cancelled') continue;
      for (final item in order.items) {
        if (item.brandName.isEmpty) continue;
        final revenue = (item.discountPrice > 0 ? item.discountPrice : item.price) * item.quantity;
        byBrand[item.brandName] = (byBrand[item.brandName] ?? 0) + revenue;
      }
    }

    return _buildBreakdownCard(context, title: 'Revenue by Brand', data: byBrand, currency: currency);
  }

  Widget _buildBreakdownCard(
    BuildContext context, {
    required String title,
    required Map<String, double> data,
    required String currency,
  }) {
    final theme = Theme.of(context);
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(6).toList();
    final maxValue = top.isEmpty ? 0.0 : top.first.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (top.isEmpty)
              Text('No data for this period.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))
            else
              ...top.map((entry) {
                final fraction = maxValue <= 0 ? 0.0 : entry.value / maxValue;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(entry.key, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                Container(
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                                Container(
                                  height: 14,
                                  width: constraints.maxWidth * fraction,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('$currency ${entry.value.toStringAsFixed(2)}', style: theme.textTheme.bodySmall),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitSummary(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profit Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Profit data is not available — cost price isn\'t tracked in the current '
                    'product/order schema, so margin can\'t be computed yet.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.show_chart, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('No revenue data yet.', style: Theme.of(context).textTheme.bodyMedium),
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