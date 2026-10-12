import 'package:flutter/material.dart';

import '../../../models/order_model.dart';

/// Displays an order's price breakdown: subtotal, discounts, shipping,
/// tax, and grand total.
class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Summary',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _row(theme, 'Subtotal', order.subtotal, order.currency),
            if (order.discount > 0)
              _row(theme, 'Discount', -order.discount, order.currency, isDeduction: true),
            if (order.couponDiscount > 0)
              _row(theme, 'Coupon Discount', -order.couponDiscount, order.currency, isDeduction: true),
            _row(theme, 'Shipping', order.shippingCharge, order.currency),
            if (order.tax > 0) _row(theme, 'Tax', order.tax, order.currency),
            const Divider(height: 24),
            _row(
              theme,
              'Grand Total',
              order.grandTotal,
              order.currency,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    String label,
    double amount,
    String currency, {
    bool isTotal = false,
    bool isDeduction = false,
  }) {
    final valueStyle = isTotal
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : theme.textTheme.bodyMedium?.copyWith(
            color: isDeduction ? Colors.green.shade700 : null,
          );
    final labelStyle = isTotal
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    final sign = isDeduction ? '-' : '';
    final displayAmount = amount.abs();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Text('$sign$currency ${displayAmount.toStringAsFixed(2)}', style: valueStyle),
        ],
      ),
    );
  }
}