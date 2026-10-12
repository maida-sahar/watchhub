import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../config/clay_widgets.dart';
import '../../../models/order_model.dart';

class OrderSummaryCard extends StatelessWidget {
  final OrderModel order;

  const OrderSummaryCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClayCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Subtotal', '\$${order.subtotal.toStringAsFixed(2)}', theme),
          const SizedBox(height: 12),
          if (order.discount > 0) ...[
            _buildSummaryRow(
              'Product Discount',
              '-\$${order.discount.toStringAsFixed(2)}',
              theme,
              valueColor: AppColors.success,
            ),
            const SizedBox(height: 12),
          ],
          if (order.couponDiscount > 0) ...[
            _buildSummaryRow(
              'Coupon Discount',
              '-\$${order.couponDiscount.toStringAsFixed(2)}',
              theme,
              valueColor: AppColors.success,
            ),
            const SizedBox(height: 12),
          ],
          _buildSummaryRow('Shipping Charges', '\$${order.shippingCharge.toStringAsFixed(2)}', theme),
          const SizedBox(height: 12),
          _buildSummaryRow('Estimated Tax', '\$${order.tax.toStringAsFixed(2)}', theme),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Grand Total',
            '\$${order.grandTotal.toStringAsFixed(2)}',
            theme,
            isGrandTotal: true,
            valueColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    ThemeData theme, {
    Color? valueColor,
    bool isGrandTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isGrandTotal ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isGrandTotal ? 16 : 14,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: isGrandTotal ? 18 : 14,
          ),
        ),
      ],
    );
  }
}
