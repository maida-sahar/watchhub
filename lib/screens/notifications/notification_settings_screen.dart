import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../config/app_typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';
import 'widgets/notification_permission_card.dart';
import 'widgets/notification_setting_tile.dart';
import 'widgets/notification_topic_selector.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated && auth.user != null) {
        context.read<NotificationProvider>().checkPermission();
        context.read<NotificationProvider>().watchNotificationSettings(auth.user!.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAuthenticated || auth.user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to manage notification settings.')),
      );
    }

    final user = auth.user!;

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
          'Notification Settings',
          style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            final settings = provider.settings;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Permission Card (displays only if permissions are missing)
                NotificationPermissionCard(userId: user.uid),

                // Section header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: Text(
                    'Push Preferences',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                // Global Push Notifications
                NotificationSettingTile(
                  title: 'Push Notifications',
                  subtitle: 'Enable or disable all notifications from WatchHub globally.',
                  icon: Icons.notifications_active_rounded,
                  value: settings.pushEnabled,
                  onChanged: (val) {
                    provider.updateNotificationSettings(
                      user.uid,
                      settings.copyWith(pushEnabled: val),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Sub-Settings (Only active if global push is enabled)
                AbsorbPointer(
                  absorbing: !settings.pushEnabled,
                  child: Opacity(
                    opacity: settings.pushEnabled ? 1.0 : 0.5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order Notifications
                        NotificationSettingTile(
                          title: 'Orders Updates',
                          subtitle: 'Get alerts on your order confirmations, updates, and status.',
                          icon: Icons.receipt_long_rounded,
                          value: settings.orderEnabled,
                          onChanged: (val) {
                            provider.updateNotificationSettings(
                              user.uid,
                              settings.copyWith(orderEnabled: val),
                            );
                          },
                        ),

                        // Promotions / Offers
                        NotificationSettingTile(
                          title: 'Promotions & Deals',
                          subtitle: 'Alert me about discount codes, coupons, and flash sales.',
                          icon: Icons.local_offer_rounded,
                          value: settings.promotionEnabled,
                          onChanged: (val) {
                            provider.updateNotificationSettings(
                              user.uid,
                              settings.copyWith(promotionEnabled: val),
                            );
                          },
                        ),

                        // Wishlist alerts
                        NotificationSettingTile(
                          title: 'Wishlist Alerts',
                          subtitle: 'Receive updates when your favorited items drop in price.',
                          icon: Icons.favorite_rounded,
                          value: settings.wishlistEnabled,
                          onChanged: (val) {
                            provider.updateNotificationSettings(
                              user.uid,
                              settings.copyWith(wishlistEnabled: val),
                            );
                          },
                        ),

                        // Review notifications
                        NotificationSettingTile(
                          title: 'Review Responses',
                          subtitle: 'Get alerts when administrators reply to your reviews.',
                          icon: Icons.rate_review_rounded,
                          value: settings.reviewEnabled,
                          onChanged: (val) {
                            provider.updateNotificationSettings(
                              user.uid,
                              settings.copyWith(reviewEnabled: val),
                            );
                          },
                        ),

                        // System Notifications
                        NotificationSettingTile(
                          title: 'System Bulletins',
                          subtitle: 'Get vital notifications about app maintenance and accounts.',
                          icon: Icons.notifications_paused_rounded,
                          value: settings.systemEnabled,
                          onChanged: (val) {
                            provider.updateNotificationSettings(
                              user.uid,
                              settings.copyWith(systemEnabled: val),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // Topic subscriptions details selector
                        NotificationTopicSelector(
                          settings: settings,
                          onChanged: (updatedSettings) {
                            provider.updateNotificationSettings(user.uid, updatedSettings);
                          },
                        ),
                      ],
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
}
