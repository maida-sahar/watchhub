import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/wishlist_provider.dart';

/// Card item for search result listings with synchronized wishlist toggle.
class SearchResultCard extends StatelessWidget {
  final ProductModel product;
  final String currentUserId;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.product,
    required this.currentUserId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: product.thumbnail,
            width: 48,
            height: 48,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 48,
              height: 48,
              color: theme.colorScheme.surfaceContainerHigh,
            ),
            errorWidget: (_, __, ___) => Container(
              width: 48,
              height: 48,
              color: theme.colorScheme.surfaceContainerHigh,
              child: const Icon(Icons.watch),
            ),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('\$${product.price.toStringAsFixed(2)} • ${product.brandName}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Selector<WishlistProvider, bool>(
              selector: (_, provider) =>
                  provider.checkWishlistStatusLocally(product.id),
              builder: (context, isInWishlist, child) {
                return IconButton(
                  icon: Icon(
                    isInWishlist
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isInWishlist ? Colors.redAccent : null,
                  ),
                  onPressed: () {
                    context.read<WishlistProvider>().toggleWishlist(
                          userId: currentUserId,
                          product: product,
                        );
                  },
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.add_shopping_cart_rounded,
                color: product.stock <= 0 ? theme.disabledColor : null,
              ),
              tooltip: product.stock <= 0 ? 'Out of stock' : 'Add to cart',
              onPressed: product.stock <= 0
                  ? null
                  : () async {
                      final cartProvider = context.read<CartProvider>();
                      final success = await cartProvider.addToCart(currentUserId, product);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? '${product.name} added to cart'
                                : cartProvider.errorMessage ?? 'Could not add to cart.',
                          ),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }
}