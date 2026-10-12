import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/admin/notifications/widgets/notification_action_dialog.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/config/app_typography.dart';
import 'package:watch_hub/config/clay_widgets.dart';
import 'package:watch_hub/models/notification_model.dart';
import 'package:watch_hub/providers/auth_provider.dart';
import 'package:watch_hub/providers/notification_provider.dart';
import '../../notifications/widgets/notification_action_dialog.dart';

class NotificationDetailsScreen extends StatelessWidget {
  final NotificationModel notification;

  const NotificationDetailsScreen({
    super.key,
    required this.notification,
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

  Future<void> _handleDelete(BuildContext context, NotificationProvider provider, String uid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const NotificationActionDialog(
        title: 'Delete Notification',
        content: 'Are you sure you want to delete this notification from your inbox?',
        confirmLabel: 'Delete',
        confirmColor: AppColors.error,
      ),
    );

    if (confirm == true) {
      final success = await provider.deleteNotificationForUser(notification.id, uid);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notification removed.'),
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
    final auth = context.watch<AuthProvider>();
    
    if (!auth.isAuthenticated || auth.user == null) {
      return const Scaffold(
        body: Center(child: Text('Unauthorized access.')),
      );
    }

    final user = auth.user!;
    final dateStr = DateFormat('MMMM dd, yyyy - hh:mm a').format(notification.createdAt);
    final themeColor = _getColorForType();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(''),
      ),
      body: SafeArea(
        child: Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Header Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconForType(),
                        color: themeColor,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header card with date and subject title
                  ClayCard(
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              notification.type.toUpperCase(),
                              style: AppTypography.bodySmall.copyWith(
                                color: themeColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              dateStr,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: AppColors.divider),
                        Text(
                          notification.title,
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message body card
                  ClayCard(
                    borderRadius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Message details',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          notification.body,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Delete button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _handleDelete(context, provider, user.uid),
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                      label: Text(
                        'Remove from Inbox',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.error, width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
