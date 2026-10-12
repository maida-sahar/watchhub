import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';

class CustomerStatusBadge extends StatelessWidget {
  final bool isActive;
  final bool isBlocked;

  const CustomerStatusBadge({
    super.key,
    required this.isActive,
    required this.isBlocked,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    if (isBlocked) {
      label = 'Blocked';
      color = AppColors.error;
    } else if (!isActive) {
      label = 'Inactive';
      color = Colors.amber[800] ?? Colors.amber;
    } else {
      label = 'Active';
      color = AppColors.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
