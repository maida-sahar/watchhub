import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/config/clay_widgets.dart';
import 'package:watch_hub/models/checkout_model.dart';

class OrderSummary extends StatelessWidget {
  final CheckoutModel checkout;
  final DateTime? estimatedDeliveryDate;

  const OrderSummary({
    super.key,
    required this.checkout,
    this.estimatedDeliveryDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Format delivery date nicely
    final deliveryDate = estimatedDeliveryDate ??
        DateTime.now().add(
          Duration(days: checkout.deliveryMethod?.estimatedDeliveryDays ?? 5),
        );
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(deliveryDate);

    return ClayCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildRow('Subtotal', checkout.subtotal, theme),
          if (checkout.discount > 0)
            _buildRow('Product Discount', -checkout.discount, theme, isSuccess: true),
          if (checkout.couponDiscount > 0)
            _buildRow('Coupon Discount', -checkout.couponDiscount, theme, isSuccess: true),
          _buildRow('Shipping Charge', checkout.shippingCharge, theme),
          _buildRow('Tax (Placeholder)', checkout.tax, theme),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grand Total',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '\$${checkout.grandTotal.toStringAsFixed(2)}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (checkout.deliveryMethod != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Delivery',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedDate,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    double value,
    ThemeData theme, {
    bool isSuccess = false,
  }) {
    final valueText = value < 0
        ? '-\$${value.abs().toStringAsFixed(2)}'
        : '\$${value.toStringAsFixed(2)}';
    final valueColor = isSuccess ? AppColors.success : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            valueText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: isSuccess ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
