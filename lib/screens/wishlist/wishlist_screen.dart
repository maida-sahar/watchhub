import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_routes.dart';
import '../../models/product_model.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/cart_provider.dart';
import '../products/product_details_screen.dart';
import 'widgets/remove_confirmation_dialog.dart';
import 'widgets/wishlist_app_bar.dart';
import 'widgets/wishlist_card.dart';
import 'widgets/wishlist_empty_widget.dart';
import 'widgets/wishlist_shimmer.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  Future<void> _handleMoveToCart(
      BuildContext context, ProductModel product) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isEmpty) {
      _showSnackBar(context, 'Please log in to manage your cart.',
          isError: true);
      return;
    }

    final wishlistProvider = context.read<WishlistProvider>();

    try {
      await wishlistProvider.moveToCart(
        userId: userId,
        product: product,
        onAddToCartDelegate: (prod) async {
          return await context.read<CartProvider>().addToCart(userId, prod);
        },
      );

      if (context.mounted) {
        _showSnackBar(
          context,
          '${product.name} moved to cart successfully!',
          isError: false,
        );
      }
    } on OutOfStockException catch (e) {
      if (context.mounted) _showSnackBar(context, e.message, isError: true);
    } on DuplicateCartItemException catch (e) {
      if (context.mounted) _showSnackBar(context, e.message, isError: true);
    } on WishlistException catch (e) {
      if (context.mounted) _showSnackBar(context, e.message, isError: true);
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'An unexpected error occurred. Please try again.',
            isError: true);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message,
      {required bool isError}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: const WishlistAppBar(),
      body: Consumer<WishlistProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const WishlistShimmer();
          }

          if (provider.wishlistItems.isEmpty) {
            return WishlistEmptyWidget(
              onContinueShopping: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppRoutes.customerHome,
                  (route) => false,
                );
              },
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: provider.wishlistItems.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final item = provider.wishlistItems[index];
                  final isProcessing = provider.isItemProcessing(item.id);

                  return WishlistCard(
                    item: item,
                    isProcessing: isProcessing,
                    onRemove: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => RemoveConfirmationDialog(productName: item.name),
                      );
                      if (confirm == true) {
                        try {
                          await provider.removeFromWishlist(
                            userId: currentUserId,
                            productId: item.id,
                          );
                          if (context.mounted) {
                            _showSnackBar(
                                context, '${item.name} removed from wishlist.',
                                isError: false);
                          }
                        } catch (_) {
                          if (context.mounted) {
                            _showSnackBar(
                                context, 'Failed to remove product.',
                                isError: true);
                          }
                        }
                      }
                    },
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsScreen(
                            product: item,
                            currentUserId: currentUserId,
                          ),
                        ),
                      );
                    },
                    onMoveToCart: () => _handleMoveToCart(context, item),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}