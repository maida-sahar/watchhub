import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../models/cart_model.dart';
import 'quantity_selector.dart';

/// A card widget representing a single cart item.
class CartItemCard extends StatelessWidget {
  final CartModel item;
  final bool isProcessing;
  final VoidCallback onRemove;
  final Function(int) onQuantityChanged;

  const CartItemCard({
    super.key,
    required this.item,
    this.isProcessing = false,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount = item.discountPrice > 0 && item.discountPrice < item.price;
    final finalPrice = hasDiscount ? item.discountPrice : item.price;
    final lineTotal = finalPrice * item.quantity;

    // Stock warning status logic
    Widget stockStatusWidget;
    if (item.stock <= 0) {
      stockStatusWidget = Text(
        'Out of Stock',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      );
    } else if (item.stock <= 3) {
      stockStatusWidget = Text(
        'Only ${item.stock} left in stock',
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.orange[800],
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      stockStatusWidget = Text(
        'In Stock',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 90,
                height: 90,
                child: item.productImage.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.productImage,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.watch, size: 36),
                        ),
                      )
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.watch, size: 36),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.brandName.isNotEmpty)
                              Text(
                                item.brandName.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 2),
                            Text(
                              item.productName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Remove button
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.only(left: 8),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: theme.colorScheme.error.withOpacity(0.8),
                          size: 20,
                        ),
                        onPressed: isProcessing ? null : onRemove,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Stock status
                  stockStatusWidget,
                  const SizedBox(height: 8),
                  // Price row and quantity adjustments
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              children: [
                                Text(
                                  '\$${finalPrice.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (hasDiscount)
                                  Text(
                                    '\$${item.price.toStringAsFixed(2)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total: \$${lineTotal.toStringAsFixed(2)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      QuantitySelector(
                        quantity: item.quantity,
                        stock: item.stock,
                        onIncrement: () => onQuantityChanged(item.quantity + 1),
                        onDecrement: () => onQuantityChanged(item.quantity - 1),
                        onQuantityChanged: onQuantityChanged,
                        isProcessing: isProcessing,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}