import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/admin/notifications/widgets/notification_action_dialog.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/config/app_typography.dart';
import 'package:watch_hub/providers/auth_provider.dart';
import 'package:watch_hub/providers/notification_provider.dart';
import '../../notifications/widgets/notification_action_dialog.dart';
import 'notification_details_screen.dart';
import 'widgets/notification_tile.dart';
import 'widgets/notification_empty_state.dart';
import 'package:watch_hub/config/app_routes.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated && auth.user != null) {
        context.read<NotificationProvider>().watchNotifications(auth.user!.uid);
      }
    });
  }

  Future<void> _handleMarkAllRead(BuildContext context, NotificationProvider provider, String uid, String role) async {
    final success = await provider.markAllAsRead(uid, role);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'All notifications marked as read.' : 'Failed to update notifications.'),
          backgroundColor: success ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleDeleteAll(BuildContext context, NotificationProvider provider, String uid, String role) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const NotificationActionDialog(
        title: 'Clear Notification Inbox',
        content: 'Are you sure you want to delete all notifications? This action will empty your notifications inbox.',
        confirmLabel: 'Clear All',
        confirmColor: AppColors.error,
      ),
    );

    if (confirm == true) {
      final success = await provider.deleteAllNotificationsForUser(uid, role);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Inbox cleared successfully.' : 'Failed to clear notifications.'),
            backgroundColor: success ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    if (!auth.isAuthenticated || auth.user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view notifications.')),
      );
    }

    final user = auth.user!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notifications',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              final list = provider.getUserNotifications(user.uid, user.role);
              return Row(
                children: [
                  if (list.isNotEmpty) ...[
                    IconButton(
                      icon: const Icon(Icons.done_all_rounded, color: AppColors.primary),
                      tooltip: 'Mark all as read',
                      onPressed: () => _handleMarkAllRead(context, provider, user.uid, user.role),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
                      tooltip: 'Clear inbox',
                      onPressed: () => _handleDeleteAll(context, provider, user.uid, user.role),
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.settings_rounded, color: AppColors.primary),
                    tooltip: 'Notification Settings',
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.notificationSettings);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.notifications.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null && provider.notifications.isEmpty) {
              return _buildErrorState(provider.errorMessage!);
            }

            final list = provider.getUserNotifications(user.uid, user.role);

            if (list.isEmpty) {
              return const NotificationEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () async {
                provider.stopWatching();
                provider.watchNotifications();
              },
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final n = list[index];
                  return NotificationTile(
                    notification: n,
                    userId: user.uid,
                    onTap: () {
                      if (!n.isReadBy(user.uid)) {
                        provider.markAsRead(n.id, user.uid);
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationDetailsScreen(notification: n),
                        ),
                      );
                    },
                    onDelete: () {
                      provider.deleteNotificationForUser(n.id, user.uid);
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load notifications',
              style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
