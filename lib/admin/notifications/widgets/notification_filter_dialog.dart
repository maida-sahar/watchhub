import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_colors.dart';
import '../../../config/app_typography.dart';
import '../../../config/clay_widgets.dart';
import '../../../providers/notification_provider.dart';

class NotificationFilterDialog extends StatefulWidget {
  const NotificationFilterDialog({super.key});

  @override
  State<NotificationFilterDialog> createState() => _NotificationFilterDialogState();
}

class _NotificationFilterDialogState extends State<NotificationFilterDialog> {
  late String _typeFilter;
  late String _recipientFilter;

  final Map<String, String> _typeOptions = {
    'all': 'All Types',
    'order': 'Order',
    'product': 'Product',
    'wishlist': 'Wishlist',
    'promotion': 'Promotion',
    'review': 'Review',
    'system': 'System',
  };

  final Map<String, String> _recipientOptions = {
    'all': 'All Targetings',
    'all_users': 'All Users',
    'role_customer': 'Customers Only',
    'role_admin': 'Admins Only',
    'specific_users': 'Specific Selected Users',
  };

  @override
  void initState() {
    super.initState();
    final provider = context.read<NotificationProvider>();
    _typeFilter = provider.typeFilter;
    _recipientFilter = provider.recipientFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: AppTypography.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: AppColors.divider, height: 24),
            
            // 1. Notification Type Section
            Text(
              'Notification Type',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _typeOptions.entries.map((entry) {
                final isSelected = _typeFilter == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.12),
                  backgroundColor: AppColors.surface,
                  labelStyle: AppTypography.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _typeFilter = entry.key;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 2. Recipient Targeting Section
            Text(
              'Recipient Group Target',
              style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recipientOptions.entries.map((entry) {
                final isSelected = _recipientFilter == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.12),
                  backgroundColor: AppColors.surface,
                  labelStyle: AppTypography.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _recipientFilter = entry.key;
                      });
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _typeFilter = 'all';
                        _recipientFilter = 'all';
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(
                      'Reset All',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ClayButton(
                    onPressed: () {
                      final provider = context.read<NotificationProvider>();
                      provider.setTypeFilter(_typeFilter);
                      provider.setRecipientFilter(_recipientFilter);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Apply Filters',
                      style: AppTypography.bodyLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
