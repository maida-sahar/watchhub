import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_hub/widgets/app_header.dart';
import '../../../providers/cart_provider.dart';

/// App bar showing the cart title, dynamic badge count, and clear cart options.
class CartAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CartAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Future<void> _handleClearCart(BuildContext context) async {
    final theme = Theme.of(context);
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final cartProvider = context.read<CartProvider>();
      await cartProvider.clearCart(userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cart cleared successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartProvider, int>((p) => p.cartCount);

    return AppHeader(
      title: 'Shopping Cart',
      subtitle: count > 0 ? '$count item${count == 1 ? '' : 's'}' : '0 items',
      actions: [
        if (count > 0)
          AppHeaderActionButton(
            tooltip: 'Clear Cart',
            icon: Icon(
              Icons.delete_sweep_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => _handleClearCart(context),
          ),
      ],
    );
  }
}
