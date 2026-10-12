import 'package:flutter/material.dart';
import 'package:watch_hub/config/app_colors.dart';

class ProductBadges extends StatelessWidget {
  final bool isFeatured;
  final bool isBestSeller;
  final bool isNewArrival;
  final int stock;
  final int minStock;

  const ProductBadges({
    super.key,
    required this.isFeatured,
    required this.isBestSeller,
    required this.isNewArrival,
    required this.stock,
    this.minStock = 5,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> badges = [];

    if (isFeatured) {
      badges.add(_buildBadge('Featured', AppColors.primary, AppColors.primaryLight.withOpacity(0.3)));
    }
    if (isBestSeller) {
      badges.add(_buildBadge('Best Seller', AppColors.accent, AppColors.accent.withOpacity(0.12)));
    }
    if (isNewArrival) {
      badges.add(_buildBadge('New Arrival', AppColors.accent, AppColors.surfaceVariant));
    }
    if (stock <= 0) {
      badges.add(_buildBadge('Out Of Stock', AppColors.error, AppColors.error.withOpacity(0.1)));
    } else if (stock <= minStock) {
      badges.add(_buildBadge('Low Stock', AppColors.primary, AppColors.primaryLight.withOpacity(0.2)));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: badges,
    );
  }

  Widget _buildBadge(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}