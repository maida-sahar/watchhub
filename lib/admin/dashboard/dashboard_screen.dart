// admin/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/config/app_shadows.dart';
import 'package:watch_hub/config/clay_widgets.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/config/app_routes.dart';
import 'package:watch_hub/config/app_spacing.dart';
import 'package:watch_hub/config/app_typography.dart';
import 'package:watch_hub/providers/auth_provider.dart';
import 'package:watch_hub/providers/notification_provider.dart';
import 'package:watch_hub/providers/order_provider.dart';
import 'package:watch_hub/providers/user_provider.dart';

/// Admin-facing dashboard. Shown after a successful admin login.
/// Uses Claymorphism and Material 3 theme.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // The stats row below previously showed hardcoded "0" for every
    // metric because nothing ever triggered these providers to load —
    // same watch-on-open pattern already used by ReportsDashboardScreen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OrderProvider>().watchAllOrders();
      context.read<UserProvider>().watchCustomers();
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await context.read<NotificationProvider>().removeTokenOnLogout();
    } catch (_) {}
    final auth = context.read<AuthProvider>();
    await auth.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Admin Dashboard', style: AppTypography.headlineSmall),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Overview', style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.md),
              const _StatsRow(),
              const SizedBox(height: AppSpacing.xxl),
              Text('Manage', style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.md),
              const _ManageGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    // Previously these three values were hardcoded to '0'/'\$0' — the
    // dashboard is meant to be "all important statistics in one place",
    // so it needs to read the same live data the Reports module uses
    // rather than static placeholders.
    final orderProv = context.watch<OrderProvider>();
    final userProv = context.watch<UserProvider>();

    final totalOrders = orderProv.allOrders.length;
    final totalCustomers = userProv.customers.length;
    final totalRevenue = orderProv.allOrders
        .where((o) =>
            o.orderStatus.toLowerCase() != 'cancelled' &&
            o.orderStatus.toLowerCase() != 'returned')
        .fold<double>(0.0, (sum, o) => sum + o.grandTotal);

    final isLoading = (orderProv.isLoadingAllOrders && orderProv.allOrders.isEmpty) ||
        (userProv.isLoading && userProv.customers.isEmpty);

    final stats = [
      (
        'Orders',
        isLoading ? '—' : totalOrders.toString(),
        Icons.receipt_long_rounded,
        AppColors.primary,
      ),
      (
        'Customers',
        isLoading ? '—' : totalCustomers.toString(),
        Icons.people_alt_rounded,
        AppColors.primaryLight,
      ),
      (
        'Revenue',
        isLoading ? '—' : '\$${totalRevenue.toStringAsFixed(0)}',
        Icons.trending_up_rounded,
        AppColors.success,
      ),
    ];

    return Row(
      children: stats
          .map(
            (s) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ClayCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  borderRadius: 20,
                  shadows: AppShadows.soft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(s.$3, color: s.$4, size: 22),
                      const SizedBox(height: AppSpacing.sm),
                      Text(s.$2, style: AppTypography.headlineSmall),
                      Text(s.$1, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ManageGrid extends StatelessWidget {
  const _ManageGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      _ManageTile(icon: Icons.watch_rounded, label: 'Products', route: AppRoutes.adminProducts),
      _ManageTile(icon: Icons.category_rounded, label: 'Categories', route: AppRoutes.adminCategories),
      _ManageTile(icon: Icons.sell_rounded, label: 'Brands', route: AppRoutes.adminBrands),
      _ManageTile(icon: Icons.local_offer_rounded, label: 'Coupons', route: AppRoutes.adminCoupons),
      _ManageTile(icon: Icons.receipt_long_rounded, label: 'Orders', route: AppRoutes.adminOrders),
      _ManageTile(icon: Icons.people_alt_rounded, label: 'Customers', route: AppRoutes.adminCustomers),
      _ManageTile(icon: Icons.bar_chart_rounded, label: 'Reports', route: AppRoutes.adminReports),
      _ManageTile(icon: Icons.rate_review_rounded, label: 'Reviews', route: AppRoutes.adminReviews),
      _ManageTile(icon: Icons.settings_rounded, label: 'Settings', route: AppRoutes.adminSettings),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.4,
      ),
      itemBuilder: (context, index) => items[index],
    );
  }
}

class _ManageTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;

  const _ManageTile({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.of(context).pushNamed(route),
      child: ClayCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        borderRadius: 20,
        shadows: AppShadows.soft,
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}