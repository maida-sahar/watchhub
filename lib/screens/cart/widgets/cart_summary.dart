import 'package:flutter/material.dart';
import '../../../config/clay_widgets.dart';

/// Sticky bottom panel displaying quick totals and primary action buttons.
class CartSummary extends StatelessWidget {
  final double grandTotal;
  final int itemsCount;
  final VoidCallback onCheckout;
  final VoidCallback onContinueShopping;

  const CartSummary({
    super.key,
    required this.grandTotal,
    required this.itemsCount,
    required this.onCheckout,
    required this.onContinueShopping,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClayCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderRadius: 24,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Price ($itemsCount ${itemsCount == 1 ? 'item' : 'items'})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${grandTotal.toStringAsFixed(2)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // Proceed button
                SizedBox(
                  width: 160,
                  child: ClayButton(
                    onPressed: itemsCount == 0 ? null : onCheckout,
                    child: Text(
                      'Checkout',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onContinueShopping,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
              child: const Text('Continue Shopping'),
            ),
          ],
        ),
      ),
    );
  }
}
