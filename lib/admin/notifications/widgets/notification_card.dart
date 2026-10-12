import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';
import '../../../models/notification_model.dart';
import 'notification_status_badge.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onDelete,
    required this.onTap,
  });

  String _getRecipientSummary() {
    switch (notification.recipientType) {
      case 'all':
        return 'To: All Users';
      case 'role':
        return 'To: ${notification.recipientRole == "customer" ? "Customers Only" : "Admins Only"}';
      case 'users':
        return 'To: Selected (${notification.recipientIds.length} users)';
      default:
        return 'To: Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy - hh:mm a').format(notification.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: ClayCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  NotificationStatusBadge(type: notification.type),
                  Text(
                    dateStr,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                notification.title,
                style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                notification.body,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Divider(height: 24, color: AppColors.divider),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_alt_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        _getRecipientSummary(),
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                    onPressed: onDelete,
                    style: IconButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
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
