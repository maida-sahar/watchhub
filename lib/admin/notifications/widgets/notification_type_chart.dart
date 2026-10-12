import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';
import '../../../models/notification_model.dart';

class NotificationTypeChart extends StatelessWidget {
  final List<NotificationModel> notifications;

  const NotificationTypeChart({
    super.key,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Calculate count for each type
    final Map<String, int> typeCounts = {
      'order': 0,
      'product': 0,
      'wishlist': 0,
      'promotion': 0,
      'review': 0,
      'system': 0,
    };

    for (final n in notifications) {
      final type = n.type.toLowerCase().trim();
      if (typeCounts.containsKey(type)) {
        typeCounts[type] = typeCounts[type]! + 1;
      } else {
        typeCounts['system'] = (typeCounts['system'] ?? 0) + 1;
      }
    }

    final total = notifications.length;
    final sortedTypes = typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Colors matching notification types
    final Map<String, Color> typeColors = {
      'order': AppColors.primary,
      'product': Colors.blue,
      'wishlist': Colors.pink,
      'promotion': AppColors.success,
      'review': Colors.amber[800] ?? Colors.amber,
      'system': Colors.blueGrey,
    };

    final Map<String, IconData> typeIcons = {
      'order': Icons.receipt_long_rounded,
      'product': Icons.watch_rounded,
      'wishlist': Icons.favorite_rounded,
      'promotion': Icons.local_offer_rounded,
      'review': Icons.star_rounded,
      'system': Icons.notifications_active_rounded,
    };

    return ClayCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Type Distribution',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...sortedTypes.map((entry) {
            final type = entry.key;
            final count = entry.value;
            final double percent = total > 0 ? count / total : 0.0;
            final color = typeColors[type] ?? Colors.grey;
            final icon = typeIcons[type] ?? Icons.notifications_rounded;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              type.toUpperCase(),
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '$count (${(percent * 100).toStringAsFixed(0)}%)',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Progress bar track
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 6,
                            width: double.infinity,
                            color: AppColors.border.withOpacity(0.5),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: (percent * 1000).toInt(),
                                  child: Container(
                                    color: color,
                                  ),
                                ),
                                Expanded(
                                  flex: ((1.0 - percent) * 1000).toInt(),
                                  child: const SizedBox.shrink(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
