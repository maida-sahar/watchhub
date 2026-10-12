import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';
import '../../../models/user_model.dart';
import '../customer_details_screen.dart';
import 'customer_status_badge.dart';

class CustomerCard extends StatelessWidget {
  final UserModel customer;
  final int totalOrders;
  final double totalSpending;

  const CustomerCard({
    super.key,
    required this.customer,
    required this.totalOrders,
    required this.totalSpending,
  });

  @override
  Widget build(BuildContext context) {
    final joinDate = DateFormat('MMM dd, yyyy').format(customer.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailsScreen(customer: customer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: ClayCard(
          borderRadius: 24,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image or Initials Avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                    backgroundImage: customer.photoUrl.isNotEmpty
                        ? NetworkImage(customer.photoUrl)
                        : null,
                    child: customer.photoUrl.isEmpty
                        ? Text(
                            customer.name.isNotEmpty
                                ? customer.name[0].toUpperCase()
                                : '?',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  // Name and Contact info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                customer.name.isNotEmpty ? customer.name : 'No Name',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomerStatusBadge(
                              isActive: customer.isActive,
                              isBlocked: customer.isBlocked,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.email_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                customer.email,
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              customer.phone.isNotEmpty ? customer.phone : 'No Phone',
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.divider),
              // Order / Spend / Join Date Summary Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _summaryItem(
                    icon: Icons.receipt_long_outlined,
                    label: 'Orders',
                    value: '$totalOrders',
                  ),
                  _summaryItem(
                    icon: Icons.monetization_on_outlined,
                    label: 'Spent',
                    value: '\$${totalSpending.toStringAsFixed(2)}',
                    valueColor: AppColors.success,
                  ),
                  _summaryItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Joined',
                    value: joinDate,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
