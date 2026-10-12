import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../config/clay_widgets.dart';
import '../../providers/user_provider.dart';

class CustomerStatisticsScreen extends StatelessWidget {
  const CustomerStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Customer Reports',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.totalCustomersCount == 0) {
              return const Center(child: CircularProgressIndicator());
            }

            final formattedLastOrder = provider.lastOrderDate != null
                ? DateFormat('MMM dd, yyyy').format(provider.lastOrderDate!)
                : 'No orders';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Headline Summary Cards (Row)
                  Row(
                    children: [
                      Expanded(
                        child: ClayCard(
                          borderRadius: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.people_rounded, color: AppColors.primary, size: 24),
                              const SizedBox(height: 12),
                              Text(
                                '${provider.totalCustomersCount}',
                                style: AppTypography.displayMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Total Customers',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ClayCard(
                          borderRadius: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.monetization_on_rounded, color: AppColors.success, size: 24),
                              const SizedBox(height: 12),
                              Text(
                                '\$${provider.totalSpendingSum.toStringAsFixed(0)}',
                                style: AppTypography.displayMedium.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.success,
                                ),
                              ),
                              Text(
                                'Total Revenue',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Demographics & Activity',
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Grid of details
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.4,
                    children: [
                      _statCell(
                        icon: Icons.check_circle_rounded,
                        label: 'Active Customers',
                        value: '${provider.activeCustomersCount}',
                        color: AppColors.success,
                      ),
                      _statCell(
                        icon: Icons.person_add_rounded,
                        label: 'New Customers',
                        value: '${provider.newCustomersCount}',
                        color: Colors.blue,
                      ),
                      _statCell(
                        icon: Icons.shopping_cart_rounded,
                        label: 'Total Orders',
                        value: '${provider.totalOrdersCount}',
                        color: AppColors.primary,
                      ),
                      _statCell(
                        icon: Icons.done_all_rounded,
                        label: 'Completed Orders',
                        value: '${provider.completedOrdersCount}',
                        color: AppColors.success,
                      ),
                      _statCell(
                        icon: Icons.hourglass_top_rounded,
                        label: 'Pending Orders',
                        value: '${provider.pendingOrdersCount}',
                        color: Colors.amber[800] ?? Colors.amber,
                      ),
                      _statCell(
                        icon: Icons.cancel_schedule_send_rounded,
                        label: 'Cancelled Orders',
                        value: '${provider.cancelledOrdersCount}',
                        color: AppColors.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Operational Performance',
                    style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ClayCard(
                    borderRadius: 24,
                    child: Column(
                      children: [
                        _summaryRow(
                          icon: Icons.trending_up_rounded,
                          label: 'Average Order Value',
                          value: '\$${provider.averageOrderValue.toStringAsFixed(2)}',
                          color: AppColors.success,
                        ),
                        const Divider(height: 24, color: AppColors.divider),
                        _summaryRow(
                          icon: Icons.schedule_rounded,
                          label: 'Last Order Placement',
                          value: formattedLastOrder,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _statCell({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return ClayCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
