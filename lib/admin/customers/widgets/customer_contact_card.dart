import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';
import '../../../models/user_model.dart';

class CustomerContactCard extends StatelessWidget {
  final UserModel customer;

  const CustomerContactCard({
    super.key,
    required this.customer,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Email Row
          _contactItem(
            context,
            icon: Icons.email_rounded,
            title: 'Email Address',
            value: customer.email,
            onCopy: () => _copyToClipboard(context, customer.email, 'Email'),
          ),
          const SizedBox(height: 16),
          // Phone Row
          _contactItem(
            context,
            icon: Icons.phone_rounded,
            title: 'Phone Number',
            value: customer.phone.isNotEmpty ? customer.phone : 'Not provided',
            onCopy: customer.phone.isNotEmpty
                ? () => _copyToClipboard(context, customer.phone, 'Phone number')
                : null,
          ),
        ],
      ),
    );
  }

  Widget _contactItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onCopy,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (onCopy != null)
          IconButton(
            icon: const Icon(
              Icons.copy_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Copy',
            onPressed: onCopy,
          ),
      ],
    );
  }
}
