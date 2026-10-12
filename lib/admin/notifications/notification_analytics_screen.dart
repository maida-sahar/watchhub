import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import 'widgets/notification_statistics_card.dart';
import 'widgets/notification_chart.dart';
import 'widgets/notification_type_chart.dart';
import 'widgets/notification_activity_card.dart';
import 'notification_history_screen.dart';

class NotificationAnalyticsScreen extends StatefulWidget {
  const NotificationAnalyticsScreen({super.key});

  @override
  State<NotificationAnalyticsScreen> createState() => _NotificationAnalyticsScreenState();
}

class _NotificationAnalyticsScreenState extends State<NotificationAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().watchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Notification Analytics',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
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

            final list = provider.notifications;

            if (list.isEmpty) {
              return _buildEmptyState();
            }

            // Calculations
            final total = list.length;
            final sent = list.where((n) => n.deliveryStatus == 'sent').length;
            final failed = list.where((n) => n.deliveryStatus == 'failed').length;
            
            // Read status
            final read = list.where((n) => n.readBy.isNotEmpty).length;
            final unread = list.where((n) => n.readBy.isEmpty).length;

            // Most Sent Type
            final Map<String, int> typeCounts = {};
            for (final n in list) {
              typeCounts[n.type] = (typeCounts[n.type] ?? 0) + 1;
            }
            String mostSentType = 'None';
            int maxCount = 0;
            typeCounts.forEach((key, val) {
              if (val > maxCount) {
                maxCount = val;
                mostSentType = key.toUpperCase();
              }
            });

            return RefreshIndicator(
              onRefresh: () async {
                provider.stopWatching();
                provider.watchNotifications();
              },
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Row 1 Statistics
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      NotificationStatisticsCard(
                        title: 'Total Notifications',
                        value: '$total',
                        icon: Icons.notifications_rounded,
                        color: AppColors.primary,
                        subtitle: 'Created alerts',
                      ),
                      NotificationStatisticsCard(
                        title: 'Sent / Delivered',
                        value: '$sent',
                        icon: Icons.send_rounded,
                        color: AppColors.success,
                        subtitle: 'Dispatched push',
                      ),
                      NotificationStatisticsCard(
                        title: 'Read Alerts',
                        value: '$read',
                        icon: Icons.mark_email_read_rounded,
                        color: Colors.blue,
                        subtitle: 'Opened by users',
                      ),
                      NotificationStatisticsCard(
                        title: 'Unread Alerts',
                        value: '$unread',
                        icon: Icons.mark_email_unread_rounded,
                        color: Colors.blueGrey,
                        subtitle: 'Not opened yet',
                      ),
                      NotificationStatisticsCard(
                        title: 'Failed Dispatches',
                        value: '$failed',
                        icon: Icons.error_outline_rounded,
                        color: AppColors.error,
                        subtitle: 'Delivery errors',
                      ),
                      NotificationStatisticsCard(
                        title: 'Most Sent Category',
                        value: mostSentType,
                        icon: Icons.trending_up_rounded,
                        color: Colors.amber[800] ?? Colors.amber,
                        subtitle: 'Highest volume',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Weekly activity chart
                  NotificationChart(notifications: list),
                  const SizedBox(height: 20),

                  // Type distribution chart
                  NotificationTypeChart(notifications: list),
                  const SizedBox(height: 20),

                  // Recent Broadcast activity
                  NotificationActivityCard(
                    notifications: list,
                    onViewHistory: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationHistoryScreen()),
                      );
                    },
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics_outlined, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            'No notifications to analyze',
            style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Create new broadcasts to see statistics.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
        ],
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
              'Failed to load analytics',
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
