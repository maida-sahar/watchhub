import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/product_model.dart';
import '../../../providers/wishlist_provider.dart';

/// Related Product card displaying wishlist state and enabling fast toggle.
class RelatedProductCard extends StatelessWidget {
  final ProductModel product;
  final String currentUserId;
  final VoidCallback onTap;

  const RelatedProductCard({
    super.key,
    required this.product,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 150,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.4),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Image.network(
                          product.thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: theme.colorScheme.surfaceContainerHigh,
                            child: const Icon(Icons.watch),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Selector<WishlistProvider, bool>(
                        selector: (_, provider) =>
                            provider.checkWishlistStatusLocally(product.id),
                        builder: (context, isInWishlist, child) {
                          return CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                theme.colorScheme.surface.withOpacity(0.85),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                isInWishlist
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isInWishlist
                                    ? Colors.redAccent
                                    : theme.colorScheme.onSurfaceVariant,
                                size: 16,
                              ),
                              onPressed: () {
                                context.read<WishlistProvider>().toggleWishlist(
                                      userId: currentUserId,
                                      product: product,
                                    );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}