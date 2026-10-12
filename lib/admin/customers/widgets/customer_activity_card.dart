import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';

class CustomerActivityCard extends StatelessWidget {
  final DateTime? lastOrderDate;
  final double averageOrderValue;
  final double completionRate; // e.g. 0.85 for 85%

  const CustomerActivityCard({
    super.key,
    this.lastOrderDate,
    required this.averageOrderValue,
    required this.completionRate,
  });

  @override
  Widget build(BuildContext context) {
    final formattedLastOrder = lastOrderDate != null
        ? DateFormat('MMM dd, yyyy').format(lastOrderDate!)
        : 'Never ordered';

    return ClayCard(
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Activity',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _activityItem(
            icon: Icons.history_rounded,
            label: 'Last Order Date',
            value: formattedLastOrder,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          _activityItem(
            icon: Icons.shopping_bag_rounded,
            label: 'Average Order Value',
            value: '\$${averageOrderValue.toStringAsFixed(2)}',
            color: AppColors.success,
          ),
          const SizedBox(height: 16),
          _activityItem(
            icon: Icons.analytics_rounded,
            label: 'Fulfillment Rate',
            value: '${(completionRate * 100).toStringAsFixed(0)}%',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _activityItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
