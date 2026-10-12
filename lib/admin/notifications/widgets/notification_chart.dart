import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';
import '../../../models/notification_model.dart';

class NotificationChart extends StatelessWidget {
  final List<NotificationModel> notifications;

  const NotificationChart({
    super.key,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate daily counts for the last 7 days
    final now = DateTime.now();
    final List<DateTime> last7Days = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return DateTime(date.year, date.month, date.day);
    });

    final Map<DateTime, int> counts = {for (var d in last7Days) d: 0};

    for (final n in notifications) {
      final createdDate = DateTime(n.createdAt.year, n.createdAt.month, n.createdAt.day);
      if (counts.containsKey(createdDate)) {
        counts[createdDate] = counts[createdDate]! + 1;
      }
    }

    final maxCount = counts.values.fold<int>(0, (max, val) => val > max ? val : max);
    final double maxBarHeight = 140.0;

    return ClayCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity (Last 7 Days)',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: last7Days.map((date) {
              final count = counts[date] ?? 0;
              final double percent = maxCount > 0 ? count / maxCount : 0.0;
              final double barHeight = percent * maxBarHeight;
              final label = DateFormat('E').format(date); // Day of week

              return Expanded(
                child: Column(
                  children: [
                    // Bar Tooltip / Count Label
                    Text(
                      '$count',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: count > 0 ? AppColors.primary : AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Animated bar container
                    Container(
                      height: maxBarHeight,
                      width: 14,
                      alignment: Alignment.bottomCenter,
                      decoration: BoxDecoration(
                        color: AppColors.border.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        height: barHeight > 4.0 ? barHeight : (count > 0 ? 4.0 : 0.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryLight],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Weekday label
                    Text(
                      label,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
