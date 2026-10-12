import 'package:flutter/material.dart';
import 'package:watch_hub/config/app_shadows.dart';
import 'package:watch_hub/config/clay_widgets.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/config/app_typography.dart';
import 'package:watch_hub/config/app_spacing.dart';

import 'package:watch_hub/config/app_routes.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: ClayCard(
        borderRadius: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shadows: AppShadows.medium,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(Icons.home_rounded, 0, 'Home', context),
            _navItem(Icons.shopping_bag_outlined, 1, 'Cart', context),
            _navItem(Icons.favorite_border_rounded, 2, 'Wishlist', context),
            _navItem(Icons.person_outline_rounded, 3, 'Profile', context),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index, String label, BuildContext context) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () {
        switch (index) {
          case 0:
            Navigator.pushNamedAndRemoveUntil(context, AppRoutes.customerHome, (route) => false);
            break;
          case 1:
            Navigator.pushNamed(context, AppRoutes.customerCart);
            break;
          case 2:
            Navigator.pushNamed(context, AppRoutes.customerWishlist);
            break;
          case 3:
            Navigator.pushNamed(context, AppRoutes.customerProfile);
            break;
        }
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}