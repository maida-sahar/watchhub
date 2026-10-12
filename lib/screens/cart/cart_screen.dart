import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/config/app_colors.dart';
import 'package:watch_hub/config/app_routes.dart';
import 'package:watch_hub/models/cart_model.dart';
import 'package:watch_hub/providers/cart_provider.dart';
import 'package:watch_hub/providers/checkout_provider.dart';
import 'widgets/cart_app_bar.dart';
import 'widgets/cart_empty_widget.dart';
import 'widgets/cart_list.dart';
import 'widgets/cart_shimmer.dart';
import 'widgets/cart_summary.dart';
import 'widgets/remove_item_dialog.dart';

/// Main screen of the Cart module.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  
  Future<void> _handleQuantityChanged(
    BuildContext context,
    CartModel item,
    int newQuantity,
  ) async {
    final cartProvider = context.read<CartProvider>();
    try {
      if (newQuantity <= 0) {
        // Automatically prompt to remove item if quantity becomes zero or less
        await _handleRemoveItem(context, item);
      } else {
        await cartProvider.updateQuantity(item.id, newQuantity);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, e.toString(), isError: true);
      }
    }
  }

  Future<void> _handleRemoveItem(BuildContext context, CartModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => RemoveItemDialog(productName: item.productName),
    );

    if (confirm == true && context.mounted) {
      final cartProvider = context.read<CartProvider>();
      try {
        await cartProvider.removeItem(item.id);
        if (context.mounted) {
          _showSnackBar(
            context,
            '${item.productName} removed from cart.',
            isError: false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          _showSnackBar(context, 'Failed to remove item: ${e.toString()}', isError: true);
        }
      }
    }
  }

  void _handleContinueShopping(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.customerHome,
        (route) => false,
      );
    }
  }

  void _handleCheckout(BuildContext context) {
    final cartProvider = context.read<CartProvider>();
    final checkoutProvider = context.read<CheckoutProvider>();
    checkoutProvider.prepareCheckout(cartProvider.cartItems);
    Navigator.of(context).pushNamed(AppRoutes.customerCheckout);
  }

  void _showSnackBar(BuildContext context, String message, {required bool isError}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CartAppBar(),
      body: Consumer<CartProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const CartShimmer();
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => provider.loadCart(userId),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.cartItems.isEmpty) {
            return CartEmptyWidget(
              onContinueShopping: () => _handleContinueShopping(context),
            );
          }

          return Column(
            children: [
              Expanded(
                child: CartList(
                  items: provider.cartItems,
                  subtotal: provider.subtotal,
                  discount: provider.discount,
                  grandTotal: provider.grandTotal,
                  onRemoveItem: (item) => _handleRemoveItem(context, item),
                  onQuantityChanged: (item, quantity) =>
                      _handleQuantityChanged(context, item, quantity),
                  isItemProcessing: (itemId) => provider.isItemProcessing(itemId),
                ),
              ),
              // Sticky bottom summary bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CartSummary(
                  grandTotal: provider.grandTotal,
                  itemsCount: provider.cartCount,
                  onCheckout: () => _handleCheckout(context),
                  onContinueShopping: () => _handleContinueShopping(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
