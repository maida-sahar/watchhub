import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';
import '../../../models/notification_model.dart';

class NotificationTopicSelector extends StatelessWidget {
  final NotificationSettingsModel settings;
  final ValueChanged<NotificationSettingsModel> onChanged;

  const NotificationTopicSelector({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: Text(
              'Public Broadcast Channels',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          ClayCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTopicTile(
                  title: 'Promotional Offers',
                  description: 'Receive newsletters, deals, and flash sales broadcasts.',
                  icon: Icons.local_offer_rounded,
                  color: AppColors.success,
                  isSubscribed: settings.pushEnabled && settings.promotionEnabled,
                  onToggle: (val) {
                    if (settings.pushEnabled) {
                      onChanged(settings.copyWith(promotionEnabled: val));
                    }
                  },
                ),
                const Divider(height: 24, color: AppColors.divider),
                _buildTopicTile(
                  title: 'System announcements',
                  description: 'Receive critical service updates and maintenance broadcasts.',
                  icon: Icons.settings_suggest_rounded,
                  color: Colors.blueGrey,
                  isSubscribed: settings.pushEnabled && settings.systemEnabled,
                  onToggle: (val) {
                    if (settings.pushEnabled) {
                      onChanged(settings.copyWith(systemEnabled: val));
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicTile({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isSubscribed,
    required ValueChanged<bool> onToggle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Visual Chip state
        InkWell(
          onTap: () => onToggle(!isSubscribed),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSubscribed
                  ? AppColors.primary.withOpacity(0.08)
                  : Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSubscribed ? AppColors.primary : Colors.grey[400]!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSubscribed ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                  size: 14,
                  color: isSubscribed ? AppColors.primary : Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  isSubscribed ? 'Subscribed' : 'Subscribe',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSubscribed ? AppColors.primary : Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
