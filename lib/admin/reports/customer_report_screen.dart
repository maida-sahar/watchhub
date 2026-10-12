import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import 'reports_dashboard_screen.dart';
import 'sales_report_screen.dart';
import 'revenue_report_screen.dart';
import 'inventory_report_screen.dart';
import 'product_report_screen.dart';
import 'export_report_screen.dart';
import 'widgets/date_range_picker.dart';
import 'widgets/report_filter_dialog.dart';
import 'widgets/customer_summary_card.dart';
import 'widgets/customer_statistics_chart.dart';
import 'widgets/top_customers_card.dart';

/// Admin Customer Report screen: a real-time dashboard showing customer signup growth,
/// returning customer ratios, purchase trends, and top customer leaderboards.
class CustomerReportScreen extends StatefulWidget {
  const CustomerReportScreen({super.key});

  @override
  State<CustomerReportScreen> createState() => _CustomerReportScreenState();
}

class _CustomerReportScreenState extends State<CustomerReportScreen> {
  ReportDateFilterResult _dateFilter = const ReportDateFilterResult(ReportDateFilter.thisMonth);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().watchCustomers();
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

  List<UserModel> _customersCreatedInRange(List<UserModel> source, DateTimeRange range) {
    return source
        .where((u) => !u.createdAt.isBefore(range.start) && u.createdAt.isBefore(range.end))
        .toList();
  }

  List<OrderModel> _ordersInRange(List<OrderModel> source, DateTimeRange range) {
    return source
        .where((o) => !o.createdAt.isBefore(range.start) && o.createdAt.isBefore(range.end))
        .toList();
  }

  List<CustomerChartBucket> _buildGrowthBuckets(List<UserModel> customers, DateTimeRange range) {
    final totalDays = range.end.difference(range.start).inDays;
    final byPeriod = <String, double>{};
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    if (totalDays <= 31) {
      // Day buckets
      for (var i = 0; i < totalDays; i++) {
        final date = range.start.add(Duration(days: i));
        byPeriod['${date.day} ${months[date.month - 1]}'] = 0;
      }
      for (final u in customers) {
        if (u.createdAt.isBefore(range.start) || u.createdAt.isAfter(range.end)) continue;
        final key = '${u.createdAt.day} ${months[u.createdAt.month - 1]}';
        if (byPeriod.containsKey(key)) {
          byPeriod[key] = (byPeriod[key] ?? 0) + 1;
        }
      }
    } else {
      // Month buckets
      var cursor = DateTime(range.start.year, range.start.month, 1);
      while (cursor.isBefore(range.end)) {
        byPeriod['${months[cursor.month - 1]} ${cursor.year}'] = 0;
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }
      for (final u in customers) {
        if (u.createdAt.isBefore(range.start) || u.createdAt.isAfter(range.end)) continue;
        final key = '${months[u.createdAt.month - 1]} ${u.createdAt.year}';
        if (byPeriod.containsKey(key)) {
          byPeriod[key] = (byPeriod[key] ?? 0) + 1;
        }
      }
    }

    return byPeriod.entries
        .map((e) => CustomerChartBucket(label: e.key, value: e.value))
        .toList();
  }

