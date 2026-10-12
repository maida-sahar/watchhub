import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';
import '../../../models/notification_model.dart';
import '../../../providers/notification_provider.dart';

class NotificationHistoryCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationHistoryCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  String _getRecipientDescription() {
    switch (notification.recipientType) {
      case 'all':
        return 'All Users';
      case 'role':
        return 'Role: ${notification.recipientRole == "customer" ? "Customers" : "Admins"}';
      case 'users':
        return 'Selected (${notification.recipientIds.length} users)';
      default:
        return 'Broadcast';
    }
  }

  Color _getTypeColor() {
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

  IconData _getTypeIcon() {
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

  @override
  Widget build(BuildContext context) {
    final themeColor = _getTypeColor();
    final dateStr = DateFormat('MMM dd, yyyy - hh:mm a').format(notification.createdAt);
    final status = notification.deliveryStatus;

    final Map<String, Color> statusColors = {
      'sent': AppColors.success,
      'failed': AppColors.error,
      'scheduled': Colors.orange,
    };
    final color = statusColors[status] ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClayCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Type Icon + Type Label
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getTypeIcon(),
                          color: themeColor,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        notification.type.toUpperCase(),
                        style: AppTypography.bodySmall.copyWith(
                          color: themeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  // Delivery Status Badge
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
              const SizedBox(height: 12),

              // Title
              Text(
                notification.title,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Body snippet
              Text(
                notification.body,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Divider(height: 20, color: AppColors.divider),

              // Footer metadata row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Date
                  Text(
                    dateStr,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                  // Recipient & Read count
                  Row(
                    children: [
                      const Icon(Icons.people_alt_rounded, color: AppColors.textSecondary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        _getRecipientDescription(),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.remove_red_eye_rounded, color: AppColors.textSecondary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${notification.readBy.length}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
