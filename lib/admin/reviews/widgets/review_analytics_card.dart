import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';

class ReviewAnalyticsCard extends StatelessWidget {
  final List<MapEntry<String, int>> topProducts;
  final List<MapEntry<String, int>> topCustomers;

  const ReviewAnalyticsCard({
    super.key,
    required this.topProducts,
    required this.topCustomers,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Most Reviewed Products Card
        ClayCard(
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Most Reviewed Products',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (topProducts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: Text(
                      'No products reviewed yet.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                ...topProducts.map((e) => _rankingRow(
                      context,
                      name: e.key,
                      count: e.value,
                      icon: Icons.watch_rounded,
                      color: AppColors.primary,
                    )),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Most Active Customers Card
        ClayCard(
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Most Active Customers',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (topCustomers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: Text(
                      'No customer reviews yet.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                ...topCustomers.map((e) => _rankingRow(
                      context,
                      name: e.key,
                      count: e.value,
                      icon: Icons.person_rounded,
                      color: AppColors.primaryLight,
                    )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rankingRow(
    BuildContext context, {
    required String name,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count reviews',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
