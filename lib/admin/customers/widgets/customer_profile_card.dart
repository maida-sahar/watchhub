import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';
import '../../../models/user_model.dart';
import 'customer_status_badge.dart';

class CustomerProfileCard extends StatelessWidget {
  final UserModel customer;

  const CustomerProfileCard({
    super.key,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    final joinDate = DateFormat('MMMM dd, yyyy').format(customer.createdAt);

    return ClayCard(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            // Large Avatar with Clay glow / border
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.background,
                backgroundImage: customer.photoUrl.isNotEmpty
                    ? NetworkImage(customer.photoUrl)
                    : null,
                child: customer.photoUrl.isEmpty
                    ? Text(
                        customer.name.isNotEmpty
                            ? customer.name[0].toUpperCase()
                            : '?',
                        style: AppTypography.headlineLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            // Customer Name
            Text(
              customer.name.isNotEmpty ? customer.name : 'No Name Provided',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Status Badge
            CustomerStatusBadge(
              isActive: customer.isActive,
              isBlocked: customer.isBlocked,
            ),
            const SizedBox(height: 16),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 8),
            // Join Date Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Joined: $joinDate',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
