import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';

class ReviewStatisticsCard extends StatelessWidget {
  final int totalCount;
  final int approvedCount;
  final int pendingCount;
  final int reportedCount;
  final double averageRating;

  const ReviewStatisticsCard({
    super.key,
    required this.totalCount,
    required this.approvedCount,
    required this.pendingCount,
    required this.reportedCount,
    required this.averageRating,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ClayCard(
                borderRadius: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.rate_review_rounded, color: AppColors.primary, size: 24),
                    const SizedBox(height: 12),
                    Text(
                      '$totalCount',
                      style: AppTypography.displayMedium.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      'Total Reviews',
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
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                    const SizedBox(height: 12),
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: AppTypography.displayMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.amber[800],
                      ),
                    ),
                    Text(
                      'Average Rating',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _subStatTile(
              icon: Icons.check_circle_outline_rounded,
              label: 'Approved',
              value: '$approvedCount',
              color: AppColors.success,
            ),
            _subStatTile(
              icon: Icons.hourglass_top_rounded,
              label: 'Pending',
              value: '$pendingCount',
              color: Colors.amber,
            ),
            _subStatTile(
              icon: Icons.flag_rounded,
              label: 'Reported',
              value: '$reportedCount',
              color: AppColors.error,
            ),
          ],
        ),
      ],
    );
  }

  Widget _subStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return ClayCard(
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(fontSize: 10, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
