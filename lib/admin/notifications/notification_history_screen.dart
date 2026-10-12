import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import 'widgets/notification_history_card.dart';
import 'widgets/notification_search_bar.dart';
import 'widgets/notification_filter_dialog.dart';
import 'notification_details_screen.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary),
          onPressed: () {
            // Reset filters on pop so it doesn't affect notifications manager search state
            context.read<NotificationProvider>().resetFilters();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Notification History',
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

            final list = provider.filteredNotifications;

            return Column(
              children: [
                // Search + Filter triggers
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

                // Active Filters chip row
                if (provider.typeFilter != 'all' || provider.recipientFilter != 'all')
                  _buildFilterChipsRow(provider),

                // List View
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
                              return NotificationHistoryCard(
                                notification: notification,
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
        const Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.textTertiary),
        const SizedBox(height: 16),
        Text(
          'No notification logs found',
          style: AppTypography.titleMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          provider.searchQuery.isNotEmpty || provider.typeFilter != 'all' || provider.recipientFilter != 'all'
              ? 'Try resetting the filters or modifying your search.'
              : 'Sent broadcast history logs will appear here.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
      ],
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
              'Failed to load history',
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
