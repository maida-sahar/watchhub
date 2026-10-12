// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/config/clay_widgets.dart';
import 'package:watch_hub/models/checkout_model.dart';

class ShippingAddressCard extends StatelessWidget {
  final ShippingAddress address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;
  final bool isSelected;
  final bool showSelectionMode;

  const ShippingAddressCard({
    super.key,
    required this.address,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
    this.isSelected = false,
    this.showSelectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dynamic color for Address Type badge
    Color badgeColor;
    switch (address.addressType.toLowerCase()) {
      case 'home':
        badgeColor = Colors.blue.shade700;
        break;
      case 'office':
        badgeColor = AppColors.primary;
        break;
      default:
        badgeColor = Colors.purple.shade700;
    }

    final cardWidget = ClayCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      shadows: isSelected
          ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ]
          : null,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showSelectionMode) ...[
                Radio<bool>(
                  value: true,
                  groupValue: isSelected,
                  activeColor: AppColors.primary,
                  onChanged: (_) => onSetDefault(),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            address.addressType,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${address.streetAddress}, ${address.area}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      '${address.city}, ${address.province}, ${address.country} - ${address.postalCode}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.8),
                      ),
                    ),
                    if (address.landmark != null && address.landmark!.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Landmark: ${address.landmark}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          address.phone,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (address.alternatePhone != null && address.alternatePhone!.trim().isNotEmpty) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.phone_callback_outlined, size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            address.alternatePhone!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: AppColors.border),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!address.isDefault && !showSelectionMode) ...[
                          TextButton.icon(
                            onPressed: onSetDefault,
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: const Text('Set as Default'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.success,
                            ),
                          ),
                          const Spacer(),
                        ],
                        TextButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ));
    if (showSelectionMode) {
      return InkWell(
        onTap: onSetDefault,
        borderRadius: BorderRadius.circular(20),
        child: cardWidget,
      );
    }
    return cardWidget;
  }
}
