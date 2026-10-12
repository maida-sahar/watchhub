import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/wishlist_provider.dart';
import 'widgets/product_actions.dart';
import 'widgets/product_badges.dart';
import 'widgets/product_header.dart';
import 'widgets/product_image_slider.dart';
import 'widgets/product_price.dart';
import 'widgets/product_rating.dart';
import 'widgets/product_reviews_section.dart';
import 'widgets/product_specifications.dart';
import 'widgets/product_stock_status.dart';

/// Details screen displaying product information, an interactive
/// wishlist toggle, and Add to Cart / Buy Now — both backed by the
/// existing [CartProvider] (same one used by [CartScreen]/[CheckoutScreen]),
/// no separate cart logic is created here.
class ProductDetailsScreen extends StatelessWidget {
  final ProductModel product;
  final String currentUserId;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    required this.currentUserId,
  });

  bool get _isOutOfStock => product.stock <= 0;

  void _showSnackBar(BuildContext context, String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
  }

  Future<void> _handleAddToCart(BuildContext context) async {
    if (currentUserId.isEmpty) {
      _showSnackBar(context, 'Please log in to add items to your cart.', isError: true);
      return;
    }
    final cartProvider = context.read<CartProvider>();
    final success = await cartProvider.addToCart(currentUserId, product);
    if (!context.mounted) return;
    _showSnackBar(
      context,
      success
          ? '${product.name} added to cart.'
          : (cartProvider.errorMessage ?? 'Could not add this item to your cart.'),
      isError: !success,
    );
  }

  /// Buy Now = add this product to the cart, then jump straight into the
  /// same Checkout flow the Cart screen's "Proceed to Checkout" uses —
  /// [CheckoutProvider.prepareCheckout] is what actually builds the
  /// active checkout session; without calling it first, CheckoutScreen
  /// has nothing to show ("No active checkout session").
  Future<void> _handleBuyNow(BuildContext context) async {
    if (currentUserId.isEmpty) {
      _showSnackBar(context, 'Please log in to continue.', isError: true);
      return;
    }

    final cartProvider = context.read<CartProvider>();
    final checkoutProvider = context.read<CheckoutProvider>();

    final added = await cartProvider.addToCart(currentUserId, product);
    if (!context.mounted) return;
    if (!added) {
      _showSnackBar(
        context,
        cartProvider.errorMessage ?? 'Could not add this item to your cart.',
        isError: true,
      );
      return;
    }

    // CartProvider.addToCart only waits for the write itself — the cart's
    // real-time listener (the source prepareCheckout reads from) can lag
    // a beat behind it. Give it a short, bounded window to catch up so
    // Buy Now always checks out with this item included, never a stale
    // cart snapshot.
    var waited = Duration.zero;
    const step = Duration(milliseconds: 50);
    const timeout = Duration(seconds: 2);
    while (!cartProvider.cartItemExists(product.id) && waited < timeout) {
      await Future.delayed(step);
      waited += step;
    }
    if (!context.mounted) return;

    await checkoutProvider.prepareCheckout(cartProvider.cartItems);
    if (!context.mounted) return;

    if (checkoutProvider.errorMessage != null) {
      _showSnackBar(context, checkoutProvider.errorMessage!, isError: true);
      return;
    }

    Navigator.pushNamed(context, AppRoutes.customerCheckout);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.brandName),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shows the thumbnail together with every gallery image
            // (product.galleryImages), with a swipeable slider and a
            // full-screen viewer on tap — instead of only the thumbnail.
            ProductImageSlider(
              thumbnail: product.thumbnail,
              galleryImages: product.galleryImages,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProductHeader(
                    name: product.name,
                    brandName: product.brandName,
                    categoryName: product.categoryName,
                    sku: product.sku,
                  ),
                  const SizedBox(height: 8),
                  ProductBadges(
                    isFeatured: product.isFeatured,
                    isBestSeller: product.isBestSeller,
                    isNewArrival: product.isNewArrival,
                    stock: product.stock,
                    minStock: product.minimumStock,
                  ),
                  const SizedBox(height: 8),
                  ProductPrice(
                    price: product.price,
                    discountPrice: product.discountPrice,
                  ),
                  const SizedBox(height: 8),
                  if (product.totalReviews > 0)
                    ProductRating(
                      averageRating: product.averageRating,
                      totalReviews: product.totalReviews,
                    ),
                  const SizedBox(height: 12),
                  ProductStockStatus(
                    stock: product.stock,
                    minStock: product.minimumStock,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  ProductSpecifications(specifications: product.specifications),
                  // Leaves room so the last bit of description isn't
                  // hidden behind the fixed Add to Cart / Buy Now bar.
                  const SizedBox(height: 24),
                ],
              ),
            ),
            const Divider(height: 1),
            ProductReviewsSection(product: product),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Selector<WishlistProvider, bool>(
        selector: (_, provider) => provider.checkWishlistStatusLocally(product.id),
        builder: (context, isInWishlist, _) {
          return ProductActions(
            isOutOfStock: _isOutOfStock,
            isWishlisted: isInWishlist,
            onToggleWishlist: () {
              context.read<WishlistProvider>().toggleWishlist(
                    userId: currentUserId,
                    product: product,
                  );
            },
            onAddToCart: () => _handleAddToCart(context),
            onBuyNow: () => _handleBuyNow(context),
          );
        },
      ),
    );
  }
}