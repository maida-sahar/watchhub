import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';
import '../../../models/notification_model.dart';
import '../../../providers/notification_provider.dart';

class NotificationActivityCard extends StatelessWidget {
  final List<NotificationModel> notifications;
  final VoidCallback onViewHistory;

  const NotificationActivityCard({
    super.key,
    required this.notifications,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final recent = notifications.take(5).toList();

    final Map<String, Color> statusColors = {
      'sent': AppColors.success,
      'failed': AppColors.error,
      'scheduled': Colors.orange,
    };

    return ClayCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Broadcasts',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: onViewHistory,
                child: Text(
                  'View All',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No recent notifications.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...recent.map((n) {
              final dateStr = DateFormat('MMM dd, hh:mm a').format(n.createdAt);
              final status = n.deliveryStatus;
              final color = statusColors[status] ?? Colors.grey;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    // Small status dot
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Target: ${n.recipientType.toUpperCase()} • $dateStr',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: AppTypography.bodySmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
