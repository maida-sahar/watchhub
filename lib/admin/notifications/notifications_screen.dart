import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import 'create_notification_screen.dart';
import 'notification_details_screen.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_filter_dialog.dart';
import 'widgets/notification_search_bar.dart';
import 'widgets/notification_action_dialog.dart';
import 'notification_analytics_screen.dart';
import 'notification_history_screen.dart';

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
      context.read<NotificationProvider>().watchNotifications();
    });
  }

  void _openFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NotificationFilterDialog(),
    );
  }

  Future<void> _handleDelete(BuildContext context, NotificationProvider provider, NotificationModel notification) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Notification deleted permanently.' : (provider.processError ?? 'Action failed.')),
            backgroundColor: success ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notifications Manager',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_rounded, color: AppColors.primary),
            tooltip: 'Notification Analytics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationAnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.primary),
            tooltip: 'Notification History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationHistoryScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateNotificationScreen()),
          );
        },
        child: const Icon(Icons.add_alert_rounded, color: Colors.white),
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

            final list = provider.filteredNotifications;

            return Column(
              children: [
                // Search + Filter Trigger
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      const Expanded(child: NotificationSearchBar()),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _openFilterDialog,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: provider.typeFilter != 'all' || provider.recipientFilter != 'all'
                                  ? AppColors.primary.withOpacity(0.4)
                                  : AppColors.border.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.filter_list_rounded,
                            color: provider.typeFilter != 'all' || provider.recipientFilter != 'all'
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Active Chips Row
                if (provider.typeFilter != 'all' || provider.recipientFilter != 'all')
                  _buildFilterChipsRow(provider),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      provider.stopWatching();
                      provider.watchNotifications();
                    },
                    color: AppColors.primary,
                    child: list.isEmpty
                        ? _buildEmptyState(provider)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final notification = list[index];
                              return NotificationCard(
                                notification: notification,
                                onDelete: () => _handleDelete(context, provider, notification),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NotificationDetailsScreen(notification: notification),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChipsRow(NotificationProvider provider) {
    final Map<String, String> recipientLabels = {
      'all_users': 'Target: All Users',
      'role_customer': 'Target: Customers',
      'role_admin': 'Target: Admins',
      'specific_users': 'Target: Selected Users',
    };

    return Container(
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (provider.typeFilter != 'all')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InputChip(
                label: Text('Type: ${provider.typeFilter.toUpperCase()}'),
                onDeleted: () => provider.setTypeFilter('all'),
                deleteIconColor: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.08),
                side: BorderSide(color: AppColors.primary.withOpacity(0.12)),
                labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          if (provider.recipientFilter != 'all')
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InputChip(
                label: Text(recipientLabels[provider.recipientFilter] ?? provider.recipientFilter),
                onDeleted: () => provider.setRecipientFilter('all'),
                deleteIconColor: AppColors.primary,
                backgroundColor: AppColors.primary.withOpacity(0.08),
                side: BorderSide(color: AppColors.primary.withOpacity(0.12)),
                labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ActionChip(
            label: const Text('Clear All'),
            onPressed: provider.resetFilters,
            backgroundColor: AppColors.background,
            side: const BorderSide(color: AppColors.border),
            labelStyle: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(NotificationProvider provider) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.22),
        const Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.textTertiary),
        const SizedBox(height: 16),
        Text(
          'No notifications found',
          style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          provider.searchQuery.isNotEmpty || provider.typeFilter != 'all' || provider.recipientFilter != 'all'
              ? 'Try widening your search text or clearing the filters.'
              : 'Add new promotion alerts or system broad messages.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
