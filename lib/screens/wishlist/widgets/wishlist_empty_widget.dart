import 'package:flutter/material.dart';

/// Displayed when the user's wishlist is empty.
class WishlistEmptyWidget extends StatelessWidget {
  final VoidCallback? onContinueShopping;

  const WishlistEmptyWidget({
    super.key,
    this.onContinueShopping,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 72,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Wishlist is Empty',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Explore WatchHub collections and save your favorite timepieces for later.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            if (onContinueShopping != null)
              FilledButton.icon(
                onPressed: onContinueShopping,
                icon: const Icon(Icons.watch),
                label: const Text('Continue Shopping'),
              ),
          ],
        ),
      ),
    );
  }
}