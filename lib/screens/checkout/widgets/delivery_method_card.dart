// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/config/clay_widgets.dart';
import 'package:watch_hub/models/checkout_model.dart';

class DeliveryMethodCard extends StatelessWidget {
  final DeliveryMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const DeliveryMethodCard({
    super.key,
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final op = method.isAvailable ? 1.0 : 0.5;

    return InkWell(
      onTap: method.isAvailable ? onTap : null,
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: op,
        child: ClayCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 20,
          shadows: isSelected && method.isAvailable
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
          child: Row(
            children: [
              Radio<bool>(
                value: isSelected,
                groupValue: true,
                activeColor: AppColors.primary,
                onChanged: method.isAvailable ? (_) => onTap() : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          method.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (!method.isAvailable) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Coming Soon',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    method.deliveryCharge == 0.0
                        ? 'Free'
                        : '\$${method.deliveryCharge.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.estimatedDeliveryDays == 0
                        ? 'Same Day'
                        : method.estimatedDeliveryDays == 1
                            ? '1 day'
                            : '${method.estimatedDeliveryDays} days',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