  List<CustomerChartBucket> _buildSpendingBuckets(List<OrderModel> orders, DateTimeRange range) {
    final totalDays = range.end.difference(range.start).inDays;
    final byPeriod = <String, double>{};
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final validOrders = orders
        .where((o) => o.orderStatus.trim().toLowerCase() != 'cancelled' &&
            o.orderStatus.trim().toLowerCase() != 'returned')
        .toList();

    if (totalDays <= 31) {
      // Day buckets
      for (var i = 0; i < totalDays; i++) {
        final date = range.start.add(Duration(days: i));
        byPeriod['${date.day} ${months[date.month - 1]}'] = 0;
      }
      for (final o in validOrders) {
        final key = '${o.createdAt.day} ${months[o.createdAt.month - 1]}';
        if (byPeriod.containsKey(key)) {
          byPeriod[key] = (byPeriod[key] ?? 0) + o.grandTotal;
        }
      }
    } else {
      // Month buckets
      var cursor = DateTime(range.start.year, range.start.month, 1);
      while (cursor.isBefore(range.end)) {
        byPeriod['${months[cursor.month - 1]} ${cursor.year}'] = 0;
        cursor = DateTime(cursor.year, cursor.month + 1, 1);
      }
      for (final o in validOrders) {
        final key = '${months[o.createdAt.month - 1]} ${o.createdAt.year}';
        if (byPeriod.containsKey(key)) {
          byPeriod[key] = (byPeriod[key] ?? 0) + o.grandTotal;
        }
      }
    }

    return byPeriod.entries
        .map((e) => CustomerChartBucket(label: e.key, value: e.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Report'),
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
                child: const Text('Inventory Report'),
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const InventoryReportScreen()),
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
        child: Consumer<UserProvider>(
          builder: (context, userProv, _) {
            if (userProv.isLoading && userProv.customers.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (userProv.errorMessage != null && userProv.customers.isEmpty) {
              return _buildErrorState(userProv.errorMessage!);
            }

            if (userProv.customers.isEmpty) {
              return _buildEmptyState();
            }

            final customers = userProv.customers;
            final allOrders = userProv.allOrders;
            final currency = allOrders.isNotEmpty ? allOrders.first.currency : 'USD';

            // Selected date range
            final range = _dateFilter.resolve();
            final previousRange = _dateFilter.resolvePrevious();

            // Calculate Customer Growth metrics
            final currentPeriodSignups = _customersCreatedInRange(customers, range).length;
            final prevPeriodSignups = _customersCreatedInRange(customers, previousRange).length;
            final customerGrowthPercent = prevPeriodSignups == 0
                ? null
                : ((currentPeriodSignups - prevPeriodSignups) / prevPeriodSignups) * 100;

            // Group orders by customer overall vs in selected period
            final customerOrderCountsOverall = <String, int>{};
            final customerSpendingPeriod = <String, double>{};
            final customerOrderCountsPeriod = <String, int>{};

            // Process overall orders (to determine active vs returning overall)
            for (final order in allOrders) {
              final status = order.orderStatus.trim().toLowerCase();
              if (status == 'cancelled' || status == 'returned') continue;

              customerOrderCountsOverall[order.userId] = (customerOrderCountsOverall[order.userId] ?? 0) + 1;
            }

            // Process period orders
            final ordersInPeriod = _ordersInRange(allOrders, range);
            for (final order in ordersInPeriod) {
              final status = order.orderStatus.trim().toLowerCase();
              if (status == 'cancelled' || status == 'returned') continue;

              customerSpendingPeriod[order.userId] = (customerSpendingPeriod[order.userId] ?? 0.0) + order.grandTotal;
              customerOrderCountsPeriod[order.userId] = (customerOrderCountsPeriod[order.userId] ?? 0) + 1;
            }

            // Returning Customers: customers with >= 2 orders overall
            final returningCustomersCount = customerOrderCountsOverall.values.where((c) => c >= 2).length;

            // Total Customer Orders in period
            final totalOrdersInPeriod = ordersInPeriod
                .where((o) => o.orderStatus.trim().toLowerCase() != 'cancelled' &&
                    o.orderStatus.trim().toLowerCase() != 'returned')
                .length;

            // Total spending in period
            final totalSpendingInPeriod = ordersInPeriod
                .where((o) => o.orderStatus.trim().toLowerCase() != 'cancelled' &&
                    o.orderStatus.trim().toLowerCase() != 'returned')
                .fold<double>(0.0, (sum, o) => sum + o.grandTotal);

            // Average customer spending per customer who made a purchase in this period
            final customersWhoOrderedInPeriod = customerOrderCountsPeriod.length;
            final averageSpending = customersWhoOrderedInPeriod > 0
                ? (totalSpendingInPeriod / customersWhoOrderedInPeriod)
                : 0.0;

            // Map customers to their report items for Leaderboards
            final customerReportItems = customers.map((c) {
              return CustomerReportItem(
                user: c,
                orderCount: customerOrderCountsPeriod[c.uid] ?? 0,
                totalSpent: customerSpendingPeriod[c.uid] ?? 0.0,
              );
            }).toList();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<UserProvider>().watchCustomers();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomerSummaryCard(
                      currency: currency,
                      totalCustomers: customers.length,
                      activeCustomers: customers.where((c) => c.isActive).length,
                      newCustomers: currentPeriodSignups,
                      returningCustomers: returningCustomersCount,
                      totalOrders: totalOrdersInPeriod,
                      averageSpending: averageSpending,
                      customerGrowthPercent: customerGrowthPercent,
                    ),
                    const SizedBox(height: 16),
                    CustomerStatisticsChart(
                      growthBuckets: _buildGrowthBuckets(customers, range),
                      spendingBuckets: _buildSpendingBuckets(allOrders, range),
                      currency: currency,
                    ),
                    const SizedBox(height: 16),
                    TopCustomersCard(
                      customerItems: customerReportItems,
                      currency: currency,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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
            const Icon(Icons.people_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Customers Found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'No customer accounts have registered in the store yet.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
