import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';
import '../../../models/notification_model.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final String userId;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.userId,
    required this.onTap,
    required this.onDelete,
  });

  IconData _getIconForType() {
    switch (notification.type.trim().toLowerCase()) {
      case 'order':
        return Icons.receipt_long_rounded;
      case 'product':
        return Icons.watch_rounded;
      case 'wishlist':
        return Icons.favorite_rounded;
      case 'promotion':
        return Icons.local_offer_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'system':
      default:
        return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForType() {
    switch (notification.type.trim().toLowerCase()) {
      case 'order':
        return AppColors.primary;
      case 'product':
        return Colors.blue;
      case 'wishlist':
        return Colors.pink;
      case 'promotion':
        return AppColors.success;
      case 'review':
        return Colors.amber[800] ?? Colors.amber;
      case 'system':
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isReadBy(userId);
    final dateStr = DateFormat('MMM dd, hh:mm a').format(notification.createdAt);
    final themeColor = _getColorForType();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
        ),
        onDismissed: (direction) => onDelete(),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: ClayCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Icon Circle
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: themeColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIconForType(),
                    color: themeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Body & content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateStr,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          // Unread Blue Dot
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.title,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          color: isUnread ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.body,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isUnread ? AppColors.textSecondary : AppColors.textTertiary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
