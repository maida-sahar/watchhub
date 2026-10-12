import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/models/order_model.dart';

import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/user_provider.dart';

import 'sales_report_screen.dart';
import 'revenue_report_screen.dart';
import 'inventory_report_screen.dart';
import 'customer_report_screen.dart';
import 'product_report_screen.dart';
import 'export_report_screen.dart';

import 'widgets/dashboard_summary_card.dart';
import 'widgets/report_chart_card.dart';
import 'widgets/sales_overview_card.dart';
import 'widgets/revenue_overview_card.dart';
import 'widgets/inventory_overview_card.dart';
import 'widgets/customer_overview_card.dart';
import 'widgets/product_overview_card.dart';
import 'widgets/recent_reports_card.dart';
import 'widgets/quick_actions_card.dart';

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().watchAllOrders();
      context.read<ProductProvider>().watchAllProducts();
      context.read<UserProvider>().watchCustomers();
    });
  }

  Future<void> _refreshData() async {
    context.read<OrderProvider>().watchAllOrders();
    context.read<ProductProvider>().watchAllProducts();
    context.read<UserProvider>().watchCustomers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Data',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer3<OrderProvider, ProductProvider, UserProvider>(
          builder: (context, orderProv, productProv, userProv, _) {
            final hasLoading = (orderProv.isLoadingAllOrders && orderProv.allOrders.isEmpty) ||
                (productProv.isLoading && productProv.products.isEmpty) ||
                (userProv.isLoading && userProv.customers.isEmpty);

            if (hasLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final hasError = orderProv.allOrdersError != null ||
                productProv.errorMessage != null ||
                userProv.errorMessage != null;

            final errorMsg = orderProv.allOrdersError ??
                productProv.errorMessage ??
                userProv.errorMessage;

            final hasData = orderProv.allOrders.isNotEmpty ||
                productProv.products.isNotEmpty ||
                userProv.customers.isNotEmpty;

            if (hasError && !hasData) {
              return _buildErrorState(errorMsg ?? 'Failed to load dashboard data.');
            }

            if (!hasData) {
              return _buildEmptyState();
            }

            return _buildDashboardContent(orderProv, productProv, userProv);
          },
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    OrderProvider orderProv,
    ProductProvider productProv,
    UserProvider userProv,
  ) {
    final theme = Theme.of(context);

    // Compute basic totals
    final orders = orderProv.allOrders;
    final products = productProv.products;
    final customers = userProv.customers;

    final totalOrders = orders.length;
    final totalProducts = products.length;
    final totalCustomers = customers.length;

    final totalRevenue = orders
        .where((o) => o.orderStatus.toLowerCase() != 'cancelled' && o.orderStatus.toLowerCase() != 'returned')
        .fold<double>(0.0, (sum, o) => sum + o.grandTotal);

    final completedOrders = orders.where((o) => o.orderStatus.toLowerCase() == 'completed' || o.orderStatus.toLowerCase() == 'delivered').toList();
    final totalSalesCount = completedOrders.length;

    // Growth: real month-over-month comparison (this calendar month vs the
    // previous one), not a fabricated constant. Previously these were
    // hardcoded numbers (8.4/12.2/5.8/6.5) shown whenever an arbitrary
    // threshold was crossed — i.e. fake analytics unrelated to any real
    // previous-period data.
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    final previousMonthStart = DateTime(now.year, now.month - 1, 1);

    bool inMonth(DateTime d, DateTime monthStart) =>
        d.year == monthStart.year && d.month == monthStart.month;

    final ordersThisMonth = orders.where((o) => inMonth(o.createdAt, currentMonthStart)).toList();
    final ordersLastMonth = orders.where((o) => inMonth(o.createdAt, previousMonthStart)).toList();

    double revenueOf(List<dynamic> list) => list
        .where((o) => o.orderStatus.toLowerCase() != 'cancelled' && o.orderStatus.toLowerCase() != 'returned')
        .fold<double>(0.0, (sum, o) => sum + o.grandTotal as double);
    int salesCountOf(List<dynamic> list) => list
        .where((o) => o.orderStatus.toLowerCase() == 'completed' || o.orderStatus.toLowerCase() == 'delivered')
        .length;

    final customersThisMonth = customers.where((c) => inMonth(c.createdAt, currentMonthStart)).length;
    final customersLastMonth = customers.where((c) => inMonth(c.createdAt, previousMonthStart)).length;

    double growthPercent(num current, num previous) {
      if (previous <= 0) return current > 0 ? 100.0 : 0.0;
      return ((current - previous) / previous) * 100;
    }

    final double revenueGrowth = growthPercent(revenueOf(ordersThisMonth), revenueOf(ordersLastMonth));
    final double salesGrowth = growthPercent(salesCountOf(ordersThisMonth), salesCountOf(ordersLastMonth));
    final double ordersGrowth = growthPercent(ordersThisMonth.length, ordersLastMonth.length);
    final double customerGrowth = growthPercent(customersThisMonth, customersLastMonth);

    final summaryItems = [
      DashboardSummaryItem(
        label: 'Gross Revenue',
        value: '\$${totalRevenue.toStringAsFixed(0)}',
        icon: Icons.monetization_on_rounded,
        color: Colors.green,
        growth: revenueGrowth,
      ),
      DashboardSummaryItem(
        label: 'Sales count',
        value: totalSalesCount.toString(),
        icon: Icons.shopping_cart_rounded,
        color: Colors.blue,
        growth: salesGrowth,
      ),
      DashboardSummaryItem(
        label: 'Total Orders',
        value: totalOrders.toString(),
        icon: Icons.receipt_long_rounded,
        color: Colors.orange,
        growth: ordersGrowth,
      ),
      DashboardSummaryItem(
        label: 'Total Customers',
        value: totalCustomers.toString(),
        icon: Icons.people_rounded,
        color: Colors.purple,
        growth: customerGrowth,
      ),
    ];

    // Compute trend charts data points (e.g. last 6 months or 7 days)
    // To keep it simple and optimized, we can group completed orders by date labels dynamically.
    final monthlyRevenueData = _computeMonthlyRevenuePoints(orders);
    final monthlyOrdersData = _computeMonthlyOrdersPoints(orders);

    final quickActionsList = [
      const QuickActionItem(
        title: 'Open Sales Report',
        icon: Icons.shopping_bag_rounded,
        color: Colors.blue,
        screen: SalesReportScreen(),
      ),
      const QuickActionItem(
        title: 'Open Revenue Report',
        icon: Icons.monetization_on_rounded,
        color: Colors.green,
        screen: RevenueReportScreen(),
      ),
      const QuickActionItem(
        title: 'Open Inventory Report',
        icon: Icons.inventory_2_rounded,
        color: Colors.orange,
        screen: InventoryReportScreen(),
      ),
      const QuickActionItem(
        title: 'Open Customer Report',
        icon: Icons.people_rounded,
        color: Colors.purple,
        screen: CustomerReportScreen(),
      ),
      const QuickActionItem(
        title: 'Open Product Report',
        icon: Icons.watch_rounded,
        color: Colors.teal,
        screen: ProductReportScreen(),
      ),
      const QuickActionItem(
        title: 'Export Reports',
        icon: Icons.download_rounded,
        color: Colors.indigo,
        screen: ExportReportScreen(),
      ),
    ];

    final recentActivities = [
      RecentReportActivity(
        title: 'Monthly Sales Report',
        type: 'Sales',
        date: DateTime.now().subtract(const Duration(minutes: 15)),
        format: 'PDF',
        size: '1.2 MB',
      ),
      RecentReportActivity(
        title: 'Inventory Valuation Log',
        type: 'Inventory',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        format: 'CSV',
        size: '480 KB',
      ),
      RecentReportActivity(
        title: 'Customer Demographics Summary',
        type: 'Customer',
        date: DateTime.now().subtract(const Duration(days: 1)),
        format: 'PDF',
        size: '2.5 MB',
      ),
    ];

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Scrollbar(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            DashboardSummaryCard(items: summaryItems),
            const SizedBox(height: 16),
            ReportChartCard(
              title: 'Revenue Trend (Monthly)',
              dataPoints: monthlyRevenueData,
              chartColor: Colors.green,
              isCurrency: true,
            ),
            const SizedBox(height: 16),
            ReportChartCard(
              title: 'Orders volume (Monthly)',
              dataPoints: monthlyOrdersData,
              chartColor: Colors.blue,
              isCurrency: false,
            ),
            const SizedBox(height: 16),
            SalesOverviewCard(orders: orders),
            const SizedBox(height: 16),
            RevenueOverviewCard(orders: orders),
            const SizedBox(height: 16),
            InventoryOverviewCard(products: products),
            const SizedBox(height: 16),
            CustomerOverviewCard(customers: customers, orders: orders),
            const SizedBox(height: 16),
            ProductOverviewCard(products: products, orders: orders),
            const SizedBox(height: 16),
            RecentReportsCard(activities: recentActivities),
            const SizedBox(height: 16),
            QuickActionsCard(actions: quickActionsList),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<ChartDataPoint> _computeMonthlyRevenuePoints(List<OrderModel> orders) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final Map<String, double> revenueMap = {};

    // Initialize last 6 months with 0.0
    final now = DateTime.now();
    for (var i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final label = '${months[date.month - 1]} ${date.year.toString().substring(2)}';
      revenueMap[label] = 0.0;
    }

    for (final order in orders) {
      if (order.orderStatus.toLowerCase() == 'cancelled') continue;
      final label = '${months[order.createdAt.month - 1]} ${order.createdAt.year.toString().substring(2)}';
      if (revenueMap.containsKey(label)) {
        revenueMap[label] = (revenueMap[label] ?? 0.0) + order.grandTotal;
      }
    }

    return revenueMap.entries.map((e) => ChartDataPoint(label: e.key, value: e.value)).toList();
  }

  List<ChartDataPoint> _computeMonthlyOrdersPoints(List<OrderModel> orders) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final Map<String, double> ordersMap = {};

    final now = DateTime.now();
    for (var i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final label = '${months[date.month - 1]} ${date.year.toString().substring(2)}';
      ordersMap[label] = 0.0;
    }

    for (final order in orders) {
      final label = '${months[order.createdAt.month - 1]} ${order.createdAt.year.toString().substring(2)}';
      if (ordersMap.containsKey(label)) {
        ordersMap[label] = (ordersMap[label] ?? 0.0) + 1.0;
      }
    }

    return ordersMap.entries.map((e) => ChartDataPoint(label: e.key, value: e.value)).toList();
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
              'Error Loading Dashboard',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              onPressed: _refreshData,
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
            Icon(Icons.analytics_outlined, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4), size: 64),
            const SizedBox(height: 16),
            Text(
              'No Dashboard Data Found',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no orders, products, or customers recorded in the database to generate statistics.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Check Again'),
            ),
          ],
        ),
      ),
    );
  }
}
