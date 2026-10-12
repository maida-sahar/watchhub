import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:watch_hub/models/product_model.dart';
import 'package:watch_hub/models/wishlist_model.dart';

class WishlistCard extends StatelessWidget {
  final dynamic item; // Handles both ProductModel and WishlistModel cleanly
  final bool isProcessing;
  final VoidCallback onRemove;
  final VoidCallback onTap;
  final VoidCallback onMoveToCart;

  const WishlistCard({
    super.key,
    required this.item,
    this.isProcessing = false,
    required this.onRemove,
    required this.onTap,
    required this.onMoveToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String title = '';
    String image = '';
    String brand = '';
    double rawPrice = 0.0;
    double rawDiscount = 0.0;
    bool isStockAvailable = true;

    if (item is WishlistModel) {
      final w = item as WishlistModel;
      title = w.productName;
      image = w.productImage;
      brand = w.brandName;
      rawPrice = w.price;
      rawDiscount = w.discountPrice;
      isStockAvailable = w.isInStock;
    } else if (item is ProductModel) {
      final p = item as ProductModel;
      title = p.name;
      image = p.thumbnail.isNotEmpty ? p.thumbnail : (p.galleryImages.isNotEmpty ? p.galleryImages.first : '');
      brand = p.brandName;
      rawPrice = p.price;
      rawDiscount = p.discountPrice;
      isStockAvailable = p.stock > 0;
    }

    final hasDiscount = rawDiscount > 0 && rawDiscount < rawPrice;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: InkWell(
        onTap: isProcessing ? null : onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: image,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: theme.colorScheme.surfaceContainerHigh,
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHigh,
                        child: const Icon(Icons.watch, size: 40),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          theme.colorScheme.surface.withOpacity(0.85),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: theme.colorScheme.error,
                          size: 18,
                        ),
                        onPressed: isProcessing ? null : onRemove,
                      ),
                    ),
                  ),
                  if (!isStockAvailable)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Out of Stock',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (brand.isNotEmpty)
                    Text(
                      brand.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '\$${(hasDiscount ? rawDiscount : rawPrice).toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          '\$${rawPrice.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 34,
                    child: FilledButton.icon(
                      onPressed: (isProcessing || !isStockAvailable)
                          ? null
                          : onMoveToCart,
                      icon: isProcessing
                          ? SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.shopping_bag_outlined, size: 14),
                      label: Text(
                        isProcessing
                            ? 'Moving...'
                            : (!isStockAvailable ? 'Out of Stock' : 'Move To Cart'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
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