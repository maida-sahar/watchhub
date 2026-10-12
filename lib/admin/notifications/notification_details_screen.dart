import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../config/clay_widgets.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import 'widgets/notification_status_badge.dart';
import 'widgets/notification_action_dialog.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailsScreen({
    super.key,
    required this.notification,
  });

  String _getRecipientSummary() {
    switch (notification.recipientType) {
      case 'all':
        return 'Broadcast to all system users';
      case 'role':
        return 'Broadcast to role: ${notification.recipientRole == "customer" ? "Customers Only" : "Administrators Only"}';
      case 'users':
        return 'Broadcast to specific users list (${notification.recipientIds.length} users)';
      default:
        return 'Broadcast to unknown target';
    }
  }

  Future<void> _handleDelete(BuildContext context, NotificationProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const NotificationActionDialog(
        title: 'Delete Notification',
        content: 'Are you sure you want to permanently delete this notification? Users will no longer be able to read it.',
        confirmLabel: 'Delete',
        confirmColor: AppColors.error,
      ),
    );

    if (confirm == true) {
      final success = await provider.deleteNotificationPermanently(notification.id);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification deleted successfully.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.processError ?? 'Failed to delete notification.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMMM dd, yyyy - hh:mm a').format(notification.createdAt);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notification Details',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type & Time Card
                  ClayCard(
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Topic / Type',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                            NotificationStatusBadge(type: notification.type),
                          ],
                        ),
                        const Divider(height: 24, color: AppColors.divider),
                        Text(
                          'Created At',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateStr,
                          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Target Group Card
                  ClayCard(
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recipient Targets',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.people_alt_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _getRecipientSummary(),
                                style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Content Card
                  ClayCard(
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Message Subject',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.title,
                          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 24, color: AppColors.divider),
                        Text(
                          'Message Body',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            notification.body,
                            style: AppTypography.bodyMedium.copyWith(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Controls
                  Text(
                    'Administrative Controls',
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: InkWell(
                      onTap: () => _handleDelete(context, provider),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.error.withOpacity(0.2), width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Delete Broadcast Alert',
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
