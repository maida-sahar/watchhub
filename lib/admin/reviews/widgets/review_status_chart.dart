import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';

class ReviewStatusChart extends StatelessWidget {
  final int approved;
  final int pending;
  final int hidden;
  final int rejected;

  const ReviewStatusChart({
    super.key,
    required this.approved,
    required this.pending,
    required this.hidden,
    required this.rejected,
  });

  @override
  Widget build(BuildContext context) {
    final total = approved + pending + hidden + rejected;

    return ClayCard(
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Status Breakdown',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Stacked Segment Bar
          if (total > 0)
            Container(
              height: 20,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  if (approved > 0)
                    Expanded(
                      flex: approved,
                      child: Tooltip(
                        message: 'Approved',
                        child: Container(color: AppColors.success),
                      ),
                    ),
                  if (pending > 0)
                    Expanded(
                      flex: pending,
                      child: Tooltip(
                        message: 'Pending',
                        child: Container(color: Colors.amber),
                      ),
                    ),
                  if (hidden > 0)
                    Expanded(
                      flex: hidden,
                      child: Tooltip(
                        message: 'Hidden',
                        child: Container(color: Colors.blueGrey),
                      ),
                    ),
                  if (rejected > 0)
                    Expanded(
                      flex: rejected,
                      child: Tooltip(
                        message: 'Rejected',
                        child: Container(color: AppColors.error),
                      ),
                    ),
                ],
              ),
            )
          else
            Container(
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Text('No data available')),
            ),
          const SizedBox(height: 20),
          _indicatorRow(
            label: 'Approved Reviews',
            value: approved,
            total: total,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          _indicatorRow(
            label: 'Pending Reviews',
            value: pending,
            total: total,
            color: Colors.amber,
          ),
          const SizedBox(height: 12),
          _indicatorRow(
            label: 'Hidden Reviews',
            value: hidden,
            total: total,
            color: Colors.blueGrey,
          ),
          const SizedBox(height: 12),
          _indicatorRow(
            label: 'Rejected Reviews',
            value: rejected,
            total: total,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _indicatorRow({
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final percent = total > 0 ? (value / total * 100).toStringAsFixed(0) : '0';

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium,
          ),
        ),
        Text(
          '$value ($percent%)',
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}