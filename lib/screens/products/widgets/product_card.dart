import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:watch_hub/models/product_model.dart';
import 'package:watch_hub/providers/auth_provider.dart';
import 'package:watch_hub/providers/cart_provider.dart';
import 'package:watch_hub/providers/wishlist_provider.dart';
import 'package:watch_hub/config/app_colors.dart';

/// Product card used across the User App (Home Page sections, Category
/// listing, Product catalogue/search) so every screen renders products
/// the exact same way.
///
/// Reads real product data only — no placeholder/dummy fields — and
/// wires the wishlist heart button straight into the existing
/// [WishlistProvider], the same one used by [ProductDetailsScreen].
class UserProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onTap;

  const UserProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  bool get _hasDiscount =>
      product.discountPrice > 0 && product.discountPrice < product.price;

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().currentUid ?? '';
    final imageUrl =
        product.thumbnail.isNotEmpty ? product.thumbnail : (product.galleryImages.isNotEmpty ? product.galleryImages.first : '');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Hero(
                    tag: 'product_${product.id}',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: SizedBox(
                        width: double.infinity,
                        child: _ProductImage(imageUrl: imageUrl),
                      ),
                    ),
                  ),
                  if (_hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          '-${product.discountPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (product.stock <= 0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black.withOpacity(0.6),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        alignment: Alignment.center,
                        child: const Text(
                          'OUT OF STOCK',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Selector<WishlistProvider, bool>(
                      selector: (_, provider) => provider.checkWishlistStatusLocally(product.id),
                      builder: (context, isInWishlist, child) {
                        return Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              context.read<WishlistProvider>().toggleWishlist(
                                    userId: currentUserId,
                                    product: product,
                                  );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                isInWishlist ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                size: 18,
                                color: isInWishlist ? Colors.redAccent : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Quick-view + Add to Cart cluster — mirrors the existing
                  // wishlist circle's style, kept in the image Stack so the
                  // card's overall size/proportions never change.
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CircleIconButton(
                          icon: Icons.remove_red_eye_outlined,
                          onTap: onTap,
                          tooltip: 'View details',
                        ),
                        const SizedBox(width: 6),
                        _CircleIconButton(
                          icon: Icons.add_shopping_cart_rounded,
                          tooltip: product.stock <= 0 ? 'Out of stock' : 'Add to cart',
                          onTap: product.stock <= 0
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.brandName.isNotEmpty)
                    Text(
                      product.brandName.toUpperCase(),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.accent),
                    ),
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  if (product.averageRating > 0) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 2),
                        Text(
                          product.averageRating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        if (product.totalReviews > 0)
                          Text(
                            ' (${product.totalReviews})',
                            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\$${product.discountPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                      ),
                      if (_hasDiscount) ...[
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, decoration: TextDecoration.lineThrough, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
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

/// Small white circular icon button matching the existing wishlist button's
/// style — reused for the View and Add-to-Cart quick actions so all three
/// icons look consistent. A null [onTap] renders the button disabled
/// (e.g. Add to Cart when the product is out of stock).
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDisabled ? Colors.white.withOpacity(0.6) : Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              size: 16,
              color: isDisabled ? AppColors.textTertiary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Handles the three real-world states a product image can be in:
/// a valid remote URL, a missing URL, or an invalid/broken URL — never
/// falling back to a local placeholder "product".
class _ProductImage extends StatelessWidget {
  final String imageUrl;

  const _ProductImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _placeholder();
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      ),
      errorWidget: (context, url, error) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.surfaceVariant,
      alignment: Alignment.center,
      child: const Icon(Icons.watch_outlined, size: 36, color: AppColors.textTertiary),
    );
  }
}