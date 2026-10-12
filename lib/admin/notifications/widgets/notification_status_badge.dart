import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';

class NotificationStatusBadge extends StatelessWidget {
  final String type;

  const NotificationStatusBadge({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (type.trim().toLowerCase()) {
      case 'order':
        color = AppColors.primary;
        icon = Icons.receipt_long_rounded;
        break;
      case 'product':
        color = Colors.blue;
        icon = Icons.watch_rounded;
        break;
      case 'wishlist':
        color = Colors.pink;
        icon = Icons.favorite_rounded;
        break;
      case 'promotion':
        color = AppColors.success;
        icon = Icons.local_offer_rounded;
        break;
      case 'review':
        color = Colors.amber[800] ?? Colors.amber;
        icon = Icons.star_rounded;
        break;
      case 'system':
      default:
        color = Colors.blueGrey;
        icon = Icons.dns_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            type.toUpperCase(),
            style: AppTypography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}
