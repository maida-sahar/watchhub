import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;

  const NotificationBadge({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    // If not authenticated, just render base icon without count overlays
    if (!auth.isAuthenticated || auth.user == null) {
      return child;
    }

    final user = auth.user!;

    return Consumer<NotificationProvider>(
      builder: (context, notifProvider, _) {
        final count = notifProvider.getUnreadCount(user.uid, user.role);

        if (count == 0) {
          return child;
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
